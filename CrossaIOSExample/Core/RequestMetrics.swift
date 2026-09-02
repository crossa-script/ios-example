import Foundation

struct RequestMetrics: Equatable {
    let elapsedNanoseconds: UInt64
    let itemCount: Int

    var milliseconds: Double {
        Double(elapsedNanoseconds) / 1_000_000
    }

    var formattedMilliseconds: String {
        String(format: "%.2f ms", milliseconds)
    }
}

enum MonotonicClock {
    static func now() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds
    }

    static func elapsed(since start: UInt64) -> UInt64 {
        DispatchTime.now().uptimeNanoseconds - start
    }
}
