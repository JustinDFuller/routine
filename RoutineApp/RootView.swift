import Foundation
import OSLog
import RoutineCore
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineRuntimeConfiguration) private var runtime
    @Environment(\.routineCalendar) private var routineCalendar
    @Environment(\.scenePhase) private var scenePhase

    @State private var path: [AppRoute] = []
    @State private var hasAppliedDebugLaunchRoute = false
    @State private var seedErrorIsPresented = false
    @State private var checkInOnboardingPromptIsPresented = false

    private let debugLaunchConfiguration: RoutineDebugLaunchConfiguration

    private static let starterDataLogger = AppDiagnostics.logger(.starterData)
    private static let routingLogger = AppDiagnostics.logger(.routing)
    private static let notificationsLogger = AppDiagnostics.logger(.notifications)
    private static let forceCheckInOnboardingArgument = "-routine-force-checkin-onboarding-prompt"

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
                await syncCheckIns()
                presentCheckInOnboardingPromptIfNeeded()
            } catch {
                Self.starterDataLogger.error(
                    "Starter data setup failed at launch: \(String(describing: error), privacy: .private)")
                seedErrorIsPresented = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await syncCheckIns()
            }
        }
        .alert("Could not set up starter routines.", isPresented: $seedErrorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can still use Routine.")
        }
        .alert(
            "Stay on track with check-ins?",
            isPresented: $checkInOnboardingPromptIsPresented
        ) {
            Button("Enable Check-ins") {
                enableCheckInsFromOnboarding()
            }

            Button("Not Now", role: .cancel) {
                markCheckInOnboardingShown()
            }
        } message: {
            Text(
                "Routine can send a few quiet reminders during the day — morning, afternoon, and evening — "
                    + "and go quiet automatically once everything's done. No per-routine spam."
            )
        }
        .onOpenURL { url in
            guard url.host == "today" else {
                return
            }

            path = []
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

    private func syncCheckIns() async {
        do {
            try await CheckInScheduler().reschedule(context: modelContext, calendar: routineCalendar, now: runtime.now)
        } catch {
            Self.notificationsLogger.error(
                "syncCheckInsFailed e=\(String(describing: error), privacy: .private)"
            )
        }
    }

    private func presentCheckInOnboardingPromptIfNeeded() {
        let onboardingShown = UserDefaults.standard.bool(forKey: RoutineSettingsKeys.checkInOnboardingShown)
        let forcesPrompt = ProcessInfo.processInfo.arguments.contains(Self.forceCheckInOnboardingArgument)

        guard onboardingShown == false || forcesPrompt else {
            return
        }

        checkInOnboardingPromptIsPresented = true
    }

    private func enableCheckInsFromOnboarding() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInAfternoonEnabled)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInEveningEnabled)
        markCheckInOnboardingShown()

        Task {
            await CheckInScheduler().requestAuthorizationIfNeeded()
            await syncCheckIns()
        }
    }

    private func markCheckInOnboardingShown() {
        UserDefaults.standard.set(true, forKey: RoutineSettingsKeys.checkInOnboardingShown)
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
