import Foundation

struct FileDownload {
    let progress: Double
    let from: URL
    let to: URL
    let task: Task<Void, Never>
}