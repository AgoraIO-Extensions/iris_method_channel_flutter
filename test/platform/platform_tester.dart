export 'fake/platform_tester_interface.dart';

export 'platform_tester_expect.dart'
    if (dart.library.io) 'platform_tester_actual_io.dart'
    if (dart.library.js) 'platform_tester_actual_web.dart';
