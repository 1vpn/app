// Device probe for the pigeon channel deadlines. It runs as the app entry
// point inside the real Android process, against the real native host. The
// filename carries no _test suffix, so flutter test never loads it.
// channel_deadline_probe_test.dart pins the pure classifier below.
//
// Phases, in order:
//   healthyStatus     a real status read succeeds under its bound
//   healthyInvoke     a real invoke (xrayVersion) round-trips
//   wedgedInvoke      a ping that holds the native invoke lock for
//                     [wedgeHold] must fail at [ChannelDeadlines.invoke]
//                     with [ChannelDeadlines.expired]
//   drainDuringWedge  a status read while the native side is still busy
//                     succeeds, so an expiry leaves the channel usable
//   recoveredInvoke   after the native hold clears, its late real reply
//                     has been dropped and a fresh invoke succeeds
//
// The wedge needs no fault hook. pingBatch takes a caller timeout. A dial
// to TEST-NET-1 gets no reply. The RFC 5737 address is unroutable, and as
// an IP literal it needs no DNS lookup. The native side stays busy for the
// full timeout while the Dart bound expires first.
//
// The build needs the staged native library and geodata. See tool/build.sh.
// Build and run on a device with these commands:
//   flutter build apk --debug -t test/onevpn/device/channel_deadline_probe.dart
//   adb -s <serial> install -r build/app/outputs/flutter-apk/app-debug.apk
//   adb -s <serial> shell am start -n com.one.vpnapp/net.yuandev.onexray.MainActivity
//   adb -s <serial> logcat -d | grep channelDeadlineProbe
//
// Every probe line carries the channelDeadlineProbe tag. The last line is
// the verdict.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:onexray/core/pigeon/flutter_api.dart';
import 'package:onexray/core/pigeon/host_api.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/app/app.dart';
import 'package:onexray/onevpn/app/channel_deadlines.dart';

/// How long the wedge occupies the native invoke lock. It must exceed the
/// invoke bound plus [wedgeGrace]. Otherwise an expiry cannot be told apart
/// from a native reply. The probe test pins the margin.
const wedgeHold = Duration(seconds: 25);

/// Scheduling slop allowed past a bound before an expiry counts as late.
const wedgeGrace = Duration(seconds: 3);

/// Ping target for the wedge. TEST-NET-1 blackholes the dial. Override
/// with --dart-define=WEDGE_URL=... on a network that rejects TEST-NET
/// fast instead of dropping it.
const wedgeUrl = String.fromEnvironment(
  'WEDGE_URL',
  defaultValue: 'http://192.0.2.1/',
);

/// Minimal config for the wedge ping: one direct outbound, no server.
const wedgeConfig = '{"outbounds":[{"protocol":"freedom","tag":"proxy"}]}';

/// Outcome of one probe phase.
enum ProbeOutcome { pass, fail, inconclusive }

/// Classifies the wedged-invoke observation. [bound] is the deadline
/// under test. [elapsed] is the observed duration of the wedged call.
/// [sentinelLogged] says whether the failure log carried
/// [ChannelDeadlines.expired]. The outcome is pass when the call failed at
/// the bound with the sentinel. It is inconclusive when the native side
/// replied before the bound: the wedge did not hold, so the deadline went
/// unexercised. It is fail when the call outlived the bound plus
/// [wedgeGrace] or expired without the sentinel.
ProbeOutcome classifyWedge({
  required Duration bound,
  required Duration elapsed,
  required bool sentinelLogged,
}) {
  if (elapsed < bound) {
    return ProbeOutcome.inconclusive;
  }
  if (elapsed > bound + wedgeGrace) {
    return ProbeOutcome.fail;
  }
  return sentinelLogged ? ProbeOutcome.pass : ProbeOutcome.fail;
}

/// Folds phase outcomes into the run verdict: FAIL if any phase failed,
/// otherwise INCONCLUSIVE if any phase was inconclusive, otherwise PASS.
String probeVerdict(Iterable<ProbeOutcome> outcomes) {
  if (outcomes.contains(ProbeOutcome.fail)) {
    return 'FAIL';
  }
  if (outcomes.contains(ProbeOutcome.inconclusive)) {
    return 'INCONCLUSIVE';
  }
  return 'PASS';
}

