import Foundation

@MainActor
struct AlamofirePostsPresentationData: PostsPresentationData {
    private let posts: [AlamofirePostDTO]

    init(posts: [AlamofirePostDTO]) {
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
