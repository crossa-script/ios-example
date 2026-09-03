import Foundation

@MainActor
protocol PostsPresentationData: Sendable {
    var count: Int { get }
    func item(at index: Int) -> PostRowModel
}

struct PostRowModel: Identifiable, Sendable {
    let id: Int
    let userID: Int
    let title: String
    let body: String
}
