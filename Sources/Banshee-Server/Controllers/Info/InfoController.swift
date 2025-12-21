import Vapor

struct InfoController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("info") { info in
            info.get(use: getInfo)
        }
    }

    private func getInfo(req: Request) -> Info {
        Info(
            name: "Banshee-Server", 
            version: "1.0.0"
        )
    }
}

extension InfoController {
    struct Info: Content {
        let name: String
        let version: String
    }
}