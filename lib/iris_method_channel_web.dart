// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: avoid_classes_with_only_static_members
/// A web implementation of the IrisMethodChannelPlatform of the IrisMethodChannel plugin.
class IrisMethodChannelWeb {
  /// Constructs a IrisMethodChannelWeb
  IrisMethodChannelWeb();

  // ignore: public_member_api_docs
  static void registerWith(Registrar registrar) {
    // do nothing
  }
}
