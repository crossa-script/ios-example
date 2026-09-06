import Alamofire
import Foundation

struct AlamofirePostsClient: PostsBenchmarkClient, @unchecked Sendable {
    let implementation = BenchmarkImplementation.alamofire
    private let session: Session
    private let endpoint: URL

    init(session: Session, endpoint: URL) {
        self.session = session
        self.endpoint = endpoint
    }

    func fetchPosts() async throws -> BenchmarkResponse {
        let posts = try await session
            .request(
                endpoint,
                method: .get,
                headers: HTTPHeaders(ExampleConfiguration.requestHeaders.map {
                    HTTPHeader(name: $0.key, value: $0.value)
                })
            )
            .serializingDecodable([AlamofirePostDTO].self)
            .value
        return BenchmarkResponse(itemCount: posts.count)
    }
}

@MainActor
final class AlamofirePostsRepository: PostsRepositoryProtocol {
    private let client: AlamofirePostsClient

    init(session: Session, endpoint: URL) {
        self.client = AlamofirePostsClient(session: session, endpoint: endpoint)
    }

    func getPosts() async throws -> any PostsPresentationData {
        let response = try await client.fetchPosts()
        return CountOnlyPresentationData(count: response.itemCount)
    }

    func cancelCurrentRequest() {}
}

private struct CountOnlyPresentationData: PostsPresentationData {
    let count: Int
    func item(at index: Int) -> PostRowModel {
        PostRowModel(id: index, userID: 0, title: "", body: "")
    }
}
