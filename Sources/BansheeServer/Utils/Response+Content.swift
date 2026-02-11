import Vapor

extension Response {
    convenience init(status: HTTPStatus, content: some Content, encoder: any ContentEncoder) throws {
        var buffer = ByteBuffer()
        var headers = HTTPHeaders()
        try encoder.encode(content, to: &buffer, headers: &headers)

        self.init(
            status: status,
            version: .init(major: 1, minor: 1),
            headersNoUpdate: headers,
            body: Body(buffer: buffer)
        )
    }
}
