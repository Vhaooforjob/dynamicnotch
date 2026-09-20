import AppKit
import XCTest
@testable import DynamicNotch

final class NotchFrameCalculatorTests: XCTestCase {
    func testResizePreservesTopCenterAnchor() {
        let compactFrame = NSRect(x: 610, y: 957, width: 280, height: 43)

        let expandedFrame = NotchFrameCalculator.frame(
            contentSize: NSSize(width: 720, height: 238),
            screenFrame: NSRect(x: 0, y: 0, width: 1500, height: 1000),
            anchorFrame: compactFrame
        )

        XCTAssertEqual(expandedFrame.midX, compactFrame.midX)
        XCTAssertEqual(expandedFrame.maxY, compactFrame.maxY)
        XCTAssertEqual(expandedFrame.width, 720)
        XCTAssertEqual(expandedFrame.height, 238)
    }

    func testInitialFrameUsesScreenTopCenter() {
        let screenFrame = NSRect(x: 100, y: 50, width: 1200, height: 800)

        let frame = NotchFrameCalculator.frame(
            contentSize: NSSize(width: 280, height: 43),
            screenFrame: screenFrame,
            anchorFrame: nil
        )

        XCTAssertEqual(frame.midX, screenFrame.midX)
        XCTAssertEqual(frame.maxY, screenFrame.maxY)
    }
}
