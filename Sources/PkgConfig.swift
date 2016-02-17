import Foundation

public struct PkgConfigResource {
    let package: String
    let version: String
}

public enum PkgConfigError: ErrorType {
    case ServiceNotAvailable
    case ParsingCommandOutput
    case CommandExecutionFailed
}

public struct PkgConfigPackage {
    let name: String
    let description: String

    var provides: [PkgConfigResource] {
        print("FIXME: Implement")
        return []
    }
    var requires: [PkgConfigResource] {
        print("FIXME: Implement")
        return []
    }
    var cflags: String {
        print("FIXME: Implement")
        return ""
    }
    var lflags: String {
        print("FIXME: Implement")
        return ""
    }
}

// Note: On ubuntu linux, pkg-config returns a 0 exit status to signal success.
//       That might not be the case in every environment.
public class PkgConfig {
    private static let sharedInstance = PkgConfig()
    private lazy var executablePath: String? = {
        let fileManager = NSFileManager.defaultManager()

        // Just to get started, for Ubuntu
        let path = "/usr/bin/pkg-config"

        return fileManager.isExecutableFileAtPath(path) ?
            path : nil
    }()

    private init() {}

    private func pathIsExecutable(path: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.isExecutableFileAtPath(path)
    }

    public var isAvailable: Bool {
        return executablePath != nil
    }

    public static func defaultPkgConfig() -> PkgConfig {
        return PkgConfig.sharedInstance
    }

    // We could also do a callback-based version of this api, but these calls
    // are supposed to be very short-term executions. It might be convenient
    // in the future, though.
    public func packageExists(package:String) throws -> Bool {
        guard let executable = executablePath else {
            throw PkgConfigError.ServiceNotAvailable
        }

        let arguments = ["--exists", package]
        let task = NSTask()
        task.launchPath = executable
        task.arguments  = arguments

        task.launch()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            return true
        }

        // leave room to do other things, like report why it failed

        return false
    }

    public func package(package: String) throws -> PkgConfigPackage? {
        // FIXME: Implement
        return nil
    }

    subscript(index: String) -> PkgConfigPackage? {
        do {
            return try self.package(index)
        }
        catch _ {}
        return nil
    }

    public func availablePackages() throws -> [PkgConfigPackage] {
        guard let executable = executablePath else {
            throw PkgConfigError.ServiceNotAvailable
        }

        let arguments = ["--list-all"]
        let task = NSTask()
        task.launchPath = executable
        task.arguments  = arguments

        let stdout = NSPipe()
        task.standardOutput = stdout
        task.launch()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = stdout.fileHandleForReading.readDataToEndOfFile()
            // FIXME: Assumes UTF-8 encoding of the output
            guard let string = String(data: data, encoding: NSUTF8StringEncoding) else {
                throw PkgConfigError.ParsingCommandOutput
            }

            return string.characters.lazy
                         .split("\n", allowEmptySlices: false)
                         .map(String.init(_:))
                         .map {
                             (line:String) -> PkgConfigPackage in
                             let parts = line.characters.lazy
                                             .split(" ", allowEmptySlices: false)
                                             .map(String.init(_:))
                             var name: String?
                             var description: String?
                             if parts.count >= 2 {
                                 description = parts.dropFirst().joinWithSeparator(" ")
                             }
                             if parts.count >= 1 {
                                 name = parts[0]
                             }

                             return PkgConfigPackage(
                                 name: name ?? "",
                                 description: description ?? ""
                             )
                         }
        }

        throw PkgConfigError.CommandExecutionFailed
    }

}

