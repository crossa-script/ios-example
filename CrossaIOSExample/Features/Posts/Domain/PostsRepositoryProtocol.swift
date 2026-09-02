import Foundation

@MainActor
protocol PostsRepositoryProtocol: AnyObject {
    func getPosts() async throws -> any PostsPresentationData
    func cancelCurrentRequest()
}
