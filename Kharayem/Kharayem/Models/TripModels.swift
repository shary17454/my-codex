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

/// Reference facts for a named landmark (mountain, valley, lava field, dune sea).
///
/// Every figure is optional and every entry carries its `source`. A value is
/// listed ONLY when it is traceable to a named reference — an unknown figure is
/// left `nil` so the UI shows "غير متوفر" instead of an invented number. Field
/// navigation decisions get made on these numbers, so guessing is not an option.
struct GeoFacts: Hashable {
    /// نوع التضاريس: جبل، وادي، حرة، نفود…
    var landform: String?
    /// المنطقة الإدارية
    var region: String?
    /// الارتفاع عن سطح البحر (متر)
    var elevationMeters: Int?
    /// الارتفاع كنص — يُستخدم حين يكون الرقم مدى وليس قيمة واحدة
    var elevationText: String?
    /// الارتفاع عن السهل المحيط — الشموخ (متر)
    var prominenceMeters: Int?
    /// الطول (كم) — للأودية والسلاسل الجبلية
    var lengthKm: Int?
    /// العرض (كم) — نص لأنه غالبًا مدى وليس رقمًا واحدًا
    var widthText: String?
    /// المساحة (كم²) — للحرات والنفود
    var areaKm2: Int?
    /// ميزة بارزة تستحق الذكر
    var highlight: String?
    /// مصدر الأرقام
    var source: String?

