import SwiftData
import SwiftUI

@MainActor
@main
struct RoutineApp: App {
    private let bootstrapState: AppBootstrapState

    init() {
        bootstrapState = AppBootstrap.initialState()
    }

    var body: some Scene {
        WindowGroup {
            AppBootstrapRootView(state: bootstrapState)
        }
    }
}
