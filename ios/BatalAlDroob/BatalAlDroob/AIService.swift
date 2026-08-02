import Foundation

protocol AIAssistantServicing: Sendable {
    var isRemoteAIConfigured: Bool { get }
    func answer(_ request: AIAssistantRequest) async throws -> AIAssistantResponse
}

struct CompositeAIAssistantService: AIAssistantServicing {
    let remote: BatalRemoteAIService?
    let local = LocalCatalogAssistantService()

    var isRemoteAIConfigured: Bool {
        remote != nil
    }

    func answer(_ request: AIAssistantRequest) async throws -> AIAssistantResponse {
        guard let remote else {
            return try await local.answer(request)
        }
        do {
            return try await remote.answer(request)
        } catch {
            BatalLog.ai.error("Remote AI request failed: \(String(describing: error), privacy: .public)")
            return try await local.answer(request)
        }
    }
}

struct BatalRemoteAIService: AIAssistantServicing {
    let baseURL: URL
    let clientToken: String
    let session: URLSession

    var isRemoteAIConfigured: Bool { true }

    init?(session: URLSession = .shared) {
        let rawURL = Bundle.main.object(forInfoDictionaryKey: "AIAssistantBaseURL") as? String ?? ""
        let rawToken = Bundle.main.object(forInfoDictionaryKey: "AIAssistantClientToken") as? String ?? ""
        let trimmedURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedURL.isEmpty,
            !trimmedToken.isEmpty,
            !trimmedURL.contains("$("),
            !trimmedToken.contains("$("),
            trimmedToken.count >= 16,
            let url = URL(string: trimmedURL),
            url.scheme == "https" || url.host == "127.0.0.1" || url.host == "localhost"
        else { return nil }
        baseURL = url
        clientToken = trimmedToken
        self.session = session
    }

    init(baseURL: URL, clientToken: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.clientToken = clientToken
        self.session = session
    }

    func answer(_ request: AIAssistantRequest) async throws -> AIAssistantResponse {
        guard request.message.count <= 800 else { throw AIAssistantError.invalidQuestion }
        let endpoint = baseURL.appending(path: "api/ai/chat")
        var urlRequest = URLRequest(url: endpoint, timeoutInterval: 18)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(clientToken, forHTTPHeaderField: "X-Batal-AI-Client-Token")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw AIAssistantError.invalidResponse }
        guard (200 ..< 300).contains(http.statusCode) else { throw AIAssistantError.unavailable }
        let decoded = try JSONDecoder().decode(AIAssistantResponse.self, from: data)
        guard !decoded.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIAssistantError.invalidResponse
        }
        return decoded
    }
}

struct LocalCatalogAssistantService: AIAssistantServicing {
    var isRemoteAIConfigured: Bool { false }

    func answer(_ request: AIAssistantRequest) async throws -> AIAssistantResponse {
        let question = request.message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, question.count <= 800 else { throw AIAssistantError.invalidQuestion }

        let isArabic = request.language == "ar"
        let topParts = request.parts.prefix(3)
        let partsSummary = topParts.map { part in
            let engines = part.engines.isEmpty ? "-" : part.engines.prefix(3).joined(separator: ", ")
            let years = part.years.isEmpty ? "-" : part.years.prefix(4).joined(separator: ", ")
            return isArabic
                ? "\(part.protectedNumber): \(part.title) · \(years) · \(engines)"
                : "\(part.protectedNumber): \(part.title) · \(years) · \(engines)"
        }.joined(separator: "\n")

        let answer: String
        if request.parts.isEmpty {
            answer = isArabic
                ? "لم أجد نتائج كتالوج في السياق الحالي. جرّب كتابة رقم القطعة أو وصف العطل، ثم افتح المساعد مرة أخرى. لم يتم إرسال أي بيانات إلى خادم AI لأن الخلفية غير مكوّنة."
                : "I do not have catalog matches in the current context. Try entering a part number or symptom, then ask again. No data was sent to an AI server because the backend is not configured."
        } else {
            answer = isArabic
                ? "بناءً على نتائج الكتالوج الحالية، هذه أقرب القطع:\n\(partsSummary)\n\nللدقة: طابق الجيل والمحرك والسنة، ثم افتح سجل القطعة لعرض الدليل والأرقام المتاحة. لم يتم إرسال أي بيانات إلى خادم AI لأن الخلفية غير مكوّنة."
                : "Based on the current catalog results, these are the closest records:\n\(partsSummary)\n\nFor accuracy, match generation, engine, and year, then open the part record for evidence and available numbers. No data was sent to an AI server because the backend is not configured."
        }

        return AIAssistantResponse(
            answer: answer,
            suggestions: localSuggestions(for: request),
            generatedByAI: false,
            privacyNote: isArabic
                ? "وضع محلي: لم يتم إرسال بيانات خارج الجهاز."
                : "Local mode: no data was sent off device."
        )
    }

    private func localSuggestions(for request: AIAssistantRequest) -> [AISuggestion] {
        let isArabic = request.language == "ar"
        var suggestions: [AISuggestion] = []
        if !request.parts.isEmpty {
            suggestions.append(.init(
                id: "review-top-result",
                title: isArabic ? "افتح أقرب نتيجة" : "Open the closest result",
                reason: isArabic ? "النتيجة الأولى هي أفضل مرشح من البحث الحالي." : "The first result is the strongest current search candidate."
            ))
        }
        if request.vehicleSummary.contains("لم يتم") || request.vehicleSummary.contains("No vehicle") {
            suggestions.append(.init(
                id: "complete-vehicle",
                title: isArabic ? "أكمل بيانات سيارتي" : "Complete My Vehicle",
                reason: isArabic ? "بيانات السيارة تحسن ترتيب التوافق." : "Vehicle details improve fitment ranking."
            ))
        }
        suggestions.append(.init(
            id: "prepare-request",
            title: isArabic ? "جهّز طلب قطعة" : "Prepare a part request",
            reason: isArabic ? "الطلب المحفوظ يسهل إرساله للمورد بعد التحقق." : "A saved request is easier to send after verification."
        ))
        return suggestions
    }
}
