import Foundation

struct ProgressRingDrawingModel: Equatable, Sendable {
    let targetCount: Int
    let completedCount: Int
    let fillRatio: Double
    let usesSegments: Bool

    init(viewData: ProgressRingViewData) {
        let clampedTargetCount = max(viewData.targetCount, 1)

        targetCount = clampedTargetCount
        completedCount = min(max(viewData.completedCount, 0), clampedTargetCount)
        fillRatio = min(max(viewData.fillRatio, 0), 1)
        usesSegments = viewData.showsSegments && (1...8).contains(clampedTargetCount)
    }

    var segmentCount: Int {
        usesSegments ? targetCount : 0
    }
}
