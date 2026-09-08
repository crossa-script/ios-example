import Foundation

struct BenchmarkRunner: Sendable {
    var configuration: BenchmarkConfiguration
    var clients: [any PostsBenchmarkClient]
    var clientFactory: @Sendable () throws -> [any PostsBenchmarkClient]

    func run() async -> BenchmarkRunResult {
        if configuration.mode == .cold {
            return await runCold()
        }
        await warmup()
        let samples = await measure(clients: clients)
        return result(samples)
    }

    private func warmup() async {
        for _ in 0..<configuration.warmupIterations {
            for client in clients {
                _ = try? await client.fetchPosts()
            }
        }
    }

    private func measure(clients: [any PostsBenchmarkClient]) async -> [BenchmarkSample] {
        var samples: [BenchmarkSample] = []
        for iteration in 0..<configuration.measuredIterations {
            for client in rotating(clients, iteration: iteration) {
                samples.append(await sample(client: client, iteration: iteration))
            }
        }
        return samples
    }

    private func runCold() async -> BenchmarkRunResult {
        var samples: [BenchmarkSample] = []
        for iteration in 0..<configuration.measuredIterations {
            for implementation in rotating(BenchmarkImplementation.allCases, iteration: iteration) {
                do {
                    let coldClients = try clientFactory()
                    guard let client = coldClients.first(where: { $0.implementation == implementation }) else {
                        samples.append(failedSample(implementation: implementation, iteration: iteration, error: "client unavailable"))
                        continue
                    }
                    samples.append(await sample(client: client, iteration: iteration))
                } catch {
                    samples.append(failedSample(implementation: implementation, iteration: iteration, error: error.localizedDescription))
                }
            }
        }
        return result(samples)
    }

    private func sample(client: any PostsBenchmarkClient, iteration: Int) async -> BenchmarkSample {
        let start = DispatchTime.now().uptimeNanoseconds
        do {
            try Task.checkCancellation()
            let response = try await client.fetchPosts()
            return BenchmarkSample(
                implementation: client.implementation,
                iteration: iteration,
                durationNanoseconds: DispatchTime.now().uptimeNanoseconds - start,
                success: true,
                itemCount: response.itemCount,
                materializationNanoseconds: response.materializationNanoseconds
            )
        } catch is CancellationError {
            return BenchmarkSample(
                implementation: client.implementation,
                iteration: iteration,
                durationNanoseconds: DispatchTime.now().uptimeNanoseconds - start,
                success: false,
                itemCount: 0,
                error: "cancelled"
            )
        } catch {
            return BenchmarkSample(
                implementation: client.implementation,
                iteration: iteration,
                durationNanoseconds: DispatchTime.now().uptimeNanoseconds - start,
                success: false,
                itemCount: 0,
                error: error.localizedDescription
            )
        }
    }

    private func rotating(_ clients: [any PostsBenchmarkClient], iteration: Int) -> [any PostsBenchmarkClient] {
        guard !clients.isEmpty else { return clients }
        let offset = iteration % clients.count
        return Array(clients[offset...]) + Array(clients[..<offset])
    }

    private func rotating(_ implementations: [BenchmarkImplementation], iteration: Int) -> [BenchmarkImplementation] {
        guard !implementations.isEmpty else { return implementations }
        let offset = iteration % implementations.count
        return Array(implementations[offset...]) + Array(implementations[..<offset])
    }

    private func failedSample(implementation: BenchmarkImplementation, iteration: Int, error: String) -> BenchmarkSample {
        BenchmarkSample(
            implementation: implementation,
            iteration: iteration,
            durationNanoseconds: 0,
            success: false,
            itemCount: 0,
            error: error
        )
    }

    private func result(_ samples: [BenchmarkSample]) -> BenchmarkRunResult {
        let summaries = BenchmarkImplementation.allCases.map { implementation in
            BenchmarkStatistics.summarize(
                implementation: implementation,
                samples: samples.filter { $0.implementation == implementation }
            )
        }
        let crossaSamples = samples.filter { $0.implementation == .crossa }
        let nativeReady = BenchmarkStatistics.summarize(implementation: .crossa, samples: crossaSamples) { sample in
            guard sample.success else { return nil }
            return sample.durationNanoseconds - (sample.materializationNanoseconds ?? 0)
        }
        let materialization = BenchmarkStatistics.summarize(implementation: .crossa, samples: crossaSamples) { sample in
            sample.success ? sample.materializationNanoseconds : nil
        }
        return BenchmarkRunResult(
            metadata: metadata(),
            summaries: summaries,
            crossaSplit: CrossaSplitSummary(
                nativeReady: nativeReady,
                materialization: materialization.successCount > 0 ? materialization : nil,
                applicationReady: summaries.first { $0.implementation == .crossa } ?? nativeReady
            ),
            samples: samples
        )
    }

    private func metadata() -> BenchmarkMetadata {
        #if DEBUG
        let build = "Debug"
        #else
        let build = "Release"
        #endif
        return BenchmarkMetadata(
            deviceModel: ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "unknown",
            systemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            architecture: "arm64",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            buildConfiguration: build,
            warmupIterations: configuration.warmupIterations,
            measuredIterations: configuration.measuredIterations,
            endpoint: configuration.endpoint.absoluteString,
            endpointKind: configuration.endpointKind,
            mode: configuration.mode,
            timestamp: Date()
        )
    }

}
