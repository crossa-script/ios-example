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
                self?.lastResult = result
                self?.state = .loaded(result)
                self?.loadingTask = nil
            }
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
