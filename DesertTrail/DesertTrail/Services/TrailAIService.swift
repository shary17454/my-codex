import CoreLocation
import Foundation

struct TrailAIContext {
    var prompt: String
    var trip: TripPlan
    var hasSelectedTrip: Bool
    var hiddenPlaces: [HiddenPlace]
    var routes: [DirtRoadRoute]
    var weather: EnvironmentalReport
    var currentLocation: CLLocation?
}

struct TrailAIResponse {
    var title: String
    var answer: String
    var summary: String
    var matches: [TrailAISearchResult]
    var suggestions: [TrailAISuggestion]
    var alerts: [TrailAIAlert]
    var isLocalOnly: Bool = true
}

struct TrailAISearchResult: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var reason: String
    var coordinate: CLLocationCoordinate2D?
}

struct TrailAISuggestion: Identifiable {
    var id = UUID()
    var title: String
    var detail: String
    var icon: String
}

struct TrailAIAlert: Identifiable {
    enum Severity: String {
        case info = "معلومة"
        case warning = "تنبيه"
        case critical = "حرج"
    }

    var id = UUID()
    var title: String
    var detail: String
    var severity: Severity
}

struct TrailAIService {
    func answer(_ context: TrailAIContext) -> TrailAIResponse {
        let normalizedPrompt = normalize(context.prompt)
        let matches = search(prompt: normalizedPrompt, in: context)
        let alerts = buildAlerts(from: context)
        let suggestions = buildSuggestions(prompt: normalizedPrompt, context: context, matches: matches, alerts: alerts)
        let summary = summarize(context)
        let answer = buildAnswer(prompt: normalizedPrompt, context: context, matches: matches, alerts: alerts, suggestions: suggestions)

        return TrailAIResponse(
            title: title(for: normalizedPrompt),
            answer: answer,
            summary: summary,
            matches: matches,
            suggestions: suggestions,
            alerts: alerts
        )
    }

    private func search(prompt: String, in context: TrailAIContext) -> [TrailAISearchResult] {
        let keywords = Set(prompt.split(separator: " ").map(String.init).filter { $0.count > 2 })

        let placeMatches = context.hiddenPlaces
            .filter { place in
                place.status == .approved && score(place: place, prompt: prompt, keywords: keywords) > 0
            }
            .sorted { score(place: $0, prompt: prompt, keywords: keywords) > score(place: $1, prompt: prompt, keywords: keywords) }
            .prefix(5)
            .map { place in
                TrailAISearchResult(
                    id: "place-\(place.id.uuidString)",
                    title: place.name,
                    subtitle: "تقييم \(place.rating)/5 · \(place.notes)",
                    reason: "تطابق مع طلبك ومناسب للبحث داخل مواقع الدروب.",
                    coordinate: place.coordinate
                )
            }

        let routeMatches = context.routes
            .filter { route in
                score(route: route, prompt: prompt, keywords: keywords) > 0
            }
            .sorted { score(route: $0, prompt: prompt, keywords: keywords) > score(route: $1, prompt: prompt, keywords: keywords) }
            .prefix(4)
            .map { route in
                TrailAISearchResult(
                    id: "route-\(route.id)",
                    title: route.name,
                    subtitle: route.subtitle,
                    reason: "\(route.condition) \(route.recommendationText)",
                    coordinate: route.endCoordinate
                )
            }

        let combined = Array(placeMatches) + Array(routeMatches)
        if !combined.isEmpty {
            return combined
        }

        return fallbackResults(context: context)
    }

