// Failure notices in fork strings. Titles read OneVpnLocalizations.
// Diagnostic details stay in the source language.

import 'package:onexray/core/errors/failure.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/service/connect/failure.dart'
    show connectionFailureReason;
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/runtime_host.dart';

/// The notice text for [error]: a title, then the diagnostic detail on a
/// second line.
///
/// The title is the native operation title when [error] or a cause carries
/// one. Otherwise it is [operation], or a title from the failure category.
/// The detail line is absent when it is empty or equals the title.
String oneVpnAppFailureMessage(
  OneVpnLocalizations l,
  Object? error, {
  String? operation,
}) {
  final title =
      _nativeOperationFailure(l, error) ??
      operation ??
      switch (failureCategory(error)) {
        FailureCategory.configuration => 'Xray · ${l.onevpnResultFailed}',
        FailureCategory.network =>
          '${l.onevpnDownload} · ${l.onevpnResultFailed}',
        FailureCategory.permission => l.onevpnPermissionNotGranted,
        _ => l.onevpnResultFailed,
      };
  final detail = failureDetails(error).trim();
  return detail.isEmpty || detail == title ? title : '$title\n$detail';
}

/// The title for a native start or stop failure [code], or null for any
/// other code.
String? oneVpnNativeOperationFailureTitle(
  OneVpnLocalizations l,
  String? code,
) => switch (code) {
  'startFailed' => l.onevpnConnectionFailed,
  'stopFailed' => l.onevpnActionResult(
    l.onevpnDisconnect,
    l.onevpnResultFailed,
  ),
  'startTimeout' => '${l.onevpnConnect} · ${l.onevpnTimeout}',
  'stopTimeout' => '${l.onevpnDisconnect} · ${l.onevpnTimeout}',
  _ => null,
};

String? _nativeOperationFailure(OneVpnLocalizations l, Object? error) =>
    switch (error) {
      AppFailure() =>
        oneVpnNativeOperationFailureTitle(l, error.code) ??
            _nativeOperationFailure(l, error.cause),
      _ => null,
    };

/// The notice text for a failed connection action.
///
/// [issue] defaults to the reason [error] carries. A known issue becomes the
/// title. The detail then comes from the cause of an [AppFailure], or else
/// from the [permission] message. An unknown issue falls back to
/// [oneVpnAppFailureMessage] for [error]. A [ConnectionHostException]
/// supplies [permission] when none is given.
String oneVpnConnectionFailureMessage(
  OneVpnLocalizations l, {
  Object? error,
  String? issue,
  PlatformPermissionResult? permission,
  String? operation,
}) {
  issue ??= error == null ? null : connectionFailureReason(error);
  if (error is ConnectionHostException) permission ??= error.permission;
  final message = switch (issue) {
    'selectionUnavailable' => l.onevpnConnectionFailed,
    'insufficientCandidates' || 'insufficientHealthyServers' =>
      error is ConnectionResolutionException && error.requiredCount > 0
          ? '${l.onevpnNotEnoughServers} (${error.availableCount}/${error.requiredCount})'
          : l.onevpnNotEnoughServers,
    'finalExitUnavailable' =>
      '${l.onevpnVpnFinalExit} · ${l.onevpnNoAvailableEntries}',
    'selfReference' => l.onevpnFinalExitEntryConflict,
    'invalidSettings' => l.onevpnChooseNamedRoute,
    'permissionRequired' => switch (permission?.kind) {
      PlatformPermissionKind.androidLocalNetwork =>
        l.onevpnAllowLocalNetworkHint,
      PlatformPermissionKind.macosSystemExtension =>
        l.onevpnSystemApprovalRequired,
      _ => l.onevpnVpnPermissionRequired,
    },
    'interfaceRequired' ||
    'interfaceUnavailable' => l.onevpnChooseInterfaceNotice,
    'readFailed' ||
    'runtimeUnavailable' ||
    'nativeStatusFailed' => l.onevpnConnectionFailed,
    _ => oneVpnNativeOperationFailureTitle(l, issue),
  };
  if (message == null) {
    return oneVpnAppFailureMessage(l, error, operation: operation);
  }
  return oneVpnAppFailureMessage(
    l,
    error is AppFailure ? error.cause : permission?.message,
    operation: message,
  );
}
