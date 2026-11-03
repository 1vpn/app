import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/preparation.dart';
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/routing/custom/state.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

/// Prepares [configuration] through [resolver] and starts no core.
///
/// [cancelled] ends the wait. [onResolved] receives the resolved ids.
typedef OneVpnPreparation = Future<ConnectionRuntime> Function(
  ConnectionConfiguration configuration,
  ConnectionResolver resolver, {
  Future<void>? cancelled,
  void Function(Set<int>)? onResolved,
});

/// Wraps [preparation] so a location selection never falls back to
/// Automatic.
///
/// A prepare that moved a location selection to Automatic throws
/// [ConnectionResolutionFailure.selectionUnavailable] instead. The selection
/// then stays, and the connect, reconnect, or reload fails with an error.
/// Every other prepare passes through unchanged.
OneVpnPreparation oneVpnKeepLocation(OneVpnPreparation preparation) =>
    (configuration, resolver, {cancelled, onResolved}) async {
      final runtime = await preparation(
        configuration,
        resolver,
        cancelled: cancelled,
        onResolved: onResolved,
      );
      if (configuration.connection.selection.kind == SelectionKind.location &&
          runtime.notice == 'selectionReset') {
        throw const ConnectionResolutionException(
          ConnectionResolutionFailure.selectionUnavailable,
        );
      }
      return runtime;
    };

/// The candidate one observatory read picks.
class OneVpnPick {
  const OneVpnPick({
    required this.id,
    required this.account,
    required this.delayMs,
  });

  /// The row id of the candidate.
  final int id;

  /// Whether the candidate is an account row. Otherwise it is a free row.
  final bool account;

  /// The candidate's mean probe round trip, in milliseconds.
  final int delayMs;
}

/// How one [OneVpnNativeConnect.run] ends.
enum OneVpnPinOutcome {
  /// The pin applied. The pinned runtime carries the traffic.
  pinned,

  /// The measure core stays up and blocks every flow. A second rolled-back
  /// pin ends the run here. So do a pin that cannot reload in place and the
  /// last of [OneVpnNativeConnect.pinAttempts] missed pins.
  held,

  /// The run ended with no pin. A stop or another runtime replaced the
  /// measure core.
  stopped,

  /// The hold read no alive result for [OneVpnNativeConnect.holdRounds]
  /// probe rounds. The run stopped the measure core and published a failed
  /// view with [oneVpnHoldExpiredIssue].
  expired,
}

/// Connects through one measure core, then pins one candidate.
///
/// An Automatic selection measures to find the fastest server. Any other
/// selection measures to guard its pick: a dead server is never pinned, and
/// no alive server starts the hold.
///
/// Phase 1 starts a measure core. The core probes every candidate in scope
/// and blocks every flow. Phase 2 reads the core's observatory, picks a
/// candidate, and pins it through an in-place reload. The pinned runtime
/// then carries the traffic through that one entry.
///
/// No alive result by [allDeadCap] starts the hold. The measure core keeps
/// blocking every flow, and [allDead] reads true. The first alive result
/// then opens [firstResultWindow], as on a fresh measure. A hold with no
/// alive result for [holdCap] expires. The run then stops the measure core
/// and leaves a failed view that a tap retries.
///
/// A pin lands whether or not the app is visible. The pin's reload
/// publishes an observed connected status, which the coordinator takes in
/// the background. The run lives in the Flutter engine and stops with it.
///
/// Where [supported] is false, nothing measures. The prepare pins the last
/// pin when it is in scope. Otherwise it pins the lowest id in scope.
class OneVpnNativeConnect {
  OneVpnNativeConnect({
    required ConnectionCoordinator coordinator,
    required OneVpnReloadPolicy reloads,
    required this._observatory,
    required this._measureConfig,
    Future<String> Function()? probeUrl,
    bool? supported,
    Stream<List<CoreConfigData>> Function()? rows,
    OneVpnPreparation? preparation,
  }) : _coordinator = coordinator,
       _reloads = reloads,
       probeUrl = probeUrl ?? ProbeEndpoints.resolve,
       supported = supported ?? reloads.supported,
       _rows = rows ?? (() => coordinator.db.coreConfigDao.watchOutbounds()),
       _preparation = oneVpnKeepLocation(
         preparation ??
             ((configuration, resolver, {cancelled, onResolved}) =>
                 ConnectionPreparation(
                   db: coordinator.db,
                   resolver: resolver,
                 ).prepare(
                   configuration,
                   cancelled: cancelled,
                   onResolved: onResolved,
                 )),
       );

