import XCTest
@testable import WIC

final class YabaiCompatibilityTests: XCTestCase {
    func testMatchingWindowPrefersExactTitleAndClosestFrame() {
        let target = YabaiTargetWindow(
            pid: 100,
            title: "Editor",
            frame: CGRect(x: 100, y: 100, width: 900, height: 700)
        )

        let candidates = [
            YabaiWindowSnapshot(
                id: 1,
                pid: 100,
                app: "Code",
                title: "Editor",
                frame: CGRect(x: 130, y: 120, width: 900, height: 700),
                isFloating: false
            ),
            YabaiWindowSnapshot(
                id: 2,
                pid: 100,
                app: "Code",
                title: "Editor",
                frame: CGRect(x: 102, y: 101, width: 900, height: 700),
                isFloating: false
            ),
            YabaiWindowSnapshot(
                id: 3,
                pid: 100,
                app: "Code",
                title: "Terminal",
                frame: CGRect(x: 100, y: 100, width: 900, height: 700),
                isFloating: false
            )
        ]

        let match = YabaiCompatibility.matchingWindow(for: target, among: candidates)

        XCTAssertEqual(match?.id, 2)
    }

    func testWindowIDsRequiringFloatOnBspSpace() {
        let targets = [
            YabaiTargetWindow(
                pid: 100,
                title: "Editor",
                frame: CGRect(x: 0, y: 0, width: 900, height: 700)
            ),
            YabaiTargetWindow(
                pid: 101,
                title: "Finder",
                frame: CGRect(x: 920, y: 0, width: 900, height: 700)
            )
        ]

        let windows = [
            YabaiWindowSnapshot(
                id: 11,
                pid: 100,
                app: "Code",
                title: "Editor",
                frame: CGRect(x: 0, y: 0, width: 900, height: 700),
                isFloating: false
            ),
            YabaiWindowSnapshot(
                id: 12,
                pid: 101,
                app: "Finder",
                title: "Finder",
                frame: CGRect(x: 920, y: 0, width: 900, height: 700),
                isFloating: true
            )
        ]

        let ids = YabaiCompatibility.windowIDsRequiringFloat(
            for: targets,
            windows: windows,
            currentSpaceType: "bsp"
        )

        XCTAssertEqual(ids, [11])
    }

    func testWindowIDsRequiringFloatIsEmptyOnFloatSpace() {
        let targets = [
            YabaiTargetWindow(
                pid: 100,
                title: "Editor",
                frame: CGRect(x: 0, y: 0, width: 900, height: 700)
            )
        ]

        let windows = [
            YabaiWindowSnapshot(
                id: 11,
                pid: 100,
                app: "Code",
                title: "Editor",
                frame: CGRect(x: 0, y: 0, width: 900, height: 700),
                isFloating: false
            )
        ]

        let ids = YabaiCompatibility.windowIDsRequiringFloat(
            for: targets,
            windows: windows,
            currentSpaceType: "float"
        )

        XCTAssertTrue(ids.isEmpty)
    }

    func testWindowIDsRequiringFloatSkipsUnmovableWindows() {
        let targets = [
            YabaiTargetWindow(
                pid: 100,
                title: "Control Center",
                frame: CGRect(x: 100, y: 100, width: 400, height: 300)
            )
        ]

        let windows = [
            YabaiWindowSnapshot(
                id: 44,
                pid: 100,
                app: "Parallels Desktop",
                title: "Control Center",
                frame: CGRect(x: 100, y: 100, width: 400, height: 300),
                isFloating: false,
                hasAXReference: true,
                canMove: false,
                canResize: true
            )
        ]

        let ids = YabaiCompatibility.windowIDsRequiringFloat(
            for: targets,
            windows: windows,
            currentSpaceType: "bsp"
        )

        XCTAssertTrue(ids.isEmpty)
    }
}
