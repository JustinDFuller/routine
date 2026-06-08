import XCTest

@testable import Routine

final class ProgressRingDrawingModelTests: XCTestCase {
    func testUsesSegmentsOnlyThroughTargetCountEight() {
        let segmentedModel = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 8,
                completedCount: 4,
                fillRatio: 0.5,
                showsSegments: true,
                showsTodayCheckmark: false
            )
        )
        let continuousModel = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 9,
                completedCount: 4,
                fillRatio: 0.5,
                showsSegments: true,
                showsTodayCheckmark: false
            )
        )

        XCTAssertTrue(segmentedModel.usesSegments)
        XCTAssertEqual(segmentedModel.segmentCount, 8)
        XCTAssertFalse(continuousModel.usesSegments)
        XCTAssertEqual(continuousModel.segmentCount, 0)
    }

    func testCompletedCountIsCappedAtTargetCount() {
        let drawingModel = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 5,
                completedCount: 9,
                fillRatio: 1,
                showsSegments: true,
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
                showsSegments: false,
                showsTodayCheckmark: false
            )
        )
        let aboveOne = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 5,
                completedCount: 1,
                fillRatio: 1.8,
                showsSegments: false,
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
                showsSegments: true,
                showsTodayCheckmark: false
            )
        )

        XCTAssertEqual(drawingModel.targetCount, 1)
        XCTAssertEqual(drawingModel.completedCount, 1)
        XCTAssertTrue(drawingModel.usesSegments)
        XCTAssertEqual(drawingModel.segmentCount, 1)
    }

    func testShowsSegmentsFlagCanDisableSegmentsWithinSupportedRange() {
        let drawingModel = ProgressRingDrawingModel(
            viewData: ProgressRingViewData(
                targetCount: 4,
                completedCount: 2,
                fillRatio: 0.5,
                showsSegments: false,
                showsTodayCheckmark: false
            )
        )

        XCTAssertFalse(drawingModel.usesSegments)
        XCTAssertEqual(drawingModel.segmentCount, 0)
    }
}