  static OneVpnNativeConnect? _instance;

  /// The native connect the app uses. [install] sets it at boot.
  ///
  /// Before [install] runs, it is an idle one over the shared coordinator
  /// and reload policy. Nothing attaches it, so [measuring] and [allDead]
  /// stay false. It measures nothing.
  static OneVpnNativeConnect get instance => _instance ??= OneVpnNativeConnect(
    coordinator: ConnectionCoordinator.instance,
    reloads: OneVpnReloadPolicy.instance,
    observatory: const _IdleObservatory(),
    measureConfig: _idleMeasureConfig,
    supported: false,
  );

  /// Sets [instance] to [value].
  static void install(OneVpnNativeConnect value) => _instance = value;

  /// How long after the first alive result the pick waits for the rest.
  static const firstResultWindow = Duration(milliseconds: 1500);

  /// How long after the measure core connects an alive result may take.
  static const allDeadCap = Duration(seconds: 5);

  /// The time between two observatory reads.
  static const pollInterval = Duration(milliseconds: 250);

  /// The number of consecutive empty probe rounds that expire the hold.
  static const holdRounds = 6;

  /// How long the hold reads no alive result before it expires: [holdRounds]
  /// probe rounds at [oneVpnMeasureProbeInterval], one minute.
  static final holdCap = oneVpnMeasureProbeInterval * holdRounds;

  /// The number of missed pins that ends a run in the hold.
  ///
  /// A missed pin answers notRunning, superseded or held, or throws, while
  /// the measure core still runs. Each earlier one retries on the next read.
  static const pinAttempts = 3;

  final ConnectionCoordinator _coordinator;
  final OneVpnReloadPolicy _reloads;
  final OneVpnObservatorySource _observatory;
  final OneVpnMeasureConfigBuilder _measureConfig;
  final Stream<List<CoreConfigData>> Function() _rows;
  final OneVpnPreparation _preparation;

  /// Answers the URL a measure core probes. Each measure reads it once,
  /// before its core starts.
  ///
  /// The default is [ProbeEndpoints.resolve]: the ping URL on the domain
  /// the account API reached, or the primary's with no remembered domain.
  final Future<String> Function() probeUrl;

  /// Whether this platform measures. The default follows the reload policy.
  final bool supported;

  final _measuring = ValueNotifier(false);
  final _allDead = ValueNotifier(false);

  /// The identities of the measure runtimes a run in flight owns.
  final _claimed = <String>{};

  /// The identities of the measure cores a held run left up. They stay
  /// claimed while the coordinator shows one of them.
  final _held = <String>{};

  /// The entry id of the last pinned runtime.
  int? _lastPin;

  bool _attached = false;

  /// The coordinator's fresh-connect prepare. It starts Phase 1.
  ///
  /// It reports every id in scope to the coordinator. An empty scope throws
  /// before any core starts.
  PrepareConnection get prepare => _prepareFresh;

  /// The coordinator's default resolver. It never probes.
  ///
  /// It resolves the last pin when it is in scope. Otherwise it resolves the
  /// lowest ids in scope.
  ConnectionResolver get defaultResolver =>
      _RankedResolver(_rows, (row) => row.id == _lastPin ? 0 : 1);

  /// The reload policy's prepare.
  ///
  /// A changed selection, or a running measure runtime, starts Phase 1. An
  /// unchanged selection over a pinned runtime keeps the running entries.
  OneVpnReloadPrepare get reloadPrepare => _prepareReload;

  /// True from Phase 1 start until the pin lands or the hold stands.
  ValueListenable<bool> get measuring => _measuring;

  /// Whether a connect to [selection] measures for the fastest server: an
  /// Automatic selection on a platform that measures.
  bool picksFastest(ServerSelection selection) =>
      supported && selection.kind == SelectionKind.automatic;

  /// True while the hold stands. The measure core stays up and blocks every
  /// flow.
  ValueListenable<bool> get allDead => _allDead;

  /// Listens to the coordinator's state. Calling it again does nothing.
  ///
  /// A connected measure runtime that no run claims starts a [run]. A
  /// view that leaves a held core releases its claims. A connected pinned
  /// runtime records its entry as the last pin. It clears [measuring] and
  /// [allDead]. So does a disconnecting, disconnected or failed view.
  void attach() {
    if (_attached) return;
    _attached = true;
    _coordinator.state.addListener(_onView);
    _onView();
  }

