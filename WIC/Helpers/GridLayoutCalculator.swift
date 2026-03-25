import CoreGraphics
import Foundation

struct GridLayoutResult {
    let columns: Int
    let rows: Int
    let usableFrame: CGRect
    let frames: [CGRect]
}

enum GridLayoutCalculator {
    static let defaultBottomPadding: CGFloat = 20

    static func calculate(
        windowCount: Int,
        in frame: CGRect,
        padding: CGFloat,
        bottomPadding: CGFloat = GridLayoutCalculator.defaultBottomPadding
    ) -> GridLayoutResult {
        guard windowCount > 0, frame.width > 0, frame.height > 0 else {
            return GridLayoutResult(columns: 0, rows: 0, usableFrame: .zero, frames: [])
        }

        let usableFrame = makeUsableFrame(
            from: frame,
            padding: max(0, padding),
            bottomPadding: max(0, bottomPadding)
        )

        guard usableFrame.width > 0, usableFrame.height > 0 else {
            return GridLayoutResult(columns: 0, rows: 0, usableFrame: usableFrame, frames: [])
        }

        let dimensions = chooseDimensions(for: windowCount, in: usableFrame)
        let frames = makeFrames(
            windowCount: windowCount,
            columns: dimensions.columns,
            rows: dimensions.rows,
            in: usableFrame
        )

        return GridLayoutResult(
            columns: dimensions.columns,
            rows: dimensions.rows,
            usableFrame: usableFrame,
            frames: frames
        )
    }

    private static func chooseDimensions(for windowCount: Int, in frame: CGRect) -> (columns: Int, rows: Int) {
        let aspectRatio = Double(frame.width / max(frame.height, 1))
        let rawColumns = sqrt(Double(windowCount) * aspectRatio)
        let columns = min(windowCount, max(1, Int(rawColumns.rounded())))
        let rows = Int(ceil(Double(windowCount) / Double(columns)))
        return (columns, rows)
    }

    private static func makeUsableFrame(from frame: CGRect, padding: CGFloat, bottomPadding: CGFloat) -> CGRect {
        let minUsableWidth: CGFloat = frame.width > 0 ? 1 : 0
        let minUsableHeight: CGFloat = frame.height > 0 ? 1 : 0

        let horizontalInsetTotal = min(padding * 2, max(0, frame.width - minUsableWidth))
        let horizontalInset = horizontalInsetTotal / 2

        let desiredTopInset = padding
        let desiredBottomInset = padding + bottomPadding
        let desiredVerticalInsetTotal = desiredTopInset + desiredBottomInset
        let availableVerticalInset = max(0, frame.height - minUsableHeight)
        let verticalInsetTotal = min(desiredVerticalInsetTotal, availableVerticalInset)
        let verticalScale = desiredVerticalInsetTotal > 0 ? verticalInsetTotal / desiredVerticalInsetTotal : 0
        let topInset = desiredTopInset * verticalScale
        let bottomInset = desiredBottomInset * verticalScale

        return CGRect(
            x: frame.minX + horizontalInset,
            y: frame.minY + bottomInset,
            width: max(0, frame.width - horizontalInsetTotal),
            height: max(0, frame.height - topInset - bottomInset)
        )
    }

    private static func makeFrames(
        windowCount: Int,
        columns: Int,
        rows: Int,
        in frame: CGRect
    ) -> [CGRect] {
        let xDivisor = CGFloat(columns)
        let yDivisor = CGFloat(rows)

        return (0..<windowCount).map { index in
            let column = index % columns
            let row = index / columns

            let minX = frame.minX + (frame.width * CGFloat(column) / xDivisor)
            let maxX = frame.minX + (frame.width * CGFloat(column + 1) / xDivisor)
            let minY = frame.minY + (frame.height * CGFloat(row) / yDivisor)
            let maxY = frame.minY + (frame.height * CGFloat(row + 1) / yDivisor)

            return CGRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
        }
    }
}
