import SwiftUI

struct CompletedRoutineRowView: View {
    let viewData: RoutineCardViewData
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.routineAccentComplete)

                Text(viewData.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.routineLabelSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(viewData.countText)
                    .font(.caption)
                    .foregroundStyle(Color.routineLabelSecondary)

                Image(systemName: "chevron.down")
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
            "routine-completed-row-\(viewData.name.routineAccessibilityIdentifierComponent)"
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
