import Foundation
import UIKit

private struct CatalogSearchIntent {
    private let normalizedQuery: String
    private let wantsInteriorTrim: Bool
    private let wantsGearArea: Bool
    private let wantsExplicitHardware: Bool
    private let preferredConcepts: [String]
    private let rejectedConcepts: [String]
    private let yearTokens: [String]

    init(query: String) {
        normalizedQuery = normalized(query)
        wantsInteriorTrim = Self.containsAny(
            normalized(query),
            [
                "ديكور", "دكور", "زينة", "زينه", "تلبيس", "تلبيسة", "تلبيسه", "تلبيسات",
                "غطاء", "غطا", "كسوة", "حلية", "خشب", "خشبي", "عنابي", "خمري", "ماروني",
                "بيج", "ذهبي", "داخلية", "داخلي", "كونسول", "درجالقير", "trim", "finisher",
                "finish", "garnish", "bezel", "console", "interior", "wood", "maroon", "burgundy"
            ]
        )
        wantsGearArea = Self.containsAny(
            normalized(query),
            ["قير", "جير", "فتيس", "جربكس", "جيربوكس", "ناقلحركة", "transmission", "gearbox", "shift", "selector"]
        )
        wantsExplicitHardware = Self.containsAny(
            normalized(query),
            [
                "صامولة", "صواميل", "مسمار", "مسامير", "برغي", "براغي", "واشر", "وردة",
                "كلبسة", "كلبسات", "مشبك", "مشابك", "ربلة", "جلدة", "nut", "screw",
                "bolt", "washer", "clip", "retainer", "grommet"
            ]
        )
        let intentProfile = Self.intentProfile(for: normalized(query))
        preferredConcepts = intentProfile.preferred
        rejectedConcepts = intentProfile.rejected
        yearTokens = partNumberCandidates(in: query).isEmpty
            ? query.split(whereSeparator: { !$0.isNumber }).map(String.init).filter { $0.count == 4 }
            : []
    }

    func adjustedScore(_ baseScore: Int, for part: Part, searchText: String) -> Int? {
        var score = baseScore

        if wantsInteriorTrim {
            if isClearlyHardware(part) {
                return nil
            }

            let preferredHits = interiorTrimPreferredTerms.filter { searchText.contains(normalized($0)) }.count
            if preferredHits > 0 { score += min(220, preferredHits * 45) }

            if wantsGearArea, Self.containsAny(searchText, gearAreaPreferredTerms.map(normalized)) {
                score += 120
            }

            if Self.containsAny(searchText, ["لوحةالعدادات", "طبلون", "تابلوه", "داخلي", "كونسول", "كسوة", "ديكور"]) {
                score += 80
            }
        }

        let preferredHits = preferredConcepts.filter { searchText.contains($0) }.count
        if preferredHits > 0 {
            score += min(260, preferredHits * 35)
        }

        let rejectedHits = rejectedConcepts.filter { searchText.contains($0) }.count
        if rejectedHits > 0 {
            score -= min(220, rejectedHits * 45)
        }

        if wantsExplicitHardware {
            if isClearlyHardware(part) {
                score += 280
            } else if !preferredConcepts.isEmpty {
                score -= 100
            }
        } else if isClearlyHardware(part), !preferredConcepts.isEmpty {
            return nil
        }

        for year in yearTokens where part.years.contains(year) || part.dateRanges.contains(where: { $0.contains(year) }) {
            score += 60
            break
        }

        if normalizedQuery.contains("y60"), normalized(part.model ?? "").contains("y60") {
            score += 80
        }

        return score
    }

