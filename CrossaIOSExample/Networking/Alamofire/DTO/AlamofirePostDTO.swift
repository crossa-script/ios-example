import Foundation

struct AlamofirePostDTO: Decodable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
