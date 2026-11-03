// The fork's in-place core reload contract. tool/gen_onevpn_pigeon.sh
// generates the Dart and Kotlin bindings from it. The channels live under
// dev.flutter.pigeon.onevpn and allocate nothing from upstream's onexray
// namespace.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/onevpn/handover/handover.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/app/src/main/kotlin/net/yuandev/onexray/onevpn/handover/Handover.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'net.yuandev.onexray.onevpn.handover',
      errorClassName: 'OneVpnHandoverError',
    ),
    dartPackageName: 'onevpn',
  ),
)
/// The outcome of one reload. The order is the wire encoding.
enum ReloadResult {
  /// The new core runs. The tunnel stays up. start.json describes the new
  /// core.
  applied,

  /// The new core failed to start. The previous core runs again. The tunnel
  /// stays up. start.json is unchanged.
  rolledBack,

  /// The new core and the previous core both failed. The failed-start path
  /// ran. start.json is unchanged.
  failed,

  /// No core runs to reload: no tunnel is up, or the TUN is held with no
  /// core. Nothing changed.
  notRunning,

  /// A stop or a start moved the tunnel generation during the reload, or
  /// the request passed its deadline before it claimed the staged request.
  /// The winning command owns the state.
  superseded,

  /// The staged request is missing, unreadable, or asks for a different
  /// TUN, the running request is unreadable, or the request id is blank or
  /// already in flight. Nothing changed.
  invalidRequest,

  /// The reload outlived its bound, or the channel failed. The state is
  /// unknown.
  timeout,

  /// This build has no native reload. Nothing changed.
  notSupported,
}

/// What started a reload.
enum ReloadTrigger {
  /// A location or direct-regions change while connected.
  settings,

  /// A change of the default network.
  network,
}

/// Where a reload stands.
enum ReloadPhase { started, finished }

/// Asks the native side to reload the core from the staged config at its
/// fixed path.
class ReloadRequest {
  ReloadRequest({required this.requestId});

  /// Correlates the request with its events.
  String requestId;
}

/// One reload phase change, from either trigger.
class ReloadEvent {
  ReloadEvent({
    this.requestId,
    required this.trigger,
    required this.phase,
    this.result,
  });

  /// The id of the reload this event belongs to. A settings reload carries
  /// its request id. A network reload carries an id from the native side
  /// that starts with `network-`.
  String? requestId;

  ReloadTrigger trigger;

  ReloadPhase phase;

  /// Set on the finished phase only.
  ReloadResult? result;
}

/// Dart to native. Each method answers once.
@HostApi()
abstract class OneVpnHandoverHostApi {
  /// True where the native reload exists and a running core can be
  /// reloaded: the tunnel interface is up and the service reads connected.
  /// False in the held state and with no tunnel.
  @asyncCallback
  bool reloadSupported();

  /// Reloads the core from the staged request and answers the outcome. The
  /// caller gives each reload a request id no other reload uses.
  @asyncCallback
  ReloadResult reload(ReloadRequest request);
}

/// Native to Dart. Delivered only while a Flutter engine exists.
@FlutterApi()
abstract class OneVpnHandoverFlutterApi {
  @asyncCallback
  void reloadEvent(ReloadEvent event);
}
