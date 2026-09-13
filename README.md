# iris_method_channel

[![pub package](https://img.shields.io/pub/v/iris_method_channel.svg)](https://pub.dev/packages/iris_method_channel)
[![Flutter Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`iris_method_channel` is a method channel that communicate between C/C++(iris) and dart, which is used by [agora_rtc_engine](https://github.com/AgoraIO-Extensions/Agora-Flutter-SDK).

---

## Overview

Unlike standard Flutter Platform Channels (which rely on `MethodChannel` binary messenger platform calls), `iris_method_channel` executes native Iris C/C++ API calls on a background Dart worker isolate using **Dart FFI (`dart:ffi`)** on native platforms (Android, iOS, macOS, Windows) and **JavaScript Interop (`dart:js`)** on Web.

Key capabilities:
- **Background Isolate FFI Dispatch**: Dispatches API calls asynchronously to a worker isolate where Dart FFI invokes native C/C++ functions.
- **Bi-directional Event Dispatching**: Listens to native C++ event callbacks and dispatches them back to Dart event listeners.
- **Buffer Support**: Transmits binary byte buffers (`Uint8List` or native memory pointers) alongside JSON parameter payloads.

---

## Features

- ⚡ **Background FFI Execution**: Executes native C/C++ functions via Dart FFI on a background worker isolate.
- 🔄 **Event Loop Routing**: Routes native C++ event callbacks to registered Dart handlers.
- 📦 **Binary Buffer Support**: Transmits binary buffers (`Uint8List` or native memory pointers) alongside JSON parameter payloads.
- 🎯 **Scoped Handler Lifecycle**: Provides scoped event listener registration and lifecycle cleanup via `ScopedObjects`.
- 🔁 **Debug Hot Restart Safety**: Includes debug-mode hot restart listeners (`HotRestartListener`) to clean up native handles when Flutter hot restarts.

---

## Platform Support

| Platform | Technology | Execution Mode | Buffer Support |
| :--- | :--- | :--- | :--- |
| **Android** | `dart:ffi` | Asynchronous Worker Isolate | Yes (`BufferParam` / `Uint8List`) |
| **iOS** | `dart:ffi` | Asynchronous Worker Isolate | Yes (`BufferParam` / `Uint8List`) |
| **macOS** | `dart:ffi` | Asynchronous Worker Isolate | Yes (`BufferParam` / `Uint8List`) |
| **Windows** | `dart:ffi` | Asynchronous Worker Isolate | Yes (`BufferParam` / `Uint8List`) |
| **Web** | JS Interop (`package:js` / `dart:js`) | Asynchronous JS Interop | Yes (`Uint8List`) |

---

## Getting Started

### Prerequisites

- **Dart SDK**: `>=2.14.0 <4.0.0`
- **Flutter SDK**: `>=2.0.0`

### Installation

Add `iris_method_channel` as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  iris_method_channel: ^2.2.7
```

Or run:

```bash
flutter pub add iris_method_channel
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.