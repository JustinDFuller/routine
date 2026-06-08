import Foundation

#if canImport(UIKit)
    import UIKit
#endif

@MainActor
enum RoutineHaptics {
    static func signalCompletion() {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        #endif
    }

    static func signalUndo() {
        #if canImport(UIKit)
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        #endif
    }
}
