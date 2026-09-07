import Foundation

enum ExampleConfiguration {
    static let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    static let postsEndpoint = baseURL.appendingPathComponent("posts")
    static let requestIterations = 5
    static let requestDelayNanoseconds: UInt64 = 2_000_000_000
    static let crossaArtifactChecksum = "e1d3fb6872bde28fe1a185ade80b97187366c9fbbefa4f3a3a049503a448d82c"
    static let crossaSourceCommit = "03d421801191f67c59722e96a1cc4a962a4b54ba"
    static let requestHeaders = [
        "Accept": "application/json",
        "X-Crossa-Demo": "ios-example",
        "X-Crossa-Scenario": "cli",
        "Cache-Control": "no-cache, no-store, max-age=0",
        "Pragma": "no-cache",
        "Expires": "0"
    ]
}
