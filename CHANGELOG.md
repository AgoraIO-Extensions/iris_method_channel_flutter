# Changelog

## [2.0.1](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/2.0.0...2.0.1) (2024-01-29)


### Bug Fixes

* Wait for the executor.dispose done before exit the isolate ([#93](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/93)) ([dc202d9](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/dc202d9e537c6cfdc702346f27c09fc2db77c53a))

## [2.0.0](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/2.0.0-dev.4...2.0.0) (2023-12-05)

## [2.0.0-dev.4](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/2.0.0-dev.3...2.0.0-dev.4) (2023-10-24)


### Features

* Introduce the InitilizationArgProvider to allow the creation of the initialization arg lazily ([#90](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/90)) ([b0f6be2](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/b0f6be203675bdfe89c86c0eb55c20b50519c3b1))

## [2.0.0-dev.3](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/2.0.0-dev.2...2.0.0-dev.3) (2023-09-13)


### Bug Fixes

* [native] Fix errors when hot restarted ([#86](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/86)) ([ab6260e](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/ab6260ee461aa7e4363a993794c0956116a0ad9c))

## [2.0.0-dev.2](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/2.0.0-dev.1...2.0.0-dev.2) (2023-09-11)


### Bug Fixes

* [android] Add namespace to work with android gradle 8.0 ([#82](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/82)) ([98ee75f](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/98ee75f31609ffd77b833a5636f3019b40c2bd39))
* Align web implementation to native implementation ([#84](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/84)) ([27bb000](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/27bb000f2b1910484db77571a3728a870c3fe871))

## [2.0.0-dev.1](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.2.2...2.0.0-dev.1) (2023-09-04)


### Features

* Refactor to work with flutter web ([#79](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/79)) ([bfbb3c8](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/bfbb3c8525778dd4c64c65dc6287e5e24e52ee50))

## [1.2.2](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.2.1...1.2.2) (2023-08-21)


### Bug Fixes

* [android] Fix linux build error ([0dd39c8](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/0dd39c847140cf46e92bd34874158052100f67b8))

## [1.2.1](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.2.0...1.2.1) (2023-08-10)


### Bug Fixes

* [android] Bound the IrisMethodChannel lifecycle with the FlutterEngine ([#75](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/75)) ([7249bf0](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/7249bf06b794572d405461b3e7c3b2a0d242a017))

## [1.2.0](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0...1.2.0) (2023-07-07)


### Bug Fixes

* Fix "Failed to load dynamic library 'iris_method_channel.framework/iris_method_channel' after remove the use_frameworks! in Podfile" ([#72](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/72)) ([7339cde](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/7339cdeebafe2b03658a26339b3442d1d1403ae3))
* Fix android build in some ubuntu ([777bcd6](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/777bcd646e12b104c7b5d8a9328ff9daae2e6dc2))

## [1.1.0](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.5...1.1.0) (2023-05-16)


### Features

* add InitilizationResult return type for IrisMethodChannel.initilize ([#45](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/issues/45)) ([ed46461](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/ed464616bdf65ccbb9fae1548968a8091200c71b))

## [1.1.0-rc.5](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.4...1.1.0-rc.5) (2023-03-16)


### Features

* allow initilize/dispose multiple times for same IrisMethodChannel object ([00d1388](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/00d13889fa39383af86703be1011579dfcc97486))


### Bug Fixes

* fix memeory leak if Dart_PostCObject_DL failed to send the message ([55f322f](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/55f322fd202c361b4cc78c1fb060109518e918aa))

## [1.1.0-rc.4](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.3...1.1.0-rc.4) (2023-03-11)


### Features

* implement invokeMethodList ([15c6e38](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/15c6e3855c1a3bdfbd51101bcbda5a1b36a2c98b))

## [1.1.0-rc.3](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.2...1.1.0-rc.3) (2023-02-23)


### Bug Fixes

* [windows] fix warning C4068: unknown pragma 'clang' ([f26cdba](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/f26cdba2bfebcce9f2ed5ce25468aa6427ea400f))
* fix _HotRestartFinalizer._onExitPort not be initialized in release build ([ea5f4cb](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/ea5f4cbd925e79c229d7f4013cce5d649d256990))

## [1.1.0-rc.2](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.1...1.1.0-rc.2) (2023-02-16)


### Bug Fixes

* fix ConcurrentModificationError when  and  are called ynchronously but without  keyword ([4f5058d](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/4f5058d70224c8072cc8706adb4761b28cebd8fc))

## [1.1.0-rc.1](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.0.0...1.1.0-rc.1) (2023-02-16)


### Bug Fixes

* fix registerEventHandler with same ScopedEvent.scopedKey but different registerName/unregisterName not work ([268d74b](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/268d74b1f1326dd68bc12723859159f43f5b79e6))
* fix the native API engine not be destroyed when hot restarted ([bdda662](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/bdda6626de1434f5e26d12369d0fc570d7d582a6))

## 1.0.0

* Introduce `NativeBindingDelegateProvider` to allow pass custom `NativeBindingDelegate` from outside.

## 0.1.0

* Initial release.
