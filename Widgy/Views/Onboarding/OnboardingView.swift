import SwiftUI
import WidgyCore

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var demoWidgetIndex = 0

    private let demoWidgets = SampleConfigs.all

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage
                .tag(0)
            previewPage
                .tag(1)
            getStartedPage
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text("Create Any Widget\nYou Imagine")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Describe your perfect widget in plain English and watch it come to life with AI.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Page 2: Live Preview Demo

    private var previewPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("See It Live")
                .font(.largeTitle.bold())

            Text("Widgets render instantly from your description.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Live widget demo
            WidgetPreviewChrome(config: demoWidgets[demoWidgetIndex])
                .shadow(color: .accentColor.opacity(0.2), radius: 16, y: 4)
                .animation(.spring(duration: 0.4, bounce: 0.2), value: demoWidgetIndex)
                .padding(.vertical, 8)

            // Widget name label
            Text(demoWidgets[demoWidgetIndex].name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            // Dot selector
            HStack(spacing: 12) {
                ForEach(demoWidgets.indices, id: \.self) { index in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            demoWidgetIndex = index
                        }
                    } label: {
                        Circle()
                            .fill(index == demoWidgetIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Page 3: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wand.and.stars")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text("Ready to Create?")
                    .font(.largeTitle.bold())

                Text("Your first widget is just a conversation away.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Create Your First Widget")
            }
            .buttonStyle(.brand)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
