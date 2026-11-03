import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/service/shared/ping/state.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('timeout round trips', () async {
    final original = PingState()..timeout = 8;

    await original.saveToPreferences();

    final restored = PingState();
    await restored.readFromPreferences();

    expect(restored.timeout, 8);
  });
}
