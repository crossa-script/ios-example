# Crossa iOS Example

This standalone SwiftUI app consumes a generated Crossa **Release XCFramework** and compares it with Alamofire 5.12.0 against:

```text
GET https://jsonplaceholder.typicode.com/posts
```

## Requirements

- Xcode 26.2 or later with an iOS Simulator runtime
- iOS deployment target: 14.0
- A generated `Crossa.xcframework` containing `ios-arm64` and `ios-arm64-simulator`
- Network access to resolve Alamofire 5.12.0 once through Swift Package Manager

## Install Crossa

Build both Debug and Release XCFrameworks from the Crossa repository:

```sh
crossa generate-build ios ./ios-example/crossa --output ./build/crossa-ios
```

Install the Release artifact for the public example and benchmarking:

```sh
cd ios-example
./scripts/install-crossa-framework.sh ../build/crossa-ios/release/Crossa.xcframework
```

Debug XCFrameworks remain useful for native debugging:

```sh
./scripts/install-crossa-framework.sh ../build/crossa-ios/debug/Crossa.xcframework
```

`CrossaPackage/Package.swift` is a local-development `binaryTarget(path:)` override. The generated Release output also contains `Crossa.xcframework.zip`, `checksum.txt`, and `Package.swift` for SwiftPM binary distribution. That package is project-specific; it is not a universal Crossa runtime. Remote `url` + checksum consumption requires publishing the ZIP from the repository that owns this generated SDK.

The generated `metadata/artifact-manifest.json` records the CLI SHA-256, Crossa
source commit, runtime ABI, target, and configuration. The SwiftPM-facing
`checksum.txt` is the canonical ZIP checksum. Use `--crossa-benchmark` or
`--crossa-benchmark-cold` when launching the app; the raw result is written to
the app container as `Documents/benchmark-result.json`.

## Benchmark methodology

The in-app harness is an observation tool, not a product performance claim.

- One Crossa runtime and one Alamofire `Session` are reused for warm runs.
- Cold runs create and dispose a fresh Crossa runtime and Alamofire `Session` for every measured sample.
- Warmups are excluded.
- Measured rounds alternate Crossa and Alamofire.
- Timing uses `ContinuousClock`.
- Crossa reports native-ready list availability and field materialization separately.
- Simulator and remote-network timings are not production evidence.

The repository does not claim a physical-device result until the same Release
artifact is installed on an ARM64 device and the raw result is archived with
its manifest.
