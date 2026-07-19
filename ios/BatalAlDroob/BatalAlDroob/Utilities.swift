import Foundation

// MARK: - Helpers

func partRequestDraft(for request: SavedPartRequest, plan: PartRequestPlan, language: AppLanguage) -> String {
    let header = language == .arabic ? "بطل الدروب - \(plan.titleAr)" : "Batal Al-Droob - \(plan.titleEn)"
    let fields: [(String, String)] = language == .arabic ? [
        ("الجيل", request.generation), ("السنة", request.year), ("VIN", request.vin),
        ("المحرك", request.engine), ("القير", request.transmission),
        ("رقم القطعة", request.partNumber), ("اسم القطعة", request.partName), ("ملاحظات", request.notes)
    ] : [
        ("Generation", request.generation), ("Year", request.year), ("VIN", request.vin),
        ("Engine", request.engine), ("Transmission", request.transmission),
        ("Part number", request.partNumber), ("Part name", request.partName), ("Notes", request.notes)
    ]
    let lines = fields.compactMap { label, value -> String? in
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : "\(label): \(trimmed)"
    }
    return ([header] + lines).joined(separator: "\n")
}

func partNumberCandidates(in text: String) -> [String] {
    let uppercased = text.uppercased()
    var candidates: [String] = []
    let fullRange = NSRange(uppercased.startIndex ..< uppercased.endIndex, in: uppercased)

    if
        let separated = try? NSRegularExpression(
            pattern: #"(?<![A-Z0-9])([A-Z0-9]{4,8})\s*[-–—_/]\s*([A-Z0-9]{3,8})(?![A-Z0-9])"#
        )
    {
        for match in separated.matches(in: uppercased, range: fullRange) where match.numberOfRanges == 3 {
            guard
                let firstRange = Range(match.range(at: 1), in: uppercased),
                let secondRange = Range(match.range(at: 2), in: uppercased) else { continue }
            candidates.append("\(uppercased[firstRange])-\(uppercased[secondRange])")
        }
    }

    if let compact = try? NSRegularExpression(pattern: #"(?<![A-Z0-9])[A-Z0-9]{8,14}(?![A-Z0-9])"#) {
        for match in compact.matches(in: uppercased, range: fullRange) {
            guard let range = Range(match.range, in: uppercased) else { continue }
            let candidate = String(uppercased[range])
            if candidate.contains(where: \.isNumber) {
                candidates.append(candidate)
            }
        }
    }

    return candidates.uniqued()
}

func isAllowedExternalURL(_ url: URL) -> Bool {
    guard
        let scheme = url.scheme?.lowercased(),
        scheme == "https",
        url.host != nil else { return false }
    return true
}

func diagnosticKeywords(_ text: String) -> [String] {
    let normalizedText = text.lowercased()
    var words: [String] = []
    if
        normalizedText.contains("حر") || normalizedText.contains("heat") || normalizedText
            .contains("cool") || normalizedText.contains("radiator")
    { words += [
        "cooling",
        "fan",
        "radiator"
    ] }
    if
        normalizedText.contains("كهرب") || normalizedText.contains("electric") || normalizedText
            .contains("light") || normalizedText.contains("sensor")
    { words += [
        "electrical",
        "sensor",
        "lamp"
    ] }
    if normalizedText.contains("فرامل") || normalizedText.contains("brake") { words += ["brake"] }
    if
        normalizedText.contains("تعليق") || normalizedText.contains("suspension") || normalizedText
            .contains("shock") { words += ["suspension"] }
    if
        normalizedText.contains("وقود") || normalizedText.contains("fuel") || normalizedText
            .contains("pump")
    { words += [
        "fuel",
        "pump"
    ] }
    return words.isEmpty ? normalizedText.split(separator: " ").prefix(6).map(String.init) : words.uniqued()
}

func tireDiameter(_ size: String) -> Double? {
    let cleaned = size.uppercased().replacingOccurrences(of: " ", with: "")
    let parts = cleaned.replacingOccurrences(of: "R", with: "/").split(separator: "/")
    guard
        parts.count >= 3,
        let width = Double(parts[0]),
        let aspect = Double(parts[1]),
        let wheel = Double(parts[2]) else { return nil }
    return (width * (aspect / 100) * 2 / 25.4) + wheel
}

func nonEmpty(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
    return value
}

func masked(_ value: String) -> String {
    guard value.count > 4 else { return "••••" }
    return String(value.prefix(2)) + "••••" + String(value.suffix(2))
}

func short(_ values: [String], limit: Int = 6) -> String {
    guard !values.isEmpty else { return "-" }
    let head = values.prefix(limit).joined(separator: ", ")
    return values.count > limit ? head + " …" : head
}

func normalized(_ value: String) -> String {
    value.lowercased()
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: " ", with: "")
        .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleStringArray(forKey key: Key) throws -> [String] {
        if let values = try? decodeIfPresent([String].self, forKey: key) { return values }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value.isEmpty ? [] : [value] }
        if let values = try? decodeIfPresent([Int].self, forKey: key) { return values.map(String.init) }
        return []
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Int(value) }
        return nil
    }

    func decodeFlexibleDouble(forKey key: Key) throws -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return Double(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Double(value) }
        return nil
    }
}

extension UserDefaults {
    func codable<T: Decodable>(_: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setCodable(_ value: some Encodable, forKey key: String) {
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: key)
    }
}
