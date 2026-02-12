import Vapor
import XMLCoder

struct RSS: Content {
    @Element var channel: PodcastRSS
}
