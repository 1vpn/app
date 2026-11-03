import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:onexray/core/pigeon/constants.dart';
import 'package:onexray/core/pigeon/host_api.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/core/tools/json.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/service/advanced/xray/geodata/service.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:path/path.dart' as p;

/// Where the in-place reload stands.
///
/// Each settings reload goes connected, reloading, then connected,
/// rolledBack, or failed. The policy returns to connected once it answers
/// the outcome. A network reload leaves the state unchanged.
enum OneVpnReloadState {
  /// No reload runs.
  connected,

  /// The policy prepares, validates, reloads, or confirms a change.
  reloading,

  /// The change did not apply. The previous core runs.
  rolledBack,

  /// The reload failed twice. The TUN is held with no core.
  failed,
}

/// The answer [OneVpnReloadPolicy.applyInPlace] gives for one change.
enum OneVpnReloadOutcome {
  /// The new core runs. The policy commits the change.
  applied,

  /// The change did not apply. The policy commits nothing. The previous
  /// core runs.
  rolledBack,

  /// A stop or a start moved the tunnel during the reload. The winning
  /// command owns the state. The policy commits nothing.
  superseded,

  /// The change cannot reload in place while the tunnel runs. The caller
  /// takes the reconnect path.
  needsReconnect,

  /// No core runs to reload. The caller commits without a reconnect.
  notRunning,

  /// No core runs over a held TUN: a network reload failed twice during
  /// the change. The policy commits and releases nothing, so the network
  /// retry stays armed. The caller takes the red landing.
  held,
}

/// An outcome with the notice of the applied runtime, such as
/// `selectionReset`.
typedef OneVpnReloadResult = ({OneVpnReloadOutcome outcome, String? notice});

/// Prepares the runtime for a change while [running] still carries traffic.
typedef OneVpnReloadPrepare = Future<ConnectionRuntime> Function(
  ConnectionCoordinator coordinator,
  ConnectionConfiguration next,
  ConnectionRuntime running,
);

/// The staged request the native reload reads, at its fixed path.
class OneVpnReloadStage {
  OneVpnReloadStage({this._file});

  /// The staged file name in the run directory. The native side reads the
  /// same path.
  static const fileName = 'onevpn_start.next.json';

  final File? _file;

  File get _target => _file ?? File(p.join(VpnConstants.runDir, fileName));

