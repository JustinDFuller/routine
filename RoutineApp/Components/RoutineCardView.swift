import SwiftUI

struct RoutineCardView: View {
    let viewData: RoutineCardViewData
    let onTap: () -> Void
    let onMore: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var ringAccentColor: Color {
        if viewData.isCompletedToday || viewData.isTargetMet || viewData.isOverTarget {
            return .routineAccentComplete
        }

        return .routineAccentActive
    }

    private var primaryAccessibilityHint: String {
        if viewData.isCompletedToday {
            return "Opens routine actions."
        }

        return "Completes this routine for today."
    }

    private var backgroundColor: Color {
        viewData.isCompletedToday ? .routineSurface : .routineSurfaceElevated
    }

    private var borderColor: Color {
        viewData.isCompletedToday
            ? Color.routineDivider.opacity(0.35)
            : Color.routineDivider.opacity(0.6)
    }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 12) {
                    SegmentedProgressRingView(
                        viewData: viewData.progressRing,
                        size: 34,
                        lineWidth: 4.5,
                        accentColor: ringAccentColor,
                        accessibilityLabel: viewData.accessibilityLabel
                    )
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewData.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.routineLabelPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        metadataContent
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.leading, 14)
                .padding(.trailing, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewData.accessibilityLabel)
            .accessibilityHint(primaryAccessibilityHint)
            .accessibilityIdentifier("routine-card-primary-\(viewData.id.uuidString)")

            Button(action: onMore) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.routineLabelSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More actions for \(viewData.name)")
            .accessibilityIdentifier("routine-card-more-\(viewData.id.uuidString)")
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
        .overlay {
            if viewData.isCompletedToday {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.routineAccentComplete.opacity(0.08))
            }
        }
    }

    @ViewBuilder
    private var metadataContent: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                metadataPills
                lastDoneText
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    metadataPills
                    lastDoneText
                }
                VStack(alignment: .leading, spacing: 6) {
                    metadataPills
                    lastDoneText
                }
            }
        }
    }

    private var metadataPills: some View {
        HStack(spacing: 8) {
            metadataPill(text: viewData.countText)
            metadataPill(text: viewData.periodText)
        }
    }

    private var lastDoneText: some View {
        Text(viewData.lastDoneText)
            .font(.caption)
            .foregroundStyle(Color.routineLabelSecondary)
            .lineLimit(1)
    }

    private func metadataPill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.routineLabelPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(ringAccentColor.opacity(viewData.isCompletedToday ? 0.14 : 0.1))
            )
    }
}

#Preview("Routine Cards - Dark") {
    ComponentPreviewCanvas {
        VStack(spacing: 12) {
            RoutineCardView(viewData: ComponentPreviewFixtures.incompleteCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.completedTodayCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.targetMetCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.overTargetCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.highTargetCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.longNameCard, onTap: {}, onMore: {})
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Routine Cards - Light") {
    ComponentPreviewCanvas {
        VStack(spacing: 12) {
            RoutineCardView(viewData: ComponentPreviewFixtures.incompleteCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.completedTodayCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.longNameCard, onTap: {}, onMore: {})
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Routine Cards - Accessibility Type") {
    ComponentPreviewCanvas {
        VStack(spacing: 12) {
            RoutineCardView(viewData: ComponentPreviewFixtures.incompleteCard, onTap: {}, onMore: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.longNameCard, onTap: {}, onMore: {})
        }
    }
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Routine Cards - Reduce Motion") {
    ComponentPreviewCanvas {
        RoutineCardView(viewData: ComponentPreviewFixtures.completedTodayCard, onTap: {}, onMore: {})
    }
    .preferredColorScheme(.dark)
    .transaction { transaction in
        transaction.animation = nil
        transaction.disablesAnimations = true
    }
}
