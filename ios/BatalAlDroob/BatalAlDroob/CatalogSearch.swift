import Foundation
import UIKit

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
            text(ar: "الرقم الأساسي: \(protectedNumber(match))", en: "Primary number: \(protectedNumber(match))"),
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

    func categoryCount(_ category: CatalogCategory) -> Int {
        guard category != .all else { return parts.count }
        return parts.lazy.filter { $0.categoryValue == category }.count
    }

    func openStore(_ store: VerifiedStore, part: Part?) {
        let url = store.searchURL(partNumber: part?.partNumber ?? "") ?? URL(string: store.website ?? "")
        guard let url, isAllowedExternalURL(url, for: store) else {
            errorMessage = text(ar: "رابط المتجر غير صالح.", en: "The store link is invalid.")
            return
        }
        #if os(iOS)
            Task {
                let opened = await UIApplication.shared.open(url)
                if !opened {
                    errorMessage = text(ar: "تعذر فتح رابط المتجر.", en: "The store link could not be opened.")
                }
            }
        #endif
    }

    private func rankedFitmentMatches(for query: String, limit: Int) -> [Part] {
        let normalizedQuery = normalized(query)
        let expandedTerms = expandedSearchTerms(for: query)
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
            } else if
                isLikelyPartNumberLookup(query, normalizedQuery: normalizedQuery),
                let distance = closestPartNumberDistance(normalizedNumbers, to: normalizedQuery) {
                score = 180 - distance
            } else if searchText.contains(normalizedQuery) {
                score = 100 + (part.confidence ?? 0)
            } else if let expandedScore = expandedSearchScore(in: searchText, terms: expandedTerms) {
                score = expandedScore + (part.confidence ?? 0)
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
        ] + part.partNumbers + part.years + part.engines + part.evidence.prefix(4).flatMap {
            [$0.sourceID, $0.year, $0.reference, $0.quantity, $0.context.map { String($0.prefix(240)) }]
        }).compactMap(\.self).joined(separator: " "))
    }

    func searchTextMatches(_ searchText: String, rawQuery: String, normalizedQuery query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return searchText.contains(query) || expandedSearchScore(in: searchText, terms: expandedSearchTerms(for: rawQuery)) != nil
    }

    func expandedSearchTerms(for query: String) -> [String] {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return [] }
        var terms = [normalizedQuery]

        let groups: [(triggers: [String], expansions: [String])] = [
            (
                ["دركسون", "دريكسون", "دركسيون", "ستيرنج", "توجيه", "مقود", "steering", "strg"],
                ["steering", "power steering", "pwr strg", "strg", "pitman", "arm pitman", "link assy drag link", "drag link"]
            ),
            (
                ["ذراع", "اذرع", "أذرع", "عمود", "arm", "rod", "link"],
                ["arm", "rod", "link", "arm pitman", "pitman", "link assy drag link", "drag link"]
            ),
            (
                ["تي رود", "تيرود", "تايرود", "tie rod", "tierod"],
                ["tie rod", "tierod", "rod assy", "socket kit"]
            )
        ]

        for group in groups where group.triggers.map(normalized).contains(where: normalizedQuery.contains) {
            terms.append(contentsOf: group.expansions.map(normalized))
        }

        if ["دركسون", "دريكسون", "دركسيون", "توجيه"].map(normalized).contains(where: normalizedQuery.contains),
           ["ذراع", "اذرع", "أذرع", "arm", "rod", "link"].map(normalized).contains(where: normalizedQuery.contains) {
            terms.append(contentsOf: ["arm pitman", "pitman", "drag link", "link assy drag link"].map(normalized))
        }

        return terms.filter { !$0.isEmpty }.uniqued()
    }

    private func expandedSearchScore(in searchText: String, terms: [String]) -> Int? {
        let hits = terms.filter { term in
            term.count >= 3 && searchText.contains(term)
        }
        guard !hits.isEmpty else { return nil }
        return 80 + min(hits.count, 4) * 15
    }

    func isLikelyPartNumberLookup(_ rawQuery: String, normalizedQuery: String) -> Bool {
        guard normalizedQuery.count >= 5 else { return false }
        if !partNumberCandidates(in: rawQuery).isEmpty { return true }
        return normalizedQuery.contains(where: \.isNumber)
            && normalizedQuery.contains(where: \.isLetter)
    }

    func partNumberMatches(
        _ part: Part,
        normalizedQuery query: String,
        allowingCloseMatches: Bool = true
    ) -> Bool {
        guard !query.isEmpty else { return false }
        let normalizedNumbers = part.allNumbers.map(normalized)
        if normalizedNumbers.contains(where: { number in number == query || number.contains(query) }) {
            return true
        }
        guard allowingCloseMatches else { return false }
        return closestPartNumberDistance(normalizedNumbers, to: query) != nil
    }
}
