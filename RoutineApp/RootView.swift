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
    @State private var behindScheduleConsentIsPresented = false
    @State private var behindScheduleRescheduleCoordinator = BehindScheduleRescheduleCoordinator()

    private let debugLaunchConfiguration: RoutineDebugLaunchConfiguration

    private static let starterDataLogger = AppDiagnostics.logger(.starterData)
    private static let routingLogger = AppDiagnostics.logger(.routing)
    private static let forceBehindScheduleOnboardingArgument = "-routine-force-behind-schedule-onboarding-prompt"

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
        .environment(\.behindScheduleRescheduleCoordinator, behindScheduleRescheduleCoordinator)
        .task {
            do {
                if let screenshotFixture = runtime.screenshotFixture {
                    try RoutineScreenshotFixtureSeeder(context: modelContext).seed(
                        screenshotFixture,
                        now: runtime.now
                    )
                }

                try applyDebugLaunchRouteIfNeeded()
                await syncBehindScheduleAlerts()
                presentBehindScheduleOnboardingPromptIfNeeded()
            } catch {
                Self.starterDataLogger.error(
                    "Launch setup failed: \(String(describing: error), privacy: .private)")
                seedErrorIsPresented = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await syncBehindScheduleAlerts()
            }
        }
        .alert("Could not load initial data.", isPresented: $seedErrorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can still use Routine.")
        }
        .alert(
            "Behind-schedule alerts?",
            isPresented: $behindScheduleConsentIsPresented
        ) {
            Button("Enable alerts") {
                enableBehindScheduleAlertsFromOnboarding()
            }

            Button("Not Now", role: .cancel) {
                markBehindScheduleOnboardingShown()
            }
        } message: {
            Text("Routine sends at most one daily alert when progress falls behind pace.")
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

    private func syncBehindScheduleAlerts() async {
        await rescheduleBehindScheduleAlerts(
            coordinator: behindScheduleRescheduleCoordinator,
            context: modelContext,
            calendar: routineCalendar,
            now: runtime.now,
            logLabel: "syncBehindScheduleAlertsFailed"
        )
    }

    private func presentBehindScheduleOnboardingPromptIfNeeded() {
        let onboardingShown = UserDefaults.standard.bool(
            forKey: RoutineSettingsKeys.behindScheduleOnboardingShown
        )
        let forcesPrompt = ProcessInfo.processInfo.arguments.contains(
            Self.forceBehindScheduleOnboardingArgument
        )

        guard onboardingShown == false || forcesPrompt else {
            return
        }

        behindScheduleConsentIsPresented = true
    }

    private func enableBehindScheduleAlertsFromOnboarding() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
        markBehindScheduleOnboardingShown()

        Task {
            await behindScheduleRescheduleCoordinator.requestAuthorizationIfNeeded()
            await syncBehindScheduleAlerts()
        }
    }

    private func markBehindScheduleOnboardingShown() {
        UserDefaults.standard.set(
            true,
            forKey: RoutineSettingsKeys.behindScheduleOnboardingShown
        )
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
