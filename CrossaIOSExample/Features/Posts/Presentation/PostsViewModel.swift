import Foundation

@MainActor
final class PostsViewModel: ObservableObject {
    @Published private(set) var state: PostsScreenState = .idle
    @Published private(set) var lastResult: BenchmarkRunResult?

    private let runner: BenchmarkRunner
    private var loadingTask: Task<Void, Never>?

    init(runner: BenchmarkRunner) {
        self.runner = runner
    }

    func runComparison() {
        cancelCurrentRequest()
        state = .loading
        print("CROSSA_BENCHMARK_STARTED")
        loadingTask = Task.detached { [runner] in
            let result = await runner.run()
            await MainActor.run { [weak self] in
                self?.printBenchmarkResult(result)
                print("CROSSA_BENCHMARK_COMPLETED")
                self?.lastResult = result
                self?.state = .loaded(result)
                self?.loadingTask = nil
            }
        }
    }

    private func printBenchmarkResult(_ result: BenchmarkRunResult) {
        var lines: [String] = []
        for summary in result.summaries {
            let line = "\(summary.implementation.rawValue) p50=\(summary.medianNanoseconds) p95=\(summary.p95Nanoseconds) mean=\(summary.meanNanoseconds) success=\(summary.successCount)/\(summary.sampleCount)"
            lines.append(line)
            print("CROSSA_BENCHMARK_RESULT \(line)")
        }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("benchmark-result.txt")
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        let metadata = result.metadata
        let raw: [String: Any] = [
            "metadata": [
                "deviceModel": metadata.deviceModel,
                "systemVersion": metadata.systemVersion,
                "architecture": metadata.architecture,
                "appVersion": metadata.appVersion,
                "buildConfiguration": metadata.buildConfiguration,
                "crossaArtifact": metadata.crossaArtifact,
                "crossaArtifactChecksum": metadata.crossaArtifactChecksum,
                "crossaSourceCommit": metadata.crossaSourceCommit,
                "warmupIterations": metadata.warmupIterations,
                "measuredIterations": metadata.measuredIterations,
                "endpoint": metadata.endpoint,
                "endpointKind": metadata.endpointKind.rawValue,
                "mode": metadata.mode.rawValue,
                "timestamp": metadata.timestamp.timeIntervalSince1970
            ],
            "samples": result.samples.map { sample in
                [
                    "implementation": sample.implementation.rawValue,
                    "iteration": sample.iteration,
                    "durationNanoseconds": sample.durationNanoseconds,
                    "success": sample.success,
                    "itemCount": sample.itemCount,
                    "materializationNanoseconds": sample.materializationNanoseconds as Any
                ]
            }
        ]
        if JSONSerialization.isValidJSONObject(raw), let data = try? JSONSerialization.data(withJSONObject: raw, options: [.prettyPrinted]) {
            let rawURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("benchmark-result.json")
            try? data.write(to: rawURL, options: .atomic)
        }
    }

    func cancelCurrentRequest() {
        loadingTask?.cancel()
        loadingTask = nil
        if case .loading = state {
            state = .cancelled
        }
    }

    func clearResults() {
        cancelCurrentRequest()
        state = .idle
        lastResult = nil
    }
}
