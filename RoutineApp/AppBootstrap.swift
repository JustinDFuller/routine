import OSLog
import SwiftData
import SwiftUI

@MainActor
enum AppBootstrapState {
    case ready(ModelContainer)
    case failed
}

@MainActor
enum AppBootstrap {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Routine",
        category: "app.bootstrap"
    )

    static func initialState() -> AppBootstrapState {
        do {
            return .ready(try persistentContainer())
        } catch {
            logger.error(
                "Persistent container initialization failed: \(String(describing: error), privacy: .private)"
            )
            return .failed
        }
    }

    static func persistentContainer() throws -> ModelContainer {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-routine-force-bootstrap-failure") {
                throw ForcedBootstrapFailure()
            }
        #endif

        return try RoutineModelContainer.persistent()
    }
}

private struct ForcedBootstrapFailure: Error {}

struct AppBootstrapRootView: View {
    let state: AppBootstrapState

    var body: some View {
        switch state {
        case .ready(let modelContainer):
            RootView()
                .modelContainer(modelContainer)
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
        AppBootstrapRootView(state: .ready(modelContainer))
    } else {
        AppBootstrapRootView(state: .failed)
    }
}

#Preview("Failed") {
    AppBootstrapRootView(state: .failed)
}
