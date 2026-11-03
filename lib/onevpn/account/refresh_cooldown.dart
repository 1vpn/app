// The refresh cooldown: one constant and one pure function over a clock.

/// The shortest interval between two background revalidations.
///
/// The trigger is app resume, which is user-local and unscheduled. The
/// cooldown bounds successful refreshes to one per day per device.
const Duration kOneVpnRefreshCooldown = Duration(hours: 24);

/// Whether a background refresh may run.
///
/// [lastStampedAt] is when a refresh last succeeded or a sign-in adopted
/// the session, or null when neither has. A null stamp is due. A device
/// with no stamp or a lost stamp pays at most one early refresh.
///
/// A stamp in the future reads as due. A clock that moves backwards never
/// pins the cooldown shut.
///
/// The function is pure: it takes [now] rather than reading a clock. A
/// test reaches the boundary without waiting a day.
bool isRefreshDue(
  DateTime? lastStampedAt,
  DateTime now, {
  Duration cooldown = kOneVpnRefreshCooldown,
}) {
  if (lastStampedAt == null) return true;
  final elapsed = now.difference(lastStampedAt);
  if (elapsed.isNegative) return true;
  return elapsed >= cooldown;
}
