import Vapor

extension URI {
    init(from url: URL) {
        self.init(string: url.absoluteString)
    }
}