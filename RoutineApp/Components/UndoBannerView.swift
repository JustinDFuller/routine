import SwiftUI

struct UndoBannerView: View {
    let viewData: UndoBannerViewData
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(viewData.message)
                .font(.subheadline)
                .foregroundStyle(Color.routineLabelPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onUndo) {
                Text(viewData.actionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.routineAccentActive)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.routineAccentActive.opacity(0.12))
                    )
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel("Undo completion")
            .accessibilityHint("Removes today's completion.")
            .accessibilityIdentifier("today-dashboard-undo-button")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.routineSurfaceElevated)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.routineDivider.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
    }
}

#Preview("Undo Banner - Dark") {
    ComponentPreviewCanvas {
        VStack {
            Spacer()
            UndoBannerView(viewData: ComponentPreviewFixtures.undoBanner, onUndo: {})
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Undo Banner - Light") {
    ComponentPreviewCanvas {
        VStack {
            Spacer()
            UndoBannerView(viewData: ComponentPreviewFixtures.undoBanner, onUndo: {})
        }
    }
    .preferredColorScheme(.light)
}
