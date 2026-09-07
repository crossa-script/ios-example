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
        let start = DispatchTime.now().uptimeNanoseconds
        for index in posts.indices {
            let post = posts[index]
            _ = (post.userId, post.id, post.title, post.body)
        }
        return BenchmarkResponse(
            itemCount: nativeReadyCount,
            materializationNanoseconds: DispatchTime.now().uptimeNanoseconds - start
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
