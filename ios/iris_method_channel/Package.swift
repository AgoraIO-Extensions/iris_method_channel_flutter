// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iris_method_channel",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "iris-method-channel", targets: ["iris_method_channel"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "iris_method_channel",
            dependencies: [],
            publicHeadersPath: "include/iris_method_channel",
            cSettings: [
                .headerSearchPath("include/iris_method_channel")
            ],
            cxxSettings: [
                .unsafeFlags(["-std=c++14"])
            ],
            linkerSettings: [
                // These symbols are looked up through DynamicLibrary.process().
                .unsafeFlags([
                    "-Xlinker", "-u", "-Xlinker", "_Iris_InitDartApiDL",
                    "-Xlinker", "-u", "-Xlinker", "_Iris_Dispose",
                    "-Xlinker", "-u", "-Xlinker", "_Iris_OnEvent",
                    "-Xlinker", "-u", "-Xlinker", "_Iris_RegisterDartPort",
                    "-Xlinker", "-u", "-Xlinker", "_Iris_UnregisterDartPort"
                ])
            ]
        )
    ]
)