    private static func intentProfile(for query: String) -> (preferred: [String], rejected: [String]) {
        let profiles: [(triggers: [String], preferred: [String], rejected: [String])] = [
            (
                ["ديكور", "دكور", "زينة", "زينه", "تلبيس", "تلبيسة", "كسوة", "حلية", "غطاء", "غطا", "كونسول", "طبلون", "تابلوه", "درجالقير", "داخلية", "داخلي", "عنابي", "خمري", "ماروني", "خشب", "خشبي", "trim", "finisher", "garnish", "bezel", "console", "interior"],
                ["ديكور", "زينة", "تلبيس", "كسوة", "حلية", "غطاء", "كونسول", "طبلون", "تابلوه", "درجالقير", "داخلي", "عنابي", "خمري", "ماروني", "trim", "finisher", "garnish", "bezel", "console", "interior", "cover", "lid", "wood", "burgundy", "maroon"],
                ["صامولة", "مسمار", "برغي", "واشر", "وردة", "كلبسة", "مشبك", "nut", "screw", "bolt", "washer", "clip", "grommet"]
            ),
            (
                ["قير", "جير", "فتيس", "جربكس", "جيربوكس", "ناقلحركة", "عصاالقير", "ديكورالقير", "transmission", "gearbox"],
                ["قير", "جير", "فتيس", "transmission", "gearbox", "shift", "selector", "lever", "knob", "boot", "case transfer", "console", "finisher"],
                ["صدام", "رفرف", "نور", "فرامل", "مكيف", "bumper", "fender", "lamp", "brake", "air conditioner"]
            ),
            (
                ["دركسون", "دريكسون", "دركسيون", "مقود", "طارة", "طاره", "توجيه", "ستيرنج", "دودة", "دوده", "علبةدركسون", "علبةدريكسون", "steering"],
                ["دركسون", "مقود", "توجيه", "steering", "strg", "pitman", "drag link", "tie rod", "column", "wheel steering", "rod", "link", "arm"],
                ["فرامل", "مكيف", "رديتر", "صدام", "brake", "air conditioner", "radiator", "bumper"]
            ),
            (
                ["رديتر", "راديتر", "راديتور", "اديتر", "رديترماء", "راديترماء", "مبرد", "حرارة", "تبريد", "cooling", "radiator"],
                ["radiator", "cooling", "cooler", "water", "fan", "shroud", "hose radiator", "cap radiator", "reservoir"],
                ["ديكور", "قير", "فرامل", "صدام", "trim", "gearbox", "brake", "bumper"]
            ),
            (
                ["طرمبةبنزين", "طمبةبنزين", "بمبةبنزين", "مضخةوقود", "طرمبهوقود", "بنزين", "وقود", "بخاخ", "بخاخات", "رشاش", "رشاشات", "تانكي", "fuel", "injector"],
                ["fuel", "pump fuel", "fuel pump", "injector", "nozzle", "rail fuel", "tank fuel", "filter fuel", "strainer fuel"],
                ["مكيف", "فرامل", "ديكور", "air conditioner", "brake", "trim"]
            ),
            (
                ["فرامل", "بريك", "بريكات", "فحمات", "اقمشة", "أقمشة", "هوبات", "هوب", "ديسكفرامل", "brake"],
                ["brake", "pad", "shoe", "disc", "rotor", "drum", "caliper", "booster", "master cylinder"],
                ["ديكور", "مكيف", "قير", "trim", "air conditioner", "gearbox"]
            ),
            (
                ["مساعد", "مساعدات", "ياي", "يايات", "سسته", "سبرنق", "سبرنج", "مقص", "مقصات", "جلدة", "تعليق", "suspension", "shock", "spring"],
                ["suspension", "shock", "absorber", "spring", "coil", "arm", "control arm", "bushing", "stabilizer", "ball joint", "link"],
                ["ديكور", "مكيف", "نور", "trim", "air conditioner", "lamp"]
            ),
            (
                ["مكيف", "مكييف", "كمبروسر", "كومبروسر", "ثلاجة", "كوندنسر", "رديترمكيف", "فريون", "ac", "a/c", "airconditioner"],
                ["air conditioner", "a/c", "compressor", "condenser", "evaporator", "cooler", "receiver drier", "hose air conditioner"],
                ["فرامل", "قير", "دركسون", "brake", "gearbox", "steering"]
            ),
            (
                ["نور", "انوار", "أنوار", "كشاف", "اسطب", "اصطب", "شمعة", "شمعةامامية", "شمعةخلفية", "فانوس", "لمبة", "lamp", "headlight", "taillight"],
                ["lamp", "headlamp", "head light", "tail lamp", "combination lamp", "fog lamp", "lens", "bulb"],
                ["فرامل", "قير", "مكيف", "brake", "gearbox", "air conditioner"]
            ),
            (
                ["صدام", "دعامة", "دعامية", "نسافة", "نسافات", "رفرف", "رفارف", "كبوت", "غطاءمكينة", "باب", "بيبان", "شنطة", "هيكل", "body", "bumper", "fender", "hood", "door"],
                ["body", "bumper", "fender", "hood", "bonnet", "door", "panel", "guard", "protector", "reinforcement", "bracket"],
                ["مكيف", "فرامل", "قير", "air conditioner", "brake", "gearbox"]
            ),
            (
                ["قزاز", "زجاج", "جام", "دريشة", "قزازة", "مساحات", "مساحة", "wiper", "glass", "window"],
                ["glass", "window", "windshield", "wiper", "blade wiper", "arm wiper", "motor wiper", "washer", "nozzle washer"],
                ["فرامل", "قير", "مكيف", "brake", "gearbox", "air conditioner"]
            ),
            (
                ["حساس", "حساسات", "سنسر", "سينسور", "كهرباء", "فيش", "ظفيرة", "افياش", "ريليه", "كتاوت", "فيوز", "sensor", "switch", "relay", "harness"],
                ["sensor", "switch", "sender", "temperature sensor", "pressure sensor", "relay", "harness", "wire", "fusible link", "control unit", "module"],
                ["صدام", "فرامل", "ديكور", "bumper", "brake", "trim"]
            )
        ]

        var preferred = [String]()
        var rejected = [String]()
        for profile in profiles where containsAny(query, profile.triggers) {
            preferred.append(contentsOf: profile.preferred)
            rejected.append(contentsOf: profile.rejected)
        }
        return (preferred.map(normalized).filter { !$0.isEmpty }.uniqued(), rejected.map(normalized).filter { !$0.isEmpty }.uniqued())
    }