  void _onView() {
    final view = _coordinator.state.value;
    final runtime = view.runtime;
    if (!_owns(_held)) _held.clear();
    switch (view.phase) {
      case ConnectionPhase.connected when runtime != null && isMeasure(runtime):
        if (!_isClaimed(runtime.identity)) unawaited(run(runtime));
      case ConnectionPhase.connected when runtime != null:
        _lastPin = runtime.entries.firstOrNull?.id ?? _lastPin;
        _show(measuring: false, allDead: false);
      case ConnectionPhase.disconnected ||
          ConnectionPhase.disconnecting ||
          ConnectionPhase.failed:
        _show(measuring: false, allDead: false);
      case _:
        break;
    }
  }

  /// Whether [runtime] is a measure runtime: its config carries
  /// `burstObservatory`.
  static bool isMeasure(ConnectionRuntime runtime) {
    if (!runtime.xrayJson.contains('"burstObservatory"')) return false;
    try {
      final config = jsonDecode(runtime.xrayJson);
      return config is Map<String, dynamic> &&
          config.containsKey('burstObservatory');
    } on FormatException {
      return false;
    }
  }

  /// Polls the observatory of [measure], picks a candidate, and pins it.
  ///
  /// A read runs every [pollInterval]. The pick fires once every candidate
  /// has reported, or [firstResultWindow] after the first alive result. A
  /// rolled-back pin picks again once without that row. A second rollback
  /// holds. A missed pin retries on the next read. The last of
  /// [pinAttempts] missed pins holds. No alive result by [allDeadCap] starts
  /// the hold. A hold with no alive result for [holdCap] expires: the run
  /// stops the measure core, publishes a failed view with
  /// [oneVpnHoldExpiredIssue], and ends [OneVpnPinOutcome.expired]. An alive
  /// result restarts that count. While a command moves the measure core, the
  /// expiry waits until the view reads connected again.
  ///
  /// The release from the hold and the repick after a rollback open the
  /// window again. The first alive result after either starts it. A release
  /// pins only when the window closes.
  ///
  /// A claimed runtime starts no second run. A run claims each measure
  /// runtime it owns. It releases them as it ends. A held run's cores stay
  /// claimed while the coordinator shows one of them.
  Future<OneVpnPinOutcome> run(ConnectionRuntime measure) async {
    if (_isClaimed(measure.identity)) return OneVpnPinOutcome.stopped;
    final round = _MeasureRound.of(measure);
    if (round == null) return OneVpnPinOutcome.stopped;
    final owned = {measure.identity};
    _claimed.add(measure.identity);
    // Must run before the returned future completes. A view that shows an
    // owned core in between would find it claimed and start no run.
    OneVpnPinOutcome end(OneVpnPinOutcome outcome) {
      _claimed.removeAll(owned);
      if (outcome == OneVpnPinOutcome.held) _held.addAll(owned);
      return outcome;
    }

    final excluded = <int>{};
    var rollbacks = 0;
    var missed = 0;
    var holding = false;
    var retry = false;
    var capped = false;
    var windowClosed = false;
    var expired = false;
    Timer? cap;
    Timer? window;
    Timer? expiry;
    // The next alive result starts the window. The next pin waits for it.
    void reopen() {
      window?.cancel();
      window = null;
      windowClosed = false;
      retry = false;
    }

    void arm() {
      cap?.cancel();
      reopen();
      capped = false;
      cap = Timer(allDeadCap, () => capped = true);
    }

    void hold() {
      holding = true;
      reopen();
      _show(measuring: false, allDead: true);
      _log('hold');
    }

    arm();
    try {
      while (true) {
        if (!_owns(owned)) return end(OneVpnPinOutcome.stopped);
        _show(measuring: !holding, allDead: holding);
        final set = await _observatory.read(round.port);
        if (!_owns(owned)) return end(OneVpnPinOutcome.stopped);
        final pick = OneVpnNativeConnect.pick(
          set,
          account: round.account.difference(excluded),
          free: round.free.difference(excluded),
        );
        if (pick != null) {
          window ??= Timer(firstResultWindow, () => windowClosed = true);
        }
        // Entries a held core shows predate the release. Only the window
        // pins a release.
        final reported = !holding && round.tags.every(set.byTag.containsKey);
        if (pick != null && (reported || windowClosed || retry)) {
          final result = await _pin(pick.id);
          final outcome = result?.outcome;
          if (outcome == OneVpnReloadOutcome.applied) {
            _lastPin = pick.id;
            _show(measuring: false, allDead: false);
            _log('pin id=${pick.id} delay=${pick.delayMs}ms');
            return end(OneVpnPinOutcome.pinned);
          }
          if (!_owns(owned)) return end(OneVpnPinOutcome.stopped);
          if (outcome == OneVpnReloadOutcome.rolledBack && rollbacks == 0) {
            rollbacks++;
            excluded.add(pick.id);
            reopen();
            continue;
          }
          if (outcome == OneVpnReloadOutcome.rolledBack ||
              outcome == OneVpnReloadOutcome.needsReconnect ||
              ++missed == pinAttempts) {
            hold();
            return end(OneVpnPinOutcome.held);
          }
          // A missed pin. The measure core still runs. The next read pins
          // again.
          retry = true;
        }
        if (pick == null && capped && !holding) hold();
        if (holding && pick == null) {
          expiry ??= Timer(holdCap, () => expired = true);
        } else {
          expiry?.cancel();
          expiry = null;
          expired = false;
        }
        // Must wait for a settled connected view: the stop cancels a command
        // in flight, such as a connect that moves off the measure core.
        if (expired &&
            _coordinator.state.value.phase == ConnectionPhase.connected) {
          await _expire();
          return end(OneVpnPinOutcome.expired);
        }
        await Future<void>.delayed(pollInterval);
      }
    } finally {
      cap?.cancel();
      window?.cancel();
      expiry?.cancel();
    }
  }

