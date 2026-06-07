import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Routine")
                    .font(.largeTitle.weight(.semibold))

                Text("Milestone 1 scaffold")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle("Today")
        }
    }
}

#Preview {
    RootView()
}
