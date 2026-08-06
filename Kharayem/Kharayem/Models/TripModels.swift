import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Map defaults shown before the user's own location is available.
/// Every map opens on وادي الرشاء, then recenters on the device location once
/// the user grants access and GPS returns a fix.
enum MapDefaults {
    /// وادي الرشاء between عرجاء and نفي — where the valley crosses the
    /// نفي–الدوادمي road (24° 02.342' N, 44° 24.428' E).
    static let wadiAlRisha = CLLocationCoordinate2D(latitude: 24.0390, longitude: 44.4071)

    /// Valley-area view used on first launch.
    static var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: wadiAlRisha,
            span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
        )
    }
}

struct TripPlan: Identifiable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var meetingPoint: CLLocationCoordinate2D
    var routeName: String
    var notes: String
    var participants: [String]
    var status: TripLifecycleStatus = .planned
    var updatedAt: Date = .now

    var shareURL: URL {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(meetingPoint.latitude),\(meetingPoint.longitude)"),
            URLQueryItem(name: "q", value: title)
        ]
        guard let url = components?.url else { return URL(fileURLWithPath: "/") }
        return url
    }

    static let draft = TripPlan(
        id: UUID(uuidString: "B238B5D8-7074-42D0-97D2-03D8F1DA9A4D")!,
        title: "رحلة جديدة",
        startDate: .now,
        endDate: Calendar.current.date(byAdding: .hour, value: 8, to: .now) ?? .now,
        meetingPoint: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        routeName: "مسار مباشر",
        notes: "",
        participants: []
    )

    static let sample = TripPlan(
        id: UUID(uuidString: "7B3C61DA-A32B-4D89-B292-3014F8C62F68")!,
        title: "كشتة وادي مخفي",
        startDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
        endDate: Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now,
        meetingPoint: CLLocationCoordinate2D(latitude: 24.6028, longitude: 46.5535),
        routeName: "مسار مباشر",
        notes: "تجهيز ماء إضافي، جهاز ماجلان، وحطب آمن.",
        participants: ["سارة", "فهد", "نورة"]
    )

    static let samples: [TripPlan] = [
        sample,
        TripPlan(
            id: UUID(uuidString: "E73E4549-734E-4ED9-8B95-F1D22A3753A1")!,
            title: "مسار حافة طويق",
            startDate: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: 8, to: .now) ?? .now,
            meetingPoint: CLLocationCoordinate2D(latitude: 24.5229, longitude: 46.2748),
            routeName: "مسار مباشر",
            notes: "مسار جبلي يحتاج فحص الإطارات قبل الانطلاق.",
            participants: ["أحمد", "ماجد"]
        ),
        TripPlan(
            id: UUID(uuidString: "34F43132-5273-487A-A947-8EA77A3AD0B4")!,
            title: "رحلة روضة خريم",
            startDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
            meetingPoint: CLLocationCoordinate2D(latitude: 25.3828, longitude: 47.2552),
            routeName: "مسار مباشر",
            notes: "مناسبة للعائلات مع متابعة حالة الطقس.",
            participants: ["نورة", "سارة", "فهد"]
        )
    ]
}

enum TripLifecycleStatus: String, Codable, CaseIterable, Hashable {
    case planned
    case active
    case completed

    var title: String {
        switch self {
        case .planned: return "مخططة"
        case .active: return "جارية"
        case .completed: return "منتهية"
        }
    }

    var icon: String {
        switch self {
        case .planned: return "calendar"
        case .active: return "location.north.line.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .planned: return .desertCopper
        case .active: return .oasisTeal
        case .completed: return .green
        }
    }
}

struct HiddenPlace: Identifiable, Hashable {
    let id: UUID
    var name: String
    var coordinate: CLLocationCoordinate2D
    var rating: Int
    var imageSystemName: String
    var notes: String
    var status: ReviewStatus
    var contributor: String
    var points: Int