    /// Verified figures keyed by landmark name.
    ///
    /// Coverage is deliberately partial: only landmarks whose figures were
    /// confirmed against a named reference appear here. Add more as they get
    /// sourced — never fill a gap with an estimate.
    static let reference: [String: GeoFacts] = [
        "وادي حنيفة": GeoFacts(
            landform: "وادي",
            region: "الرياض",
            lengthKm: 160,
            highlight: "أكبر أودية الرياض ويمر بوسط المدينة.",
            source: "سعوديبيديا"
        ),
        "جبل طويق": GeoFacts(
            landform: "سلسلة جبلية",
            region: "نجد (الرياض والقصيم)",
            lengthKm: 800,
            widthText: "10 – 20 كم",
            highlight: "حافة صخرية تمتد في وسط نجد، من أبرز معالم المملكة.",
            source: "وكالة الأنباء السعودية"
        ),
        "حرة رهط": GeoFacts(
            landform: "حرة بركانية",
            region: "المدينة المنورة – مكة المكرمة",
            areaKm2: 20_000,
            highlight: "أكبر حقل حمم بركانية في السعودية، يمتد من المدينة حتى وادي فاطمة.",
            source: "سعوديبيديا / ويكيبيديا"
        ),
        "السودة": GeoFacts(
            landform: "جبل",
            region: "عسير",
            elevationMeters: 3_015,
            highlight: "أعلى قمة في السعودية، وتبعد نحو 20 كم عن أبها.",
            source: "هيئة المساحة الجيولوجية السعودية"
        ),
        "وادي الرمة": GeoFacts(
            landform: "وادي",
            region: "المدينة المنورة – القصيم – الحدود الشمالية",
            lengthKm: 1_200,
            highlight: "من أطول أودية الجزيرة العربية؛ ينبع من حرة خيبر ويمتد بامتداد وادي الباطن.",
            source: "ويكيبيديا / سعوديبيديا"
        ),
        "وادي الرشاء": GeoFacts(
            landform: "وادي",
            region: "الرياض – القصيم",
            lengthKm: 205,
            highlight: "ينبع من جبل ثهلان ويصب في قاع الخرماء؛ متوسط انحداره 1.2 م/كم، ويمر بين عرجاء ونفي.",
            source: "ويكيبيديا"
        ),
        "جبال أجا": GeoFacts(
            landform: "سلسلة جبلية جرانيتية",
            region: "حائل",
            elevationMeters: 1_544,
            highlight: "أعلى قمم حائل؛ جرانيت وردي وأحمر شمال هضبة نجد.",
            source: "أمانة منطقة حائل"
        ),
        "جبل شدا": GeoFacts(
            landform: "جبل",
            region: "الباحة",
            elevationMeters: 2_202,
            highlight: "شدا الأعلى شمال شرق المخواة؛ الوصول للقمة سيرًا يستغرق نحو 4 ساعات.",
            source: "سعوديبيديا"
        ),
        "جبال فيفاء": GeoFacts(
            landform: "سلسلة جبلية",
            region: "جازان",
            elevationMeters: 1_814,
            highlight: "مدرجات زراعية وطرق متعرجة حادة.",
            source: "ويكيبيديا"
        ),
        "جبل القهر": GeoFacts(
            landform: "جبل",
            region: "جازان",
            elevationMeters: 2_041,
            highlight: "تكوينات صخرية فريدة ومنحدرات حادة.",
            source: "سعوديبيديا"
        ),
        "حافة العالم": GeoFacts(
            landform: "مطل / جرف صخري",
            region: "الرياض",
            prominenceMeters: 300,
            highlight: "جرف صخري ضمن حافة جبل طويق، يرتفع نحو 300 م عن السهل المحيط.",
            source: "ويكيبيديا"
        ),
        "حرة خيبر": GeoFacts(
            landform: "حرة بركانية",
            region: "المدينة المنورة",
            areaKm2: 14_600,
            highlight: "ثاني أكبر حرة في السعودية بعد حرة رهط.",
            source: "سعوديبيديا"
        ),
        "حرة كشب": GeoFacts(
            landform: "حرة بركانية",
            region: "مكة المكرمة",
            areaKm2: 5_892,
            highlight: "منطقة فوهات بركانية ومسارات وعرة.",
            source: "سعوديبيديا / ويكيبيديا"
        ),
        "الدهناء": GeoFacts(
            landform: "نفود رملي",
            region: "الرياض – الشرقية – القصيم",
            lengthKm: 1_200,
            widthText: "‏75 كم (متوسط)",
            highlight: "حزام رملي أحمر يمتد من جنوب شرق النفود الكبير حتى شمال الربع الخالي.",
            source: "ويكيبيديا"
        ),
        "وادي الدواسر": GeoFacts(
            landform: "وادي",
            region: "الرياض",
            lengthKm: 350,
            highlight: "مساحات برية واسعة؛ خطط للوقود والماء قبل الانطلاق.",
            source: "ويكيبيديا"
        ),
        "وادي بيشة": GeoFacts(
            landform: "وادي",
            region: "عسير",
            lengthKm: 350,
            highlight: "من المنبع إلى المصب، وقد يمتد نحو 100 كم إضافية داخل الرمال.",
            source: "المعرفة"
        ),
        "وادي نجران": GeoFacts(
            landform: "وادي",
            region: "نجران",
            lengthKm: 180,
            highlight: "تختلف المصادر بين 150 و180 كم. منطقة سد ووادٍ؛ راقب تعليمات الجهات المحلية.",
            source: "سعوديبيديا / جريدة المدينة"
        ),
        "وادي لجب": GeoFacts(
            landform: "وادي / مضيق صخري",
            region: "جازان",
            lengthKm: 11,
            highlight: "مضيق ضيق يمتد من الشمال إلى الجنوب؛ تجنب الدخول عند احتمالية الأمطار.",
            source: "سعوديبيديا"
        ),
        "وادي الديسة": GeoFacts(
            landform: "وادي جبلي",
            region: "تبوك",
            elevationMeters: 400,
            highlight: "يبعد نحو 220 كم عن تبوك؛ مضيق جبلي بمياه عذبة وأشجار الدوم.",
            source: "جريدة الجزيرة"
        ),
        "جبل ورقان": GeoFacts(
            landform: "جبل",
            region: "المدينة المنورة",
            elevationMeters: 2_393,
            highlight: "يُعد من أعلى جبال الحجاز؛ يقع جنوب غرب المدينة على نحو 70 كم من طريق الهجرة السريع.",
            source: "سعوديبيديا"
        ),
        "جبال حسمي": GeoFacts(
            landform: "هضبة وتكوينات صخرية",
            region: "تبوك",
            elevationText: "800 – 1,700 م",
            highlight: "هضبة تضم جبال السفينة والظهر والمحماش وغيرها؛ الارتفاع يتفاوت داخل الهضبة.",
            source: "سعوديبيديا"
        ),
        "جبال سلمى": GeoFacts(
            landform: "سلسلة جبلية",
            region: "حائل",
            elevationMeters: 1_300,
            lengthKm: 60,
            widthText: "‏12 كم",
            highlight: "تبعد نحو 60 كم عن مدينة حائل؛ ضمن نطاق سلمى جيوبارك.",
            source: "موسوعة كيوبيديا (نبذة جغرافية عن حائل)"
        ),
        "العلا": GeoFacts(
            landform: "جبال وتكوينات صخرية",
            region: "المدينة المنورة",
            elevationMeters: 700,
            highlight: "مواقع أثرية وتكوينات صخرية؛ الحِجر على بعد 22 كم شمال شرقها — التزم بالمسارات المسموحة.",
            source: "موضوع / ويكيبيديا"
        ),
        "روضة خريم": GeoFacts(
            landform: "روضة",
            region: "الرياض",
            areaKm2: 52,
            highlight: "أكبر روضة في المملكة (نحو 52.3 كم²)، ضمن محمية الإمام عبدالعزيز بن محمد الملكية — تحقق من الأنظمة والتصاريح.",
            source: "صحيفة سبق / الهيئة الملكية للمحميات"
        )
    ]

