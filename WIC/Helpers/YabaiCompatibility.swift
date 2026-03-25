import AppKit
import Foundation

struct YabaiTargetWindow {
    let pid: pid_t
    let title: String
    let frame: CGRect
}

struct YabaiWindowSnapshot: Decodable {
    let id: Int
    let pid: pid_t
    let app: String
    let title: String
    let frame: CGRect
    let isFloating: Bool
    let isVisible: Bool
    let hasAXReference: Bool
    let canMove: Bool
    let canResize: Bool

    init(
        id: Int,
        pid: pid_t,
        app: String,
        title: String,
        frame: CGRect,
        isFloating: Bool,
        isVisible: Bool = true,
        hasAXReference: Bool = true,
        canMove: Bool = true,
        canResize: Bool = true
    ) {
        self.id = id
        self.pid = pid
        self.app = app
        self.title = title
        self.frame = frame
        self.isFloating = isFloating
        self.isVisible = isVisible
        self.hasAXReference = hasAXReference
        self.canMove = canMove
        self.canResize = canResize
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case pid
        case app
        case title
        case frame
        case isFloating = "is-floating"
        case isVisible = "is-visible"
        case hasAXReference = "has-ax-reference"
        case canMove = "can-move"
        case canResize = "can-resize"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawFrame = try container.decode(YabaiFrameSnapshot.self, forKey: .frame)

        id = try container.decode(Int.self, forKey: .id)
        pid = try container.decode(pid_t.self, forKey: .pid)
        app = try container.decode(String.self, forKey: .app)
        title = try container.decode(String.self, forKey: .title)
        frame = rawFrame.cgRect
        isFloating = try container.decode(Bool.self, forKey: .isFloating)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        hasAXReference = try container.decode(Bool.self, forKey: .hasAXReference)
        canMove = try container.decode(Bool.self, forKey: .canMove)
        canResize = try container.decode(Bool.self, forKey: .canResize)
    }
}

private struct YabaiFrameSnapshot: Decodable {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }
}

private struct YabaiSpaceSnapshot: Decodable {
    let type: String
}

private struct YabaiSnapshot {
    let currentSpaceType: String
    let windows: [YabaiWindowSnapshot]
}

enum YabaiCompatibility {
    private struct PreparedWindow {
        let element: AXUIElement
        let target: YabaiTargetWindow?
        let matchedWindow: YabaiWindowSnapshot?
    }

    private static let shellPath = "/usr/bin/env"
    private static let defaultPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    static func prepareWindowForManualFrameChange(_ window: AXUIElement) -> Bool {
        !prepareWindowsForManualLayout([window]).isEmpty
    }

    static func prepareWindowsForManualLayout(_ windows: [AXUIElement]) -> [AXUIElement] {
        guard !windows.isEmpty else { return [] }
        guard let snapshot = captureSnapshot() else { return windows }

        let preparedWindows = windows.map { element -> PreparedWindow in
            let target = makeTargetWindow(from: element)
            let matchedWindow = target.flatMap { matchingWindow(for: $0, among: snapshot.windows) }
            return PreparedWindow(element: element, target: target, matchedWindow: matchedWindow)
        }

        let floatWindowIDs = windowIDsRequiringFloat(
            for: preparedWindows.compactMap(\.target),
            windows: snapshot.windows,
            currentSpaceType: snapshot.currentSpaceType
        )

        guard !floatWindowIDs.isEmpty else { return windows }

        Logger.shared.info(
            "yabai detected on \(snapshot.currentSpaceType) space - floating \(floatWindowIDs.count) window(s) for manual WIC layout"
        )

        let floatedWindowIDs = Set(floatWindowIDs.filter { toggleFloat(windowID: $0) })

        if floatedWindowIDs.count != floatWindowIDs.count {
            Logger.shared.warning(
                "Could only float \(floatedWindowIDs.count) of \(floatWindowIDs.count) yabai-managed window(s); unsupported ones will be skipped"
            )
        }

        return preparedWindows.compactMap { prepared in
            guard let matchedWindow = prepared.matchedWindow else {
                return prepared.element
            }

            if !requiresFloat(
                matchedWindow,
                currentSpaceType: snapshot.currentSpaceType
            ) {
                return prepared.element
            }

            return floatedWindowIDs.contains(matchedWindow.id) ? prepared.element : nil
        }
    }