  /// Stops the measure core, then publishes a failed view with
  /// [oneVpnHoldExpiredIssue] once the coordinator reads disconnected. A
  /// command that moved the tunnel in between keeps its own view. The hold's
  /// flags stand until the view the stop publishes clears them, so the
  /// control never reads connected over the blocking core.
  Future<void> _expire() async {
    _log('hold expired');
    try {
      await _coordinator.disconnect();
      await _coordinator.runExclusive(() async {
        if (_coordinator.state.value.phase != ConnectionPhase.disconnected) {
          return;
        }
        throw const ConnectionHostException(oneVpnHoldExpiredIssue);
      });
    } catch (error) {
      // The failed view carries the expiry. A failed stop publishes its own.
      if (error is! ConnectionHostException ||
          error.reason != oneVpnHoldExpiredIssue) {
        ygLogger('OneVpnNativeConnect: expiry failed (${error.runtimeType})');
      }
    }
  }

  /// The candidate [set] picks among the [account] and [free] row ids.
  ///
  /// It takes the lowest alive delay among the account rows. With no alive
  /// account row, it takes the lowest alive free row. A tie goes to the
  /// lower id. Null means no candidate is alive.
  static OneVpnPick? pick(
    OneVpnObservationSet set, {
    required Set<int> account,
    required Set<int> free,
  }) {
    OneVpnPick? best({required bool accountTier}) {
      final ids = accountTier ? account : free;
      OneVpnPick? best;
      for (final MapEntry(key: tag, value: observation) in set.byTag.entries) {
        final id = OneVpnCandidateTags.idOf(tag);
        if (id == null ||
            !observation.alive ||
            OneVpnCandidateTags.isAccount(tag) != accountTier ||
            !ids.contains(id)) {
          continue;
        }
        final delay = observation.delayMs;
        if (best == null ||
            delay < best.delayMs ||
            (delay == best.delayMs && id < best.id)) {
          best = OneVpnPick(id: id, account: accountTier, delayMs: delay);
        }
      }
      return best;
    }

    return best(accountTier: true) ?? best(accountTier: false);
  }

  /// Whether a run in flight or a held run claims [identity].
  bool _isClaimed(String identity) =>
      _claimed.contains(identity) || _held.contains(identity);

  /// Whether the coordinator still shows one of the [owned] runtimes.
  bool _owns(Set<String> owned) {
    final view = _coordinator.state.value;
    return (view.phase == ConnectionPhase.connected ||
            view.phase == ConnectionPhase.connecting) &&
        owned.contains(view.runtime?.identity);
  }

  /// Pins the row [id] over the stored configuration. Null means the
  /// reload threw.
  Future<OneVpnReloadResult?> _pin(int id) async {
    try {
      final same = await _coordinator.configuration;
      return await _reloads.applyInPlace(
        _coordinator,
        same,
        expectedConfiguration: same.encode(),
        prepare: (_, next, _) => _preparation(
          next,
          _RankedResolver(_rows, (row) => row.id == id ? 0 : null),
        ),
      );
    } catch (error) {
      ygLogger('OneVpnNativeConnect: pin failed (${error.runtimeType})');
      return null;
    }
  }

