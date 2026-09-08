import Foundation

enum ExampleConfiguration {
    static let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    static let postsEndpoint = baseURL.appendingPathComponent("posts")
    static let requestIterations = 5
    static let requestDelayNanoseconds: UInt64 = 2_000_000_000
    static let crossaArtifactChecksum = "86889bb70f6d0e19ef094ce7496ea6032e46d92cc662d3d58117c7b75229e438"
    static let crossaSourceCommit = "8c362e10fba65cbc2279f08c06eb5469e16a72e5"
    static let requestHeaders = [
        "Accept": "application/json",
        "X-Crossa-Demo": "ios-example",
        "X-Crossa-Scenario": "cli",
        "Cache-Control": "no-cache, no-store, max-age=0",
        "Pragma": "no-cache",
        "Expires": "0"
    ]
}
