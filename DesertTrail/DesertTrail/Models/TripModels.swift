import Foundation
import CoreLocation
import SwiftUI

struct TripPlan: Identifiable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var meetingPoint: CLLocationCoordinate2D
    var routeName: String
    var notes: String
    var participants: [String]

    var shareURL: URL {
        URL(string: "https://deserttrail.local/trip/\(id.uuidString)") ?? URL(fileURLWithPath: "/")
    }

    static let sample = TripPlan(
        id: UUID(uuidString: "7B3C61DA-A32B-4D89-B292-3014F8C62F68")!,
        title: "كشتة وادي مخفي",
        startDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
        endDate: Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now,
        meetingPoint: CLLocationCoordinate2D(latitude: 24.6028, longitude: 46.5535),
        routeName: "SampleRoute",
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
            routeName: "SampleRoute",
            notes: "مسار جبلي يحتاج فحص الإطارات قبل الانطلاق.",
            participants: ["أحمد", "ماجد"]
        ),
        TripPlan(
            id: UUID(uuidString: "34F43132-5273-487A-A947-8EA77A3AD0B4")!,
            title: "رحلة روضة خريم",
            startDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
            meetingPoint: CLLocationCoordinate2D(latitude: 25.3828, longitude: 47.2552),
            routeName: "SampleRoute",
            notes: "مناسبة للعائلات مع متابعة حالة الطقس.",
            participants: ["نورة", "سارة", "فهد"]
        )
    ]
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
        HiddenPlace(id: UUID(), name: "وادي حنيفة", coordinate: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730), rating: 5, imageSystemName: "water.waves", notes: "وادي معروف داخل الرياض، مناسب للتجربة والتوجيه.", status: .approved, contributor: "الدروب", points: 510),
        HiddenPlace(id: UUID(), name: "حافة العالم", coordinate: CLLocationCoordinate2D(latitude: 24.9530, longitude: 45.9960), rating: 5, imageSystemName: "mountain.2.fill", notes: "مطل صحراوي مرتفع، يحتاج سيارة مناسبة ومتابعة الرياح.", status: .approved, contributor: "الدروب", points: 870),
        HiddenPlace(id: UUID(), name: "روضة خريم", coordinate: CLLocationCoordinate2D(latitude: 25.3828, longitude: 47.2552), rating: 4, imageSystemName: "leaf.fill", notes: "منطقة ربيعية، تحقق من الأنظمة والتصاريح قبل الزيارة.", status: .approved, contributor: "الدروب", points: 430),
        HiddenPlace(id: UUID(), name: "جبل طويق", coordinate: CLLocationCoordinate2D(latitude: 24.5229, longitude: 46.2748), rating: 5, imageSystemName: "figure.hiking", notes: "تضاريس صخرية جميلة، انتبه للحواف والمنحدرات.", status: .approved, contributor: "الدروب", points: 620),
        HiddenPlace(id: UUID(), name: "نفود الثويرات", coordinate: CLLocationCoordinate2D(latitude: 26.0900, longitude: 44.1500), rating: 4, imageSystemName: "sun.horizon.fill", notes: "كثبان رملية واسعة، مناسبة للتطعيس مع تجهيزات سلامة.", status: .approved, contributor: "الدروب", points: 390),
        HiddenPlace(id: UUID(), name: "وادي الدواسر", coordinate: CLLocationCoordinate2D(latitude: 20.4630, longitude: 44.7890), rating: 4, imageSystemName: "mappin.and.ellipse", notes: "مساحات برية واسعة، خطط للوقود والماء قبل الانطلاق.", status: .approved, contributor: "الدروب", points: 350)
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
        temperatureCelsius: 34,
        airQualityIndex: 72,
        weatherSummary: "سماء صافية",
        windSpeedKPH: 18,
        windDirectionDegrees: 305,
        updatedAt: .now
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
