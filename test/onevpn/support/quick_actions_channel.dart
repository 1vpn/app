import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake of the quick-actions plugin channel for the whole test body.
///
/// `getLaunchAction` answers [launchAction] once, as a cold start's
/// launching shortcut, then null. [published] records each item list a
/// `setShortcutItems` call sends. [launch] delivers a launch from the
/// platform, as a warm start does.
class FakeQuickActionsChannel {
  FakeQuickActionsChannel({this.launchAction}) {
    _messenger.setMockMethodCallHandler(channel, _handle);
    addTearDown(() => _messenger.setMockMethodCallHandler(channel, null));
  }

  /// The channel the quick-actions plugin talks over in a test.
  static const channel = MethodChannel('plugins.flutter.io/quick_actions');

  /// The type the next `getLaunchAction` answers, or null for none.
  String? launchAction;

  /// How many `getLaunchAction` calls arrived.
  int launchReads = 0;

  /// Each item list sent, in call order. An item maps its field names to
  /// their values.
  final List<List<Map<Object?, Object?>>> published = [];

  /// A set error makes the next `getLaunchAction` throw it, once.
  PlatformException? launchError;

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'getLaunchAction':
        launchReads++;
        final error = launchError;
        launchError = null;
        if (error != null) throw error;
        final action = launchAction;
        launchAction = null;
        return action;
      case 'setShortcutItems':
        published.add([
          for (final item in call.arguments as List<Object?>)
            Map<Object?, Object?>.from(item! as Map<Object?, Object?>),
        ]);
        return null;
    }
    throw MissingPluginException();
  }

  /// Delivers a launch of [type] from the platform.
  Future<void> launch(String type) => _messenger.handlePlatformMessage(
    channel.name,
    channel.codec.encodeMethodCall(MethodCall('launch', type)),
    (_) {},
  );
}
