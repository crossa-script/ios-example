import Foundation

@MainActor
final class PostsViewModel: ObservableObject {
    @Published var selectedEngine: NetworkingEngine = .crossa
    @Published private(set) var state: PostsScreenState = .idle
    @Published private(set) var scenarioMetrics: [NetworkingEngine: ScenarioMetrics] = [:]

    private let crossaRepository: any PostsRepositoryProtocol
    private let alamofireRepository: any PostsRepositoryProtocol
    private var loadingTask: Task<Void, Never>?
    private var activeRunIdentifier: UUID?

    init(
        crossaRepository: any PostsRepositoryProtocol,
        alamofireRepository: any PostsRepositoryProtocol
    ) {
        self.crossaRepository = crossaRepository
        self.alamofireRepository = alamofireRepository
    }

    func loadPosts() {
        cancelActiveRun()
        let engine = selectedEngine
        let runIdentifier = UUID()
        activeRunIdentifier = runIdentifier
        state = .loading(engine)
        loadingTask = Task { [weak self] in
            await self?.runScenario(for: engine, identifier: runIdentifier)
        }
    }

    func cancelCurrentRequest() {
        guard activeRunIdentifier != nil else {
            return
        }
        loadingTask?.cancel()
        crossaRepository.cancelCurrentRequest()
        alamofireRepository.cancelCurrentRequest()
    }

    func clearResults() {
        cancelActiveRun()
        state = .idle
        scenarioMetrics = [:]
    }

    private func cancelActiveRun() {
        activeRunIdentifier = nil
        loadingTask?.cancel()
        loadingTask = nil
        crossaRepository.cancelCurrentRequest()
        alamofireRepository.cancelCurrentRequest()
    }

    private func runScenario(for engine: NetworkingEngine, identifier: UUID) async {
        let repository = repository(for: engine)
        var requestMetrics: [RequestMetrics] = []
        var latestPosts: (any PostsPresentationData)?
        var successCount = 0

        do {
            for iteration in 0..<ExampleConfiguration.requestIterations {
                try Task.checkCancellation()
                let start = MonotonicClock.now()
                let posts = try await repository.getPosts()
                let metrics = RequestMetrics(
                    elapsedNanoseconds: MonotonicClock.elapsed(since: start),
                    itemCount: posts.count
                )
                requestMetrics.append(metrics)
                latestPosts = posts
                successCount += 1

                if iteration < ExampleConfiguration.requestIterations - 1 {
                    try await Task.sleep(nanoseconds: ExampleConfiguration.requestDelayNanoseconds)
                }
            }

            guard let latestPosts else {
                updateStateIfCurrent(
                    .failed(PostsFailure(engine: engine, message: "No response was returned.")),
                    identifier: identifier
                )
                return
            }

            let result = makeResult(
                engine: engine,
                successCount: successCount,
                metrics: requestMetrics,
                posts: latestPosts
            )
            guard activeRunIdentifier == identifier else {
                return
            }
            scenarioMetrics[engine] = ScenarioMetrics(
                engine: engine,
                requestCount: result.requestCount,
                successCount: result.successCount,
                averageMilliseconds: result.averageMilliseconds,
                minimumMilliseconds: result.minimumMilliseconds,
                maximumMilliseconds: result.maximumMilliseconds,
                itemCount: result.totalMetrics.itemCount
            )
            state = .loaded(result)
            loadingTask = nil
        } catch is CancellationError {
            updateStateIfCurrent(.cancelled(engine), identifier: identifier)
        } catch {
            updateStateIfCurrent(
                .failed(PostsFailure(engine: engine, message: error.localizedDescription)),
                identifier: identifier
            )
        }
    }

    private func repository(for engine: NetworkingEngine) -> any PostsRepositoryProtocol {
        switch engine {
        case .crossa:
            return crossaRepository
        case .alamofire:
            return alamofireRepository
        }
    }

    private func makeResult(
        engine: NetworkingEngine,
        successCount: Int,
        metrics: [RequestMetrics],
        posts: any PostsPresentationData
    ) -> PostsRunResult {
        let elapsedValues = metrics.map(\.elapsedNanoseconds)
        let total = elapsedValues.reduce(0, +)
        let average = metrics.isEmpty ? 0 : Double(total) / Double(metrics.count) / 1_000_000
        let minimum = Double(elapsedValues.min() ?? 0) / 1_000_000
        let maximum = Double(elapsedValues.max() ?? 0) / 1_000_000

        return PostsRunResult(
            engine: engine,
            requestCount: ExampleConfiguration.requestIterations,
            successCount: successCount,
            totalMetrics: RequestMetrics(elapsedNanoseconds: total, itemCount: posts.count),
            averageMilliseconds: average,
            minimumMilliseconds: minimum,
            maximumMilliseconds: maximum,
            individualMetrics: metrics,
            posts: posts
        )
    }

    private func updateStateIfCurrent(_ nextState: PostsScreenState, identifier: UUID) {
        guard activeRunIdentifier == identifier else {
            return
        }
        state = nextState
        loadingTask = nil
    }
}
