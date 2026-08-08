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
    // Closing line asks the supplier for availability/price and invites compatible
    // alternatives, so a shared request reads as a professional inquiry, not a bare list.
    let closing = language == .arabic
        ? "الرجاء تأكيد التوفر والسعر، ويسعدنا قبول البدائل المتوافقة."
        : "Please confirm availability and price; compatible alternatives are welcome."
    return ([header] + lines + ["", closing]).joined(separator: "\n")
}

/// A required input the part request is still missing, used to block ambiguous
/// requests and to tell the user exactly what to add.
enum PartRequestRequirement: String, CaseIterable, Identifiable {
    case partIdentity
    case vehicleContext

    var id: String { rawValue }

    func message(_ language: AppLanguage) -> String {
        switch self {
        case .partIdentity:
            language == .arabic
                ? "أضف رقم القطعة أو اسمها."
                : "Add a part number or a part name."
        case .vehicleContext:
            language == .arabic
                ? "أضف جيل السيارة أو سنة الصنع."
                : "Add the vehicle generation or model year."
        }
    }
}

/// Requirements the request has not met yet. Empty means the request is specific
/// enough to send to a supplier without being ambiguous.
func partRequestMissingRequirements(_ request: SavedPartRequest) -> [PartRequestRequirement] {
    func hasText(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var missing: [PartRequestRequirement] = []
    if !(hasText(request.partNumber) || hasText(request.partName)) {
        missing.append(.partIdentity)
    }
    if !(hasText(request.generation) || hasText(request.year)) {
        missing.append(.vehicleContext)
    }
    return missing
}

func partRequestHasRequiredInput(_ request: SavedPartRequest) -> Bool {
    partRequestMissingRequirements(request).isEmpty
}

/// Compiled once. These patterns are evaluated inside search ranking, and rebuilding
/// an `NSRegularExpression` per call made every catalog scan pay two regex compilations
/// per record.
private enum PartNumberPatterns {
    static let separated = try? NSRegularExpression(
        pattern: #"(?<![A-Z0-9])([A-Z0-9]{4,8})\s*[-–—_/]\s*([A-Z0-9]{3,8})(?![A-Z0-9])"#
    )
    static let compact = try? NSRegularExpression(pattern: #"(?<![A-Z0-9])[A-Z0-9]{8,14}(?![A-Z0-9])"#)
}

func partNumberCandidates(in text: String) -> [String] {
    let uppercased = text.uppercased()
    var candidates: [String] = []
    let fullRange = NSRange(uppercased.startIndex ..< uppercased.endIndex, in: uppercased)

    if let separated = PartNumberPatterns.separated {
        for match in separated.matches(in: uppercased, range: fullRange) where match.numberOfRanges == 3 {
            guard
                let firstRange = Range(match.range(at: 1), in: uppercased),
                let secondRange = Range(match.range(at: 2), in: uppercased) else { continue }
            candidates.append("\(uppercased[firstRange])-\(uppercased[secondRange])")
        }
    }

    if let compact = PartNumberPatterns.compact {
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

func closestPartNumberDistance(_ numbers: [String], to query: String) -> Int? {
    let maxDistance = maximumPartNumberDistance(for: query)
    return numbers
        .filter { abs($0.count - query.count) <= maxDistance }
        .map { levenshteinDistance($0, query, maximumDistance: maxDistance) }
        .filter { $0 <= maxDistance }
        .min()
}

func maximumPartNumberDistance(for query: String) -> Int {
    query.count >= 10 ? 3 : 1
}

func levenshteinDistance(_ lhs: String, _ rhs: String, maximumDistance: Int? = nil) -> Int {
    if lhs == rhs { return 0 }
    if lhs.isEmpty { return rhs.count }
    if rhs.isEmpty { return lhs.count }
    if let maximumDistance, abs(lhs.count - rhs.count) > maximumDistance {
        return maximumDistance + 1
    }

    let left = Array(lhs)
    let right = Array(rhs)
    var previous = Array(0 ... right.count)

    for row in 1 ... left.count {
        var current = [row] + Array(repeating: 0, count: right.count)
        var rowMinimum = current[0]

        for column in 1 ... right.count {
            let substitutionCost = left[row - 1] == right[column - 1] ? 0 : 1
            current[column] = min(
                previous[column] + 1,
                current[column - 1] + 1,
                previous[column - 1] + substitutionCost
            )
            rowMinimum = min(rowMinimum, current[column])
        }

        if let maximumDistance, rowMinimum > maximumDistance {
            return maximumDistance + 1
        }
        previous = current
    }

    return previous[right.count]
}

func isAllowedExternalURL(_ url: URL) -> Bool {
    guard
        let scheme = url.scheme?.lowercased(),
        scheme == "https",
        url.host != nil else { return false }
    return true
}

func isAllowedExternalURL(_ url: URL, for store: VerifiedStore) -> Bool {
    guard isAllowedExternalURL(url), let host = url.host?.lowercased() else { return false }
    let allowedHosts = [store.website, store.searchURLTemplate]
        .compactMap(\.self)
        .compactMap { URL(string: $0.replacingOccurrences(of: "{part_number}", with: "21082-4W000"))?.host }
        .map { $0.lowercased() }
    return allowedHosts.contains { host == $0 || host.hasSuffix("." + $0) }
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

func orderedModelYears(for model: String?, years: [String]) -> [String] {
    let normalizedModel = normalized(model ?? "")
    if normalizedModel.contains("y60") {
        return (1988 ... 1997).map(String.init)
    }
    let numericYears = years.compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    if numericYears.count == years.count, !numericYears.isEmpty {
        return numericYears.sorted().map(String.init).uniqued()
    }
    return years.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .uniqued()
}

func fullYearListText(for model: String?, years: [String]) -> String {
    let orderedYears = orderedModelYears(for: model, years: years)
    return orderedYears.isEmpty ? "-" : orderedYears.joined(separator: ", ")
}

/// Folds a catalog string into the stable form used for indexing and matching.
///
/// The fold is deliberately **locale-independent**: the bundled catalog is indexed
/// once and queried on every device, so the same input must produce the same key
/// regardless of the user's region. Passing `.current` here would let a Turkish or
/// Azeri locale fold `I`/`i` differently from the locale that built the index, and
/// the app now ships a Turkish interface.
func normalized(_ value: String) -> String {
    value.lowercased()
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: " ", with: "")
        .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: nil)
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
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            BatalLog.persistence.error("Failed to decode UserDefaults value for \(key, privacy: .public)")
            return nil
        }
    }

    func setCodable(_ value: some Encodable, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            BatalLog.persistence.error("Failed to encode UserDefaults value for \(key, privacy: .public)")
        }
    }
}
