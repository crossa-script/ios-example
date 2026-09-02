import Alamofire
import Foundation

enum AlamofireConfiguration {
    static func makeSession() -> Session {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpAdditionalHeaders = ExampleConfiguration.requestHeaders
        return Session(configuration: configuration)
    }
}
