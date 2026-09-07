# iOS Repository Guide

## Purpose and Structure

This repository is a standalone SwiftUI consumer and benchmark app for a generated Crossa Release XCFramework. It compares Crossa with Alamofire against the JSONPlaceholder posts endpoint; benchmark output is observational and must not be treated as a product performance claim.

- `CrossaIOSExample.xcodeproj/` is the Xcode project and shared scheme.
- `CrossaIOSExample/App/` owns app startup and dependency composition: `CrossaIOSExampleApp`, `AppBootstrap`, and `AppContainer`.
- `CrossaIOSExample/UI/` contains the root navigation and initialization-failure UI.
- `CrossaIOSExample/Features/Posts/` contains the feature contract, presentation data, screen state, SwiftUI screen, and view model.
- `CrossaIOSExample/Core/` contains benchmark models, configuration, timing, statistics, and `BenchmarkRunner`.
- `CrossaIOSExample/Networking/Crossa/` adapts `CrossaFunctions` and `CrossaRuntime`; `Networking/Alamofire/` contains the comparison client, DTO, presentation adapter, and session configuration.
- `crossa/` contains the `.cra` source used to generate the framework. `CrossaBinary/Crossa.xcframework` is the installed binary consumed by the app.
- `CrossaPackage/Package.swift` is a local `binaryTarget(path:)` override for the framework. `scripts/install-crossa-framework.sh` installs a generated Debug or Release XCFramework.

For a feature or benchmark change, follow `RootView` → `AppBootstrap`/`AppContainer` → `PostsView`/`PostsViewModel` → `BenchmarkRunner` → the Crossa or Alamofire client. Keep repository protocols and presentation data independent of either networking implementation.

## Build and Validation

Generate and install the framework from the repository root, then build this project:

```sh
crossa generate-build ios ./ios-example/crossa --output ./build/crossa-ios
./scripts/install-crossa-framework.sh ../build/crossa-ios/release/Crossa.xcframework
xcodebuild -project CrossaIOSExample.xcodeproj -scheme CrossaIOSExample -configuration Debug -sdk iphonesimulator build
```

Use the Debug XCFramework for native debugging and Release for benchmark runs. Resolve dependencies through Swift Package Manager when needed. Verify available simulator names with `xcodebuild -project CrossaIOSExample.xcodeproj -scheme CrossaIOSExample -showdestinations`.

## Change Guidelines

Use Swift standard naming and four-space indentation. Keep UI state on `@MainActor`, preserve cancellation behavior, and keep benchmark timing and client ordering deterministic. Do not edit generated XCFramework contents manually; regenerate and reinstall the artifact instead. Record the framework source commit and checksum when changing the binary.
