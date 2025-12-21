import XMLCoder
import Vapor


extension XMLDecoder: @retroactive ContentDecoder, @unchecked Sendable {
    public func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D where D : Decodable {
        try self.decode(decodable, from: Data(buffer: body))
    }

    static func rssDecoder() -> XMLDecoder {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)

        return decoder
    }
}