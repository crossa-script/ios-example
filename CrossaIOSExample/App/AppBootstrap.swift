import Foundation

@MainActor
final class AppBootstrap: ObservableObject {
    let container: AppContainer?
    let initializationError: String?

    init() {
        do {
            container = try AppContainer()
            initializationError = nil
        } catch {
            container = nil
            initializationError = error.localizedDescription
        }
    }
}
