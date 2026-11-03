import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/core/model/ping_json.dart';
import 'package:onexray/core/tools/empty.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';

class PingTimeout {
  static const min = 3.0;
  static const max = 8.0;
  static const defaultValue = 5.0;
}

class PingState {
  var timeout = PingTimeout.defaultValue;

  /// The probe URL for every batch. It is the primary probe endpoint until
  /// [readFromPreferences] reads the remembered domain.
  String get realUrl => _realUrl;
  var _realUrl = ProbeEndpoints.urls.first;

  /// Restores the timeout, clamped to the [PingTimeout] range. It ignores
  /// stored `url` and `customUrl` entries. The next save drops them.
  ///
  /// It also sets [realUrl] from [ProbeEndpoints.resolve], which makes no
  /// network call.
  Future<void> readFromPreferences() async {
    _realUrl = await ProbeEndpoints.resolve();
    final jsonMap = await PreferencesKey().readPingState();
    if (!EmptyTool.checkMap(jsonMap)) {
      return;
    }
    final pingJson = PingJson.fromJson(jsonMap!);
    if (pingJson.timeout != null) {
      var timeout = pingJson.timeout!;
      if (timeout < PingTimeout.min) {
        timeout = PingTimeout.min;
      } else if (timeout > PingTimeout.max) {
        timeout = PingTimeout.max;
      }
      this.timeout = timeout;
    }
  }

  Future<void> saveToPreferences() async {
    final pingJson = PingJson(timeout, null, null);
    await PreferencesKey().savePingState(pingJson.toJson());
  }
}
