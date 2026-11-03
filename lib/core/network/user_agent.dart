import 'package:flutter/foundation.dart';
import 'package:onexray/core/tools/logger.dart';

typedef SystemUserAgentReader = Future<String?> Function();

enum DownloadUserAgentPlatform { android, ios, macos, windows, linux, other }

enum DownloadUserAgentMode {
  system,
  oneXray;

  static const defaultMode = DownloadUserAgentMode.system;

  static DownloadUserAgentMode fromString(String? value) {
    return DownloadUserAgentMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => defaultMode,
    );
  }
}

abstract final class DownloadUserAgent {
  static const windows =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Safari/537.36';
  static const linux =
      'Mozilla/5.0 (X11; Linux x86_64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Safari/537.36';

  static Future<String> resolve({
    required DownloadUserAgentMode mode,
    required String oneXrayUserAgent,
  }) {
    return resolveForPlatform(
      mode: mode,
      // Every platform sends one fixed browser UA. It names no app or device.
      platform: DownloadUserAgentPlatform.windows,
      oneXrayUserAgent: oneXrayUserAgent,
      systemUserAgentReader: () async => null,
    );
  }

  @visibleForTesting
  static Future<String> resolveForPlatform({
    required DownloadUserAgentMode mode,
    required DownloadUserAgentPlatform platform,
    required String oneXrayUserAgent,
    required SystemUserAgentReader systemUserAgentReader,
  }) async {
    if (mode == DownloadUserAgentMode.oneXray) {
      return oneXrayUserAgent;
    }
    switch (platform) {
      case DownloadUserAgentPlatform.windows:
        return windows;
      case DownloadUserAgentPlatform.linux:
        return linux;
      case DownloadUserAgentPlatform.android:
      case DownloadUserAgentPlatform.ios:
      case DownloadUserAgentPlatform.macos:
        try {
          final userAgent = (await systemUserAgentReader())?.trim();
          if (userAgent != null && userAgent.isNotEmpty) {
            return userAgent;
          }
        } catch (error) {
          ygLogger('Unable to read the system browser User-Agent: $error');
        }
        return oneXrayUserAgent;
      case DownloadUserAgentPlatform.other:
        return oneXrayUserAgent;
    }
  }
}
