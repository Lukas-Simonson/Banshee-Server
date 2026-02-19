import Foundation

extension FileManager {
    
    // Checks if a path exists and whether or not it is a directory.
    func pathExists(_ path: String) -> (exists: Bool, isDirectory: Bool) {
        var isDirectory = ObjCBool(false)
        let exists = self.fileExists(atPath: path, isDirectory: &isDirectory)
        return (exists, isDirectory.boolValue)
    }
}
