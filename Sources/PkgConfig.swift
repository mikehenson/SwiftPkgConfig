import Foundation

public struct PkgConfigResource {
    let package: String
    let version: String
}

public struct PkgConfigPackage {
    let name: String
    let description: String
    let provides: [PkgConfigResource]
    //let requires: [PkgConfigResource]
    //let cflags: String
    //let lflags: String
}

// Note: On ubuntu linux, pkg-config returns a 0 exit status to signal success.
//       That might not be the case in every environment.
public class PkgConfig {
    private static let sharedInstance = PkgConfig()
    private let executablePath: String?

    private init() {
        let fileManager = NSFileManager.defaultManager()

        // Just to get started, for Ubuntu
        let path = "/usr/bin/pkg-config"

        if fileManager.isExecutableFileAtPath(path) {
            executablePath = path
	}
    }

    private pathIsExecutable(path: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.isExecutableFileAtPath(path)
    }

    public var isAvailable: Bool {
        return executablePath != nil
    }

    public static defaultPkgConfig() -> PkgConfig {
        return PkgConfig.sharedInstance
    }

    // We could also do a callback-based version of this api, but these calls
    // are supposed to be very short-term executions. It might be convenient
    // in the future, though.
    public packageExists(package:String) -> Bool throws {
        guard let executable = executablePath else {
            throw // FIXME: Some type that means "not available"
	}

        let arguments = ["--exists", package]
        let task = NSTask(executable, arguments: arguments)

        task.launch()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            return true
        }

        // leave room to do other things, like report why it failed

        return false
    }

    public package(package: String) -> PkgConfigPackage? throws {
    }

    subscript(index: String) -> PkgConfigPackage? throws {
        return self.package(index)
    }

    public availablePackages() -> [PkgConfigPackage] throws {
        guard let executable = executablePath else {
            throw // FIXME: Some type that means "not available"
        }

        let arguments = ["--list-all"]
        let task = NSTask(executable, arguments: arguments)

        let stdout = NSPipe()
        task.standardOutput = stdout
        task.launch()
        task.waitUntilExit()

        func lineToTuple(line: String) -> (tag: String, description: String) {
            let parts = line.characters.lazy
                            .split(" ", allowEmptySubsequences: false)
                            .map(String.init)

            // FIXME: It would be better if we didn't have to undo work. We should:
            //        1) strip any prefixing spaces
            //        2) take everything up to the first space
            //        3) strip spaces
            //        4) take everything to the EOL
            switch parts.count {
                case 0:
                    return (tag:"", description: "")
                case 1:
                    return (tag:parts[0], description: "")
                default:
                    return (tag:parts[0], description: parts.dropFirst().joinWithSeparator(" "))
        }

        if task.terminationStatus == 0 {
            let data = stdout.fileHandleForReading.readDataToEndOfFile()
            // FIXME: Assumes UTF-8 encoding of the output
            let string = String(data: data, encoding: NSUTF8StringEncoding)
            return string.characters.lazy
                         .split("\n", allowEmptySubsequences: false)
                         .map(String.init)
                         .map(lineToTuple)
        }

        // Figure out what to throw

        throw // that thing
    }

}

