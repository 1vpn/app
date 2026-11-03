import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/service/connect/coordinator.dart';

/// How long a transient phase must hold before the status label shows it.
const Duration kOneVpnTransientStatusHold = Duration(milliseconds: 300);

/// The connection view the status label renders. It skips transient phases
/// that end quickly.
///
/// It mirrors [source]. A preparing, connecting, or disconnecting view appears
/// only after it holds for [hold]. A view that replaces it sooner shows at
/// once. A fast connect then goes from disconnected to connected with no
/// connecting label. Every other view shows at once.
///
/// A transient view present at construction shows at once. Once a transient
/// view shows, later transient views show at once.
class OneVpnDebouncedConnectionView extends ValueNotifier<ConnectionView> {
  OneVpnDebouncedConnectionView(
    this.source, {
    this.hold = kOneVpnTransientStatusHold,
  }) : super(source.value) {
    source.addListener(_onSource);
  }

  /// The coordinator view this mirrors.
  final ValueListenable<ConnectionView> source;

  /// The minimum lifetime of a transient view that the label shows.
  final Duration hold;

  Timer? _pending;

  /// Whether [view] is a phase the label skips when it ends within [hold].
  static bool transient(ConnectionView view) => switch (view.phase) {
    ConnectionPhase.preparing ||
    ConnectionPhase.connecting ||
    ConnectionPhase.disconnecting => true,
    _ => false,
  };

  void _onSource() {
    final next = source.value;
    if (!transient(next)) {
      _pending?.cancel();
      _pending = null;
      value = next;
      return;
    }
    // A transient label already on screen updates at once.
    if (transient(value)) {
      value = next;
      return;
    }
    // A running hold keeps its start. It measures the whole transient
    // stretch, not the latest view.
    _pending ??= Timer(hold, () {
      _pending = null;
      value = source.value;
    });
  }

  @override
  void dispose() {
    _pending?.cancel();
    source.removeListener(_onSource);
    super.dispose();
  }
}

/// Whether the status label reads the updating copy. It turns true once
/// [source] holds reloading for [hold], and false as soon as it leaves
/// reloading. A reload that ends within [hold] never shows.
class OneVpnReloadLabel extends ValueNotifier<bool> {
  OneVpnReloadLabel(this.source, {this.hold = kOneVpnTransientStatusHold})
    : super(false) {
    source.addListener(_onSource);
    _onSource();
  }

  /// The reload state this follows.
  final ValueListenable<OneVpnReloadState> source;

  /// How long a reload runs before the label shows it.
  final Duration hold;

  Timer? _pending;

  void _onSource() {
    if (source.value != OneVpnReloadState.reloading) {
      _pending?.cancel();
      _pending = null;
      value = false;
      return;
    }
    if (value) return;
    _pending ??= Timer(hold, () {
      _pending = null;
      value = source.value == OneVpnReloadState.reloading;
    });
  }

  @override
  void dispose() {
    _pending?.cancel();
    source.removeListener(_onSource);
    super.dispose();
  }
}