  Future<ConnectionRuntime> _prepareFresh(
    ConnectionConfiguration configuration,
    Future<void> cancelled,
  ) async {
    if (!supported) {
      return _pinWithoutMeasure(
        configuration,
        cancelled: cancelled,
        onResolved: _coordinator.reportResolvedNodes,
      );
    }
    return _startPhaseOne(
      () => _measure(
        configuration,
        cancelled: cancelled,
        onResolved: _coordinator.reportResolvedNodes,
      ),
    );
  }

  Future<ConnectionRuntime> _prepareReload(
    ConnectionCoordinator _,
    ConnectionConfiguration next,
    ConnectionRuntime running,
  ) {
    if (!supported) return _pinWithoutMeasure(next);
    final sameSelection =
        jsonEncode(next.connection.selection.toJson()) ==
        jsonEncode(running.configuration.connection.selection.toJson());
    if (sameSelection && !isMeasure(running)) {
      final ids = {for (final entry in running.entries) entry.id};
      return _preparation(
        next,
        _RankedResolver(_rows, (row) => ids.contains(row.id) ? 0 : null),
      );
    }
    return _startPhaseOne(() => _measure(next));
  }

  /// Runs [measure] as a Phase 1 start. [measuring] turns true first. A
  /// throw clears it.
  Future<ConnectionRuntime> _startPhaseOne(
    Future<ConnectionRuntime> Function() measure,
  ) async {
    _show(measuring: true, allDead: false);
    try {
      return await measure();
    } catch (_) {
      _show(measuring: false, allDead: false);
      rethrow;
    }
  }

  Future<ConnectionRuntime> _pinWithoutMeasure(
    ConnectionConfiguration configuration, {
    Future<void>? cancelled,
    void Function(Set<int>)? onResolved,
  }) => _preparation(
    configuration,
    defaultResolver,
    cancelled: cancelled,
    onResolved: onResolved,
  );

  /// The measure runtime for [configuration]. It probes the URL that
  /// [probeUrl] answers at the start of the measure.
  ///
  /// It prepares the first candidate in scope through the preparation. The
  /// measure config replaces that runtime's config. The request keeps the
  /// prepared TUN and ports. A scope with no candidate, as in a raw config,
  /// answers the prepared runtime itself.
  Future<ConnectionRuntime> _measure(
    ConnectionConfiguration configuration, {
    Future<void>? cancelled,
    void Function(Set<int>)? onResolved,
  }) async {
    final url = await probeUrl();
    final scope = _ScopeResolver(await _rows().first, onScope: onResolved);
    final prepared = await _preparation(
      configuration,
      scope,
      cancelled: cancelled,
      onResolved: onResolved,
    );
    if (scope.scope.isEmpty) return prepared;
    final xrayJson = jsonEncode(
      _measureConfig(
        pinned: jsonDecode(prepared.xrayJson) as Map<String, dynamic>,
        candidates: scope.scope,
        probeUrl: url,
      ),
    );
    final request = prepared.request;
    return ConnectionRuntime.create(
      configuration: prepared.configuration,
      compiled: CompiledConnection(
        xrayJson: xrayJson,
        entries: const [],
        finalExit: null,
        nodeTags: const {},
      ),
      platform: prepared.platform,
      request: StartVpnRequest(
        request.tun,
        request.socksPort,
        request.metricsPort,
        jsonEncode(
          LibXrayInvokeRequest(
            method: LibXrayMethod.runXray,
            payload: RunXrayRequest(xrayJson).toJson(),
          ).toJson(),
        ),
      ),
      notice: prepared.notice,
    );
  }

  void _show({required bool measuring, required bool allDead}) {
    _measuring.value = measuring;
    _allDead.value = allDead;
  }

  /// Logs a pin or the hold in a debug build.
  static void _log(String line) {
    if (kDebugMode) debugPrint('OneVpnNativeConnect: $line');
  }
}

/// The candidates of one measure runtime, read from its config.
class _MeasureRound {
  _MeasureRound({
    required this.port,
    required this.tags,
    required this.account,
    required this.free,
  });

