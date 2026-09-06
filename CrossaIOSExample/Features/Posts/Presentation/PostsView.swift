import SwiftUI

struct PostsView: View {
    @ObservedObject var viewModel: PostsViewModel

    var body: some View {
        List {
            header
            stateContent
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Crossa Example")
    }

    private var header: some View {
        Section(header: Text("Network comparison")) {
            Text("GET https://jsonplaceholder.typicode.com/posts")
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack {
                Button(isLoading ? "Running" : "Run benchmark") {
                    viewModel.runComparison()
                }
                .disabled(isLoading)
                Spacer()
                if isLoading {
                    Button("Cancel") { viewModel.cancelCurrentRequest() }
                        .foregroundColor(.red)
                } else {
                    Button("Clear") { viewModel.clearResults() }
                }
            }
            Text("Warmups excluded. Rounds interleaved. Release XCFramework required for measurements.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            Section {
                Text("Run interleaved warm Crossa and Alamofire rounds. Results are observations, not product claims.")
                    .foregroundColor(.secondary)
            }
        case .loading:
            Section {
                HStack {
                    ProgressView()
                    Text("Running benchmark…")
                }
            }
        case .loaded(let result):
            metadataSection(result.metadata)
            ForEach(result.summaries, id: \.implementation) { summary in
                summarySection(summary, split: result.crossaSplit)
            }
        case .cancelled:
            Section {
                Text("Benchmark cancelled")
            }
        }
    }

    private func metadataSection(_ metadata: BenchmarkMetadata) -> some View {
        Section(header: Text("Reproducibility")) {
            Text("Build \(metadata.buildConfiguration)  Artifact \(metadata.crossaArtifact)")
            Text("Mode \(metadata.mode.rawValue)  \(metadata.endpointKind.rawValue)")
            Text("Warmups \(metadata.warmupIterations)  Measured \(metadata.measuredIterations)")
            Text(metadata.deviceModel)
                .font(.footnote)
                .foregroundColor(.secondary)
            Text(metadata.systemVersion)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func summarySection(_ summary: BenchmarkSummary, split: CrossaSplitSummary?) -> some View {
        Section(header: Text(summary.implementation.rawValue)) {
            row("p50", format(summary.medianNanoseconds))
            row("p95", format(summary.p95Nanoseconds))
            row("mean", format(summary.meanNanoseconds))
            row("min / max", "\(format(summary.minNanoseconds)) / \(format(summary.maxNanoseconds))")
            row("success", "\(summary.successCount)/\(summary.sampleCount)")
            if summary.implementation == .crossa, let split {
                row("native-ready p50", format(split.nativeReady.medianNanoseconds))
                row("materialization p50", split.materialization.map { format($0.medianNanoseconds) } ?? "n/a")
                row("application-ready p50", format(split.applicationReady.medianNanoseconds))
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }

    private func format(_ nanoseconds: UInt64) -> String {
        String(format: "%.2f ms", Double(nanoseconds) / 1_000_000)
    }

    private func format(_ nanoseconds: Double) -> String {
        String(format: "%.2f ms", nanoseconds / 1_000_000)
    }
}
