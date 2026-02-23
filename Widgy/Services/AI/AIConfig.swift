import Foundation

// MARK: - AI Configuration

enum AIConfig {
    /// Supabase Edge Function URL for widget generation
    /// Set via environment or configuration
    static var generateWidgetURL: URL {
        let baseURL = supabaseURL ?? "https://wjvuhmajhqmcblclqptl.supabase.co"
        return URL(string: "\(baseURL)/functions/v1/generate-widget")!
    }

    /// Supabase project URL — set this at app launch
    static var supabaseURL: String? {
        ProcessInfo.processInfo.environment["SUPABASE_URL"]
    }

    /// Supabase anonymous key for auth
    static var supabaseAnonKey: String? {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
    }

    /// Maximum output tokens per generation
    static let maxOutputTokens = 2000

    /// Maximum retry attempts for invalid JSON
    static let maxRetries = 2

    /// Token threshold for "minor edit" (fractional credit)
    static let minorEditThreshold = 500
}
