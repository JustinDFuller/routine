import Foundation
import SwiftUI

struct RoutineRuntimeConfiguration: Equatable, Sendable {
    let fixedNow: Date?
    let disablesAnimations: Bool
    let skipsStarterSeeding: Bool
    let starterSeedVersion: String
    let screenshotFixture: RoutineScreenshotFixture?

    init(
        fixedNow: Date? = nil,
        disablesAnimations: Bool = false,
        skipsStarterSeeding: Bool = false,
        starterSeedVersion: String = StarterDataService.seedMetadataValue,
        screenshotFixture: RoutineScreenshotFixture? = nil
    ) {
        self.fixedNow = fixedNow
        self.disablesAnimations = disablesAnimations
        self.skipsStarterSeeding = skipsStarterSeeding
        self.starterSeedVersion = starterSeedVersion
        self.screenshotFixture = screenshotFixture
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
