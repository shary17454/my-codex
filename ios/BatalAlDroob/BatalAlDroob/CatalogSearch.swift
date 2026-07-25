import Foundation

extension CatalogViewModel {
    func fitmentSummary(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return text(ar: "أدخل رقم قطعة أو وصفًا مختصرًا.", en: "Enter a part number or short description.")
        }
        let match = rankedFitmentMatches(for: trimmed, limit: 1).first
        guard let match else {
            return text(
                ar: "لم أجد تطابقًا مباشرًا. جرّب رقم قطعة مثل 21082-4W000 أو اسم القسم.",
                en: "No direct match found. Try a part number such as 21082-4W000 or a category name."
            )
        }
        return [
            text(ar: "القطعة: \(title(for: match))", en: "Part: \(title(for: match))"),
            text(ar: "الرقم الأساسي: \(match.partNumber)", en: "Primary number: \(match.partNumber)"),
            text(ar: "السنوات: \(short(match.years))", en: "Years: \(short(match.years))"),
            text(ar: "المحركات: \(short(match.engines))", en: "Engines: \(short(match.engines))"),
            text(
                ar: "مصادر الكتالوج: \((match.sourceCount ?? match.evidence.count).formatted())",
                en: "Catalog sources: \((match.sourceCount ?? match.evidence.count).formatted())"
            )
        ].joined(separator: "\n")
    }

    func fitmentMatches(for query: String) -> [Part] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return rankedFitmentMatches(for: trimmed, limit: 8)
    }

    func rankedFitmentMatches(for query: String, limit: Int) -> [Part] {
        let normalizedQuery = normalized(query)
        return parts.compactMap { part -> (Part, Int)? in
            let normalizedPrimary = normalized(part.partNumber)
            let normalizedNumbers = part.allNumbers.map(normalized)
            let searchText = self.partSearchIndex[part.partNumber] ?? self.searchableText(for: part)
            let score: Int
            if normalizedPrimary == normalizedQuery {
                score = 400
            } else if normalizedNumbers.contains(normalizedQuery) {
                score = 350
            } else if normalizedPrimary.contains(normalizedQuery) {
                score = 300
            } else if normalizedNumbers.contains(where: { $0.contains(normalizedQuery) }) {
                score = 250
            } else if searchText.contains(normalizedQuery) {
                score = 100 + (part.confidence ?? 0)
            } else {
                return nil
            }
            return (part, score)
        }
        .sorted { lhs, rhs in
            if lhs.1 == rhs.1 { return (lhs.0.confidence ?? 0) > (rhs.0.confidence ?? 0) }
            return lhs.1 > rhs.1
        }
        .prefix(limit)
        .map(\.0)
    }

    func searchableText(for part: Part) -> String {
        normalized(([
            part.partNumber,
            part.primaryOEMNumber,
            part.nameAr,
            part.nameEn,
            part.category,
            part.categoryAr,
            part.model
        ] + part.partNumbers + part.years + part.engines).compactMap(\.self).joined(separator: " "))
    }

    func isLikelyPartNumberLookup(_ rawQuery: String, normalizedQuery: String) -> Bool {
        guard normalizedQuery.count >= 5 else { return false }
        if !partNumberCandidates(in: rawQuery).isEmpty { return true }
        return normalizedQuery.contains(where: \.isNumber)
            && normalizedQuery.contains(where: \.isLetter)
    }

    func partNumberMatches(_ part: Part, normalizedQuery query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return part.allNumbers.map(normalized).contains { number in
            number == query || number.contains(query)
        }
    }
}
