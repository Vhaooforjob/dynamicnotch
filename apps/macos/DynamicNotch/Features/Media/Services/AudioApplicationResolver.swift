import AppKit
import Darwin

struct AudioApplicationIdentity: Equatable {
    let bundleID: String?
    let displayName: String
}

enum AudioApplicationResolver {
    static func resolve(pid: pid_t, fallbackBundleID: String?) -> AudioApplicationIdentity {
        var candidatePID = pid
        var visited = Set<pid_t>()

        for _ in 0..<8 where candidatePID > 1 && visited.insert(candidatePID).inserted {
            if let bundleURL = applicationBundleURL(for: candidatePID),
               let identity = identity(for: bundleURL) {
                return identity
            }

            if let application = NSRunningApplication(processIdentifier: candidatePID),
               application.activationPolicy == .regular,
               let displayName = application.localizedName {
                return AudioApplicationIdentity(
                    bundleID: application.bundleIdentifier ?? fallbackBundleID,
                    displayName: displayName
                )
            }

            guard let parentPID = parentPID(of: candidatePID), parentPID != candidatePID else {
                break
            }
            candidatePID = parentPID
        }

        let application = NSRunningApplication(processIdentifier: pid)
        let bundleID = application?.bundleIdentifier ?? fallbackBundleID
        let displayName = application?.localizedName
            ?? bundleID?.split(separator: ".").last.map(String.init)
            ?? "Process \(pid)"
        return AudioApplicationIdentity(bundleID: bundleID, displayName: displayName)
    }

    static func applicationBundleURL(inExecutablePath path: String) -> URL? {
        var currentPath = ""
        for component in URL(fileURLWithPath: path).pathComponents {
            if component == "/" {
                currentPath = "/"
            } else {
                currentPath = (currentPath as NSString).appendingPathComponent(component)
            }

            if component.hasSuffix(".app") {
                return URL(fileURLWithPath: currentPath, isDirectory: true)
            }
        }
        return nil
    }

    private static func applicationBundleURL(for pid: pid_t) -> URL? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        let bytes = buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }
        return applicationBundleURL(inExecutablePath: String(decoding: bytes, as: UTF8.self))
    }

    private static func identity(for bundleURL: URL) -> AudioApplicationIdentity? {
        guard let bundle = Bundle(url: bundleURL) else { return nil }
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? bundleURL.deletingPathExtension().lastPathComponent
        return AudioApplicationIdentity(bundleID: bundle.bundleIdentifier, displayName: name)
    }

    private static func parentPID(of pid: pid_t) -> pid_t? {
        var info = proc_bsdinfo()
        let expectedSize = MemoryLayout<proc_bsdinfo>.size
        let bytesRead = proc_pidinfo(
            pid,
            PROC_PIDTBSDINFO,
            0,
            &info,
            Int32(expectedSize)
        )
        guard bytesRead == expectedSize else { return nil }
        return pid_t(info.pbi_ppid)
    }
}
