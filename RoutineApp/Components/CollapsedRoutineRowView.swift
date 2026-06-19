import SwiftUI

struct CollapsedRoutineRowView: View {
    let viewData: CollapsedRoutineRowViewData
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(viewData.routine.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.routineLabelSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                DoubleChevron(direction: .expand, spacing: 2)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.routineLabelSecondary)
            }
            .frame(minHeight: 44)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.routineSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.routineDivider.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewData.routine.accessibilityLabel)
        .accessibilityHint("Expands the full routine card.")
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var iconName: String {
        switch viewData.style {
        case .unavailable:
            "clock"
        case .completed:
            "checkmark.circle.fill"
        case .goalMet:
            "checkmark.circle"
        }
    }

    private var iconColor: Color {
        switch viewData.style {
        case .unavailable, .goalMet:
            .routineLabelSecondary
        case .completed:
            .routineAccentComplete
        }
    }

    private var accessibilityIdentifier: String {
        let name = viewData.routine.name.routineAccessibilityIdentifierComponent

        return switch viewData.style {
        case .unavailable:
            "routine-unavailable-row-\(name)"
        case .completed:
            "routine-completed-row-\(name)"
        case .goalMet:
            "routine-goal-met-row-\(name)"
        }
    }
}

#Preview("Completed Row - Dark") {
    ComponentPreviewCanvas {
        CollapsedRoutineRowView(
            viewData: CollapsedRoutineRowViewData(
                routine: ComponentPreviewFixtures.completedTodayCard,
                style: .completed
            ),
            onExpand: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Completed Row - Light") {
    ComponentPreviewCanvas {
        CollapsedRoutineRowView(
            viewData: CollapsedRoutineRowViewData(
                routine: ComponentPreviewFixtures.completedTodayCard,
                style: .completed
            ),
            onExpand: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Goal Met Row - Dark") {
    ComponentPreviewCanvas {
        CollapsedRoutineRowView(
            viewData: CollapsedRoutineRowViewData(
                routine: ComponentPreviewFixtures.targetMetCard,
                style: .goalMet
            ),
            onExpand: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Goal Met Row - Light") {
    ComponentPreviewCanvas {
        CollapsedRoutineRowView(
            viewData: CollapsedRoutineRowViewData(
                routine: ComponentPreviewFixtures.targetMetCard,
                style: .goalMet
            ),
            onExpand: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Unavailable Row - Dark") {
    ComponentPreviewCanvas {
        CollapsedRoutineRowView(
            viewData: CollapsedRoutineRowViewData(
                routine: ComponentPreviewFixtures.unavailableCard,
                style: .unavailable
            ),
            onExpand: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Unavailable Row - Light") {
    ComponentPreviewCanvas {
        CollapsedRoutineRowView(
            viewData: CollapsedRoutineRowViewData(
                routine: ComponentPreviewFixtures.unavailableCard,
                style: .unavailable
            ),
            onExpand: {}
        )
    }
    .preferredColorScheme(.light)
}
