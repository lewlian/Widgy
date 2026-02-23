import Foundation
import WidgyCore

// MARK: - Widget Generation Service

/// Manages AI-powered widget generation via Supabase Edge Functions.
/// Handles SSE streaming, JSON parsing, validation, and retry logic.
@MainActor @Observable
final class WidgetGenerationService {
    var isGenerating = false
    var streamedText = ""
    var currentConfig: WidgetConfig?
    var error: GenerationError?

    private let validator = ConfigValidator()

    // MARK: - Generate Widget

    /// Generate a widget config from a natural language description.
    /// Streams the response via SSE and parses the final JSON.
    func generate(
        prompt: String,
        conversationHistory: [ConversationMessage],
        existingConfig: WidgetConfig? = nil,
        family: WidgetFamily = .systemSmall
    ) async throws -> WidgetConfig {
        isGenerating = true
        streamedText = ""
        error = nil
        currentConfig = nil

        defer { isGenerating = false }

        var lastError: GenerationError?

        for attempt in 0...AIConfig.maxRetries {
            do {
                let config = try await attemptGeneration(
                    prompt: prompt,
                    conversationHistory: conversationHistory,
                    existingConfig: existingConfig,
                    family: family,
                    previousError: lastError?.localizedDescription
                )

                // Validate the generated config
                let result = validator.validate(config)
                if result.isValid {
                    currentConfig = config
                    return config
                } else {
                    let errorDesc = result.errors.map(\.description).joined(separator: "; ")
                    lastError = .validationFailed(errorDesc)
                    if attempt == AIConfig.maxRetries {
                        throw GenerationError.validationFailed(errorDesc)
                    }
                }
            } catch let e as GenerationError {
                lastError = e
                if attempt == AIConfig.maxRetries {
                    self.error = e
                    throw e
                }
            } catch {
                let genError = GenerationError.networkError(error.localizedDescription)
                self.error = genError
                throw genError
            }
        }

        throw GenerationError.maxRetriesExceeded
    }

    // MARK: - SSE Streaming

    private func attemptGeneration(
        prompt: String,
        conversationHistory: [ConversationMessage],
        existingConfig: WidgetConfig?,
        family: WidgetFamily,
        previousError: String?
    ) async throws -> WidgetConfig {
        var request = URLRequest(url: AIConfig.generateWidgetURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.setValue("Bearer \(AIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let body = GenerationRequest(
            prompt: prompt,
            conversationHistory: conversationHistory.map { $0.toAPIMessage() },
            existingConfig: existingConfig,
            family: family.rawValue,
            previousError: previousError
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GenerationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GenerationError.serverError(httpResponse.statusCode)
        }

        // Parse SSE stream
        var fullContent = ""

        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let data = String(line.dropFirst(6))
                if data == "[DONE]" { break }

                if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: Data(data.utf8)) {
                    fullContent += chunk.content
                    self.streamedText = fullContent
                }
            }
        }

        // Parse JSON from the streamed content
        return try parseWidgetConfig(from: fullContent, family: family)
    }

    // MARK: - JSON Parsing

    private func parseWidgetConfig(from text: String, family: WidgetFamily) throws -> WidgetConfig {
        // Try to extract JSON from the response (it might be wrapped in markdown code blocks)
        let jsonString = extractJSON(from: text)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GenerationError.invalidJSON("Could not convert response to data")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            var config = try decoder.decode(WidgetConfig.self, from: jsonData)
            config = SchemaVersion.migrate(config)
            return config
        } catch {
            throw GenerationError.invalidJSON(error.localizedDescription)
        }
    }

    private func extractJSON(from text: String) -> String {
        // Try to find JSON in code blocks first
        if let range = text.range(of: "```json\n"),
           let endRange = text.range(of: "\n```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
        }

        // Try to find JSON between { and }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }

        return text
    }
}

// MARK: - API Types

struct GenerationRequest: Codable {
    let prompt: String
    let conversationHistory: [APIMessage]
    let existingConfig: WidgetConfig?
    let family: String
    let previousError: String?

    enum CodingKeys: String, CodingKey {
        case prompt
        case conversationHistory = "conversation_history"
        case existingConfig = "existing_config"
        case family
        case previousError = "previous_error"
    }
}

struct APIMessage: Codable {
    let role: String
    let content: String
}

struct StreamChunk: Codable {
    let content: String
}

// MARK: - Errors

enum GenerationError: Error, LocalizedError {
    case networkError(String)
    case serverError(Int)
    case invalidResponse
    case invalidJSON(String)
    case validationFailed(String)
    case maxRetriesExceeded

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .serverError(let code): return "Server error: \(code)"
        case .invalidResponse: return "Invalid server response"
        case .invalidJSON(let msg): return "Invalid widget config: \(msg)"
        case .validationFailed(let msg): return "Validation failed: \(msg)"
        case .maxRetriesExceeded: return "Failed after multiple attempts"
        }
    }
}