    static let samples: [HiddenPlace] = [
        HiddenPlace(id: UUID(), name: "مطل الحجر", coordinate: CLLocationCoordinate2D(latitude: 24.6352, longitude: 46.5927), rating: 5, imageSystemName: "mountain.2", notes: "إطلالة صخرية مناسبة للغروب.", status: .approved, contributor: "فهد", points: 320),
        HiddenPlace(id: UUID(), name: "فيضة الندى", coordinate: CLLocationCoordinate2D(latitude: 24.6180, longitude: 46.5720), rating: 4, imageSystemName: "leaf", notes: "أرض منبسطة بعد المطر، تحتاج سيارة دفع رباعي.", status: .approved, contributor: "نورة", points: 210),
        HiddenPlace(id: UUID(), name: "شعب السدر", coordinate: CLLocationCoordinate2D(latitude: 24.6088, longitude: 46.5615), rating: 3, imageSystemName: "camera.macro", notes: "موقع هادئ قيد التحقق.", status: .pending, contributor: "سارة", points: 84),
        HiddenPlace(id: UUID(), name: "وادي حنيفة", coordinate: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730), rating: 5, imageSystemName: "water.waves", notes: "وادي معروف داخل الرياض، مناسب للتجربة والتوجيه.", status: .approved, contributor: "خرايم", points: 510),
        HiddenPlace(id: UUID(), name: "حافة العالم", coordinate: CLLocationCoordinate2D(latitude: 24.9530, longitude: 45.9960), rating: 5, imageSystemName: "mountain.2.fill", notes: "مطل صحراوي مرتفع، يحتاج سيارة مناسبة ومتابعة الرياح.", status: .approved, contributor: "خرايم", points: 870),
        HiddenPlace(id: UUID(), name: "روضة خريم", coordinate: CLLocationCoordinate2D(latitude: 25.3828, longitude: 47.2552), rating: 4, imageSystemName: "leaf.fill", notes: "منطقة ربيعية، تحقق من الأنظمة والتصاريح قبل الزيارة.", status: .approved, contributor: "خرايم", points: 430),
        HiddenPlace(id: UUID(), name: "جبل طويق", coordinate: CLLocationCoordinate2D(latitude: 24.5229, longitude: 46.2748), rating: 5, imageSystemName: "figure.hiking", notes: "تضاريس صخرية جميلة، انتبه للحواف والمنحدرات.", status: .approved, contributor: "خرايم", points: 620),
        HiddenPlace(id: UUID(), name: "نفود الثويرات", coordinate: CLLocationCoordinate2D(latitude: 26.0900, longitude: 44.1500), rating: 4, imageSystemName: "sun.horizon.fill", notes: "كثبان رملية واسعة، مناسبة للتطعيس مع تجهيزات سلامة.", status: .approved, contributor: "خرايم", points: 390),
        HiddenPlace(id: UUID(), name: "وادي الدواسر", coordinate: CLLocationCoordinate2D(latitude: 20.4630, longitude: 44.7890), rating: 4, imageSystemName: "mappin.and.ellipse", notes: "مساحات برية واسعة، خطط للوقود والماء قبل الانطلاق.", status: .approved, contributor: "خرايم", points: 350),
        HiddenPlace(id: UUID(), name: "الدهناء", coordinate: CLLocationCoordinate2D(latitude: 24.7000, longitude: 47.9000), rating: 4, imageSystemName: "sun.max", notes: "حزام رملي طويل، يفضل دخول المسارات مع مركبة مناسبة ومرافقة.", status: .approved, contributor: "خرايم", points: 410),
        HiddenPlace(id: UUID(), name: "وادي الرمة", coordinate: CLLocationCoordinate2D(latitude: 26.0000, longitude: 43.8000), rating: 4, imageSystemName: "water.waves", notes: "مجرى واد واسع؛ تجنب بطون الأودية وقت السيول.", status: .approved, contributor: "خرايم", points: 455),
        HiddenPlace(id: UUID(), name: "جبال أجا", coordinate: CLLocationCoordinate2D(latitude: 27.5200, longitude: 41.6900), rating: 5, imageSystemName: "mountain.2.fill", notes: "سلسلة جبلية جرانيتية حول حائل، مناسبة للاستكشاف والتصوير.", status: .approved, contributor: "خرايم", points: 690),
        HiddenPlace(id: UUID(), name: "جبال سلمى", coordinate: CLLocationCoordinate2D(latitude: 27.2500, longitude: 42.1800), rating: 5, imageSystemName: "mountain.2", notes: "مرتفعات ومسارات برية شرق حائل، راقب الطقس والضباب.", status: .approved, contributor: "خرايم", points: 640),
        HiddenPlace(id: UUID(), name: "حرة خيبر", coordinate: CLLocationCoordinate2D(latitude: 25.6300, longitude: 39.7500), rating: 4, imageSystemName: "flame.fill", notes: "حرة بركانية وعرة؛ يحتاج المسار تجهيزات إطارات وماء كافية.", status: .approved, contributor: "خرايم", points: 560),
        HiddenPlace(id: UUID(), name: "حرة رهط", coordinate: CLLocationCoordinate2D(latitude: 23.0000, longitude: 39.7500), rating: 4, imageSystemName: "flame", notes: "مساحات حرة واسعة، حافظ على المسارات الواضحة وتجنب الحواف.", status: .approved, contributor: "خرايم", points: 500),
        HiddenPlace(id: UUID(), name: "وادي الديسة", coordinate: CLLocationCoordinate2D(latitude: 27.6500, longitude: 36.4500), rating: 5, imageSystemName: "water.waves", notes: "واد جبلي مميز في تبوك؛ قد تتغير حالة الطريق بعد الأمطار.", status: .approved, contributor: "خرايم", points: 760),
        HiddenPlace(id: UUID(), name: "جبال حسمي", coordinate: CLLocationCoordinate2D(latitude: 28.3000, longitude: 35.3000), rating: 5, imageSystemName: "mountain.2.fill", notes: "تكوينات صخرية ورملية شمال غرب المملكة، مناسبة للملاحة بالمعالم.", status: .approved, contributor: "خرايم", points: 720),
        HiddenPlace(id: UUID(), name: "السودة", coordinate: CLLocationCoordinate2D(latitude: 18.2700, longitude: 42.3700), rating: 5, imageSystemName: "cloud.fog.fill", notes: "مرتفعات عسير، انتبه للضباب والمنعطفات الحادة.", status: .approved, contributor: "خرايم", points: 610),
        HiddenPlace(id: UUID(), name: "جبال فيفاء", coordinate: CLLocationCoordinate2D(latitude: 17.2500, longitude: 43.1000), rating: 5, imageSystemName: "mountain.2", notes: "مدرجات جبلية وطرق متعرجة؛ القيادة الهادئة ضرورية.", status: .approved, contributor: "خرايم", points: 580),
        HiddenPlace(id: UUID(), name: "وادي لجب", coordinate: CLLocationCoordinate2D(latitude: 17.6000, longitude: 42.9500), rating: 5, imageSystemName: "water.waves", notes: "واد صخري ضيق؛ تجنب الدخول عند احتمالية الأمطار.", status: .approved, contributor: "خرايم", points: 670),
        HiddenPlace(id: UUID(), name: "جبل شدا", coordinate: CLLocationCoordinate2D(latitude: 19.8400, longitude: 41.3100), rating: 4, imageSystemName: "mountain.2.fill", notes: "جبل وكهوف في الباحة؛ تحقق من صلاحية الطريق قبل الصعود.", status: .approved, contributor: "خرايم", points: 520),
        HiddenPlace(id: UUID(), name: "جبل ورقان", coordinate: CLLocationCoordinate2D(latitude: 24.2100, longitude: 39.2700), rating: 4, imageSystemName: "mountain.2", notes: "مرتفع قرب المدينة، مناسب لرصد الاتجاهات والمعالم.", status: .approved, contributor: "خرايم", points: 470),
        HiddenPlace(id: UUID(), name: "وادي الفرع", coordinate: CLLocationCoordinate2D(latitude: 23.1500, longitude: 39.0500), rating: 4, imageSystemName: "leaf.fill", notes: "واد ومزارع جنوب المدينة؛ انتبه للطرق المحلية والعبارات.", status: .approved, contributor: "خرايم", points: 430),
        HiddenPlace(id: UUID(), name: "وادي وج", coordinate: CLLocationCoordinate2D(latitude: 21.3800, longitude: 40.4300), rating: 4, imageSystemName: "water.waves", notes: "معلم معروف في الطائف، يصلح كنقطة مرجعية داخل الخرائط.", status: .approved, contributor: "خرايم", points: 390),
        HiddenPlace(id: UUID(), name: "وادي بيشة", coordinate: CLLocationCoordinate2D(latitude: 19.9800, longitude: 42.6000), rating: 4, imageSystemName: "water.waves", notes: "مجرى واد واسع ومناطق زراعية؛ تجنب مجاري السيول.", status: .approved, contributor: "خرايم", points: 445),
        HiddenPlace(id: UUID(), name: "وادي نجران", coordinate: CLLocationCoordinate2D(latitude: 17.4900, longitude: 44.1300), rating: 4, imageSystemName: "water.waves", notes: "منطقة سد ووادي، راقب تعليمات الجهات المحلية.", status: .approved, contributor: "خرايم", points: 455),
        HiddenPlace(id: UUID(), name: "حرة كشب", coordinate: CLLocationCoordinate2D(latitude: 22.8300, longitude: 41.3500), rating: 4, imageSystemName: "flame.fill", notes: "منطقة فوهات وحرات، المسارات قد تكون وعرة جدًا.", status: .approved, contributor: "خرايم", points: 510),
        HiddenPlace(id: UUID(), name: "جبل القهر", coordinate: CLLocationCoordinate2D(latitude: 17.8700, longitude: 43.0800), rating: 5, imageSystemName: "mountain.2.fill", notes: "منحدرات وشعاب عالية، يحتاج المسار حذرًا وخبرة.", status: .approved, contributor: "خرايم", points: 590),
        HiddenPlace(id: UUID(), name: "يبرين", coordinate: CLLocationCoordinate2D(latitude: 23.2500, longitude: 49.0000), rating: 4, imageSystemName: "sun.horizon.fill", notes: "أطراف الربع الخالي؛ خطط للوقود والماء والاتصال مسبقًا.", status: .approved, contributor: "خرايم", points: 620),
        HiddenPlace(id: UUID(), name: "صحراء جبة", coordinate: CLLocationCoordinate2D(latitude: 28.0030, longitude: 40.9390), rating: 5, imageSystemName: "camera.macro", notes: "نفود وآثار ومعالم صحراوية شمال حائل.", status: .approved, contributor: "خرايم", points: 540),
        HiddenPlace(id: UUID(), name: "العلا", coordinate: CLLocationCoordinate2D(latitude: 26.6085, longitude: 37.9232), rating: 5, imageSystemName: "photo.on.rectangle.angled", notes: "جبال وتكوينات صخرية ومواقع أثرية؛ التزم بالمسارات المسموحة.", status: .approved, contributor: "خرايم", points: 830)
    ]
}

enum ReviewStatus: String {
    case pending
    case approved
    case rejected

    var tint: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

struct EnvironmentalReport: Hashable, Sendable {
    var temperatureCelsius: Double
    var airQualityIndex: Int
    var weatherSummary: String
    var windSpeedKPH: Double
    var windDirectionDegrees: Double
    var updatedAt: Date
    var isLiveData = true
    var isAirQualityAvailable = true

    var airQualityDisplayText: String {
        guard isAirQualityAvailable else { return "--" }
        return airQualityIndex > 500 ? "500+" : "\(max(0, airQualityIndex))"
    }

    func alertText(language: AppLanguage) -> String {
        if airQualityIndex > 150 {
            return LocalizedKey.poorAir.value(for: language)
        }
        if temperatureCelsius > 42 {
            return LocalizedKey.highHeat.value(for: language)
        }
        return LocalizedKey.goodConditions.value(for: language)
    }

    static let placeholder = EnvironmentalReport(
        temperatureCelsius: 0,
        airQualityIndex: 0,
        weatherSummary: "بانتظار تحديث الطقس",
        windSpeedKPH: 0,
        windDirectionDegrees: 0,
        updatedAt: .distantPast,
        isLiveData: false,
        isAirQualityAvailable: false
    )
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
