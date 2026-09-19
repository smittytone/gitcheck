import Foundation


extension URL {

    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) && isDir.boolValue
    }
}
