import Foundation

struct AIContextPart: Codable, Hashable, Sendable {
    let partNumber: String
    let protectedNumber: String
    let title: String
    let category: String
    let model: String
    let years: [String]
    let engines: [String]
    let confidence: Int?
    let evidenceCount: Int
    let unlocked: Bool
}

struct AISafeMaintenanceItem: Codable, Hashable, Sendable {
    let title: String
    let odometer: String
    let notesPreview: String
}

struct AIAssistantRequest: Codable, Hashable, Sendable {
    let message: String
    let language: String
    let currentSearch: String
    let selectedCategory: String
    let vehicleSummary: String
    let parts: [AIContextPart]
    let maintenance: [AISafeMaintenanceItem]
    let savedRequestCount: Int
}

struct AISuggestion: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let reason: String
}

struct AIAssistantResponse: Codable, Hashable, Sendable {
    let answer: String
    let suggestions: [AISuggestion]
    let generatedByAI: Bool
    let privacyNote: String
}

enum AIAssistantRole: String, Codable, Sendable {
    case user
    case assistant
}

struct AIAssistantMessage: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    let role: AIAssistantRole
    let text: String
    let generatedByAI: Bool
    let createdAt: Date
}

enum AIAssistantError: LocalizedError {
    case missingBackendConfiguration
    case invalidQuestion
    case invalidServerURL
    case invalidResponse
    case unavailable

    var errorDescription: String? {
        switch self {
        case .missingBackendConfiguration:
            "AI backend is not configured."
        case .invalidQuestion:
            "The question is empty or too long."
        case .invalidServerURL:
            "AI backend URL is invalid."
        case .invalidResponse:
            "AI backend returned an invalid response."
        case .unavailable:
            "AI assistant is unavailable right now."
        }
    }
}
