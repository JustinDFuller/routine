import OSLog
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var seedErrorIsPresented = false

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Routine",
        category: "starter-data"
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Routine")
                    .font(.largeTitle.weight(.semibold))

                Text("Milestone 1 scaffold")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle("Today")
        }
        .task {
            do {
                try StarterDataService(context: modelContext).seedIfNeeded()
            } catch {
                Self.logger.error(
                    "Starter data setup failed at launch: \(String(describing: error), privacy: .private)")
                seedErrorIsPresented = true
            }
        }
        .alert("Could not set up starter routines.", isPresented: $seedErrorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can still use Routine.")
        }
    }
}

#Preview {
    if let modelContainer = try? RoutineModelContainer.inMemory() {
        RootView()
            .modelContainer(modelContainer)
    } else {
        Text("Preview unavailable")
    }
}