    private func buildSuggestions(
        prompt: String,
        context: TrailAIContext,
        matches: [TrailAISearchResult],
        alerts: [TrailAIAlert]
    ) -> [TrailAISuggestion] {
        var suggestions: [TrailAISuggestion] = []

        if let first = matches.first {
            suggestions.append(TrailAISuggestion(
                title: "ابدأ من \(first.title)",
                detail: "افتح الموقع على الخريطة وحدده كوجهة قبل الانطلاق.",
                icon: "map.fill"
            ))
        }

        if prompt.contains("عائل") || prompt.contains("سهل") {
            suggestions.append(TrailAISuggestion(
                title: "اختر مسارًا سهلًا",
                detail: "فضّل الطرق الترابية الممسوكة وتجنب بطون الأودية وقت الأمطار.",
                icon: "figure.2.and.child.holdinghands"
            ))
        }

        if context.weather.windSpeedKPH > 28 {
            suggestions.append(TrailAISuggestion(
                title: "خفف التعرض للغبار",
                detail: "الرياح مرتفعة؛ اجعل التوقفات في مناطق محمية وتجنب الحواف المكشوفة.",
                icon: "wind"
            ))
        }

        if context.weather.temperatureCelsius > 40 {
            suggestions.append(TrailAISuggestion(
                title: "انطلق بعد العصر",
                detail: "الحرارة مرتفعة؛ زد الماء وتجنب المشي الطويل وقت الظهيرة.",
                icon: "sun.max.fill"
            ))
        }

        if !context.hasSelectedTrip {
            suggestions.append(TrailAISuggestion(
                title: "أنشئ رحلة أولًا",
                detail: "بعد إنشاء رحلة يمكن للتطبيق تلخيص الوجهة وحساب المسافة والتوجيه.",
                icon: "calendar.badge.plus"
            ))
        }

        if alerts.contains(where: { $0.severity == .critical }) {
            suggestions.append(TrailAISuggestion(
                title: "راجع التنبيهات قبل التحرك",
                detail: "يوجد عامل خطر حرج في الطقس أو جودة الهواء يحتاج قرارًا واضحًا.",
                icon: "exclamationmark.triangle.fill"
            ))
        }

        return Array(suggestions.prefix(5))
    }

    private func buildAlerts(from context: TrailAIContext) -> [TrailAIAlert] {
        var alerts: [TrailAIAlert] = []

        if context.weather.isLiveData == false {
            alerts.append(TrailAIAlert(
                title: "الطقس غير محدث",
                detail: "شغّل الموقع أو حدّث الطقس قبل الاعتماد على توصيات الرحلة.",
                severity: .warning
            ))
        }

        if context.weather.temperatureCelsius >= 44 {
            alerts.append(TrailAIAlert(
                title: "حرارة عالية جدًا",
                detail: "زِد كمية الماء، قلل المشي، وتجنب الرحلات الطويلة في الظهيرة.",
                severity: .critical
            ))
        } else if context.weather.temperatureCelsius >= 39 {
            alerts.append(TrailAIAlert(
                title: "حرارة مرتفعة",
                detail: "خطط للتوقف في الظل وراقب الإجهاد الحراري.",
                severity: .warning
            ))
        }

        if context.weather.windSpeedKPH >= 35 {
            alerts.append(TrailAIAlert(
                title: "رياح قوية",
                detail: "قد تقل الرؤية ويزيد الغبار على الطرق الترابية.",
                severity: .critical
            ))
        } else if context.weather.windSpeedKPH >= 24 {
            alerts.append(TrailAIAlert(
                title: "رياح تحتاج انتباه",
                detail: "ثبّت الأمتعة وخفف السرعة في المناطق المفتوحة.",
                severity: .warning
            ))
        }

        if context.weather.isAirQualityAvailable && context.weather.airQualityIndex >= 151 {
            alerts.append(TrailAIAlert(
                title: "جودة هواء ضعيفة",
                detail: "تجنب النشاط الشاق لمن لديه حساسية أو ربو.",
                severity: .warning
            ))
        }

        if context.currentLocation == nil {
            alerts.append(TrailAIAlert(
                title: "الموقع غير متاح",
                detail: "المساعد يستخدم وجهة الرحلة والبيانات المخزنة حتى تفعّل الموقع.",
                severity: .info
            ))
        }

        return alerts
    }

    private func summarize(_ context: TrailAIContext) -> String {
        let destination = context.hasSelectedTrip ? context.trip.title : "لا توجد رحلة محددة"
        let route = context.hasSelectedTrip ? context.trip.routeName : "مسار غير محدد"
        let people = context.trip.participants.isEmpty ? "لا يوجد مشاركون" : "\(context.trip.participants.count) مشاركين"
        let weather = context.weather.isLiveData
            ? "\(Int(context.weather.temperatureCelsius))°C، رياح \(Int(context.weather.windSpeedKPH)) كم/س، AQI \(context.weather.airQualityDisplayText)"
            : "الطقس ينتظر التحديث"
        return "\(destination) · \(route) · \(people) · \(weather)"
    }

