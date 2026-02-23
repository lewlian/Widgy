import SwiftUI
import WidgyCore

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "widget.small")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)

                Text("Widgy")
                    .font(.largeTitle.bold())

                Text("AI-powered widget creation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Widgy")
        }
    }
}

#Preview {
    ContentView()
}
