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
        loadingTask = Task.detached { [runner] in
            let result = await runner.run()
            await MainActor.run { [weak self] in
                self?.printBenchmarkResult(result)
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
