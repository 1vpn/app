import 'dart:io';

import 'package:flutter/foundation.dart';

class AppPlatform {
  /// Overrides the reported operating system in tests. It lets a desktop
  /// test host reach mobile-only branches. It stays null in production.
  /// Only `AppPlatform` readers see it. `connectionPlatform` reads the host
  /// operating system directly.
  @visibleForTesting
  static String? debugOperatingSystemOverride;

  /// The operating system name, `Platform.operatingSystem` unless overridden.
  static String get operatingSystem =>
      debugOperatingSystemOverride ?? Platform.operatingSystem;

  static bool get isIOS => operatingSystem == 'ios';
  static bool get isAndroid => operatingSystem == 'android';
  static bool get isMacOS => operatingSystem == 'macos';
  static bool get isWindows => operatingSystem == 'windows';
  static bool get isLinux => operatingSystem == 'linux';
  static bool get isMobile => isIOS || isAndroid;
  static bool get isDesktop => isMacOS || isWindows || isLinux;
}