  /// Writes [request] to a temporary file named for [requestId], then
  /// renames it over the staged path. The native side reads a whole request
  /// or none.
  Future<void> write(
    StartVpnRequest request, {
    required String requestId,
  }) async {
    final target = _target;
    final temporary = File('${target.path}.$requestId.tmp');
    await target.parent.create(recursive: true);
    try {
      await temporary.writeAsString(
        JsonTool.encoder.convert(request.toJson()),
        flush: true,
      );
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  /// Removes a staged request that no reload claimed.
  Future<void> clear() async {
    final target = _target;
    if (await target.exists()) await target.delete();
  }
}

/// Applies a location or direct-regions change to a connected tunnel by
/// reloading its core in place, with the TUN up. [applyInPlace] states the
/// outcome of each change.
///
/// The native side runs network reloads on its own. The policy drops their
/// events, so a network reload leaves [state] unchanged. The policy commits
/// nothing for a network reload, shows no notice, and never retries it.
class OneVpnReloadPolicy {
  OneVpnReloadPolicy({
    OneVpnHandoverHost? host,
    OneVpnHandoverEvents? events,
    bool? supported,
    OneVpnReloadPrepare? prepare,
    Future<String> Function(String xrayJson)? validate,
    OneVpnReloadStage? stage,
    Future<void> Function(Future<void> Function() action)? withFiles,
    OneVpnHeldTunnel? held,
  }) : _host = host ?? OneVpnHandoverHost(),
       _held = held ?? OneVpnHeldTunnel.instance,
       events = events ?? OneVpnHandoverEvents(),
       supported = supported ?? defaultTargetPlatform == TargetPlatform.android,
       _prepare = prepare ?? _nativePrepare,
       _validate = validate ?? ((xrayJson) => AppHostApi().testXray(xrayJson)),
       _stage = stage ?? OneVpnReloadStage(),
       _withFiles =
           withFiles ?? ((action) => GeoDataService().withFiles(action));

  /// The shared policy the change helpers and the connect screen use.
  static final instance = OneVpnReloadPolicy();

  final OneVpnHandoverHost _host;
  final OneVpnHeldTunnel _held;

  /// The native event receiver. [attach] registers it.
  final OneVpnHandoverEvents events;

  /// Whether this platform reloads in place. Elsewhere every change takes
  /// the reconnect path.
  final bool supported;

  final OneVpnReloadPrepare _prepare;
  final Future<String> Function(String xrayJson) _validate;
  final OneVpnReloadStage _stage;
  final Future<void> Function(Future<void> Function() action) _withFiles;

  /// The current reload state. The status label and the settings pages
  /// read it.
  final state = ValueNotifier(OneVpnReloadState.connected);

  final _lastEvent = ValueNotifier<ReloadEvent?>(null);

  /// The last accepted event of the settings reload in flight. The policy
  /// drops the events of any other reload.
  @visibleForTesting
  ValueListenable<ReloadEvent?> get lastEvent => _lastEvent;

  static final _random = Random.secure();
  int _sequence = 0;
  String? _inFlight;
  StreamSubscription<ReloadEvent>? _subscription;

  /// Registers [events] on the default messenger and starts filtering
  /// them. Calling it again does nothing.
  void attach() {
    if (_subscription != null) return;
    events.attach();
    _subscription = events.events.listen(_onEvent);
  }

  void _onEvent(ReloadEvent event) {
    final accepted =
        event.trigger == ReloadTrigger.settings &&
        event.requestId != null &&
        event.requestId == _inFlight;
    ygLogger(
      'OneVpnReloadPolicy: ${accepted ? 'event' : 'dropped'} '
      '${event.requestId} ${event.phase.name} ${event.result?.name}',
    );
    if (accepted) _lastEvent.value = event;
  }

  /// Applies [next] to the connected tunnel in place.
  ///
  /// Each change runs in the coordinator's serial queue, then in the
  /// geodata file lock, as [ConnectionCoordinator.apply] takes them. It
  /// prepares while the old core carries traffic and never probes.
  /// [expectedConfiguration] is the stored configuration that the caller
  /// built [next] from. The outcomes:
  ///
  /// - applied: the native side applied, and `start.json` carries the
  ///   prepared identity. The policy commits the change.
  /// - rolledBack: the stored configuration differs from
  ///   [expectedConfiguration], or preparation or testXray failed. It also
  ///   covers a native rollback and an applied reload with another identity.
  /// - needsReconnect: this platform cannot reload, the TUN would change, or
  ///   the native side answers invalidRequest or notSupported. It also
  ///   covers a timeout that leaves another identity and a failed step after
  ///   the native call.
  /// - notRunning: no core runs to reload.
  /// - superseded: a stop or a start moved the tunnel.
  /// - held: no core runs over a held TUN.
  ///
  /// A timeout reads the identity: the prepared one counts as applied. A
  /// double failure throws after the coordinator publishes it.
  ///
  /// The coordinator publishes the running core once the queue releases. An
  /// applied reload publishes the prepared runtime as connected while the
  /// app is in the background too. A measure core it installs then starts
  /// its pin without waiting for the next resume.
  ///
  /// The connected status is trusted with no native query. A native stop
  /// that lands while the reload settles can be drained before it. The view
  /// then reads connected over a stopped tunnel until the next native
  /// status or resume. The window is the length of one coordinator
  /// refresh.
  ///
  /// [prepare] prepares this change in place of the policy's prepare.
  Future<OneVpnReloadResult> applyInPlace(
    ConnectionCoordinator coordinator,
    ConnectionConfiguration next, {
    required String expectedConfiguration,
    OneVpnReloadPrepare? prepare,
  }) async {
    if (!supported) return _needsReconnect;
    OneVpnReloadResult? result;
    try {
      await coordinator.runExclusive(
        () => _withFiles(() async {
          result = await _reload(
            coordinator,
            next,
            expectedConfiguration,
            prepare ?? _prepare,
          );
        }),
      );
      // Runs after the queue releases: the refresh publishes the runtime
      // that start.json names. The applied answer confirms a running core.
      // The coordinator takes an observed status in the background too.
      await coordinator.refresh(
        observedStatus: result?.outcome == OneVpnReloadOutcome.applied
            ? VpnStatus.connected
            : null,
      );
      return result!;
    } finally {
      state.value = OneVpnReloadState.connected;
    }
  }

  static const OneVpnReloadResult _needsReconnect = (
    outcome: OneVpnReloadOutcome.needsReconnect,
    notice: null,
  );

  /// Runs one change through [prepare]. Only a double failure throws: every
  /// other error answers rolledBack before the native call and needsReconnect
  /// after it.
  Future<OneVpnReloadResult> _reload(
    ConnectionCoordinator coordinator,
    ConnectionConfiguration next,
    String expectedConfiguration,
    OneVpnReloadPrepare prepare,
  ) async {
    if (!await _host.reloadSupported()) return _notRunning();
    final ConnectionRuntime prepared;
    final String requestId;
    try {
      final running = await coordinator.readCurrentRuntime();
      if (running == null) return _settle(OneVpnReloadOutcome.needsReconnect);
      state.value = OneVpnReloadState.reloading;
      if ((await coordinator.configuration).encode() != expectedConfiguration) {
        return _settle(OneVpnReloadOutcome.rolledBack);
      }
      prepared = await prepare(coordinator, next, running);
      if (!_sameTun(running, prepared)) {
        return _settle(OneVpnReloadOutcome.needsReconnect);
      }
      final rejection = await _validate(prepared.xrayJson);
      if (rejection.isNotEmpty) {
        ygLogger('OneVpnReloadPolicy: testXray rejected the change');
        return _settle(OneVpnReloadOutcome.rolledBack);
      }
      requestId = _nextRequestId();
      // Every request stages its own file. The reply clears one that no
      // reload claimed.
      await _stage.write(prepared.request, requestId: requestId);
    } catch (error) {
      ygLogger('OneVpnReloadPolicy: preparation failed (${error.runtimeType})');
      return _settle(OneVpnReloadOutcome.rolledBack);
    }
    _inFlight = requestId;
    final ReloadResult answer;
    try {
      answer = await _host.reload(requestId);
    } finally {
      _inFlight = null;
      await _clearStage();
    }
    ygLogger('OneVpnReloadPolicy: reply $requestId ${answer.name}');
    switch (answer) {
      case ReloadResult.applied || ReloadResult.timeout:
        try {
          return await _confirm(
            coordinator,
            prepared,
            late: answer == ReloadResult.timeout,
          );
        } catch (error) {
          // The stored configuration still equals the expected one, so the
          // reconnect path reconciles it with the running core.
          ygLogger('OneVpnReloadPolicy: confirm failed (${error.runtimeType})');
          return _settle(OneVpnReloadOutcome.needsReconnect);
        }
      case ReloadResult.rolledBack:
        return _settle(OneVpnReloadOutcome.rolledBack);
      case ReloadResult.failed:
        state.value = OneVpnReloadState.failed;
        throw const ConnectionHostException('startFailed');
      case ReloadResult.superseded:
        return _settle(OneVpnReloadOutcome.superseded);
      case ReloadResult.notRunning:
        return _notRunning();
      case ReloadResult.invalidRequest || ReloadResult.notSupported:
        return _settle(OneVpnReloadOutcome.needsReconnect);
    }
  }

  /// Confirms a reload by the runtime identity, then commits. On an applied
  /// answer, a different identity counts as a rollback. After a timeout,
  /// the prepared identity means the reload applied late. Any other
  /// identity means the state is unknown.
  Future<OneVpnReloadResult> _confirm(
    ConnectionCoordinator coordinator,
    ConnectionRuntime prepared, {
    required bool late,
  }) async {
    final current = await coordinator.readCurrentRuntime();
    if (current?.identity != prepared.identity) {
      return _settle(
        late
            ? OneVpnReloadOutcome.needsReconnect
            : OneVpnReloadOutcome.rolledBack,
      );
    }
    await coordinator.db.connectionConfigDao.commit(
      configurationJson: prepared.configuration.encode(),
    );
    return _settle(OneVpnReloadOutcome.applied, notice: prepared.notice);
  }

  OneVpnReloadResult _settle(OneVpnReloadOutcome outcome, {String? notice}) {
    state.value = outcome == OneVpnReloadOutcome.rolledBack
        ? OneVpnReloadState.rolledBack
        : OneVpnReloadState.connected;
    return (outcome: outcome, notice: notice);
  }

  /// Answers notRunning, or held when the TUN is held. The held answer
  /// publishes the held signal, which renders the red state. It passes no
  /// failure through the serial queue. The native retry's connected status
  /// then clears the red state.
  Future<OneVpnReloadResult> _notRunning() async {
    bool held;
    try {
      held = await _held.refresh();
    } catch (error) {
      ygLogger('OneVpnReloadPolicy: held read failed (${error.runtimeType})');
      held = false;
    }
    if (!held) return _settle(OneVpnReloadOutcome.notRunning);
    state.value = OneVpnReloadState.failed;
    return (outcome: OneVpnReloadOutcome.held, notice: null);
  }

  Future<void> _clearStage() async {
    try {
      await _stage.clear();
    } catch (error) {
      ygLogger('OneVpnReloadPolicy: stage clear failed (${error.runtimeType})');
    }
  }

  /// A request id that no other reload uses, across restarts too. Network
  /// reload ids start with `network-` instead.
  String _nextRequestId() =>
      'settings-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}-'
      '${_random.nextInt(1 << 32).toRadixString(16)}';

  static bool _sameTun(ConnectionRuntime a, ConnectionRuntime b) =>
      jsonEncode(a.request.tun?.toJson()) ==
      jsonEncode(b.request.tun?.toJson());

  /// The native connect's reload prepare. It reads
  /// [OneVpnNativeConnect.instance] at each call.
  static Future<ConnectionRuntime> _nativePrepare(
    ConnectionCoordinator coordinator,
    ConnectionConfiguration next,
    ConnectionRuntime running,
  ) => OneVpnNativeConnect.instance.reloadPrepare(coordinator, next, running);
}
