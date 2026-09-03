import SwiftUI

struct PostsView: View {
    @ObservedObject var viewModel: PostsViewModel

    var body: some View {
        List {
            header
            stateContent
            comparisonSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Crossa Example")
    }

    private var header: some View {
        Section(header: Text("Network comparison")) {
            Text("GET https://jsonplaceholder.typicode.com/posts")
                .font(.footnote)
                .foregroundColor(.secondary)

            Picker("Networking Engine", selection: $viewModel.selectedEngine) {
                ForEach(NetworkingEngine.allCases) { engine in
                    Text(engine.title).tag(engine)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(isLoading)

            HStack {
                Button(isLoading ? "Running" : "Run 5 requests") {
                    viewModel.runComparison()
                }
                .disabled(isLoading)

                Spacer()

                if isLoading {
                    Button("Cancel") {
                        viewModel.cancelCurrentRequest()
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Clear") {
                        viewModel.clearResults()
                    }
                }
            }

            HStack(spacing: 8) {
                MetricLabel(title: "Clients", value: "2")
                MetricLabel(title: "Requests", value: "5")
                MetricLabel(title: "Delay", value: "2000ms")
                MetricLabel(title: "Cache", value: "disabled")
            }
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            Section(header: EmptyView()) {
                    Text("Run five uncached requests through Crossa C++/libcurl and Alamofire, then compare parsed results.")
                    .foregroundColor(.secondary)
            }
        case .loading(let engine):
            Section(header: EmptyView()) {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Running \(engine.title) requests…")
                }
                Text("Each request uses the same endpoint and headers, with a 2 second interval.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        case .loaded(let result):
            resultSection(result)
        case .failed(let failure):
            Section(header: EmptyView()) {
                Text("\(failure.engine.title) request failed")
                    .font(.headline)
                    .foregroundColor(.red)
                Text(failure.message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        case .cancelled(let engine):
            Section(header: EmptyView()) {
                Text("\(engine.title) request cancelled")
                    .font(.headline)
                Text("The active operation was cancelled without presenting it as a network error.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func resultSection(_ result: PostsRunResult) -> some View {
        Section(
            header: Text("\(result.engine.title) result"),
            footer: Text("The timer ends when Crossa exposes its native-backed list or when Alamofire finishes Decodable response processing. Crossa rows are read lazily from the native result.")
        ) {
            HStack {
                Text("Engine")
                Spacer()
                Text(result.engine.title)
                    .fontWeight(.semibold)
            }
            HStack {
                Text("Success")
                Spacer()
                Text("\(result.successCount)/\(result.requestCount)")
            }
            HStack {
                Text("Total")
                Spacer()
                Text(result.totalMetrics.formattedMilliseconds)
            }
            HStack {
                Text("Average")
                Spacer()
                Text(formatMilliseconds(result.averageMilliseconds))
            }
            HStack {
                Text("Minimum / Maximum")
                Spacer()
                Text("\(formatMilliseconds(result.minimumMilliseconds)) / \(formatMilliseconds(result.maximumMilliseconds))")
            }
            HStack {
                Text("Posts")
                Spacer()
                Text("\(result.totalMetrics.itemCount)")
            }
            Text("Timings: \(result.individualMetrics.map { formatMilliseconds($0.milliseconds) }.joined(separator: ", "))")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var comparisonSection: some View {
        Section(
            header: Text("Last observations"),
            footer: Text("These are raw in-app observations, not benchmark conclusions.")
        ) {
            ForEach(NetworkingEngine.allCases) { engine in
                if let metrics = viewModel.scenarioMetrics[engine] {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(engine.title)
                            .fontWeight(.semibold)
                        Text("Average \(formatMilliseconds(metrics.averageMilliseconds)) · min \(formatMilliseconds(metrics.minimumMilliseconds)) · max \(formatMilliseconds(metrics.maximumMilliseconds))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Success \(metrics.successCount)/\(metrics.requestCount) · posts \(metrics.itemCount)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("\(engine.title): no completed observation")
                        .foregroundColor(.secondary)
                }
            }
            if let winner = viewModel.comparisonWinner {
                Text("Winner: \(winner.title) by average parsed-response time")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }
        return false
    }

    private func formatMilliseconds(_ value: Double) -> String {
        String(format: "%.2f ms", value)
    }
}

private struct MetricLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
