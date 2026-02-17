import Vapor

/// Sets up Episode Progress endpoints.
///
/// `GET /api/episodes/:episodeID/progress`: Retrieves the progress of the authenticated user for an episode based on the episodes id.
/// `PUT /api/episodes/:episodeID/progress`: Updates the progress for the authenticated user of an episode based on the episodes id.
/// `DELETE /api/episodes/:episodeID/progress`: Deletes the progress for the authenticated user of an episode based on the episodes id.
struct EpisodeProgressController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("progress") { progress in
            progress.get(use: getProgress)
            progress.put(use: updateProgress)
            progress.delete(use: deleteProgress)
        }
    }
    
    private func getProgress(_ req: Request) async throws -> EpisodeProgressDTO {
        let id = try req.parameters.require("episodeID", as: UUID.self)
        
        guard let auth = req.auth.get(UserToken.self),
              let userID = auth.userID
        else { throw AuthError.invalidAuth }
        
        return try await req.episodeProgressDAO
            .read(fromEpisodeWithID: id, fromUserWithID: userID)
            .unwrap(or: DBError.noItemFound("EpisodeProgress", with: "Episode: \(id) & User: \(userID)"))
            .toDTO()
    }
    
    private func updateProgress(_ req: Request) async throws -> Response {
        let id = try req.parameters.require("episodeID", as: UUID.self)
        
        try UpdateProgressRequest.validate(content: req)
        let progressRequest = try req.content.decode(UpdateProgressRequest.self)
        
        guard let auth = req.auth.get(UserToken.self),
              let userID = auth.userID
        else { throw AuthError.invalidAuth }
        
        var progress = try await req.episodeProgressDAO.read(fromEpisodeWithID: id, fromUserWithID: userID)
        
        if let progress {
            progress.isCompleted = progressRequest.isCompleted
            progress.watchTime = progressRequest.watchTime
            progress.lastUpdated = .now
        } else {
            progress = EpisodeProgress(
                isCompleted: progressRequest.isCompleted,
                watchTime: progressRequest.watchTime,
                startedOn: .now,
                lastUpdated: .now
            )
        }
        
        try await req.episodeProgressDAO.update(progress!, forEpisodeWithID: id, forUserWithID: userID)
        
        return try await progress!
            .toDTO()
            .encodeResponse(status: .accepted, for: req)
    }
    
    private func deleteProgress(_ req: Request) async throws -> Response {
        let id = try req.parameters.require("episodeID", as: UUID.self)
        
        guard let auth = req.auth.get(UserToken.self),
              let userID = auth.userID
        else { throw AuthError.invalidAuth }
        
        try await req.episodeProgressDAO.deleteWhere(episodeID: id, userID: userID)
        
        return Response(status: .accepted)
    }
}

extension EpisodeProgressController {
    struct UpdateProgressRequest: Content, Validatable {
        let isCompleted: Bool
        let watchTime: Int
        
        static func validations(_ validations: inout Validations) {
            validations.add("isCompleted", as: Bool.self)
            validations.add("watchTime", as: Int.self)
        }
    }
}