    private func isClearlyHardware(_ part: Part) -> Bool {
        let title = normalized([part.nameAr, part.nameEn].compactMap(\.self).joined(separator: " "))
        let hardwareNames = [
            "صامولة", "مسمار", "برغي", "وردة", "واشر", "كلبسة", "مشبك", "جلدة", "ربلة",
            "nut", "screw", "bolt", "washer", "grommet", "clip", "retainer"
        ].map(normalized)
        return hardwareNames.contains { title.contains($0) }
    }

    private var interiorTrimPreferredTerms: [String] {
        [
            "trim", "finisher", "finish", "garnish", "bezel", "cover", "lid", "console",
            "center console", "instrument panel", "dashboard", "cluster lid", "cluster",
            "shift", "selector", "knob", "boot", "interior", "wood", "maroon", "burgundy",
            "ديكور", "زينة", "زينه", "تلبيس", "غطاء", "كسوة", "حلية", "كونسول", "طبلون", "تابلوه", "عنابي"
        ]
    }

    private var gearAreaPreferredTerms: [String] {
        [
            "shift", "selector", "gear shift", "gear selector", "transmission control",
            "console", "knob", "boot", "lever", "finisher shift", "cover shift",
            "قير", "عصا القير", "ديكور القير", "كونسول"
        ]
    }

    private static func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { term in
            let normalizedTerm = normalized(term)
            return !normalizedTerm.isEmpty && text.contains(normalizedTerm)
        }
    }
}

extension CatalogViewModel {
    func fitmentSummary(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return text(ar: "أدخل رقم قطعة أو وصفًا مختصرًا.", en: "Enter a part number or short description.")
        }
        let match = rankedCatalogMatches(for: trimmed, limit: 1).first
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
        return rankedCatalogMatches(for: trimmed, limit: 8)
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

    func rankedCatalogMatches(for query: String, limit: Int) -> [Part] {
        let normalizedQuery = normalized(query)
        let shouldUseExpandedTerms = !isLikelyPartNumberLookup(query, normalizedQuery: normalizedQuery)
        let expandedTerms = shouldUseExpandedTerms ? expandedSearchTerms(for: query) : []
        let intent = CatalogSearchIntent(query: query)
        return parts.compactMap { part -> (Part, Int)? in
            let normalizedPrimary = normalized(part.partNumber)
            let normalizedNumbers = part.allNumbers.map(normalized)
            let searchText = self.partSearchIndex[part.partNumber] ?? self.searchableText(for: part)
            var score: Int
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
            guard let adjustedScore = intent.adjustedScore(score, for: part, searchText: searchText) else {
                return nil
            }
            score = adjustedScore
            return (part, score)
        }
        .sorted { lhs, rhs in
            if lhs.1 == rhs.1 { return (lhs.0.confidence ?? 0) > (rhs.0.confidence ?? 0) }
            return lhs.1 > rhs.1
        }
        .prefix(limit)
        .map(\.0)
    }

