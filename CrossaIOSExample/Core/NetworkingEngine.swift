import Foundation

enum NetworkingEngine: String, CaseIterable, Identifiable {
    case crossa
    case alamofire

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .crossa:
            return "Crossa"
        case .alamofire:
            return "Alamofire"
        }
    }
}
