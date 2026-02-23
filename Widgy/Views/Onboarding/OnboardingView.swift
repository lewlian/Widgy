import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage
                .tag(0)
            howItWorksPage
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

    // MARK: - Page 2: How It Works

    private var howItWorksPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How It Works")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 24) {
                stepRow(
                    icon: "text.bubble.fill",
                    title: "Describe",
                    detail: "Tell AI what you want your widget to look like."
                )
                stepRow(
                    icon: "eye.fill",
                    title: "Preview",
                    detail: "See a live preview and refine until it's perfect."
                )
                stepRow(
                    icon: "apps.iphone",
                    title: "Place",
                    detail: "Add it to your homescreen or lockscreen."
                )
            }
            .padding(.horizontal, 32)

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
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }

    // MARK: - Helpers

    private func stepRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