  /// The round of [runtime]. It is null when the config holds no candidate
  /// or the request names no metrics port.
  static _MeasureRound? of(ConnectionRuntime runtime) {
    final port = int.tryParse(runtime.request.metricsPort ?? '');
    if (port == null) return null;
    final Object? config;
    try {
      config = jsonDecode(runtime.xrayJson);
    } on FormatException {
      return null;
    }
    if (config is! Map<String, dynamic>) return null;
    final tags = <String>{
      if (config['outbounds'] case final List<dynamic> outbounds)
        for (final outbound in outbounds)
          if (outbound case {'tag': final String tag})
            if (OneVpnCandidateTags.idOf(tag) != null) tag,
    };
    if (tags.isEmpty) return null;
    return _MeasureRound(
      port: port,
      tags: tags,
      account: {
        for (final tag in tags)
          if (OneVpnCandidateTags.isAccount(tag))
            OneVpnCandidateTags.idOf(tag)!,
      },
      free: {
        for (final tag in tags)
          if (!OneVpnCandidateTags.isAccount(tag))
            OneVpnCandidateTags.idOf(tag)!,
      },
    );
  }

  /// The core's metrics port.
  final int port;

  /// Every candidate tag in the config.
  final Set<String> tags;

  /// The account row ids among the candidates.
  final Set<int> account;

  /// The free row ids among the candidates.
  final Set<int> free;
}

/// Resolves the rows in scope with no probe.
///
/// [rank] sets each row's delay, and null drops the row. The shared
/// resolver then takes the lowest delays, the lower id first on a tie.
class _RankedResolver implements ConnectionResolver {
  _RankedResolver(this._rows, this._rank);

  final Stream<List<CoreConfigData>> Function() _rows;
  final int? Function(CoreConfigData row) _rank;

  @override
  Future<List<ResolvedServer>> resolve(
    ConnectionSettings settings, {
    RoutingProfileState? custom,
    Future<void>? cancelled,
  }) => ConnectionResolver(
    rows: () => _rows().map(
      (rows) => [
        for (final row in rows)
          if (_rank(row) case final delay?) row.copyWith(delay: delay),
      ],
    ),
    probe: _neverProbe,
  ).resolve(settings, custom: custom, cancelled: cancelled);

  static Future<void> _neverProbe(List<int> _) async =>
      throw StateError('A pin never probes');
}

/// Resolves the first candidates in scope and records the whole scope.
///
/// The scope is the id list the shared resolver hands its probe when every
/// row reads unmeasured. A resolve answers as many scope rows as the
/// settings require. An empty scope throws the shared resolver's failure.
class _ScopeResolver implements ConnectionResolver {
  _ScopeResolver(this._rows, {this.onScope});

  final List<CoreConfigData> _rows;

  /// Receives the scope ids after each resolve that finds them.
  final void Function(Set<int>)? onScope;

  /// The scope rows of the last resolve, in row order.
  List<ResolvedServer> scope = const [];

  @override
  Future<List<ResolvedServer>> resolve(
    ConnectionSettings settings, {
    RoutingProfileState? custom,
    Future<void>? cancelled,
  }) async {
    var ids = const <int>[];
    try {
      await ConnectionResolver(
        rows: () => Stream.value([
          for (final row in _rows)
            row.copyWith(delay: PingDelayConstants.unknown),
        ]),
        probe: (candidates) async => ids = candidates,
      ).resolve(settings, custom: custom, cancelled: cancelled);
    } on ConnectionResolutionException {
      // The shared resolver throws once the probe returns. With no scope,
      // its failure stands.
      if (ids.isEmpty) rethrow;
    }
    final byId = {for (final row in _rows) row.id: row};
    scope = [for (final id in ids) ResolvedServer.fromRow(byId[id]!)];
    if (scope.isNotEmpty) onScope?.call({for (final row in scope) row.id});
    return scope
        .take(settings.requiredEntries(customEntryCount: custom?.entryCount))
        .toList();
  }
}

/// The observatory of the idle native connect. Every read is empty.
class _IdleObservatory implements OneVpnObservatorySource {
  const _IdleObservatory();

  @override
  Future<OneVpnObservationSet> read(int port) async =>
      OneVpnObservationSet(byTag: const {}, readAt: DateTime.now());
}

/// The measure config builder of the idle native connect. It always throws.
Map<String, dynamic> _idleMeasureConfig({
  required Map<String, dynamic> pinned,
  required List<ResolvedServer> candidates,
  required String probeUrl,
}) => throw StateError('No measure config builder is installed');
