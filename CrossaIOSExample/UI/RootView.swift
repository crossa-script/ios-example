import SwiftUI

struct RootView: View {
    @ObservedObject var bootstrap: AppBootstrap

    var body: some View {
        Group {
            if let container = bootstrap.container {
                PostsScene(container: container)
            } else {
                InitializationFailureView(message: bootstrap.initializationError ?? "Crossa could not be initialized.")
            }
        }
    }
}

private struct PostsScene: View {
    @ObservedObject private var viewModel: PostsViewModel
    @State private var comparisonStarted = false

    init(container: AppContainer) {
        viewModel = container.postsViewModel
    }

    var body: some View {
        NavigationContainer {
            PostsView(viewModel: viewModel)
        }
        .onAppear {
            guard !comparisonStarted else { return }
            comparisonStarted = true
            viewModel.runComparison()
        }
    }
}

private struct NavigationContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

private struct InitializationFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Crossa Example")
                .font(.title2)
                .fontWeight(.bold)
            Text("Crossa runtime initialization failed")
                .font(.headline)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
