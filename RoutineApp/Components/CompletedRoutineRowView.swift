import SwiftUI

struct CompletedRoutineRowView: View {
    let viewData: RoutineCardViewData
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                if viewData.isCompletedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.routineAccentComplete)
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.routineLabelSecondary)
                }

                Text(viewData.name)
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
        .accessibilityLabel(viewData.accessibilityLabel)
        .accessibilityHint("Expands the full routine card.")
        .accessibilityIdentifier(
            viewData.isCompletedToday
                ? "routine-completed-row-\(viewData.name.routineAccessibilityIdentifierComponent)"
                : "routine-goal-met-row-\(viewData.name.routineAccessibilityIdentifierComponent)"
        )
    }
}

#Preview("Completed Row - Dark") {
    ComponentPreviewCanvas {
        CompletedRoutineRowView(viewData: ComponentPreviewFixtures.completedTodayCard, onExpand: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Completed Row - Light") {
    ComponentPreviewCanvas {
        CompletedRoutineRowView(viewData: ComponentPreviewFixtures.completedTodayCard, onExpand: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Goal Met Row - Dark") {
    ComponentPreviewCanvas {
        CompletedRoutineRowView(viewData: ComponentPreviewFixtures.targetMetCard, onExpand: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Goal Met Row - Light") {
    ComponentPreviewCanvas {
        CompletedRoutineRowView(viewData: ComponentPreviewFixtures.targetMetCard, onExpand: {})
    }
    .preferredColorScheme(.light)
}
