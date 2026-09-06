import Crossa
import Foundation

struct CrossaPostsClient: PostsBenchmarkClient, @unchecked Sendable {
    let implementation = BenchmarkImplementation.crossa
    private let runtime: CrossaRuntime

    init(runtime: CrossaRuntime) {
        self.runtime = runtime
    }

    func fetchPosts() async throws -> BenchmarkResponse {
        let posts = try await CrossaFunctions.fetchPosts(runtime: runtime)
        let nativeReadyCount = posts.count
        let clock = ContinuousClock()
        let start = clock.now
        for index in posts.indices {
            let post = posts[index]
            _ = (post.userId, post.id, post.title, post.body)
        }
        let materialization = start.duration(to: clock.now)
        let attoseconds = UInt64(max(materialization.components.attoseconds, 0))
        let seconds = UInt64(max(materialization.components.seconds, 0))
        return BenchmarkResponse(
            itemCount: nativeReadyCount,
            materializationNanoseconds: seconds &* 1_000_000_000 &+ attoseconds / 1_000_000_000
        )
    }
}

@MainActor
final class CrossaPostsRepository: PostsRepositoryProtocol {
    private let client: CrossaPostsClient
    private var activeTask: Task<Void, Never>?

    init(runtime: CrossaRuntime) {
        self.client = CrossaPostsClient(runtime: runtime)
    }

    func getPosts() async throws -> any PostsPresentationData {
        let response = try await client.fetchPosts()
        return CountOnlyPresentationData(count: response.itemCount)
    }

    func cancelCurrentRequest() {
        activeTask?.cancel()
    }
}

private struct CountOnlyPresentationData: PostsPresentationData {
    let count: Int
    func item(at index: Int) -> PostRowModel {
        PostRowModel(id: index, userID: 0, title: "", body: "")
    }
}
