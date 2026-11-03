// Keeps the fork strings apart from upstream's. Every fork ARB key carries
// the onevpn prefix. Every fork message is non-blank and never names
// OneXray. Every locale file carries every template key with the template's
// placeholders. The fork bundle supports every upstream locale. No fork key
// shadows an upstream key. Fork code reads a copied string through its fork
// key, never through the upstream source the template names in its
// x-copy-of or x-translations-copy-of attribute. Fork code never reads the
// upstream localization class outside the fallback delegate. gen-l10n checks
// syntax and @-blocks.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';

Map<String, dynamic> _arb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The argument names an ICU [message] uses, at every nesting depth.
///
/// A select or plural branch body is a message of its own. Branch selectors
/// and literal text are never argument names.
Set<String> _arguments(String message) {
  final names = <String>{};
  var index = 0;

  // Parses one argument after its opening brace. Returns the index after
  // the closing brace.
  late int Function(int) argument;

  // Parses literal text and arguments until an unmatched closing brace or
  // the end. Returns the index of that brace or the end.
  int text(int at) {
    var i = at;
    while (i < message.length) {
      final char = message[i];
      if (char == '{') {
        i = argument(i + 1);
      } else if (char == '}') {
        return i;
      } else {
        i++;
      }
    }
    return i;
  }

  argument = (int at) {
    final close = message.indexOf('}', at);
    final comma = message.indexOf(',', at);
    if (comma == -1 || (close != -1 && close < comma)) {
      names.add(message.substring(at, close).trim());
      return close + 1;
    }
    names.add(message.substring(at, comma).trim());
    // Skips the type, then reads `selector {message}` pairs.
    var i = message.indexOf(',', comma + 1);
    i = i == -1 ? comma + 1 : i + 1;
    while (i < message.length) {
      final char = message[i];
      if (char == '{') {
        i = text(i + 1) + 1;
      } else if (char == '}') {
        return i + 1;
      } else {
        i++;
      }
    }
    return i;
  };

  while (index < message.length) {
    index = text(index);
    if (index < message.length) index++;
  }
  return names;
}

void main() {
  final forkFiles = Directory('lib/onevpn/l10n')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .toList();
  final template = _arb('lib/onevpn/l10n/onevpn_en.arb');

  test('every fork key has the prefix and a non-blank unbranded message', () {
    // Anti-vacuity guard. The template and its translations are read.
    expect(forkFiles.length, greaterThanOrEqualTo(2));
    final brand = RegExp('onexray', caseSensitive: false);
    for (final file in forkFiles) {
      for (final MapEntry(:key, :value) in _arb(file.path).entries) {
        if (key.startsWith('@@')) continue;
        final base = key.startsWith('@') ? key.substring(1) : key;
        expect(base, startsWith('onevpn'), reason: '${file.path} $key');
        if (key.startsWith('@')) continue;
        // A blank value renders a blank label. gen-l10n accepts it.
        expect(value, isA<String>(), reason: '${file.path} $key');
        expect(
          (value as String).trim(),
          isNotEmpty,
          reason: '${file.path} $key',
        );
        expect(value, isNot(matches(brand)), reason: '${file.path} $key');
      }
    }
  });

  test('the argument parser reads nested select arguments only', () {
    // Anti-vacuity guard for the placeholder check.
    expect(_arguments('Plain text'), isEmpty);
    expect(_arguments('{a} and {b}'), {'a', 'b'});
    expect(_arguments('{code, select, AD {Andorra} other {{code} · {x}}}'), {
      'code',
      'x',
    });
  });

  test('every locale file carries every template key with the template '
      'placeholders', () {
    final keys = template.keys.where((key) => !key.startsWith('@')).toSet();
    // Anti-vacuity guard. The template and its 25 translations are read.
    expect(keys, isNotEmpty);
    expect(forkFiles, hasLength(26));
    for (final file in forkFiles) {
      final arb = _arb(file.path);
      final messages = arb.keys.where((key) => !key.startsWith('@')).toSet();
      expect(messages, keys, reason: file.path);
      for (final key in keys) {
        expect(
          _arguments(arb[key] as String),
          _arguments(template[key] as String),
          reason: '${file.path} $key',
        );
      }
    }
  });

  test('every template placeholder is declared', () {
    for (final key in template.keys.where((key) => !key.startsWith('@'))) {
      final meta = template['@$key'] as Map<String, dynamic>?;
      final declared =
          (meta?['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
          <String>{};
      expect(_arguments(template[key] as String), declared, reason: key);
    }
  });

  test('the fork bundle supports every upstream locale', () {
    // A locale missing from the fork bundle leaves its delegate unsupported.
    // OneVpnLocalizations.of then returns null on that locale.
    expect(AppLocalizations.supportedLocales, isNotEmpty);
    expect(
      OneVpnLocalizations.supportedLocales.toSet(),
      containsAll(AppLocalizations.supportedLocales),
    );
  });

  test('fork code reads the upstream localization class only in the '
      'fallback delegate', () {
    const allowed = 'lib/onevpn/l10n/upstream_delegate.dart';
    final readers = Directory('lib/onevpn')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.contains('/l10n/generated/'))
        .where((file) => file.readAsStringSync().contains('AppLocalizations'))
        .map((file) => file.path)
        .toList();
    expect(readers, [allowed]);
  });

  test('no fork key is also an upstream key', () {
    Set<String> messages(Map<String, dynamic> arb) =>
        arb.keys.where((key) => !key.startsWith('@')).toSet();
    final upstream = messages(_arb('lib/l10n/app_en.arb'));
    expect(upstream, isNotEmpty);
    expect(messages(template).intersection(upstream), isEmpty);
  });

  test('fork code never reads the upstream source of a copy', () {
    final sources = {
      for (final meta in template.values.whereType<Map<String, dynamic>>())
        for (final attribute in const ['x-copy-of', 'x-translations-copy-of'])
          if (meta[attribute] case final String source) source,
    };
    // Anti-vacuity guard. The template names its copies.
    expect(sources, isNotEmpty);
    final getter = RegExp('\\.(${sources.map(RegExp.escape).join('|')})\\b');
    final comment = RegExp(r'^\s*//');
    final code = Directory('lib/onevpn')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.contains('/l10n/generated/'));
    for (final file in code) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (comment.hasMatch(lines[index])) continue;
        final match = getter.firstMatch(lines[index]);
        expect(match, isNull, reason: '${file.path}:${index + 1}');
      }
    }
  });
}
