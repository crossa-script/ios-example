import SwiftUI

struct PostsView: View {
    @ObservedObject var viewModel: PostsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                comparisonHeader
                controlCard
                stateContent
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Library benchmark")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var comparisonHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.16, green: 0.12, blue: 0.30), Color(red: 0.05, green: 0.14, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .fill(Color.purple.opacity(0.42))
                .frame(width: 190, height: 190)
                .blur(radius: 48)
                .offset(x: 190, y: -48)
            VStack(alignment: .leading, spacing: 8) {
                Text("LIBRARY BENCHMARK")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(Color(red: 0.68, green: 0.62, blue: 1))
                Text("Crossa vs Alamofire")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("One endpoint. Two libraries. The same measured request.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                Label("GET /posts", systemImage: "arrow.down.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(red: 0.48, green: 0.72, blue: 1))
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .bottomLeading)
    }

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Benchmark controls")
                .font(.headline)
            Text("Compare the scores from the same request.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    viewModel.runComparison()
                } label: {
                    Label(isLoading ? "Running" : "Run benchmark", systemImage: isLoading ? "hourglass" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                if isLoading {
                    Button("Cancel", role: .destructive) { viewModel.cancelCurrentRequest() }
                        .buttonStyle(.bordered)
                } else if viewModel.lastResult != nil {
                    Button("Clear") { viewModel.clearResults() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateCard()
        case .loading:
            LoadingCard()
        case .loaded(let result):
            let ordered = result.summaries.sorted { lhs, rhs in
                if lhs.successCount == 0 { return false }
                if rhs.successCount == 0 { return true }
                return lhs.medianNanoseconds < rhs.medianNanoseconds
            }
            ForEach(Array(ordered.enumerated()), id: \.offset) { index, summary in
                LibraryResultCard(summary: summary, rank: index, fastest: ordered.first { $0.successCount > 0 })
            }
        case .cancelled:
            StatusCard(title: "Benchmark cancelled", message: "Run it again when the simulator is ready.", color: .orange)
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}

private struct LibraryResultCard: View {
    let summary: BenchmarkSummary
    let rank: Int
    let fastest: BenchmarkSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("#\(rank + 1)  \(summary.implementation.rawValue.capitalized)")
                        .font(.title3.weight(.bold))
                    Text("\(summary.successCount)/\(summary.sampleCount) successful rounds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if rank == 0 {
                    Text("FASTEST p50")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
            HStack(spacing: 10) {
                MetricTile(title: "p50", value: format(summary.medianNanoseconds))
                MetricTile(title: "p95", value: format(summary.p95Nanoseconds))
                MetricTile(title: "mean", value: format(summary.meanNanoseconds))
            }
            HStack {
                Text("Range")
                Spacer()
                Text("\(format(summary.minNanoseconds)) – \(format(summary.maxNanoseconds))")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            if let fastest, rank > 0, fastest.medianNanoseconds > 0 {
                let delta = (Double(summary.medianNanoseconds) / Double(fastest.medianNanoseconds) - 1) * 100
                Text("+\(String(format: "%.1f", delta))% p50 vs fastest")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(rank == 0 ? Color.green.opacity(0.12) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(rank == 0 ? Color.green.opacity(0.35) : Color.clear, lineWidth: 1))
    }

    private func format(_ nanoseconds: UInt64) -> String { String(format: "%.2f ms", Double(nanoseconds) / 1_000_000) }
    private func format(_ nanoseconds: Double) -> String { String(format: "%.2f ms", nanoseconds / 1_000_000) }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ContextPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct EmptyStateCard: View {
    var body: some View { StatusCard(title: "Ready to compare", message: "Run the same posts request through Crossa and Alamofire to see p50, p95 and mean latency.", color: .blue) }
}

private struct LoadingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Measuring alternating library rounds…")
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct StatusCard: View {
    let title: String
    let message: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
