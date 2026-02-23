import SwiftUI
import AuthenticationServices

// MARK: - Sign In View

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and title
            VStack(spacing: 16) {
                Image(systemName: "widget.small.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("Widgy")
                    .font(.largeTitle.bold())

                Text("Create beautiful widgets\nwith the power of AI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Sign in section
            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    // Handled by authManager.signIn() below
                }
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    // Intercept taps to use our async flow
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            performSignIn()
                        }
                }

                if authManager.isLoading {
                    ProgressView("Signing in...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)

            // Skip option
            Button("Continue as Guest") {
                continueAsGuest()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

            Spacer()
                .frame(height: 20)
        }
        .padding()
        #if os(iOS)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 0))
        #endif
    }

    // MARK: - Actions

    private func performSignIn() {
        Task {
            do {
                try await authManager.signIn()
            } catch {
                authManager.errorMessage = error.localizedDescription
            }
        }
    }

    private func continueAsGuest() {
        authManager.currentUser = .guestUser
        authManager.isAuthenticated = true
    }
}

#Preview {
    SignInView()
        .environment(AuthManager())
}
