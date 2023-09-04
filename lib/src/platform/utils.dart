export 'package:iris_method_channel/src/platform/utils_expect.dart'
    if (dart.library.io) 'io/utils_actual_io.dart'
    if (dart.library.js) 'web/utils_actual_web.dart';
