import Foundation
import AuthenticationServices

// MARK: - User Model

struct AppUser: Codable, Sendable {
    let id: String
    let email: String?
    let displayName: String?
    let identityToken: String?

    static let guestUser = AppUser(id: "guest", email: nil, displayName: "Guest", identityToken: nil)
}

// MARK: - Auth Manager

@MainActor @Observable
final class AuthManager {
    var isAuthenticated = false
    var currentUser: AppUser?
    var isLoading = false
    var errorMessage: String?

    private static let userDefaultsKey = "com.lewlian.Widgy.currentUser"
    private static let authStateKey = "com.lewlian.Widgy.isAuthenticated"

    init() {
        checkAuthState()
    }

    // MARK: - Check Persisted Auth State

    func checkAuthState() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
              let user = try? JSONDecoder().decode(AppUser.self, from: data) else {
            isAuthenticated = false
            currentUser = nil
            return
        }

        // Verify the Apple ID credential is still valid
        let provider = ASAuthorizationAppleIDProvider()
        let userID = user.id

        // Use a detached task to call the async credential check, then hop back to MainActor
        Task {
            do {
                let state = try await provider.credentialState(forUserID: userID)
                switch state {
                case .authorized:
                    self.currentUser = user
                    self.isAuthenticated = true
                case .revoked, .notFound:
                    self.clearPersistedAuth()
                default:
                    self.clearPersistedAuth()
                }
            } catch {
                // If we can't verify, trust the persisted state
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }

    // MARK: - Sign In with Apple

    func signIn() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await performAppleSignIn()
        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        let userID = appleIDCredential.user

        // Email and name are only provided on first sign-in
        let email = appleIDCredential.email
        let displayName: String? = {
            if let fullName = appleIDCredential.fullName {
                let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
                return components.isEmpty ? nil : components.joined(separator: " ")
            }
            return nil
        }()

        let identityToken: String? = {
            if let tokenData = appleIDCredential.identityToken {
                return String(data: tokenData, encoding: .utf8)
            }
            return nil
        }()

        // Build user, merging with any previously stored info for returning users
        let existingUser = loadPersistedUser()
        let user = AppUser(
            id: userID,
            email: email ?? existingUser?.email,
            displayName: displayName ?? existingUser?.displayName,
            identityToken: identityToken
        )

        persistUser(user)
        currentUser = user
        isAuthenticated = true
    }

    // MARK: - Sign Out

    func signOut() {
        clearPersistedAuth()
    }

    // MARK: - Private Helpers

    private func performAppleSignIn() async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = SignInDelegate(continuation: continuation)
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = delegate

            // Retain delegate until callback fires
            _retainedDelegate = delegate

            controller.performRequests()
        }
    }

    // Strong reference to keep the delegate alive during the async sign-in flow
    private var _retainedDelegate: SignInDelegate?

    private func persistUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
        UserDefaults.standard.set(true, forKey: Self.authStateKey)
    }

    private func loadPersistedUser() -> AppUser? {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(AppUser.self, from: data)
    }

    private func clearPersistedAuth() {
        UserDefaults.standard.removeObject(forKey: Self.userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: Self.authStateKey)
        currentUser = nil
        isAuthenticated = false
    }
}

// MARK: - Sign-In Delegate

private final class SignInDelegate: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
    private let continuation: CheckedContinuation<ASAuthorization, Error>

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case signInFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential received."
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        }
    }
}
