import SwiftUI
import WidgetKit

struct RoutineWidgetEntryView: View {
    let entry: RoutineWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Routine")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text("Next routine widget coming soon")
                .font(.caption)
                .foregroundStyle(Color.routineLabelSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .containerBackground(Color.routineCanvas, for: .widget)
    }
}
