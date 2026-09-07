import Foundation

enum ExampleConfiguration {
    static let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    static let postsEndpoint = baseURL.appendingPathComponent("posts")
    static let requestIterations = 5
    static let requestDelayNanoseconds: UInt64 = 2_000_000_000
    static let crossaArtifactChecksum = "3735406b3017c7fb98230043152e6378143e0f67c99e23c7f5cabc1273719628"
    static let crossaSourceCommit = "ec92ea103e053613988a9fc5d34404cd7c34b177"
    static let requestHeaders = [
        "Accept": "application/json",
        "X-Crossa-Demo": "ios-example",
        "X-Crossa-Scenario": "cli",
        "Cache-Control": "no-cache, no-store, max-age=0",
        "Pragma": "no-cache",
        "Expires": "0"
    ]
}
