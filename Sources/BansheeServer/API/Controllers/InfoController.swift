import Vapor

/// Sets up the info endpoints.
///
/// `GET /api/info`
struct InfoController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("info") { info in
            info.get(use: getInfo)
        }
    }
    
    private func getInfo(req: Request) -> InfoDTO {
        InfoDTO(
            name: Environment.get("SERVER_NAME") ?? "Banshee",
            service: "Banshee Server API",
            version: "0.0.1-alpha"
        )
    }
}
