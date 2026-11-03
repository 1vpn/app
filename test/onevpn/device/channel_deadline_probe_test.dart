// Pins the pure parts of the device probe. It covers the wedge classifier's
// three outcomes and their boundaries, and the verdict fold. It also pins
// the margin the wedge needs between the wedge hold and the invoke bound.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/app/channel_deadlines.dart';

import 'channel_deadline_probe.dart';

void main() {
  const bound = ChannelDeadlines.invoke;
  const tick = Duration(milliseconds: 1);

  group('classifyWedge', () {
    test('an expiry at the bound with the sentinel passes', () {
      expect(
        classifyWedge(bound: bound, elapsed: bound, sentinelLogged: true),
        ProbeOutcome.pass,
      );
    });

    test('scheduling slop inside the grace window still passes', () {
      expect(
        classifyWedge(
          bound: bound,
          elapsed: bound + wedgeGrace,
          sentinelLogged: true,
        ),
        ProbeOutcome.pass,
      );
    });

    test('a native reply before the bound is inconclusive', () {
      expect(
        classifyWedge(
          bound: bound,
          elapsed: bound - tick,
          sentinelLogged: false,
        ),
        ProbeOutcome.inconclusive,
      );
      // A fast reply is inconclusive even when an earlier phase left the
      // sentinel in the log.
      expect(
        classifyWedge(
          bound: bound,
          elapsed: bound - tick,
          sentinelLogged: true,
        ),
        ProbeOutcome.inconclusive,
      );
    });

    test('an await outliving the bound plus grace fails', () {
      expect(
        classifyWedge(
          bound: bound,
          elapsed: bound + wedgeGrace + tick,
          sentinelLogged: true,
        ),
        ProbeOutcome.fail,
      );
    });

    test('an expiry without the sentinel fails', () {
      expect(
        classifyWedge(bound: bound, elapsed: bound, sentinelLogged: false),
        ProbeOutcome.fail,
      );
    });
  });

  group('probeVerdict', () {
    test('all passing phases verdict PASS', () {
      expect(
        probeVerdict(const [ProbeOutcome.pass, ProbeOutcome.pass]),
        'PASS',
      );
    });

    test('one inconclusive phase verdicts INCONCLUSIVE', () {
      expect(
        probeVerdict(const [ProbeOutcome.pass, ProbeOutcome.inconclusive]),
        'INCONCLUSIVE',
      );
    });

    test('one failing phase verdicts FAIL over inconclusive', () {
      expect(
        probeVerdict(const [
          ProbeOutcome.inconclusive,
          ProbeOutcome.fail,
          ProbeOutcome.pass,
        ]),
        'FAIL',
      );
    });
  });

  test('the wedge outlasts the invoke bound plus the grace window', () {
    expect(wedgeHold, greaterThan(ChannelDeadlines.invoke + wedgeGrace));
  });
}
