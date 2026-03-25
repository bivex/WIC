import XCTest
@testable import WIC

final class GridLayoutCalculatorTests: XCTestCase {
    func testZeroWindowsReturnsEmptyLayout() {
        let layout = GridLayoutCalculator.calculate(
            windowCount: 0,
            in: CGRect(x: 0, y: 0, width: 2560, height: 1415),
            padding: 10
        )

        XCTAssertEqual(layout.columns, 0)
        XCTAssertEqual(layout.rows, 0)
        XCTAssertTrue(layout.frames.isEmpty)
    }

    func testLandscapeTwoWindowsUseSingleRow() {
        let layout = GridLayoutCalculator.calculate(
            windowCount: 2,
            in: CGRect(x: 0, y: 25, width: 2560, height: 1415),
            padding: 10
        )

        XCTAssertEqual(layout.columns, 2)
        XCTAssertEqual(layout.rows, 1)
        XCTAssertEqual(layout.frames.count, 2)
        XCTAssertEqual(layout.frames[0].minY, layout.frames[1].minY, accuracy: 0.001)
        XCTAssertEqual(layout.frames[0].maxY, layout.frames[1].maxY, accuracy: 0.001)
    }

    func testPortraitTwoWindowsUseSingleColumn() {
        let layout = GridLayoutCalculator.calculate(
            windowCount: 2,
            in: CGRect(x: 6000, y: 0, width: 1440, height: 2560),
            padding: 10
        )

        XCTAssertEqual(layout.columns, 1)
        XCTAssertEqual(layout.rows, 2)
        XCTAssertEqual(layout.frames.count, 2)
        XCTAssertEqual(layout.frames[0].minX, layout.frames[1].minX, accuracy: 0.001)
        XCTAssertEqual(layout.frames[0].maxX, layout.frames[1].maxX, accuracy: 0.001)
    }

    func testPortraitSixWindowsPreferTallerGrid() {
        let layout = GridLayoutCalculator.calculate(
            windowCount: 6,
            in: CGRect(x: 6000, y: 0, width: 1440, height: 2560),
            padding: 10
        )

        XCTAssertEqual(layout.columns, 2)
        XCTAssertEqual(layout.rows, 3)
        XCTAssertEqual(layout.frames.count, 6)
    }

    func testGridRespectsConfiguredPaddingAndBottomInset() {
        let frame = CGRect(x: 0, y: 25, width: 2560, height: 1415)
        let layout = GridLayoutCalculator.calculate(windowCount: 4, in: frame, padding: 10)

        XCTAssertEqual(layout.usableFrame.minX, frame.minX + 10, accuracy: 0.001)
        XCTAssertEqual(
            layout.usableFrame.minY,
            frame.minY + 10 + GridLayoutCalculator.defaultBottomPadding,
            accuracy: 0.001
        )
        XCTAssertEqual(layout.usableFrame.maxX, frame.maxX - 10, accuracy: 0.001)
        XCTAssertEqual(layout.usableFrame.maxY, frame.maxY - 10, accuracy: 0.001)
    }

    func testGridFramesStayInsideOriginalFrameWithoutOverlap() {
        let frame = CGRect(x: 2560, y: 0, width: 3440, height: 1440)
        let layout = GridLayoutCalculator.calculate(windowCount: 8, in: frame, padding: 12)

        XCTAssertEqual(layout.frames.count, 8)

        for rect in layout.frames {
            XCTAssertTrue(frame.contains(rect), "Grid frame \(rect) escaped screen bounds \(frame)")
            XCTAssertGreaterThan(rect.width, 0)
            XCTAssertGreaterThan(rect.height, 0)
        }

        for leftIndex in 0..<layout.frames.count {
            for rightIndex in leftIndex + 1..<layout.frames.count {
                let overlap = layout.frames[leftIndex].intersection(layout.frames[rightIndex])
                XCTAssertTrue(
                    overlap.isEmpty || overlap.width < 0.001 || overlap.height < 0.001,
                    "Frames \(leftIndex) and \(rightIndex) overlap: \(overlap)"
                )
            }
        }
    }

    func testTinyFramesScaleInsetsInsteadOfProducingNegativeSizes() {
        let tinyFrame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let layout = GridLayoutCalculator.calculate(windowCount: 2, in: tinyFrame, padding: 20)

        XCTAssertEqual(layout.frames.count, 2)
        XCTAssertGreaterThan(layout.usableFrame.width, 0)
        XCTAssertGreaterThan(layout.usableFrame.height, 0)

        for rect in layout.frames {
            XCTAssertTrue(tinyFrame.contains(rect), "Tiny-screen frame \(rect) escaped \(tinyFrame)")
            XCTAssertGreaterThan(rect.width, 0)
            XCTAssertGreaterThan(rect.height, 0)
        }
    }
}