    static func matchingWindow(
        for target: YabaiTargetWindow,
        among windows: [YabaiWindowSnapshot]
    ) -> YabaiWindowSnapshot? {
        let pidMatches = windows.filter { $0.pid == target.pid }
        guard !pidMatches.isEmpty else { return nil }

        let normalizedTargetTitle = normalizeTitle(target.title)
        let exactTitleMatches = pidMatches.filter { normalizeTitle($0.title) == normalizedTargetTitle }
        let candidatePool = exactTitleMatches.isEmpty ? pidMatches : exactTitleMatches

        return candidatePool.min { left, right in
            matchScore(for: left, against: target) < matchScore(for: right, against: target)
        }
    }

    static func windowIDsRequiringFloat(
        for targets: [YabaiTargetWindow],
        windows: [YabaiWindowSnapshot],
        currentSpaceType: String
    ) -> [Int] {
        guard normalizeSpaceType(currentSpaceType) != "float" else { return [] }

        var ids: [Int] = []
        var seen = Set<Int>()

        for target in targets {
            guard let matchedWindow = matchingWindow(for: target, among: windows) else { continue }
            guard requiresFloat(matchedWindow, currentSpaceType: currentSpaceType) else { continue }
            guard seen.insert(matchedWindow.id).inserted else { continue }
            ids.append(matchedWindow.id)
        }

        return ids
    }

    private static func requiresFloat(_ window: YabaiWindowSnapshot, currentSpaceType: String) -> Bool {
        guard normalizeSpaceType(currentSpaceType) != "float" else { return false }
        guard window.hasAXReference, window.canMove, window.canResize else { return false }
        return !window.isFloating
    }

    private static func makeTargetWindow(from window: AXUIElement) -> YabaiTargetWindow? {
        var pid: pid_t = 0
        AXUIElementGetPid(window, &pid)

        guard pid != 0, let info = AccessibilityHelper.getWindowInfo(window) else {
            return nil
        }

        return YabaiTargetWindow(
            pid: pid,
            title: info.title,
            frame: info.frame
        )
    }

    private static func matchScore(for candidate: YabaiWindowSnapshot, against target: YabaiTargetWindow) -> CGFloat {
        let titlePenalty: CGFloat = normalizeTitle(candidate.title) == normalizeTitle(target.title) ? 0 : 10_000
        let visibilityPenalty: CGFloat = candidate.isVisible ? 0 : 100_000
        let frame = candidate.frame
        let frameDelta =
            abs(frame.minX - target.frame.minX) +
            abs(frame.minY - target.frame.minY) +
            abs(frame.width - target.frame.width) +
            abs(frame.height - target.frame.height)

        return titlePenalty + visibilityPenalty + frameDelta
    }

    private static func normalizeTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{200E}", with: "")
            .replacingOccurrences(of: "\u{200F}", with: "")
    }

    private static func normalizeSpaceType(_ type: String) -> String {
        type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func captureSnapshot() -> YabaiSnapshot? {
        guard let windowsJSON = runYabaiCommand(["-m", "query", "--windows"]),
              let windowsData = windowsJSON.data(using: .utf8),
              let windows = try? JSONDecoder().decode([YabaiWindowSnapshot].self, from: windowsData) else {
            return nil
        }

        let currentSpaceType: String
        if let spaceJSON = runYabaiCommand(["-m", "query", "--spaces", "--space"]),
           let spaceData = spaceJSON.data(using: .utf8),
           let space = try? JSONDecoder().decode(YabaiSpaceSnapshot.self, from: spaceData) {
            currentSpaceType = space.type
        } else {
            currentSpaceType = "unknown"
        }

        return YabaiSnapshot(currentSpaceType: currentSpaceType, windows: windows)
    }

    @discardableResult
    private static func toggleFloat(windowID: Int) -> Bool {
        guard runYabaiCommand(["-m", "window", String(windowID), "--toggle", "float"]) != nil else {
            Logger.shared.warning("Failed to float yabai window \(windowID)")
            return false
        }

        return true
    }

    private static func runYabaiCommand(_ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: shellPath)
        process.arguments = ["yabai"] + arguments
        process.environment = ["PATH": defaultPath]

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
            if let errorText = String(data: errorData, encoding: .utf8), !errorText.isEmpty {
                Logger.shared.debug("yabai command failed: \(errorText.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
            return nil
        }

        let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
        return String(data: outputData, encoding: .utf8)
    }
}
