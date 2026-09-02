import SwiftUI

@main
struct CrossaIOSExampleApp: App {
    private let bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            RootView(bootstrap: bootstrap)
        }
    }
}
