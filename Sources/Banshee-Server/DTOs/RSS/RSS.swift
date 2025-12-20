import Foundation
import XMLCoder
import Vapor

struct RSS: Content {
    @Element var channel: PodcastDTO
}