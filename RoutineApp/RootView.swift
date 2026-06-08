import OSLog
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var path: [AppRoute] = []
    @State private var hasAppliedDebugLaunchRoute = false
    @State private var seedErrorIsPresented = false

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Routine",
        category: "starter-data"
    )

    init(initialPath: [AppRoute] = Self.debugInitialPath()) {
        _path = State(initialValue: initialPath)
    }

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
                try applyDebugLaunchRouteIfNeeded()
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
            RoutineHistoryView(routineID: routineID)
        }
    }

    private static func debugInitialPath() -> [AppRoute] {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-routine-open-missing-history-route") {
                return [.routineHistory(routineID: debugMissingHistoryRoutineID)]
            }
        #endif

        return []
    }

    private static var debugMissingHistoryRoutineID: UUID {
        guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-000000000099") else {
            preconditionFailure("Expected valid missing-history debug UUID.")
        }

        return uuid
    }

    private func applyDebugLaunchRouteIfNeeded() throws {
        #if DEBUG
            guard hasAppliedDebugLaunchRoute == false else {
                return
            }

            let arguments = ProcessInfo.processInfo.arguments
            guard arguments.contains("-routine-open-morning-yoga-history-with-completion") else {
                hasAppliedDebugLaunchRoute = true
                return
            }

            let descriptor = FetchDescriptor<Routine>(
                predicate: #Predicate<Routine> { routine in
                    routine.name == "Morning yoga"
                }
            )
            guard let routine = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.routineNotFound(Self.debugMissingHistoryRoutineID)
            }

            _ = try RoutineTrackingService(context: modelContext).completeToday(routineID: routine.id)
            path = [.routineHistory(routineID: routine.id)]
            hasAppliedDebugLaunchRoute = true
        #endif
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
