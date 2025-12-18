import Foundation
import Vapor

struct RSS: Content {
    let channel: PodcastDTO
}