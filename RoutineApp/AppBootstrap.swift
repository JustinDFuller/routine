import OSLog
import SwiftData
import SwiftUI

@MainActor
enum AppBootstrapState {
    case ready(ModelContainer, RoutineRuntimeConfiguration)
    case failed
}

@MainActor
enum AppBootstrap {
    private static let logger = AppDiagnostics.logger(.appLifecycle)

    static let launchConfiguration = RoutineDebugLaunchConfiguration.current

    static func initialState() -> AppBootstrapState {
        do {
            let modelContainer = try persistentContainer(launchConfiguration: launchConfiguration)
            let storeMode = launchConfiguration.storeMode.logValue
            let resetStore = launchConfiguration.resetsStore ? 1 : 0
            logger.info(
                "bootstrapReady storeMode=\(storeMode, privacy: .public) resetStore=\(resetStore, privacy: .public)"
            )
            return .ready(
                modelContainer,
                launchConfiguration.runtime
            )
        } catch {
            logger.error(
                "Persistent container initialization failed: \(String(describing: error), privacy: .private)"
            )
            return .failed
        }
    }

    static func persistentContainer(
        launchConfiguration: RoutineDebugLaunchConfiguration = launchConfiguration
    ) throws -> ModelContainer {
        if launchConfiguration.forcesBootstrapFailure {
            throw ForcedBootstrapFailure()
        }

        let modelContainer =
            switch launchConfiguration.storeMode {
            case .persistent:
                try RoutineModelContainer.persistent()
            case .inMemory:
                try RoutineModelContainer.inMemory()
            }

        if launchConfiguration.resetsStore {
            let context = ModelContext(modelContainer)
            try RoutineStoreResetService.resetAllData(in: context)
        }

        return modelContainer
    }
}

extension RoutineDebugLaunchConfiguration.StoreMode {
    fileprivate var logValue: String {
        switch self {
        case .persistent:
            "persistent"
        case .inMemory:
            "inMemory"
        }
    }
}

private struct ForcedBootstrapFailure: Error {}

struct AppBootstrapRootView: View {
    let state: AppBootstrapState

    var body: some View {
        switch state {
        case .ready(let modelContainer, let runtime):
            RootView(debugLaunchConfiguration: .current)
                .modelContainer(modelContainer)
                .environment(\.routineRuntimeConfiguration, runtime)
                .preferredColorScheme(runtime.forcedColorScheme?.swiftUIColorScheme)
                .transaction { transaction in
                    guard runtime.disablesAnimations else {
                        return
                    }

                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
        case .failed:
            AppBootstrapFailureView()
        }
    }
}

struct AppBootstrapFailureView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Unable to Open Routine")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("Routine could not open its local data.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Try relaunching the app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .accessibilityIdentifier("app-bootstrap-failure-screen")
    }
}

#Preview("Ready") {
    if let modelContainer = try? RoutineModelContainer.inMemory() {
        AppBootstrapRootView(state: .ready(modelContainer, RoutineRuntimeConfiguration()))
    } else {
        AppBootstrapRootView(state: .failed)
    }
}

#Preview("Failed") {
    AppBootstrapRootView(state: .failed)
}
