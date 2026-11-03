import 'dart:io';

/// Every host-api channel of the fork reload contract, read from its
/// generated bindings. A reload sends on one of these.
List<String> reloadChannels() {
  final source = File('lib/onevpn/handover/handover.g.dart').readAsStringSync();
  return RegExp(r'dev\.flutter\.pigeon\.onevpn\.OneVpnHandoverHostApi\.\w+')
      .allMatches(source)
      .map((match) => match.group(0)!)
      .toSet()
      .toList();
}
