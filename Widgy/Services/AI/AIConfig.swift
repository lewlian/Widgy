import Foundation

// MARK: - AI Configuration

enum AIConfig {
    /// Supabase project URL
    static let supabaseURL = "https://wjvuhmajhqmcblclqptl.supabase.co"

    /// Supabase anonymous key (public — safe to embed in client)
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqdnVobWFqaHFtY2JsY2xxcHRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4NDMzNzksImV4cCI6MjA4NzQxOTM3OX0.E_5U6c8eh-Z4PTeiszmbzcl6ZOSduXPV2YM1LgjOm1I"

    /// Supabase Edge Function URL for widget generation
    static var generateWidgetURL: URL {
        URL(string: "\(supabaseURL)/functions/v1/generate-widget")!
    }

    /// Maximum output tokens per generation
    static let maxOutputTokens = 2000

    /// Maximum retry attempts for invalid JSON
    static let maxRetries = 2

    /// Token threshold for "minor edit" (fractional credit)
    static let minorEditThreshold = 500
}
