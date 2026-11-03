// The status label's debounce. A transient phase shows only after it holds
// for 300ms, so a fast connect skips the connecting label. Stable phases
// show at once. The updating label takes the same hold. A reload that ends
// within 300ms never shows it, and the label clears as the reload ends. The
// widget test clock drives every timer.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/shell/status_debounce.dart';
import 'package:onexray/service/connect/coordinator.dart';

const _disconnected = ConnectionView();
const _preparing = ConnectionView(phase: ConnectionPhase.preparing);
const _connecting = ConnectionView(phase: ConnectionPhase.connecting);
const _connected = ConnectionView(phase: ConnectionPhase.connected);
const _disconnecting = ConnectionView(phase: ConnectionPhase.disconnecting);
const _failed = ConnectionView(phase: ConnectionPhase.failed);

void main() {
  late ValueNotifier<ConnectionView> source;
  late OneVpnDebouncedConnectionView shown;
  late List<ConnectionPhase> seen;

  void mount(ConnectionView initial) {
    source = ValueNotifier(initial);
    shown = OneVpnDebouncedConnectionView(source);
    seen = [];
    shown.addListener(() => seen.add(shown.value.phase));
    addTearDown(shown.dispose);
  }

  test('the hold is 300ms', () {
    expect(kOneVpnTransientStatusHold, const Duration(milliseconds: 300));
  });

  testWidgets('a connect inside the hold never shows connecting', (
    tester,
  ) async {
    mount(_disconnected);
    source.value = _preparing;
    await tester.pump(const Duration(milliseconds: 100));
    source.value = _connecting;
    await tester.pump(const Duration(milliseconds: 150));
    expect(shown.value.phase, ConnectionPhase.disconnected);

    source.value = _connected;
    expect(shown.value.phase, ConnectionPhase.connected);
    await tester.pump(const Duration(seconds: 1));
    expect(seen, [ConnectionPhase.connected]);
  });

  testWidgets('a connect past the hold shows connecting at 300ms', (
    tester,
  ) async {
    mount(_disconnected);
    source.value = _connecting;
    await tester.pump(const Duration(milliseconds: 299));
    expect(shown.value.phase, ConnectionPhase.disconnected);

    await tester.pump(const Duration(milliseconds: 1));
    expect(shown.value.phase, ConnectionPhase.connecting);

    source.value = _connected;
    expect(seen, [ConnectionPhase.connecting, ConnectionPhase.connected]);
  });

  testWidgets('the hold spans the whole transient stretch', (tester) async {
    mount(_disconnected);
    source.value = _preparing;
    await tester.pump(const Duration(milliseconds: 200));
    source.value = _connecting;
    await tester.pump(const Duration(milliseconds: 100));

    // The label shows 300ms after the stretch begins, not after its latest
    // view.
    expect(shown.value.phase, ConnectionPhase.connecting);
  });

  testWidgets('a transient view already shown updates at once', (tester) async {
    mount(_disconnected);
    source.value = _preparing;
    await tester.pump(kOneVpnTransientStatusHold);
    expect(shown.value.phase, ConnectionPhase.preparing);

    source.value = _connecting;
    expect(shown.value.phase, ConnectionPhase.connecting);
  });

  testWidgets('a fast disconnect never shows disconnecting', (tester) async {
    mount(_connected);
    source.value = _disconnecting;
    await tester.pump(const Duration(milliseconds: 50));
    source.value = _disconnected;
    await tester.pump(const Duration(seconds: 1));

    expect(seen, [ConnectionPhase.disconnected]);
  });

  testWidgets('a failure shows at once', (tester) async {
    mount(_connecting);
    expect(shown.value.phase, ConnectionPhase.connecting);

    source.value = _failed;
    expect(shown.value.phase, ConnectionPhase.failed);
  });

  testWidgets('a failure inside a running hold shows at once and cancels it', (
    tester,
  ) async {
    mount(_disconnected);
    source.value = _preparing;
    await tester.pump(const Duration(milliseconds: 100));
    source.value = _connecting;
    await tester.pump(const Duration(milliseconds: 100));

    source.value = _failed;
    expect(shown.value.phase, ConnectionPhase.failed);

    // A fresh attempt at 250ms starts its own hold. The timer of the first
    // hold, due at 300ms, never shows the fresh attempt early.
    await tester.pump(const Duration(milliseconds: 50));
    source.value = _connecting;
    await tester.pump(const Duration(milliseconds: 100));
    expect(shown.value.phase, ConnectionPhase.failed);
    await tester.pump(const Duration(milliseconds: 199));
    expect(shown.value.phase, ConnectionPhase.failed);
    await tester.pump(const Duration(milliseconds: 1));
    expect(shown.value.phase, ConnectionPhase.connecting);
    expect(seen, [ConnectionPhase.failed, ConnectionPhase.connecting]);
  });

  testWidgets('dispose cancels a running hold', (tester) async {
    final notifier = ValueNotifier(_disconnected);
    final debounced = OneVpnDebouncedConnectionView(notifier);
    notifier.value = _connecting;
    debounced.dispose();

    // A live timer here fails the test at teardown.
    await tester.pump(const Duration(seconds: 1));
    notifier.value = _connected;
  });

  group('the updating label', () {
    late ValueNotifier<OneVpnReloadState> reload;
    late OneVpnReloadLabel updating;
    late List<bool> shows;

    void mountLabel({OneVpnReloadState initial = OneVpnReloadState.connected}) {
      reload = ValueNotifier(initial);
      updating = OneVpnReloadLabel(reload);
      shows = [];
      updating.addListener(() => shows.add(updating.value));
      addTearDown(updating.dispose);
    }

    testWidgets('a reload inside the hold never shows', (tester) async {
      mountLabel();
      reload.value = OneVpnReloadState.reloading;
      await tester.pump(const Duration(milliseconds: 250));
      reload.value = OneVpnReloadState.connected;
      await tester.pump(const Duration(seconds: 1));
      expect(shows, isEmpty);
      expect(updating.value, isFalse);
    });

    testWidgets('a reload past the hold shows at 300ms and clears as it '
        'ends', (tester) async {
      mountLabel();
      reload.value = OneVpnReloadState.reloading;
      await tester.pump(const Duration(milliseconds: 299));
      expect(updating.value, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(updating.value, isTrue);

      reload.value = OneVpnReloadState.rolledBack;
      expect(updating.value, isFalse);
      expect(shows, [true, false]);
    });

    testWidgets('a reload present at mount takes the hold', (tester) async {
      mountLabel(initial: OneVpnReloadState.reloading);
      expect(updating.value, isFalse);
      await tester.pump(kOneVpnTransientStatusHold);
      expect(updating.value, isTrue);
    });

    testWidgets('dispose cancels a running hold', (tester) async {
      reload = ValueNotifier(OneVpnReloadState.connected);
      final label = OneVpnReloadLabel(reload);
      reload.value = OneVpnReloadState.reloading;
      label.dispose();

      // A live timer here fails the test at teardown.
      await tester.pump(const Duration(seconds: 1));
      reload.value = OneVpnReloadState.connected;
    });
  });
}