    func rankingDebugSummary(for query: String, limit: Int = 5) -> [String] {
        rankedCatalogMatches(for: query, limit: limit).map { part in
            "\(part.partNumber) | \(title(for: part)) | \(part.model ?? "-") | \(short(orderedModelYears(for: part.model, years: part.years), limit: 4))"
        }
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
        guard !isLikelyPartNumberLookup(rawQuery, normalizedQuery: query) else {
            return searchText.contains(query)
        }
        return searchText.contains(query) || expandedSearchScore(in: searchText, terms: expandedSearchTerms(for: rawQuery)) != nil
    }

    func expandedSearchTerms(for query: String) -> [String] {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return [] }
        var terms = [normalizedQuery]

        let groups: [(triggers: [String], expansions: [String])] = [
            (
                ["دركسون", "دريكسون", "دركسيون", "ستيرنج", "طاره", "طارة", "مقود", "توجيه", "دوده", "دودة", "علبة دركسون", "علبة دريكسون", "steering", "strg"],
                ["steering", "power steering", "pwr strg", "strg", "steering wheel", "steering column", "gear steering", "gear assy steering", "pitman", "arm pitman", "link assy drag link", "drag link"]
            ),
            (
                ["ذراع", "اذرع", "أذرع", "عمود", "عمود توازن", "عامود", "عمودان", "مقص", "مقصات", "وصلة", "وصله", "بيضة", "بيض", "جلدة", "جلد", "ربلة", "ربلات", "arm", "rod", "link"],
                ["arm", "rod", "link", "control arm", "arm assy", "bushing", "bush", "rubber", "ball joint", "socket", "stabilizer", "stabilizer bar", "arm pitman", "pitman", "link assy drag link", "drag link"]
            ),
            (
                ["تي رود", "تيرود", "تايرود", "تيرودات", "تايرودات", "طرف دركسون", "طرف دريكسون", "tie rod", "tierod"],
                ["tie rod", "tierod", "rod assy", "socket kit", "socket steering", "end assy tie rod"]
            ),
            (
                ["رديتر", "راديتر", "رديتر ماء", "راديتر ماء", "راديتور", "اديتر", "مبرد", "cooler", "radiator"],
                ["radiator", "rad", "cooling", "cooler", "water", "reservoir", "tank", "fan", "shroud", "hose radiator", "cap radiator"]
            ),
            (
                ["مروحة", "مراوح", "كلتش مروحة", "كلج مروحة", "fan"],
                ["fan", "fan clutch", "clutch fan", "cooling fan", "shroud", "blade fan"]
            ),
            (
                ["طرمبة ماء", "طمبة ماء", "مضخة ماء", "واتر بمب", "water pump"],
                ["water pump", "pump water", "cooling", "gasket water pump", "pulley water pump"]
            ),
            (
                ["طرمبة بنزين", "طمبة بنزين", "مضخة بنزين", "مضخة وقود", "طرمبه وقود", "بمبة بنزين", "fuel pump"],
                ["fuel pump", "pump fuel", "pump assy fuel", "filter fuel", "strainer fuel", "tank fuel"]
            ),
            (
                ["بخاخ", "بخاخات", "انجكتر", "انجكترات", "رشاش", "رشاشات", "injector"],
                ["injector", "nozzle", "fuel injection", "injection", "rail fuel"]
            ),
            (
                ["فرامل", "بريك", "بريكات", "فحمات", "اقمشة", "أقمشة", "هوبات", "هوب", "ديسك فرامل", "brake"],
                ["brake", "pad", "shoe", "disc", "rotor", "drum", "caliper", "cylinder brake", "master cylinder", "booster brake"]
            ),
            (
                ["كلتش", "كلج", "دبرياج", "صحن كلتش", "دسك كلتش", "clutch"],
                ["clutch", "disc clutch", "cover clutch", "release bearing", "master cylinder clutch", "operating cylinder clutch"]
            ),
            (
                ["قير", "جير", "فتيس", "جربكس", "جيربوكس", "ناقل حركة", "transmission", "gearbox"],
                ["transmission", "gearbox", "manual transmission", "automatic transmission", "shift", "shift lever", "gear shift", "selector", "gear selector", "knob", "boot", "console", "finisher", "cover shift", "case transfer", "oil seal transmission"]
            ),
            (
                ["ديكور", "دكور", "زينة", "زينه", "تلبيس", "تلبيسة", "تلبيسه", "غطاء", "غطا", "كسوة", "تلبيسات", "عنابي", "خمري", "ماروني", "خشب", "خشبي", "بيج", "ذهبي", "داخلية", "داخلي", "كونسول", "درج القير", "حلية", "trim", "finisher", "garnish", "bezel", "console"],
                ["trim", "finisher", "finish", "garnish", "bezel", "cover", "lid", "console", "center console", "instrument panel", "dashboard", "cluster", "cluster lid", "shift", "selector", "knob", "boot", "interior", "wood", "maroon", "burgundy"]
            ),
            (
                ["دبل", "دفلوك", "دف لوك", "دفرنس", "دفرنش", "كرونة", "كارونه", "diff", "differential"],
                ["differential", "final drive", "carrier", "gear ring", "pinion", "transfer", "axle", "lock differential"]
            ),
            (
                ["عمود كردان", "كردان", "عامود كردان", "دراب شفت", "درايف شفت", "drive shaft", "propeller shaft"],
                ["propeller shaft", "drive shaft", "shaft propeller", "universal joint", "u joint", "yoke", "flange"]
            ),
            (
                ["عكس", "عكوس", "اكسل", "اكسلات", "axle", "cv"],
                ["axle", "shaft axle", "cv joint", "joint", "hub", "knuckle", "bearing wheel"]
            ),
            (
                ["مساعد", "مساعدات", "ممتص", "ممتص صدمات", "shock", "absorber"],
                ["shock absorber", "absorber", "strut", "suspension", "spring", "coil spring"]
            ),
            (
                ["ياي", "يايات", "سست", "سسته", "سبرنق", "سبرنج", "spring"],
                ["spring", "coil spring", "leaf spring", "suspension", "seat spring", "shackle"]
            ),
            (
                ["صوفة", "صوف", "جلدة زيت", "تهريب زيت", "سيل", "seal"],
                ["seal", "oil seal", "packing", "gasket", "o ring", "rubber", "retainer"]
            ),
            (
                ["وجه", "وجيه", "قازقيت", "جازكيت", "جوان", "gasket"],
                ["gasket", "packing", "seal", "o ring", "cylinder head gasket", "manifold gasket"]
            ),
            (
                ["رمان", "رمانة", "بلي", "بليه", "بيرنق", "bearing"],
                ["bearing", "ball bearing", "roller bearing", "needle bearing", "hub bearing", "pilot bearing"]
            ),
            (
                ["فلتر", "فلاتر", "صفاية", "سيفون", "filter"],
                ["filter", "element", "strainer", "cleaner", "air cleaner", "oil filter", "fuel filter"]
            ),
            (
                ["بواجي", "بوجي", "شمعة", "شمعات", "spark plug", "plug"],
                ["spark plug", "plug", "ignition", "coil", "distributor", "cap distributor", "rotor"]
            ),
            (
                ["كويل", "كويلات", "ملف", "ملفات", "coil"],
                ["coil", "ignition coil", "ignition", "distributor", "spark plug"]
            ),
            (
                ["دينمو", "دنمو", "الترنيتر", "الترناتور", "مولد", "alternator"],
                ["alternator", "generator", "dynamo", "regulator", "pulley alternator", "belt alternator"]
            ),
            (
                ["سلف", "سلفه", "مارش", "ستارتر", "starter"],
                ["starter", "motor starter", "switch starter", "relay starter", "pinion starter"]
            ),
            (
                ["سير", "سيور", "قشاط", "قشاطات", "belt"],
                ["belt", "fan belt", "alternator belt", "power steering belt", "compressor belt", "v belt"]
            ),
            (
                ["بطارية", "اصبع بطارية", "قطب بطارية", "battery"],
                ["battery", "terminal", "cable battery", "holder battery", "relay", "fusible link"]
            ),
            (
                ["حساس", "حساسات", "سنسر", "سينسور", "sensor"],
                ["sensor", "switch", "sender", "temperature sensor", "speed sensor", "oxygen sensor", "pressure sensor"]
            ),
            (
                ["كمبيوتر", "مخ", "اي سي يو", "ecu", "ecm"],
                ["control unit", "ecu", "ecm", "module", "controller", "relay", "unit assy"]
            ),
            (
                ["مكيف", "مكييف", "ثلاجة", "كمبروسر", "كومبروسر", "رديتر مكيف", "كوندنسر", "ac", "air conditioner"],
                ["air conditioner", "a/c", "compressor", "condenser", "evaporator", "cooler", "receiver drier", "hose air conditioner"]
            ),
            (
                ["نور", "انوار", "أنوار", "شمعة امامية", "شمعة خلفية", "كشاف", "اسطب", "اصطب", "فانوس", "headlight", "lamp"],
                ["lamp", "headlamp", "head light", "tail lamp", "combination lamp", "fog lamp", "lens", "bulb"]
            ),
            (
                ["صدام", "دعامة", "دعامية", "نسافة", "نسافات", "bumper"],
                ["bumper", "fascia", "guard", "protector", "reinforcement", "bracket bumper", "mud guard"]
            ),
            (
                ["رفرف", "رفارف", "جناح", "fender"],
                ["fender", "mudguard", "protector fender", "guard chipping", "flare", "apron"]
            ),
            (
                ["كبوت", "غطاء مكينة", "غطا مكينه", "hood", "bonnet"],
                ["hood", "bonnet", "hinge hood", "lock hood", "support hood", "insulator hood"]
            ),
            (
                ["باب", "بيبان", "قفل باب", "مسكة باب", "يد باب", "door"],
                ["door", "lock door", "handle door", "hinge door", "weatherstrip", "regulator window"]
            ),
            (
                ["مراية", "مرايا", "منظرة", "مناظر", "mirror"],
                ["mirror", "outside mirror", "rear view mirror", "mirror assy"]
            ),
            (
                ["قزاز", "زجاج", "جام", "دريشة", "قزازة", "glass", "window"],
                ["glass", "window", "windshield", "back door glass", "quarter glass", "regulator window"]
            ),
            (
                ["مساحات", "مساحة", "مسااحات", "wiper"],
                ["wiper", "blade wiper", "arm wiper", "motor wiper", "washer", "nozzle washer"]
            ),
            (
                ["طرمبة زيت", "مضخة زيت", "طمبة زيت", "oil pump"],
                ["oil pump", "pump oil", "strainer oil", "pan oil", "filter oil"]
            ),
            (
                ["ثروتل", "بوابة", "بوابة الهواء", "دعسة", "throttle"],
                ["throttle", "throttle chamber", "accelerator", "pedal accelerator", "cable accelerator"]
            ),
            (
                ["شكمان", "اكزوز", "دبة", "دبات", "exhaust"],
                ["exhaust", "muffler", "pipe exhaust", "catalyst", "hanger exhaust", "gasket exhaust"]
            ),
            (
                ["تانكي", "تنده", "خزان", "خزان بنزين", "fuel tank"],
                ["fuel tank", "tank fuel", "cap fuel", "hose fuel", "pipe fuel", "sender fuel"]
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
        var hitCount = 0
        for term in terms where term.count >= 3 && searchText.contains(term) {
            hitCount += 1
            if hitCount >= 4 { break }
        }
        guard hitCount > 0 else { return nil }
        return 80 + hitCount * 15
    }

    func isLikelyPartNumberLookup(_ rawQuery: String, normalizedQuery: String) -> Bool {
        guard normalizedQuery.count >= 5 else { return false }
        if !partNumberCandidates(in: rawQuery).isEmpty { return true }
        let latinTokens = rawQuery
            .uppercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { token in
                token.range(of: #"^[A-Z0-9]{5,14}$"#, options: .regularExpression) != nil
            }

        return latinTokens.contains { token in
            let hasDigit = token.contains(where: \.isNumber)
            let hasLatinLetter = token.contains { character in
                character >= "A" && character <= "Z"
            }
            guard hasDigit else { return false }
            return hasLatinLetter || token.count >= 7
        }
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
