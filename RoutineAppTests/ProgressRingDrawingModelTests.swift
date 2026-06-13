import XCTest

@testable import Routine

final class ProgressRingDrawingModelTests: XCTestCase {
    func testCompletedCountIsCappedAtTargetCount() {
        let drawingModel = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 5,
                completedCount: 9,
                fillRatio: 1,
                showsTodayCheckmark: true
            )
        )

        XCTAssertEqual(drawingModel.completedCount, 5)
    }

    func testFillRatioIsClampedIntoUnitInterval() {
        let belowZero = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 5,
                completedCount: 1,
                fillRatio: -0.25,
                showsTodayCheckmark: false
            )
        )
        let aboveOne = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 5,
                completedCount: 1,
                fillRatio: 1.8,
                showsTodayCheckmark: false
            )
        )

        XCTAssertEqual(belowZero.fillRatio, 0)
        XCTAssertEqual(aboveOne.fillRatio, 1)
    }

    func testTargetCountHasMinimumOfOne() {
        let drawingModel = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 0,
                completedCount: 3,
                fillRatio: 0.5,
                showsTodayCheckmark: false
            )
        )

        XCTAssertEqual(drawingModel.targetCount, 1)
        XCTAssertEqual(drawingModel.completedCount, 1)
    }

    func testOverTargetVisualFillRemainsCappedAtFull() {
        let drawingModel = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 4,
                completedCount: 9,
                fillRatio: 1.8,
                showsTodayCheckmark: false
            )
        )

        XCTAssertEqual(drawingModel.completedCount, 4)
        XCTAssertEqual(drawingModel.fillRatio, 1)
    }
}
