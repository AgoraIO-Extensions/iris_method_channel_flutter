import 'package:iris_method_channel/src/platform/iris_method_channel_interface.dart';
import 'package:iris_method_channel/src/platform/platform_bindings_delegate_interface.dart';
import 'package:iris_method_channel/src/platform/web/iris_method_channel_internal_web.dart';

/// Create the [IrisMethodChannelInternal] for web
IrisMethodChannelInternal createIrisMethodChannelInternal(
        PlatformBindingsProvider provider) =>
    IrisMethodChannelInternalWeb(provider);
