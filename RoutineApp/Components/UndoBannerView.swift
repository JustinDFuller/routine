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

            Button(viewData.actionTitle, action: onUndo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.routineAccentActive)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.routineAccentActive.opacity(0.12))
                )
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
