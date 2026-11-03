import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The text of [path]. Fails the test when the file is missing.
String kotlinSource(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

/// The declaration in [path] whose first line starts, after indentation,
/// with [signaturePrefix], through the closing brace at the signature's
/// own indent. Line comments are dropped and whitespace runs collapse to
/// single spaces, so formatting cannot move a pin and statements can. A
/// block comment inside the declaration fails the test: it could hide a
/// statement from the pin.
String normalizedKotlinMethod(String path, String signaturePrefix) {
  final lines = File(path).readAsLinesSync();
  final start = lines.indexWhere(
    (line) => line.trimLeft().startsWith(signaturePrefix),
  );
  expect(start, isNot(-1), reason: '$path lacks $signaturePrefix');
  final signature = lines[start];
  final indent = signature.substring(
    0,
    signature.length - signature.trimLeft().length,
  );
  final body = <String>[];
  for (var index = start; index < lines.length; index++) {
    final line = lines[index];
    if (RegExp(r'^\s*//').hasMatch(line)) continue;
    if (index > start && line.contains('/*')) {
      fail('$path: a block comment opens inside $signaturePrefix');
    }
    body.add(line);
    if (index > start && line == '$indent}') {
      return body.join('\n').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  fail('$path: $signaturePrefix never closes at its indent');
}

/// Every trimmed line of [path] containing [needle], in file order.
List<String> kotlinLines(String path, String needle) => [
  for (final line in File(path).readAsLinesSync())
    if (line.contains(needle)) line.trim(),
];

/// The fork Kotlin sources under [dir], recursively, generated output
/// excluded, in path order.
List<File> kotlinSources(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.kt') && !f.path.endsWith('.g.kt'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Every trimmed line matching [pattern] in the sources under [dir], as
/// `file: line`, in path order.
List<String> kotlinCensus(String dir, Pattern pattern) => [
  for (final file in kotlinSources(dir))
    for (final line in File(file.path).readAsLinesSync())
      if (line.contains(pattern))
        '${file.uri.pathSegments.last}: ${line.trim()}',
];
