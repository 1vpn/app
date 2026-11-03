// The app-build guard for the free node IP literals.
//
// An app build that carries the free REALITY triple must carry a literal for
// every free node. A free node without one never provisions. The guard reads
// each value from the define file alone, the one source the build passes to
// Flutter. It prints hostnames and entry positions only.

import 'dart:convert';
import 'dart:io';

import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/catalogue/free_node_ips.dart';

const _tripleNames = <String>['ONEVPN_UUID', 'ONEVPN_PBK', 'ONEVPN_SID'];
const _ipsName = 'ONEVPN_FREE_NODE_IPS';

/// Runs the guard and returns its exit code.
///
/// [args] holds the define file path. A missing file reads as empty. The
/// environment plays no part. The status goes to [out] and each finding to
/// [err].
int run(List<String> args, {StringSink? out, StringSink? err}) {
  final outSink = out ?? stdout;
  final errSink = err ?? stderr;
  final path = args.isEmpty ? null : args.first;
  final Map<String, Object?> file;
  try {
    file = _readDefines(path);
  } on FormatException {
    errSink.writeln('$path is not a JSON object');
    return 1;
  }
  String define(String name) {
    final value = file[name];
    return value is String ? value : '';
  }

  final findings = freeNodeIpsFindings(define);
  if (findings == null) {
    outSink.writeln('free triple not set: no free node literals required');
    return 0;
  }
  if (findings.isEmpty) {
    outSink.writeln(
      '$_ipsName names all ${kOneVpnFreeHosts.length} free hosts',
    );
    return 0;
  }
  findings.forEach(errSink.writeln);
  errSink.writeln(
    'an app build with the free triple needs a literal for every free host',
  );
  return 1;
}

/// The guard's findings, one line each, or null without the full free triple.
///
/// [define] reads one build-time value by name. An empty list passes. Each
/// line names a hostname or an entry position, never an address.
List<String>? freeNodeIpsFindings(String Function(String name) define) {
  if (_tripleNames.any((name) => define(name).isEmpty)) return null;
  final raw = define(_ipsName);
  if (raw.trim().isEmpty) return <String>['$_ipsName is empty'];
  final ips = OneVpnFreeNodeIps.parse(raw, hosts: kOneVpnFreeHosts);
  return <String>[
    for (final host in kOneVpnFreeHosts)
      if (!ips.byHost.containsKey(host) && !ips.malformed.contains(host))
        '$_ipsName names no literal for $host',
    for (final key in ips.malformed) '$_ipsName rejects $key',
    for (final host in ips.unknown) '$_ipsName names unknown host $host',
  ];
}

/// The defines in the JSON object at [path], or none when no file is there.
///
/// Throws a [FormatException] when the file is not a JSON object.
Map<String, Object?> _readDefines(String? path) {
  if (path == null) return const <String, Object?>{};
  final file = File(path);
  if (!file.existsSync()) return const <String, Object?>{};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) throw const FormatException();
  return decoded;
}

void main(List<String> args) {
  exitCode = run(args);
}
