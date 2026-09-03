import Crossa
import Foundation

@MainActor
struct CrossaPostsPresentationData: PostsPresentationData, @unchecked Sendable {
    private let posts: CrossaList<Post>

    init(posts: CrossaList<Post>) {
        self.posts = posts
    }

    var count: Int {
        posts.count
    }

    func item(at index: Int) -> PostRowModel {
        let post = posts[index]
        return PostRowModel(
            id: post.id,
            userID: post.userId,
            title: post.title,
            body: post.body
        )
    }
}
