import SwiftUI
import WidgetKit

struct RoutineWidgetEntryView: View {
    let entry: RoutineWidgetProvider.Entry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
            .containerBackground(Color.routineCanvas, for: .widget)
            .widgetURL(URL(string: "routine://today"))
    }

    @ViewBuilder
    private var content: some View {
        switch entry.selection {
        case .ready(let snapshot):
            ReadyRoutineView(snapshot: snapshot, family: family)
        case .noRoutines:
            WidgetEmptyStateView(
                title: "Add routines in Routine",
                message: "Open the app to set up your first routine.",
                isComplete: false
            )
        case .allCaughtUp:
            WidgetEmptyStateView(
                title: "All caught up",
                message: "Nothing ready right now.",
                isComplete: true
            )
        }
    }
}

private struct ReadyRoutineView: View {
    let snapshot: NextRoutineSnapshot
    let family: WidgetFamily

    private var accentColor: Color {
        snapshot.isComplete ? .routineAccentComplete : .routineAccentActive
    }

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetProgressRing(
                fillRatio: snapshot.fillRatio,
                showsCheckmark: snapshot.isComplete,
                accentColor: accentColor
            )
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.routineLabelPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                metadataPill(text: snapshot.countText)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            DoneButton(routineID: snapshot.routineID, accentColor: accentColor)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 14) {
            WidgetProgressRing(
                fillRatio: snapshot.fillRatio,
                showsCheckmark: snapshot.isComplete,
                accentColor: accentColor
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.routineLabelPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 8) {
                    metadataPill(text: snapshot.countText)
                    metadataPill(text: snapshot.periodText)
                }

                Text(snapshot.lastDoneText)
                    .font(.caption)
                    .foregroundStyle(Color.routineLabelSecondary)
            }

            Spacer(minLength: 0)

            DoneButton(routineID: snapshot.routineID, accentColor: accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func metadataPill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.routineLabelPrimary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(accentColor.opacity(0.12))
            )
    }
}

private struct DoneButton: View {
    let routineID: UUID
    let accentColor: Color

    var body: some View {
        Button(intent: CompleteRoutineIntent(routineID: routineID)) {
            Text("Done")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.routineCanvas)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(accentColor)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct WidgetEmptyStateView: View {
    let title: String
    let message: String
    let isComplete: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetProgressRing(
                fillRatio: isComplete ? 1 : 0,
                showsCheckmark: isComplete,
                accentColor: isComplete ? .routineAccentComplete : .routineLabelSecondary
            )
            .frame(width: 36, height: 36)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text(message)
                .font(.caption)
                .foregroundStyle(Color.routineLabelSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct WidgetProgressRing: View {
    let fillRatio: Double
    let showsCheckmark: Bool
    let accentColor: Color

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: 4.5, lineCap: .round)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.routineDivider.opacity(0.5), style: strokeStyle)

            Circle()
                .trim(from: 0, to: fillRatio)
                .stroke(accentColor, style: strokeStyle)
                .rotationEffect(.degrees(-90))

            if showsCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.routineLabelPrimary)
            }
        }
    }
}
