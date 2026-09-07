import Foundation

enum BenchmarkImplementation: String, CaseIterable, Sendable {
    case crossa
    case alamofire
}

enum BenchmarkMode: String, Sendable {
    case cold
    case warm
}

enum BenchmarkEndpointKind: String, Sendable {
    case remote
    case controlled
}

struct BenchmarkConfiguration: Sendable {
    var warmupIterations = 2
    var measuredIterations = 8
    var endpoint = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    var endpointKind = BenchmarkEndpointKind.remote
    var mode = BenchmarkMode.warm
    var timeout: TimeInterval = 10
}

struct BenchmarkResponse: Sendable {
    var itemCount: Int
    var materializationNanoseconds: UInt64?
}

struct BenchmarkSample: Sendable {
    var implementation: BenchmarkImplementation
    var iteration: Int
    var durationNanoseconds: UInt64
    var success: Bool
    var itemCount: Int
    var materializationNanoseconds: UInt64?
    var error: String?
}

struct BenchmarkSummary: Sendable {
    var implementation: BenchmarkImplementation
    var sampleCount: Int
    var successCount: Int
    var failureCount: Int
    var minNanoseconds: UInt64
    var maxNanoseconds: UInt64
    var meanNanoseconds: Double
    var medianNanoseconds: UInt64
    var p90Nanoseconds: UInt64
    var p95Nanoseconds: UInt64
    var standardDeviationNanoseconds: Double
}

struct CrossaSplitSummary: Sendable {
    var nativeReady: BenchmarkSummary
    var materialization: BenchmarkSummary?
    var applicationReady: BenchmarkSummary
}

struct BenchmarkMetadata: Sendable {
    var deviceModel: String
    var systemVersion: String
    var architecture: String
    var appVersion: String
    var buildConfiguration: String
    var crossaArtifact: String
    var crossaArtifactChecksum: String
    var crossaSourceCommit: String
    var warmupIterations: Int
    var measuredIterations: Int
    var endpoint: String
    var endpointKind: BenchmarkEndpointKind
    var mode: BenchmarkMode
    var timestamp: Date
}

struct BenchmarkRunResult: Sendable {
    var metadata: BenchmarkMetadata
    var summaries: [BenchmarkSummary]
    var crossaSplit: CrossaSplitSummary?
    var samples: [BenchmarkSample]
}

enum BenchmarkStatistics {
    static func summarize(
        implementation: BenchmarkImplementation,
        samples: [BenchmarkSample],
        duration: (BenchmarkSample) -> UInt64? = { sample in
            sample.success ? sample.durationNanoseconds : nil
        }
    ) -> BenchmarkSummary {
        let values = samples.compactMap(duration).sorted()
        let mean = values.isEmpty ? 0 : Double(values.reduce(0, +)) / Double(values.count)
        let variance: Double
        if values.count < 2 {
            variance = 0
        } else {
            variance = values.reduce(0) { partial, value in
                let delta = Double(value) - mean
                return partial + delta * delta
            } / Double(values.count - 1)
        }
        return BenchmarkSummary(
            implementation: implementation,
            sampleCount: samples.count,
            successCount: samples.filter(\.success).count,
            failureCount: samples.filter { !$0.success }.count,
            minNanoseconds: values.first ?? 0,
            maxNanoseconds: values.last ?? 0,
            meanNanoseconds: mean,
            medianNanoseconds: percentile(values, 0.50),
            p90Nanoseconds: percentile(values, 0.90),
            p95Nanoseconds: percentile(values, 0.95),
            standardDeviationNanoseconds: variance.squareRoot()
        )
    }

    private static func percentile(_ values: [UInt64], _ quantile: Double) -> UInt64 {
        guard !values.isEmpty else { return 0 }
        let rank = Int(Double(values.count - 1) * quantile)
        return values[min(max(rank, 0), values.count - 1)]
    }
}

protocol PostsBenchmarkClient: Sendable {
    var implementation: BenchmarkImplementation { get }
    func fetchPosts() async throws -> BenchmarkResponse
}
