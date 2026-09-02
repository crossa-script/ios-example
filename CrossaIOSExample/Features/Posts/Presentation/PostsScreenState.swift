import Foundation

@MainActor
enum PostsScreenState {
    case idle
    case loading(NetworkingEngine)
    case loaded(PostsRunResult)
    case failed(PostsFailure)
    case cancelled(NetworkingEngine)
}

@MainActor
struct PostsRunResult {
    let engine: NetworkingEngine
    let requestCount: Int
    let successCount: Int
    let totalMetrics: RequestMetrics
    let averageMilliseconds: Double
    let minimumMilliseconds: Double
    let maximumMilliseconds: Double
    let individualMetrics: [RequestMetrics]
    let posts: any PostsPresentationData
}

struct ScenarioMetrics: Equatable {
    let engine: NetworkingEngine
    let requestCount: Int
    let successCount: Int
    let averageMilliseconds: Double
    let minimumMilliseconds: Double
    let maximumMilliseconds: Double
    let itemCount: Int
}

struct PostsFailure: Equatable {
    let engine: NetworkingEngine
    let message: String
}
