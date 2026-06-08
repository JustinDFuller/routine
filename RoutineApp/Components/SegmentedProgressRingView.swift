import SwiftUI

struct SegmentedProgressRingView: View {
    let viewData: ProgressRingViewData
    let size: CGFloat
    let lineWidth: CGFloat
    let accentColor: Color
    let accessibilityLabel: String

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.routineRuntimeConfiguration) private var runtime

    private var drawingModel: ProgressRingDrawingModel {
        ProgressRingDrawingModel(viewData: viewData)
    }

    private var animation: Animation? {
        animationsAreDisabled ? nil : .easeInOut(duration: 0.16)
    }

    private var trackColor: Color {
        Color.routineDivider.opacity(0.5)
    }

    private var checkmarkTransition: AnyTransition {
        animationsAreDisabled ? .identity : .opacity.combined(with: .scale(scale: 0.92))
    }

    private var animationsAreDisabled: Bool {
        accessibilityReduceMotion || runtime.disablesAnimations
    }

    var body: some View {
        ZStack {
            if drawingModel.usesSegments {
                segmentedRing
            } else {
                continuousRing
            }

            if viewData.showsTodayCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.routineLabelPrimary)
                    .transition(checkmarkTransition)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .animation(animation, value: drawingModel)
        .animation(animation, value: viewData.showsTodayCheckmark)
    }

    private var segmentedRing: some View {
        ZStack {
            ForEach(0..<drawingModel.segmentCount, id: \.self) { index in
                segmentStroke(index: index, color: trackColor)
            }

            ForEach(0..<drawingModel.completedCount, id: \.self) { index in
                segmentStroke(index: index, color: accentColor)
            }
        }
        .rotationEffect(.degrees(-90))
    }

    private var continuousRing: some View {
        ZStack {
            Circle()
                .stroke(trackColor, style: strokeStyle)

            Circle()
                .trim(from: 0, to: drawingModel.fillRatio)
                .stroke(accentColor, style: strokeStyle)
                .rotationEffect(.degrees(-90))
        }
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    private func segmentStroke(index: Int, color: Color) -> some View {
        let segmentGap = segmentGapFraction
        let segmentSize = 1 / Double(drawingModel.segmentCount)
        let start = Double(index) * segmentSize + segmentGap / 2
        let end = (Double(index + 1) * segmentSize) - segmentGap / 2

        return Circle()
            .trim(from: start, to: drawingModel.segmentCount == 1 ? 1 : max(end, start))
            .stroke(color, style: strokeStyle)
    }

    private var segmentGapFraction: Double {
        guard drawingModel.segmentCount > 1 else {
            return 0
        }

        let circumference = max(.pi * size, 1)
        let gapLength = min(max(lineWidth * 0.75, 1.5), circumference * 0.035)
        return gapLength / circumference
    }
}

#Preview("Progress Rings - Dark") {
    ComponentPreviewCanvas {
        HStack(spacing: 20) {
            SegmentedProgressRingView(
                viewData: ComponentPreviewFixtures.incompleteCard.progressRing,
                size: 34,
                lineWidth: 4.5,
                accentColor: .routineAccentActive,
                accessibilityLabel: ComponentPreviewFixtures.incompleteCard.accessibilityLabel
            )
            SegmentedProgressRingView(
                viewData: ComponentPreviewFixtures.completedTodayCard.progressRing,
                size: 34,
                lineWidth: 4.5,
                accentColor: .routineAccentComplete,
                accessibilityLabel: ComponentPreviewFixtures.completedTodayCard.accessibilityLabel
            )
            SegmentedProgressRingView(
                viewData: ComponentPreviewFixtures.targetMetCard.progressRing,
                size: 34,
                lineWidth: 4.5,
                accentColor: .routineAccentComplete,
                accessibilityLabel: ComponentPreviewFixtures.targetMetCard.accessibilityLabel
            )
            SegmentedProgressRingView(
                viewData: ComponentPreviewFixtures.highTargetCard.progressRing,
                size: 34,
                lineWidth: 4.5,
                accentColor: .routineAccentComplete,
                accessibilityLabel: ComponentPreviewFixtures.highTargetCard.accessibilityLabel
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Progress Rings - Light") {
    ComponentPreviewCanvas {
        HStack(spacing: 20) {
            SegmentedProgressRingView(
                viewData: ComponentPreviewFixtures.incompleteCard.progressRing,
                size: 34,
                lineWidth: 4.5,
                accentColor: .routineAccentActive,
                accessibilityLabel: ComponentPreviewFixtures.incompleteCard.accessibilityLabel
            )
            SegmentedProgressRingView(
                viewData: ComponentPreviewFixtures.completedTodayCard.progressRing,
                size: 34,
                lineWidth: 4.5,
                accentColor: .routineAccentComplete,
                accessibilityLabel: ComponentPreviewFixtures.completedTodayCard.accessibilityLabel
            )
            SegmentedProgressRingView(
                viewData: ComponentPreviewFixtures.highTargetCard.progressRing,
                size: 34,
                lineWidth: 4.5,
                accentColor: .routineAccentComplete,
                accessibilityLabel: ComponentPreviewFixtures.highTargetCard.accessibilityLabel
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Progress Rings - Reduce Motion") {
    ComponentPreviewCanvas {
        SegmentedProgressRingView(
            viewData: ComponentPreviewFixtures.completedTodayCard.progressRing,
            size: 40,
            lineWidth: 5,
            accentColor: .routineAccentComplete,
            accessibilityLabel: ComponentPreviewFixtures.completedTodayCard.accessibilityLabel
        )
    }
    .preferredColorScheme(.dark)
    .transaction { transaction in
        transaction.animation = nil
        transaction.disablesAnimations = true
    }
}
