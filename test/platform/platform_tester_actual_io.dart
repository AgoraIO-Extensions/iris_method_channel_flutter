import 'fake/fake_platform_binding_delegate_io.dart';
import 'fake/platform_tester_interface.dart';

/// Implementation of create the [PlatformTesterInterface] of `dart:io`
PlatformTesterInterface getPlatformTester() => PlatformTesterInterfaceIO();
