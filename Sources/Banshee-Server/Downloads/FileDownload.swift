import Foundation

/// Thread-safe wrapper for NSLock
final class LockedValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withLock<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}

/// Represents an active file download with real-time progress tracking
final class FileDownload: Sendable {
    let id: UUID
    let from: URL
    let to: URL

    // Thread-safe progress tracking
    private let _progress: LockedValue<Double>
    var progress: Double {
        _progress.withLock { $0 }
    }

    private let _status: LockedValue<Status>
    var status: Status {
        _status.withLock { $0 }
    }

    let task: Task<Void, any Error>

    enum Status: Sendable {
        case downloading
        case completed
        case failed(any Error)
        case cancelled
    }

    init(id: UUID, from: URL, to: URL, task: Task<Void, any Error>) {
        self.id = id
        self.from = from
        self.to = to
        self._progress = LockedValue(0.0)
        self._status = LockedValue(.downloading)
        self.task = task
    }

    func updateProgress(_ newProgress: Double) {
        _progress.withLock { $0 = newProgress }
    }

    func updateStatus(_ newStatus: Status) {
        _status.withLock { $0 = newStatus }
    }
}
