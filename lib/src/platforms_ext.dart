import 'dart:io';

/// Extension functions for [Platform]
extension PlatformExt on Platform {
  /// Utility function to check if the code is currently running on the OpenHarmony-adapted Flutter SDK.
  static bool get isOhos => Platform.operatingSystem == 'ohos';
}
