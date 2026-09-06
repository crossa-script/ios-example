import Foundation

enum PostsScreenState {
    case idle
    case loading
    case loaded(BenchmarkRunResult)
    case cancelled
}
