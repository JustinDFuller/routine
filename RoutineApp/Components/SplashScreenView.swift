import SwiftUI

struct SplashScreenView: View {
    var accentColor: Color = .routineAccentComplete
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    @State private var ringFill: CGFloat = 0
    @State private var showsCheckmark = false
    @State private var contentOpacity: Double = 1

    private let size: CGFloat = 96
    private let lineWidth: CGFloat = 8

    private var checkmarkTransition: AnyTransition {
        accessibilityReduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.92))
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    var body: some View {
        ZStack {
            Color.routineCanvas.ignoresSafeArea()

            VStack(spacing: 20) {
                ring

                Text("Routine")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.routineLabelPrimary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Routine")
        }
        .opacity(contentOpacity)
        .accessibilityIdentifier("splash-screen")
        .task {
            await runTimeline()
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.routineDivider.opacity(0.5), style: strokeStyle)

            Circle()
                .trim(from: 0, to: ringFill)
                .stroke(accentColor, style: strokeStyle)
                .rotationEffect(.degrees(-90))

            if showsCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.routineLabelPrimary)
                    .transition(checkmarkTransition)
            }
        }
        .frame(width: size, height: size)
    }

    private func runTimeline() async {
        if accessibilityReduceMotion {
            ringFill = 1
            showsCheckmark = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        } else {
            withAnimation(.easeInOut(duration: 0.6)) {
                ringFill = 1
            }
            try? await Task.sleep(nanoseconds: 600_000_000)

            withAnimation(.easeInOut(duration: 0.25)) {
                showsCheckmark = true
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            contentOpacity = 0
        }
        try? await Task.sleep(nanoseconds: 250_000_000)

        onFinish()
    }
}

#Preview("Splash - Dark") {
    SplashScreenView(onFinish: {})
        .preferredColorScheme(.dark)
}

#Preview("Splash - Light") {
    SplashScreenView(onFinish: {})
        .preferredColorScheme(.light)
}

#Preview("Splash - Reduce Motion") {
    SplashScreenView(onFinish: {})
        .preferredColorScheme(.dark)
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
}
