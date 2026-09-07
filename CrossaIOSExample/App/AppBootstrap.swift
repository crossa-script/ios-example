import Foundation

@MainActor
final class AppBootstrap: ObservableObject {
    let container: AppContainer?
    let initializationError: String?

    init() {
        let builtContainer: AppContainer?
        do {
            builtContainer = try AppContainer()
            initializationError = nil
        } catch {
            builtContainer = nil
            initializationError = error.localizedDescription
        }
        container = builtContainer
    }
}
