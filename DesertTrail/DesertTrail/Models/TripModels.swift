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
        HiddenPlace(id: UUID(), name: "شعب السدر", coordinate: CLLocationCoordinate2D(latitude: 24.6088, longitude: 46.5615), rating: 3, imageSystemName: "camera.macro", notes: "موقع هادئ قيد التحقق.", status: .pending, contributor: "سارة", points: 84)
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

struct EnvironmentalReport: Hashable {
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
