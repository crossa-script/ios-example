import Alamofire
import Foundation

@MainActor
final class AlamofirePostsRepository: PostsRepositoryProtocol {
    private let session: Session
    private let endpoint: URL
    private var activeRequest: DataRequest?

    init(session: Session, endpoint: URL) {
        self.session = session
        self.endpoint = endpoint
    }

    func getPosts() async throws -> any PostsPresentationData {
        try Task.checkCancellation()

        let request = session
            .request(endpoint, method: .get)
            .validate()
        activeRequest = request

        defer {
            if activeRequest === request {
                activeRequest = nil
            }
        }

        let posts: [AlamofirePostDTO]
        do {
            posts = try await withTaskCancellationHandler(operation: {
                try await request
                    .serializingDecodable([AlamofirePostDTO].self)
                    .value
            }, onCancel: {
                request.cancel()
            })
        } catch {
            if Task.isCancelled || (error as? AFError)?.isExplicitlyCancelledError == true {
                throw CancellationError()
            }
            throw error
        }

        return AlamofirePostsPresentationData(posts: posts)
    }

    func cancelCurrentRequest() {
        activeRequest?.cancel()
    }
}
