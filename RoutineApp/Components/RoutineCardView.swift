import SwiftUI

struct RoutineCardView: View {
    let viewData: RoutineCardViewData
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    let onHistory: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isUnavailable: Bool {
        viewData.isCompletedToday == false && viewData.isAvailableNow == false
    }

    private var ringAccentColor: Color {
        if isUnavailable {
            return .routineLabelSecondary
        }

        if viewData.isCompletedToday || viewData.isTargetMet || viewData.isOverTarget {
            return .routineAccentComplete
        }

        return .routineAccentActive
    }

    private var primaryAccessibilityHint: String {
        if isUnavailable {
            return "Completion is unavailable outside the configured time."
        }

        if viewData.isCompletedToday {
            return "Opens completion history."
        }

        return "Completes this routine for today."
    }

    private var backgroundColor: Color {
        if isUnavailable {
            return .routineSurface
        }

        return viewData.isCompletedToday ? .routineSurface : .routineSurfaceElevated
    }

    private var borderColor: Color {
        if isUnavailable {
            return Color.routineDivider.opacity(0.45)
        }

        return viewData.isCompletedToday
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
                            .foregroundStyle(isUnavailable ? Color.routineLabelSecondary : Color.routineLabelPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        metadataContent
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 72, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.leading, 14)
                .padding(.trailing, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isUnavailable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewData.accessibilityLabel)
            .accessibilityHint(primaryAccessibilityHint)
            .accessibilityIdentifier("routine-card-primary-\(viewData.name.routineAccessibilityIdentifierComponent)")

            if let onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color.routineLabelSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(viewData.name)")
                .accessibilityHint("Opens the routine editor.")
                .accessibilityIdentifier("routine-card-edit-\(viewData.name.routineAccessibilityIdentifierComponent)")
            }

            if let onHistory {
                Button(action: onHistory) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color.routineLabelSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("History for \(viewData.name)")
                .accessibilityHint("Opens completion history.")
                .accessibilityIdentifier(
                    "routine-card-history-\(viewData.name.routineAccessibilityIdentifierComponent)"
                )
                .padding(.trailing, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .overlay {
            if viewData.isCompletedToday {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.routineAccentComplete.opacity(0.08))
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if isUnavailable {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.routineLabelSecondary.opacity(0.04))
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var metadataContent: some View {
        if let availabilityText = viewData.availabilityText {
            VStack(alignment: .leading, spacing: 6) {
                primaryMetadataContent
                availabilityLabel(availabilityText)
            }
        } else {
            primaryMetadataContent
        }
    }

    @ViewBuilder
    private var primaryMetadataContent: some View {
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
            .fixedSize(horizontal: false, vertical: true)
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

    private func availabilityLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(isUnavailable ? Color.routineLabelPrimary : Color.routineLabelSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Routine Cards - Dark") {
    ComponentPreviewCanvas {
        VStack(spacing: 12) {
            RoutineCardView(viewData: ComponentPreviewFixtures.incompleteCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.completedTodayCard, onTap: {}, onEdit: {}, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.targetMetCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.overTargetCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.highTargetCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.unavailableCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.longNameCard, onTap: {}, onEdit: {}, onHistory: {})
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Routine Cards - Light") {
    ComponentPreviewCanvas {
        VStack(spacing: 12) {
            RoutineCardView(viewData: ComponentPreviewFixtures.incompleteCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(
                viewData: ComponentPreviewFixtures.completedTodayCard,
                onTap: {},
                onEdit: nil,
                onHistory: {}
            )
            RoutineCardView(viewData: ComponentPreviewFixtures.unavailableCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.longNameCard, onTap: {}, onEdit: {}, onHistory: {})
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Routine Cards - Accessibility Type") {
    ComponentPreviewCanvas {
        VStack(spacing: 12) {
            RoutineCardView(viewData: ComponentPreviewFixtures.incompleteCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.unavailableCard, onTap: {}, onEdit: nil, onHistory: {})
            RoutineCardView(viewData: ComponentPreviewFixtures.longNameCard, onTap: {}, onEdit: {}, onHistory: {})
        }
    }
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Routine Cards - Reduce Motion") {
    ComponentPreviewCanvas {
        RoutineCardView(viewData: ComponentPreviewFixtures.completedTodayCard, onTap: {}, onEdit: nil, onHistory: {})
    }
    .preferredColorScheme(.dark)
    .transaction { transaction in
        transaction.animation = nil
        transaction.disablesAnimations = true
    }
}
