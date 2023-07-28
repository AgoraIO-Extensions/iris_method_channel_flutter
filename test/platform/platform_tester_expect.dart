import 'fake/platform_tester_interface.dart';

/// Stub function for create the platform specific [PlatformTesterInterface].
/// See implemetation:
/// io: `platform_tester_actual_io.dart`
/// web: `platform_tester_actual_web.dart`
PlatformTesterInterface getPlatformTester() =>
    throw UnimplementedError('Unimplemented');
