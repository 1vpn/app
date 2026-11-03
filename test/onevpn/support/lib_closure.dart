import 'dart:io';

import 'package:path/path.dart' as p;

/// The app entries the closure walk starts from.
const libClosureEntries = ['lib/main_1vpn.dart', 'lib/main.dart'];

/// A directive with its URI list. `part of` is excluded.
final _directive = RegExp(
  r'^[ \t]*(?:import|export|part)\b(?![ \t]+of\b)([^;]*);',
  multiLine: true,
);

/// A quoted URI inside a directive.
final _uri = RegExp(r'''['"]([^'"]+)['"]''');

/// The parenthesized test of a conditional directive. It can quote a
/// value, so it is removed before URIs are read.
final _condition = RegExp(r'\([^)]*\)');

const _package = 'package:onexray/';

/// Every Dart source the two app entries reach, sorted by path.
///
/// The walk follows import, export, and part directives. It follows every
/// URI of a conditional directive. A `package:onexray/` URI resolves under
/// lib, and a relative URI resolves against its file. Other schemes stay
/// outside. Paths use forward slashes, as in `lib/main.dart`.
///
/// A directive whose target is missing throws. The build generates every
/// imported file before the suite runs.
List<File> libClosureSources() => [for (final path in _closure) File(path)];

final List<String> _closure = _walk();

List<String> _walk() {
  final reached = <String>{};
  final pending = [...libClosureEntries];
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (!reached.add(path)) continue;
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('$path is imported but missing');
    }
    for (final directive in _directive.allMatches(file.readAsStringSync())) {
      final uris = directive.group(1)!.replaceAll(_condition, '');
      for (final uri in _uri.allMatches(uris)) {
        final target = _resolve(path, uri.group(1)!);
        if (target != null) pending.add(target);
      }
    }
  }
  return reached.toList()..sort();
}

/// The lib path [uri] names from [from], or null outside the package.
String? _resolve(String from, String uri) {
  if (uri.startsWith(_package)) return 'lib/${uri.substring(_package.length)}';
  if (uri.contains(':')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(from), uri));
}
