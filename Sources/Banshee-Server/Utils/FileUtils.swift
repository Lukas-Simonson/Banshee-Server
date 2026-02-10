import Foundation

extension FileManager {
    func pathExists(_ path: String) -> (exists: Bool, isDirectory: Bool) {
        var isDirectory = ObjCBool(false)
        let exists = self.fileExists(atPath: path, isDirectory: &isDirectory)
        return (exists, isDirectory.boolValue)
    }
}