    private func buildAnswer(
        prompt: String,
        context: TrailAIContext,
        matches: [TrailAISearchResult],
        alerts: [TrailAIAlert],
        suggestions: [TrailAISuggestion]
    ) -> String {
        if prompt.isEmpty {
            return "اكتب طلبك مثل: أفضل مكان عائلي قريب، لخّص رحلتي، هل الطقس مناسب، أو اقترح مسار ترابي آمن."
        }

        if prompt.contains("لخص") || prompt.contains("ملخص") || prompt.contains("رحلتي") {
            return "ملخص الرحلة: \(summarize(context)). راجع التنبيهات قبل الانطلاق وحدّث الموقع والطقس إذا كانت البيانات قديمة."
        }

        if prompt.contains("خطر") || prompt.contains("سلام") || prompt.contains("طقس") || prompt.contains("غبار") {
            if alerts.isEmpty {
                return "لا توجد تنبيهات حرجة من البيانات الحالية. مع ذلك تحقق ميدانيًا من الطريق والطقس قبل الانطلاق."
            }
            return alerts.map { "\($0.title): \($0.detail)" }.joined(separator: "\n")
        }

        if let best = matches.first {
            let action = suggestions.first?.detail ?? "حدده كوجهة وراجع المسار قبل الانطلاق."
            return "أفضل نتيجة الآن: \(best.title). السبب: \(best.reason). الخطوة التالية: \(action)"
        }

        return "لم أجد نتيجة دقيقة من بيانات التطبيق الحالية. جرّب ذكر مدينة، وادي، جبل، عائلات، تخييم، رمل، أو دفع رباعي."
    }

    private func title(for prompt: String) -> String {
        if prompt.contains("لخص") || prompt.contains("ملخص") { return "ملخص ذكي" }
        if prompt.contains("خطر") || prompt.contains("سلام") || prompt.contains("طقس") { return "تقييم سلامة" }
        if prompt.contains("وين") || prompt.contains("مكان") || prompt.contains("اقترح") { return "اقتراح وجهة" }
        return "مساعد الدروب"
    }

    private func fallbackResults(context: TrailAIContext) -> [TrailAISearchResult] {
        context.hiddenPlaces
            .filter { $0.status == .approved }
            .sorted { $0.rating > $1.rating }
            .prefix(3)
            .map { place in
                TrailAISearchResult(
                    id: "fallback-\(place.id.uuidString)",
                    title: place.name,
                    subtitle: "تقييم \(place.rating)/5",
                    reason: "نتيجة مقترحة من أعلى المواقع تقييمًا عند عدم وجود تطابق مباشر.",
                    coordinate: place.coordinate
                )
            }
    }

    private func score(place: HiddenPlace, prompt: String, keywords: Set<String>) -> Int {
        let text = normalize("\(place.name) \(place.notes) \(place.contributor) \(place.imageSystemName)")
        var score = text.contains(prompt) && !prompt.isEmpty ? 8 : 0
        score += keywords.filter { text.contains($0) }.count * 2
        if prompt.contains("عائل") && (place.notes.contains("عائل") || place.rating >= 4) { score += 4 }
        if prompt.contains("جبل") && (place.name.contains("جبل") || place.notes.contains("صخر") || place.imageSystemName.contains("mountain")) { score += 4 }
        if prompt.contains("وادي") && (place.name.contains("وادي") || place.notes.contains("وادي") || place.imageSystemName.contains("water")) { score += 4 }
        if prompt.contains("رمل") && (place.name.contains("نفود") || place.name.contains("الدهناء") || place.notes.contains("رمل")) { score += 4 }
        return score
    }

    private func score(route: DirtRoadRoute, prompt: String, keywords: Set<String>) -> Int {
        let text = normalize("\(route.name) \(route.summary) \(route.surface.rawValue) \(route.difficulty.rawValue) \(route.condition)")
        var score = text.contains(prompt) && !prompt.isEmpty ? 8 : 0
        score += keywords.filter { text.contains($0) }.count * 2
        if prompt.contains("سهل") && route.difficulty == .easy { score += 4 }
        if prompt.contains("دفع") && route.requiresFourWheelDrive { score += 3 }
        if prompt.contains("رمل") && route.surface == .sand { score += 4 }
        if prompt.contains("وادي") && route.surface == .wadiBed { score += 4 }
        return score
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ar"))
    }
}
