import Foundation
import SwiftUI

struct RoutineRuntimeConfiguration: Equatable, Sendable {
    enum ForcedColorScheme: String, Equatable, Sendable {
        case dark
        case light

        var swiftUIColorScheme: ColorScheme {
            switch self {
            case .dark:
                .dark
            case .light:
                .light
            }
        }
    }

    let fixedNow: Date?
    let disablesAnimations: Bool
    let screenshotFixture: RoutineScreenshotFixture?
    let forcedColorScheme: ForcedColorScheme?

    init(
        fixedNow: Date? = nil,
        disablesAnimations: Bool = false,
        screenshotFixture: RoutineScreenshotFixture? = nil,
        forcedColorScheme: ForcedColorScheme? = nil
    ) {
        self.fixedNow = fixedNow
        self.disablesAnimations = disablesAnimations
        self.screenshotFixture = screenshotFixture
        self.forcedColorScheme = forcedColorScheme
    }

    var now: Date {
        fixedNow ?? .now
    }
}

private struct RoutineRuntimeConfigurationKey: EnvironmentKey {
    static let defaultValue = RoutineRuntimeConfiguration()
}

extension EnvironmentValues {
    var routineRuntimeConfiguration: RoutineRuntimeConfiguration {
        get { self[RoutineRuntimeConfigurationKey.self] }
        set { self[RoutineRuntimeConfigurationKey.self] = newValue }
    }
}
