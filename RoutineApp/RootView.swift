import OSLog
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var path: [AppRoute] = []
    @State private var seedErrorIsPresented = false

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Routine",
        category: "starter-data"
    )

    var body: some View {
        NavigationStack(path: $path) {
            TodayDashboardView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
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

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .manageRoutines(let editingRoutineID):
            ManageRoutinesView(initialEditRoutineID: editingRoutineID)
        case .routineHistory(let routineID):
            RoutineHistoryPlaceholderView(routineID: routineID)
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
