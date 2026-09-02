import Crossa
import Foundation

@MainActor
final class CrossaPostsRepository: PostsRepositoryProtocol {
    private let runtime: CrossaRuntime
    private var activeOperation: CrossaOperation?

    init(runtime: CrossaRuntime) {
        self.runtime = runtime
    }

    func getPosts() async throws -> any PostsPresentationData {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            let operation = CrossaFunctions.getPosts(runtime: runtime) { [weak self] state in
                Task { @MainActor in
                    self?.activeOperation = nil

                    switch state {
                    case .success(let posts):
                        continuation.resume(returning: CrossaPostsPresentationData(posts: posts))
                    case .failed(let error):
                        continuation.resume(throwing: CrossaPostsRepositoryError(error: error))
                    case .cancelled:
                        continuation.resume(throwing: CancellationError())
                    @unknown default:
                        continuation.resume(throwing: CrossaPostsRepositoryUnexpectedStateError())
                    }
                }
            }
            activeOperation = operation

            if Task.isCancelled {
                operation.cancel()
            }
        }
    }

    func cancelCurrentRequest() {
        activeOperation?.cancel()
    }
}

struct CrossaPostsRepositoryError: LocalizedError {
    let error: CrossaError

    var errorDescription: String? {
        "Crossa [domain \(error.domain), code \(error.code)]: \(error.message)"
    }
}

struct CrossaPostsRepositoryUnexpectedStateError: LocalizedError {
    var errorDescription: String? {
        "Crossa returned an unsupported operation state."
    }
}
