import Foundation

enum ExampleConfiguration {
    static let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    static let postsEndpoint = baseURL.appendingPathComponent("posts")
    static let requestIterations = 5
    static let requestDelayNanoseconds: UInt64 = 2_000_000_000
    static let crossaArtifactChecksum = "8838a6c5e23ecdb027b58d0f101f68a78f51f4eba3cbb938b3860e72207f4c04"
    static let crossaSourceCommit = "3e37fbbc774edf1bd69f457f489ceb2f72d7cfe7"
    static let requestHeaders = [
        "Accept": "application/json",
        "X-Crossa-Demo": "ios-example",
        "X-Crossa-Scenario": "cli",
        "Cache-Control": "no-cache, no-store, max-age=0",
        "Pragma": "no-cache",
        "Expires": "0"
    ]
}
