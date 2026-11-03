// The sliding-pill connect control on its own.
//
// Every coordinator phase maps to one of four states. A failed start and
// a failed stop are red. A settled view over a held TUN is red, and a
// failed start the held signal clears is disconnected. A declined
// permission, a cancelled attempt, and every other failure are
// disconnected. Each state fixes the thumb side and a palette track
// color. A tap and a keyboard activation call back and a drag does not.
// Keyboard focus draws the palette ring. The thumb slides over the
// transition time, and in one frame under reduced motion. The control reads
// as a switch with a status value.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/theme/palettes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';

const _controlPath = 'lib/onevpn/shell/connect_control.dart';

void main() {
  late int taps;

  setUp(() => taps = 0);

  /// Mounts the control centered on a 360x800 surface.
  Future<void> pump(
    WidgetTester tester,
    ConnectionPhase phase, {
    String? issue,
    Brightness brightness = Brightness.light,
    bool reduceMotion = false,
    Size size = const Size(360, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.material(brightness),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Center(
                child: OneVpnConnectControl(
                  view: ConnectionView(phase: phase, issue: issue),
                  label: 'Connect',
                  value: phase.name,
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color trackColor(WidgetTester tester) {
    final track = tester.widget<AnimatedContainer>(
      find.byKey(OneVpnConnectControl.trackKey),
    );
    return (track.decoration! as ShapeDecoration).color!;
  }

  /// The thumb center as a fraction of the track's width, 0 at the start
  /// cell center and 1 at the end cell center.
  double thumbProgress(WidgetTester tester) {
    final track = tester.getRect(find.byKey(OneVpnConnectControl.trackKey));
    final thumb = tester.getCenter(find.byKey(OneVpnConnectControl.thumbKey));
    final half = OneVpnConnectControl.height / 2;
    return (thumb.dx - track.left - half) / (track.width - 2 * half);
  }

  test('every coordinator phase maps to one control state', () {
    expect(
      {
        for (final phase in ConnectionPhase.values)
          phase: OneVpnConnectControlState.of(
            ConnectionView(
              phase: phase,
              issue: phase == ConnectionPhase.failed ? 'startFailed' : null,
            ),
          ),
      },
      {
        ConnectionPhase.disconnected: OneVpnConnectControlState.disconnected,
        ConnectionPhase.disconnecting: OneVpnConnectControlState.disconnected,
        ConnectionPhase.preparing: OneVpnConnectControlState.connecting,
        ConnectionPhase.connecting: OneVpnConnectControlState.connecting,
        ConnectionPhase.connected: OneVpnConnectControlState.connected,
        ConnectionPhase.failed: OneVpnConnectControlState.noConnection,
      },
    );
  });

  test('a cancelled attempt with no tunnel left is disconnected', () {
    for (final issue in ['cancelled', 'selectionReset']) {
      expect(
        OneVpnConnectControlState.of(
          ConnectionView(phase: ConnectionPhase.failed, issue: issue),
        ),
        OneVpnConnectControlState.disconnected,
      );
    }
    expect(
      OneVpnConnectControlState.of(
        const ConnectionView(
          phase: ConnectionPhase.failed,
          issue: 'startFailed',
        ),
      ),
      OneVpnConnectControlState.noConnection,
    );
  });

  test('red is a failed start, a failed stop, or a held TUN', () {
    OneVpnConnectControlState of(String? issue, {bool? held}) =>
        OneVpnConnectControlState.of(
          ConnectionView(phase: ConnectionPhase.failed, issue: issue),
          held: held,
        );
    const red = OneVpnConnectControlState.noConnection;
    const off = OneVpnConnectControlState.disconnected;

    for (final issue in ['startFailed', 'startNotConfirmed', 'startTimeout']) {
      expect(of(issue), red, reason: issue);
      expect(of(issue, held: true), red, reason: issue);
      // The held signal says nothing is held: the TUN is gone.
      expect(of(issue, held: false), off, reason: issue);
    }
    for (final issue in ['stopFailed', 'stopNotConfirmed']) {
      expect(of(issue, held: false), red, reason: issue);
    }
    for (final issue in [
      'permissionRequired',
      'runtimeUnavailable',
      'changeFailed',
      null,
    ]) {
      expect(of(issue), off, reason: '$issue');
    }
  });

  test('a held TUN turns every settled view red', () {
    for (final phase in [
      ConnectionPhase.disconnected,
      ConnectionPhase.failed,
    ]) {
      expect(
        OneVpnConnectControlState.of(
          ConnectionView(phase: phase, issue: 'permissionRequired'),
          held: true,
        ),
        OneVpnConnectControlState.noConnection,
        reason: phase.name,
      );
    }
    // A busy view keeps its own state over a stale answer.
    expect(
      OneVpnConnectControlState.of(
        const ConnectionView(phase: ConnectionPhase.connecting),
        held: true,
      ),
      OneVpnConnectControlState.connecting,
    );
    expect(
      OneVpnConnectControlState.of(
        const ConnectionView(phase: ConnectionPhase.disconnecting),
        held: true,
      ),
      OneVpnConnectControlState.disconnected,
    );
  });

  test('the failure line shows for a held TUN and a failed start only', () {
    bool line(String? issue, {bool? held}) =>
        OneVpnConnectControlState.failureLine(
          ConnectionView(phase: ConnectionPhase.failed, issue: issue),
          held: held,
        );
    expect(line('startFailed'), isTrue);
    expect(line('startFailed', held: false), isFalse);
    expect(line('stopFailed'), isFalse);
    expect(line('stopFailed', held: true), isTrue);
    expect(line('permissionRequired'), isFalse);
    expect(
      OneVpnConnectControlState.failureLine(const ConnectionView(), held: true),
      isTrue,
    );
    expect(
      OneVpnConnectControlState.failureLine(const ConnectionView()),
      isFalse,
    );
  });

  for (final brightness in Brightness.values) {
    final palette = OneVpnPalettes.tokens(brightness).palette;
    final cases = {
      ConnectionPhase.disconnected: (0.0, palette.borderStrong),
      ConnectionPhase.connecting: (1.0, palette.borderStrong),
      ConnectionPhase.connected: (1.0, palette.primarySolid),
      ConnectionPhase.failed: (1.0, palette.destructiveSolid),
    };
    for (final MapEntry(key: phase, value: (side, color)) in cases.entries) {
      testWidgets('${phase.name} renders its thumb side and track color in '
          'the ${brightness.name} theme', (tester) async {
        await pump(
          tester,
          phase,
          issue: phase == ConnectionPhase.failed ? 'startFailed' : null,
          brightness: brightness,
        );

        expect(thumbProgress(tester), closeTo(side, 0.001));
        expect(trackColor(tester), color);
        final thumb = tester.widget<DecoratedBox>(
          find.byKey(OneVpnConnectControl.thumbKey),
        );
        expect(
          (thumb.decoration as BoxDecoration).color,
          palette.primaryForeground,
        );
      });
    }
  }

  testWidgets('the pill is 200 by 100 and fits a 320-wide screen', (
    tester,
  ) async {
    await pump(
      tester,
      ConnectionPhase.disconnected,
      size: const Size(320, 640),
    );

    final track = tester.getRect(find.byKey(OneVpnConnectControl.trackKey));
    expect(track.size, const Size(200, 100));
    expect(track.left, greaterThanOrEqualTo(16));
    expect(track.right, lessThanOrEqualTo(320 - 16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap anywhere on the pill calls back', (tester) async {
    await pump(tester, ConnectionPhase.disconnected);
    final track = tester.getRect(find.byKey(OneVpnConnectControl.trackKey));

    await tester.tapAt(track.centerLeft + const Offset(8, 0));
    await tester.tapAt(track.centerRight - const Offset(8, 0));

    expect(taps, 2);
  });

  testWidgets('the pill takes keyboard focus', (tester) async {
    await pump(tester, ConnectionPhase.disconnected);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final focus = Focus.of(
      tester.element(find.byKey(OneVpnConnectControl.ringKey)),
    );
    expect(focus.hasPrimaryFocus, isTrue);
  });

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('${key.keyLabel} on the focused pill calls back', (
      tester,
    ) async {
      await pump(tester, ConnectionPhase.disconnected);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(key);
      await tester.pump();

      expect(taps, 1);
    });
  }

  testWidgets('keyboard focus draws the palette ring around the pill', (
    tester,
  ) async {
    final palette = OneVpnPalettes.tokens(Brightness.light).palette;
    BorderSide ring() {
      final box = tester.widget<DecoratedBox>(
        find.byKey(OneVpnConnectControl.ringKey),
      );
      return ((box.decoration as ShapeDecoration).shape as StadiumBorder).side;
    }

    await pump(tester, ConnectionPhase.disconnected);
    expect(ring(), BorderSide.none);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(ring().color, palette.ring);
    expect(ring().width, OneVpnConnectControl.ringWidth);
  });

  testWidgets('a drag across the pill does not call back', (tester) async {
    await pump(tester, ConnectionPhase.disconnected);

    await tester.drag(
      find.byKey(OneVpnConnectControl.trackKey),
      const Offset(100, 0),
    );
    await tester.pump(OneVpnConnectControl.duration);

    expect(taps, 0);
    expect(thumbProgress(tester), 0);
  });

  testWidgets('the thumb slides to the end over the transition time', (
    tester,
  ) async {
    await pump(tester, ConnectionPhase.disconnected);
    expect(thumbProgress(tester), 0);

    await pump(tester, ConnectionPhase.connecting);
    await tester.pump(OneVpnConnectControl.duration ~/ 2);
    final midway = thumbProgress(tester);
    expect(midway, greaterThan(0.05));
    expect(midway, lessThan(0.95));

    await tester.pump(OneVpnConnectControl.duration ~/ 2);
    expect(thumbProgress(tester), closeTo(1, 0.001));
  });

  testWidgets('the track fades to blue as the connection lands', (
    tester,
  ) async {
    final palette = OneVpnPalettes.tokens(Brightness.light).palette;
    await pump(tester, ConnectionPhase.connecting);
    await pump(tester, ConnectionPhase.connected);

    // The painted fill, read from the box the animation rebuilds.
    Color painted() {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(OneVpnConnectControl.trackKey),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as ShapeDecoration).color!;
    }

    await tester.pump(OneVpnConnectControl.duration ~/ 2);
    final midway = painted();
    expect(midway, isNot(palette.borderStrong));
    expect(midway, isNot(palette.primarySolid));

    await tester.pump(OneVpnConnectControl.duration ~/ 2);
    final settled = painted();
    expect(settled, palette.primarySolid);
  });

  testWidgets('reduced motion moves the thumb in one frame', (tester) async {
    await pump(tester, ConnectionPhase.disconnected, reduceMotion: true);
    await pump(tester, ConnectionPhase.connected, reduceMotion: true);
    await tester.pump();

    expect(thumbProgress(tester), closeTo(1, 0.001));
  });

  testWidgets('it reads as a switch with its status value', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final (phase, toggled) in [
      (ConnectionPhase.disconnected, false),
      (ConnectionPhase.connecting, true),
      (ConnectionPhase.connected, true),
      (ConnectionPhase.failed, true),
    ]) {
      await pump(
        tester,
        phase,
        issue: phase == ConnectionPhase.failed ? 'startFailed' : null,
      );
      final node = tester.getSemantics(find.byType(OneVpnConnectControl));
      expect(
        node,
        isSemantics(
          label: 'Connect',
          value: phase.name,
          hasToggledState: true,
          isToggled: toggled,
          hasTapAction: true,
        ),
      );
      expect(node.rect.width, greaterThanOrEqualTo(48));
      expect(node.rect.height, greaterThanOrEqualTo(48));
    }
    semantics.dispose();
  });

  test('the control reads colors and corners through the token layer', () {
    final source = File(_controlPath)
        .readAsStringSync()
        .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
    expect(source, isNot(contains('Color(0x')));
    expect(source, isNot(contains('BorderRadius.circular')));
    expect(source, isNot(contains('onevpn/theme/brand.dart')));
    expect(source, isNot(contains('Colors.')));
    expect(source, contains('ColorManager.palette(context)'));
  });
}