void main() {
  final phases = <String, ProbeOutcome>{};
  final logs = <String>[];

  void report(String phase, ProbeOutcome outcome, String detail) {
    phases[phase] = outcome;
    debugPrint(
      'channelDeadlineProbe: phase=$phase outcome=${outcome.name} $detail',
    );
  }

  runZonedGuarded(
    () async {
      // The fork binding's messenger applies the deadlines under test.
      OneVpnBinding.ensureInitialized();
      // Mirrors the boot step: native status pushes need the Dart handler.
      BridgeFlutterApi.setUp(AppFlutterApi());
      runApp(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: Color(0xFF000000),
            child: Center(
              child: Text(
                'channel deadline probe',
                style: TextStyle(color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
        ),
      );

      // Tees the app log so the wedge phase can check for the sentinel.
      final forward = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logs.add(message);
        }
        forward(message, wrapWidth: wrapWidth);
      };

      final statusTimer = Stopwatch()..start();
      final status = await AppHostApi().readVpnStatus();
      statusTimer.stop();
      final statusHealthy =
          status.state == NativeVpnCommandState.success &&
          statusTimer.elapsed < ChannelDeadlines.readVpnStatus;
      report(
        'healthyStatus',
        statusHealthy ? ProbeOutcome.pass : ProbeOutcome.fail,
        'state=${status.state.name} status=${status.status?.name} '
            'elapsedMs=${statusTimer.elapsedMilliseconds}',
      );

      final versionTimer = Stopwatch()..start();
      final version = await AppHostApi().xrayVersion();
      versionTimer.stop();
      report(
        'healthyInvoke',
        version.isNotEmpty ? ProbeOutcome.pass : ProbeOutcome.fail,
        'version=$version elapsedMs=${versionTimer.elapsedMilliseconds}',
      );

      final wedgeTimer = Stopwatch()..start();
      final wedgeResponse = await AppHostApi().pingBatch(
        PingBatchRequest(
          [PingBatchItemRequest(wedgeConfig)],
          wedgeHold.inSeconds,
          wedgeUrl,
        ),
      );
      final wedgeElapsed = wedgeTimer.elapsed;
      final sentinelLogged = logs.any(
        (line) => line.contains(
          'libXray pingBatch failed: ${ChannelDeadlines.expired}',
        ),
      );
      final wedgeOutcome = classifyWedge(
        bound: ChannelDeadlines.invoke,
        elapsed: wedgeElapsed,
        sentinelLogged: sentinelLogged,
      );
      report(
        'wedgedInvoke',
        wedgeOutcome,
        'elapsedMs=${wedgeElapsed.inMilliseconds} '
            'sentinelLogged=$sentinelLogged '
            'nativeError=${wedgeResponse?.results?.firstOrNull?.error}',
      );

      if (wedgeOutcome == ProbeOutcome.inconclusive) {
        report(
          'drainDuringWedge',
          ProbeOutcome.inconclusive,
          'skipped: the wedge did not hold',
        );
        report(
          'recoveredInvoke',
          ProbeOutcome.inconclusive,
          'skipped: the wedge did not hold',
        );
      } else {
        // The native side is still inside the wedge ping here. Status
        // reads take a different native path than invoke, so a healthy
        // read now shows the expiry freed the channel.
        final drainTimer = Stopwatch()..start();
        final drain = await AppHostApi().readVpnStatus();
        drainTimer.stop();
        final drained =
            drain.state == NativeVpnCommandState.success &&
            drainTimer.elapsed < ChannelDeadlines.readVpnStatus;
        report(
          'drainDuringWedge',
          drained ? ProbeOutcome.pass : ProbeOutcome.fail,
          'state=${drain.state.name} '
              'elapsedMs=${drainTimer.elapsedMilliseconds}',
        );

        // Waits out the native hold so its late real reply lands and is
        // dropped before the recovery invoke runs.
        final remaining = wedgeHold + wedgeGrace - wedgeTimer.elapsed;
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
        final recoveredTimer = Stopwatch()..start();
        final recovered = await AppHostApi().xrayVersion();
        recoveredTimer.stop();
        report(
          'recoveredInvoke',
          recovered.isNotEmpty ? ProbeOutcome.pass : ProbeOutcome.fail,
          'version=$recovered '
              'elapsedMs=${recoveredTimer.elapsedMilliseconds}',
        );
      }

      final summary = phases.entries
          .map((entry) => '${entry.key}:${entry.value.name}')
          .join(',');
      debugPrint(
        'channelDeadlineProbe: verdict=${probeVerdict(phases.values)} '
        '$summary',
      );
    },
    (error, stack) {
      // The late real reply must be dropped silently. Any escaped error
      // fails the run, including one that lands after the verdict line.
      report('uncaughtError', ProbeOutcome.fail, 'error=$error');
    },
  );
}
