import 'package:iris_method_channel/src/platform/io/iris_method_channel_internal_io.dart';
import 'package:iris_method_channel/src/platform/iris_method_channel_interface.dart';
import 'package:iris_method_channel/src/platform/platform_bindings_delegate_interface.dart';

/// Create the [IrisMethodChannelInternal] for `dart:io`
IrisMethodChannelInternal createIrisMethodChannelInternal(
        PlatformBindingsProvider provider) =>
    IrisMethodChannelInternalIO(provider);