    /// Facts for a landmark. Returns an empty record (not `nil`) when nothing has
    /// been sourced, so the UI still renders the placeholder rows.
    static func forPlace(named name: String) -> GeoFacts {
        reference[name.trimmingCharacters(in: .whitespaces)] ?? GeoFacts()
    }

    /// True when at least one figure came from a named source.
    var hasSourcedData: Bool { source != nil }

    /// A single display line. `isVerified == false` means the figure was never
    /// sourced and is showing the "00" placeholder — the UI must mark it so a
    /// placeholder is never mistaken for a real measurement.
    struct Row: Hashable {
        let label: String
        let value: String
        let isVerified: Bool
    }

    /// Display rows. Elevation is always present — with its real figure when
    /// sourced, otherwise the "00" placeholder flagged as unverified.
    var rows: [Row] {
        var result: [Row] = []
        if let landform { result.append(Row(label: "نوع التضاريس", value: landform, isVerified: true)) }
        if let region { result.append(Row(label: "المنطقة", value: region, isVerified: true)) }

        if let elevationText {
            result.append(Row(label: "الارتفاع عن سطح البحر", value: elevationText, isVerified: true))
        } else if let elevationMeters {
            result.append(Row(label: "الارتفاع عن سطح البحر", value: "\(elevationMeters.formatted()) م", isVerified: true))
        } else {
            result.append(Row(label: "الارتفاع عن سطح البحر", value: "00", isVerified: false))
        }

        if let prominenceMeters {
            result.append(Row(label: "الارتفاع عن السهل المحيط", value: "\(prominenceMeters.formatted()) م", isVerified: true))
        }
        if let lengthKm { result.append(Row(label: "الطول", value: "\(lengthKm.formatted()) كم", isVerified: true)) }
        if let widthText { result.append(Row(label: "العرض", value: widthText, isVerified: true)) }
        if let areaKm2 { result.append(Row(label: "المساحة", value: "\(areaKm2.formatted()) كم²", isVerified: true)) }
        return result
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
        HiddenPlace(id: UUID(), name: "وادي الرشاء", coordinate: CLLocationCoordinate2D(latitude: 24.0390, longitude: 44.4071), rating: 5, imageSystemName: "water.waves", notes: "الوادي بين عرجاء ونفي عند تقاطعه مع طريق نفي - الدوادمي؛ منطقة برية مفتوحة.", status: .approved, contributor: "خرايم", points: 480),
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
