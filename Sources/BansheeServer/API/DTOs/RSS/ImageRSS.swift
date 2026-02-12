import Vapor

struct ImageRSS: Content {
    let url: URI
    
    // Allows decoding from both <image> & <itunes:image> for better support.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let url = try container.decodeIfPresent(URI.self, forKey: CodingKeys.url)
        let href = try container.decodeIfPresent(URI.self, forKey: CodingKeys.href)

        if let url { self.url = url }
        else if let href { self.url = href }
        else {
            throw DecodingError.valueNotFound(
                URL.self,
                DecodingError.Context(
                    codingPath: [CodingKeys.url, CodingKeys.href],
                    debugDescription: "missing url or href"
                )
            )
        }
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
