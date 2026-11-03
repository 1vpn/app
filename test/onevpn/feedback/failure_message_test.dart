// Pins the fork failure notices to the shared failure helpers. In every
// shipped locale the fork text equals the shared text for each failure the
// helpers distinguish. A failure here after an upstream bump means the
// shared mapping changed. Re-check lib/onevpn/feedback/failure_message.dart
// against the new upstream helpers and copy any new string into the fork
// ARB files. The fork owns the issues in [_forkOwned]. Each of them reads
// "Connection failed" in every locale.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/feedback/failure_message.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/service/connect/failure.dart';
import 'package:onexray/service/connect/platform_requirements.dart';
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/shared/failure.dart';

/// Every quoted issue code in the function of [path] named [name].
Set<String> _issueCodes(String path, String name) {
  final source = File(path).readAsStringSync();
  final start = source.indexOf(
    RegExp('^String\\??\\s+$name\\(', multiLine: true),
  );
  expect(start, isNot(-1), reason: '$path lacks $name');
  // A top-level function ends at the first blank line after it.
  final end = source.indexOf('\n\n', start);
  final body = source.substring(start, end == -1 ? source.length : end);
  return RegExp(r"'(\w+)'").allMatches(body).map((m) => m.group(1)!).toSet();
}

/// The issues whose connection notice the fork words itself. A location
/// with no working server and an unreadable runtime both read as a failed
/// connection.
const _forkOwned = {
  'selectionUnavailable',
  'readFailed',
  'runtimeUnavailable',
  'nativeStatusFailed',
};

PlatformPermissionResult _permission(PlatformPermissionKind kind) =>
    PlatformPermissionResult(
      kind: kind,
      state: PlatformPermissionState.denied,
      message: 'denied by the system',
    );

void main() {
  const cause = FormatException('bad config');
  final errors = <String, Object?>{
    'null': null,
    'plain': StateError('boom'),
    'format': cause,
    'timeout': TimeoutException('slow'),
    'socket': const SocketException('unreachable'),
    for (final category in FailureCategory.values)
      'category ${category.name}': AppFailure(category, 'other'),
    for (final code in [
      'startFailed',
      'stopFailed',
      'startTimeout',
      'stopTimeout',
    ])
      'native $code': AppFailure(FailureCategory.runtime, code, cause: cause),
    'nested native': AppFailure(
      FailureCategory.runtime,
      'wrapper',
      cause: AppFailure(FailureCategory.runtime, 'stopTimeout'),
    ),
    for (final reason in ConnectionResolutionFailure.values)
      'resolution ${reason.name}': ConnectionResolutionException(reason),
    'resolution counted': const ConnectionResolutionException(
      ConnectionResolutionFailure.insufficientHealthyServers,
      requiredCount: 3,
      availableCount: 1,
    ),
    for (final failure in ConnectionPlatformRequirementFailure.values)
      'platform ${failure.name}': ConnectionPlatformRequirementException(
        failure,
      ),
    for (final kind in PlatformPermissionKind.values)
      'permission ${kind.name}': ConnectionHostException(
        'permissionRequired',
        permission: _permission(kind),
      ),
    for (final reason in [
      'runtimeUnavailable',
      'nativeStatusFailed',
      'startFailed',
      'unknownReason',
    ])
      'host $reason': ConnectionHostException(reason, cause: cause),
  };

  test('the cases cover every issue code the shared helpers distinguish', () {
    final codes = {
      ..._issueCodes(
        'lib/service/connect/failure.dart',
        'connectionFailureMessage',
      ),
      ..._issueCodes(
        'lib/service/shared/failure.dart',
        'nativeOperationFailureTitle',
      ),
    };
    // Anti-vacuity guard. The helpers name their codes.
    expect(codes, contains('selectionUnavailable'));
    expect(codes, contains('stopTimeout'));
    final covered = {
      for (final error in errors.values)
        if (error != null) connectionFailureReason(error),
      for (final error in errors.values)
        if (error is AppFailure) error.code,
    };
    expect(covered, containsAll(codes));
  });

  for (final locale in AppLocalizations.supportedLocales) {
    final tag = locale.toLanguageTag();

    test('$tag: the fork notices equal the shared notices', () {
      final upstream = lookupAppLocalizations(locale);
      final fork = lookupOneVpnLocalizations(locale);
      for (final MapEntry(key: name, value: error) in errors.entries) {
        expect(
          oneVpnAppFailureMessage(fork, error),
          appFailureMessage(upstream, error),
          reason: 'app $name',
        );
        expect(
          oneVpnAppFailureMessage(fork, error, operation: 'Op'),
          appFailureMessage(upstream, error, operation: 'Op'),
          reason: 'app operation $name',
        );
        if (error != null &&
            _forkOwned.contains(connectionFailureReason(error))) {
          continue;
        }
        expect(
          oneVpnConnectionFailureMessage(fork, error: error),
          connectionFailureMessage(upstream, error: error),
          reason: 'connection $name',
        );
      }
      for (final kind in PlatformPermissionKind.values) {
        expect(
          oneVpnConnectionFailureMessage(
            fork,
            issue: 'permissionRequired',
            permission: _permission(kind),
          ),
          connectionFailureMessage(
            upstream,
            issue: 'permissionRequired',
            permission: _permission(kind),
          ),
          reason: 'issue permissionRequired ${kind.name}',
        );
      }
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    final tag = locale.toLanguageTag();

    test('$tag: every fork-owned issue reads as a failed connection', () {
      final fork = lookupOneVpnLocalizations(locale);
      for (final issue in _forkOwned) {
        expect(
          oneVpnConnectionFailureMessage(fork, issue: issue),
          fork.onevpnConnectionFailed,
          reason: issue,
        );
      }
      expect(
        oneVpnConnectionFailureMessage(
          fork,
          error: const ConnectionResolutionException(
            ConnectionResolutionFailure.selectionUnavailable,
          ),
        ),
        fork.onevpnConnectionFailed,
      );
    });
  }

  test('a known issue becomes the title over the cause detail', () {
    final l = lookupOneVpnLocalizations(const Locale('en'));
    expect(
      oneVpnConnectionFailureMessage(
        l,
        error: const ConnectionResolutionException(
          ConnectionResolutionFailure.insufficientCandidates,
          requiredCount: 2,
          availableCount: 0,
        ),
      ),
      'Not enough available servers (0/2)',
    );
    expect(
      oneVpnAppFailureMessage(
        l,
        AppFailure(FailureCategory.runtime, 'stopFailed', cause: cause),
      ),
      'Disconnect failed\nbad config',
    );
  });
}
