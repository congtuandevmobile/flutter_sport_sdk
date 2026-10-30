import Foundation

/// Where the challenge journal lives. `append` returns only when the lines are on the disk (the engine shows a number only after
/// that) and throws when they are not.
protocol ChallengeJournalStore: AnyObject {
    func append(sessionId: String, lines: [String]) throws
    func read(sessionId: String) throws -> [String]
    func clear(sessionId: String) throws
    /// Replaces the journal by `lines` ATOMICALLY (a temporary file is written and synced, then moved over it) after keeping the
    /// previous content next to it for diagnosis. Used to cut a damaged tail off, so that what is appended later is never hidden
    /// behind the damage. Returns the name of the kept original.
    func replaceKeepingOriginal(sessionId: String, lines: [String]) throws -> String
    /// The challenge that was running or paused when it was last seen, or nil.
    func activeSessionId() -> String?
    func setActive(_ sessionId: String?) throws
}

/// One text file per challenge in `dir`, one line per event, synced to disk on every append.
final class FileChallengeJournalStore: ChallengeJournalStore {
    private let dir: URL
    private let manager = FileManager.default

    init(dir: URL) {
        self.dir = dir
        try? manager.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func file(_ id: String) -> URL { dir.appendingPathComponent("challenge-" + Self.safe(id) + ".journal") }
    private var pointer: URL { dir.appendingPathComponent("challenge-active.txt") }

    func append(sessionId: String, lines: [String]) throws {
        guard !lines.isEmpty else { return }
        let url = file(sessionId)
        if !manager.fileExists(atPath: url.path) { manager.createFile(atPath: url.path, contents: nil) }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((lines.joined(separator: "\n") + "\n").utf8))
        try handle.synchronize()
    }

    func read(sessionId: String) throws -> [String] {
        let url = file(sessionId)
        guard manager.fileExists(atPath: url.path) else { return [] }
        return try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    func replaceKeepingOriginal(sessionId: String, lines: [String]) throws -> String {
        let current = file(sessionId)
        let kept = dir.appendingPathComponent(current.lastPathComponent + ".damaged-\(Int(Date().timeIntervalSince1970 * 1000))")
        if manager.fileExists(atPath: current.path) { try manager.copyItem(at: current, to: kept) }
        let temp = dir.appendingPathComponent(current.lastPathComponent + ".tmp")
        manager.createFile(atPath: temp.path, contents: nil)
        let handle = try FileHandle(forWritingTo: temp)
        do {
            try handle.truncate(atOffset: 0)
            try handle.write(contentsOf: Data((lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n").utf8))
            try handle.synchronize()
            try handle.close()
        } catch {
            try? handle.close()
            throw error
        }
        _ = try manager.replaceItemAt(current, withItemAt: temp)
        return kept.lastPathComponent
    }

    func clear(sessionId: String) throws {
        let url = file(sessionId)
        if manager.fileExists(atPath: url.path) { try manager.removeItem(at: url) }
        if activeSessionId() == sessionId { try setActive(nil) }
    }

    func activeSessionId() -> String? {
        guard let text = try? String(contentsOf: pointer, encoding: .utf8) else { return nil }
        let id = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    func setActive(_ sessionId: String?) throws {
        guard let id = sessionId else {
            if manager.fileExists(atPath: pointer.path) { try manager.removeItem(at: pointer) }
            return
        }
        try Data(id.utf8).write(to: pointer, options: .atomic)
    }

    /// A file name from an id: letters and digits stay, anything else is written as its hex code, so two ids never collide.
    private static func safe(_ id: String) -> String {
        var out = ""
        for scalar in id.unicodeScalars {
            if scalar.isASCII, CharacterSet.alphanumerics.contains(scalar) {
                out.unicodeScalars.append(scalar)
            } else {
                out += "_" + String(scalar.value, radix: 16) + "_"
            }
        }
        return out
    }
}
