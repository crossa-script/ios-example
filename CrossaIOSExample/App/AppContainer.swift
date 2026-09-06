import Alamofire
import Crossa
import Foundation

@MainActor
final class AppContainer {
    let crossaRuntime: CrossaRuntime
    let alamofireSession: Session
    let postsViewModel: PostsViewModel

    init() throws {
        let runtime = try CrossaRuntime()
        let session = AlamofireConfiguration.makeSession()
        let configuration = BenchmarkConfiguration()
        crossaRuntime = runtime
        alamofireSession = session
        postsViewModel = PostsViewModel(
            runner: BenchmarkRunner(
                configuration: configuration,
                clients: [
                    CrossaPostsClient(runtime: runtime),
                    AlamofirePostsClient(session: session, endpoint: configuration.endpoint)
                ]
            )
        )
    }
}
