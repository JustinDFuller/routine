import OSLog
import RoutineCore
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineRuntimeConfiguration) private var runtime
    @Environment(\.routineCalendar) private var routineCalendar

    @State private var path: [AppRoute] = []
    @State private var hasAppliedDebugLaunchRoute = false
    @State private var seedErrorIsPresented = false

    private let debugLaunchConfiguration: RoutineDebugLaunchConfiguration

    private static let starterDataLogger = AppDiagnostics.logger(.starterData)
    private static let routingLogger = AppDiagnostics.logger(.routing)

    init(debugLaunchConfiguration: RoutineDebugLaunchConfiguration = .current) {
        self.debugLaunchConfiguration = debugLaunchConfiguration
        _path = State(initialValue: debugLaunchConfiguration.initialPath)
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
                if let screenshotFixture = runtime.screenshotFixture {
                    try RoutineScreenshotFixtureSeeder(context: modelContext).seed(
                        screenshotFixture,
                        now: runtime.now
                    )
                } else if runtime.skipsStarterSeeding == false {
                    try StarterDataService(
                        context: modelContext,
                        seedMetadataValue: runtime.starterSeedVersion
                    ).seedIfNeeded(now: runtime.now)
                }

                try applyDebugLaunchRouteIfNeeded()
            } catch {
                Self.starterDataLogger.error(
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
        case .routineHistory(let routineID):
            RoutineHistoryView(routineID: routineID)
        }
    }

    private func applyDebugLaunchRouteIfNeeded() throws {
        guard hasAppliedDebugLaunchRoute == false else {
            return
        }

        guard debugLaunchConfiguration.opensMorningYogaHistoryWithCompletion else {
            hasAppliedDebugLaunchRoute = true
            return
        }

        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { routine in
                routine.name == "Morning yoga"
            }
        )
        guard let routine = try modelContext.fetch(descriptor).first else {
            throw PersistenceError.routineNotFound(
                RoutineDebugLaunchConfiguration.missingHistoryRoutineID
            )
        }

        _ = try RoutineTrackingService(context: modelContext, routineCalendar: routineCalendar).completeToday(
            routineID: routine.id,
            now: runtime.now
        )
        path = [.routineHistory(routineID: routine.id)]
        let routineID = routine.id.uuidString
        Self.routingLogger.debug(
            "applyLaunchRoute route=morningYogaHistoryWithCompletion routineID=\(routineID, privacy: .public)"
        )
        hasAppliedDebugLaunchRoute = true
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
