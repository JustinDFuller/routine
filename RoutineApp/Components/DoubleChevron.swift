import SwiftUI

struct DoubleChevron: View {
    enum Direction {
        case expand
        case collapse
    }

    let direction: Direction
    var spacing: CGFloat = -2

    private var topSymbol: String {
        direction == .expand ? "chevron.up" : "chevron.down"
    }

    private var bottomSymbol: String {
        direction == .expand ? "chevron.down" : "chevron.up"
    }

    var body: some View {
        VStack(spacing: spacing) {
            Image(systemName: topSymbol)
            Image(systemName: bottomSymbol)
        }
    }
}

#Preview("Double Chevron - Dark") {
    ComponentPreviewCanvas {
        HStack(spacing: 32) {
            DoubleChevron(direction: .expand)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.routineLabelSecondary)
            DoubleChevron(direction: .collapse)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.routineLabelSecondary)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Double Chevron - Light") {
    ComponentPreviewCanvas {
        HStack(spacing: 32) {
            DoubleChevron(direction: .expand)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.routineLabelSecondary)
            DoubleChevron(direction: .collapse)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.routineLabelSecondary)
        }
    }
    .preferredColorScheme(.light)
}
