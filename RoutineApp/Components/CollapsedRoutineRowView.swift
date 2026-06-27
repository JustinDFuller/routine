import SwiftUI

struct CollapsedRoutineRowView: View {
    let viewData: CollapsedRoutineRowViewData
    let onExpand: () -> Void
    let actionTitle: String?
    let onAction: (() -> Void)?

    init(
        viewData: CollapsedRoutineRowViewData,
        onExpand: @escaping () -> Void,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.viewData = viewData
        self.onExpand = onExpand
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    var body: some View {
        if case .onBreak = viewData.style {
            breakRow
        } else {
            expandableRow
        }
    }

    private var breakRow: some View {
        HStack(spacing: 12) {
            Button(action: onExpand) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.routineLabelSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewData.routine.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.routineLabelSecondary)
                            .lineLimit(1)

                        if let resumeText = viewData.routine.breakResumeText {
                            Text("Off until \(resumeText)")
                                .font(.caption)
                                .foregroundStyle(Color.routineLabelSecondary)
                        }
                    }

                    Spacer(minLength: 0)

                    DoubleChevron(direction: .expand, spacing: 2)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.routineLabelSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.routineAccentActive)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.routineAccentActive.opacity(0.12))
                    )
                    .accessibilityIdentifier(
                        "routine-break-action-\(viewData.routine.name.routineAccessibilityIdentifierComponent)"
                    )
            }
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.routineSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.routineDivider.opacity(0.35), lineWidth: 1)
        }
        .accessibilityLabel(viewData.routine.accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var expandableRow: some View {
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
        case .onBreak:
            "moon.circle"
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
        case .onBreak, .unavailable, .goalMet:
            .routineLabelSecondary
        case .completed:
            .routineAccentComplete
        }
    }

    private var accessibilityIdentifier: String {
        let name = viewData.routine.name.routineAccessibilityIdentifierComponent

        return switch viewData.style {
        case .onBreak:
            "routine-break-row-\(name)"
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
