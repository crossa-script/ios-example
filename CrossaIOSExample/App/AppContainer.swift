import Alamofire
import Crossa
import Foundation

@MainActor
final class AppContainer {
    let crossaRuntime: CrossaRuntime
    let crossaPostsRepository: any PostsRepositoryProtocol
    let alamofirePostsRepository: any PostsRepositoryProtocol
    let postsViewModel: PostsViewModel

    init() throws {
        let runtime = try CrossaRuntime()
        let session = AlamofireConfiguration.makeSession()

        crossaRuntime = runtime
        crossaPostsRepository = CrossaPostsRepository(runtime: runtime)
        alamofirePostsRepository = AlamofirePostsRepository(
            session: session,
            endpoint: ExampleConfiguration.postsEndpoint
        )
        postsViewModel = PostsViewModel(
            crossaRepository: crossaPostsRepository,
            alamofireRepository: alamofirePostsRepository
        )
    }
}
