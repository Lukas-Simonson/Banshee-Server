import Vapor

extension RSS {
    struct ImageDTO: Content {
        let url: URL

        // Allows decoding both <image> & <itunes:image> for better support.
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let url = try container.decodeIfPresent(URL.self, forKey: CodingKeys.url)
            let href = try container.decodeIfPresent(URL.self, forKey: CodingKeys.href)

            if let url { self.url = url }
            else if let href { self.url = href }
            else { throw DecodingError.valueNotFound(URL.self, DecodingError.Context(codingPath: [CodingKeys.url, CodingKeys.href], debugDescription: "missing url or href")) }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(url, forKey: CodingKeys.url)
        }

        enum CodingKeys: String, CodingKey {
            case url
            case href
        }
    }   
}