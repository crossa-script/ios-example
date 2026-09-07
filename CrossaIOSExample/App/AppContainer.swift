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
        let benchmarkMode: BenchmarkMode = ProcessInfo.processInfo.arguments.contains("--crossa-benchmark-cold") ? .cold : .warm
        let configuration = BenchmarkConfiguration(mode: benchmarkMode)
        let clientFactory: @Sendable () throws -> [any PostsBenchmarkClient] = {
            let runtime = try CrossaRuntime()
            let session = AlamofireConfiguration.makeSession()
            return [
                CrossaPostsClient(runtime: runtime),
                AlamofirePostsClient(session: session, endpoint: configuration.endpoint)
            ]
        }
        crossaRuntime = runtime
        alamofireSession = session
        postsViewModel = PostsViewModel(
            runner: BenchmarkRunner(
                configuration: configuration,
                clients: [
                    CrossaPostsClient(runtime: runtime),
                    AlamofirePostsClient(session: session, endpoint: configuration.endpoint)
                ],
                clientFactory: clientFactory
            )
        )
    }
}
