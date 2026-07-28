import CoreLocation
import Foundation
import SwiftUI

enum RiskSeverity: String, CaseIterable, Identifiable {
    case advisory
    case warning
    case critical

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .advisory: return .oasisTeal
        case .warning: return .orange
        case .critical: return .red
        }
    }

    var title: String {
        switch self {
        case .advisory: return "تنبيه"
        case .warning: return "تحذير"
        case .critical: return "خطر"
        }
    }
}

struct RiskAlert: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var severity: RiskSeverity
    var distanceKilometers: Double
    var icon: String

    static let samples: [RiskAlert] = [
        RiskAlert(title: "رياح قوية", detail: "الرياح المتوقعة أعلى من 45 كم/س. ثبّت المخيم وتجنب الشعاب المكشوفة.", severity: .warning, distanceKilometers: 18, icon: "wind"),
        RiskAlert(title: "مسار رملي ناعم", detail: "الطريق القادم يحتاج تخفيض ضغط الإطارات وسيارة دفع رباعي.", severity: .advisory, distanceKilometers: 6, icon: "road.lanes"),
        RiskAlert(title: "احتمال سيول", detail: "ابتعد عن بطون الأودية وتحقق من مسار الرجوع قبل الغروب.", severity: .critical, distanceKilometers: 31, icon: "cloud.heavyrain")
    ]
}

struct OfflineRegionPack: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var size: String
    var progress: Double
    var isDownloaded: Bool

    static let samples: [OfflineRegionPack] = [
        OfflineRegionPack(name: "منطقة الرياض", size: "1.8 GB", progress: 1, isDownloaded: true),
        OfflineRegionPack(name: "القصيم", size: "940 MB", progress: 0.42, isDownloaded: false),
        OfflineRegionPack(name: "حائل", size: "1.1 GB", progress: 0, isDownloaded: false),
        OfflineRegionPack(name: "عسير", size: "1.5 GB", progress: 0, isDownloaded: false),
        OfflineRegionPack(name: "الربع الخالي", size: "2.4 GB", progress: 0.18, isDownloaded: false)
    ]
}

struct NearbyService: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var category: String
    var distanceKilometers: Double
    var icon: String

    static let samples: [NearbyService] = [
        NearbyService(name: "محطة وقود الدائري", category: "وقود", distanceKilometers: 12.4, icon: "fuelpump"),
        NearbyService(name: "ورشة الرحلات", category: "ورشة", distanceKilometers: 18.9, icon: "wrench.and.screwdriver"),
        NearbyService(name: "مركز إسعاف قريب", category: "إسعاف", distanceKilometers: 26.1, icon: "cross.case"),
        NearbyService(name: "مسجد الطريق", category: "مسجد", distanceKilometers: 8.7, icon: "moon.stars"),
        NearbyService(name: "نقطة تخييم آمنة", category: "تخييم", distanceKilometers: 5.2, icon: "tent")
    ]
}

struct PackingItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var category: String
    var isChecked: Bool

    static let samples: [PackingItem] = [
        PackingItem(title: "مياه كافية", category: "أساسيات", isChecked: true),
        PackingItem(title: "وقود احتياطي", category: "المركبة", isChecked: false),
        PackingItem(title: "إطار احتياطي", category: "المركبة", isChecked: true),
        PackingItem(title: "كمبروسر هواء", category: "المركبة", isChecked: false),
        PackingItem(title: "حبال سحب", category: "السلامة", isChecked: false),
        PackingItem(title: "إسعافات أولية", category: "السلامة", isChecked: true),
        PackingItem(title: "طفاية حريق", category: "السلامة", isChecked: false),
        PackingItem(title: "خيمة وأدوات طبخ", category: "المخيم", isChecked: false)
    ]
}

struct RouteCondition: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var terrain: String
    var difficulty: String
    var lastUpdate: String
    var icon: String

    static let samples: [RouteCondition] = [
        RouteCondition(title: "طريق وادي مخفي", terrain: "وادي ورمال", difficulty: "يحتاج دفع رباعي", lastUpdate: "قبل 35 دقيقة", icon: "car.2"),
        RouteCondition(title: "مطل الحجر", terrain: "صخور وجبال", difficulty: "متوسط", lastUpdate: "قبل ساعتين", icon: "mountain.2"),
        RouteCondition(title: "فيضة الندى", terrain: "أرض طينية بعد المطر", difficulty: "صعب", lastUpdate: "اليوم", icon: "drop")
    ]
}

enum DirtRoadDifficulty: String, CaseIterable, Identifiable {
    case easy = "سهل"
    case moderate = "متوسط"
    case technical = "يتطلب دفع رباعي"
    case avoid = "تجنب حاليًا"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .easy: return .green
        case .moderate: return .orange
        case .technical: return .desertCopper
        case .avoid: return .red
        }
    }

    var score: Int {
        switch self {
        case .easy: return 1
        case .moderate: return 2
        case .technical: return 3
        case .avoid: return 8
        }
    }
}

struct DirtRoadRoute: Identifiable {
    enum Surface: String, CaseIterable, Identifiable {
        case compactDirt = "ترابي ممسوك"
        case gravel = "حصى"
        case sand = "رمل"
        case wadiBed = "بطن وادي"
        case rocky = "صخري"

        var id: String { rawValue }
    }

    var id: String
    var name: String
    var summary: String
    var surface: Surface
    var difficulty: DirtRoadDifficulty
    var condition: String
    var lastUpdated: String
    var distanceKilometers: Double
    var estimatedMinutes: Int
    var requiresFourWheelDrive: Bool
    var coordinates: [CLLocationCoordinate2D]

    var startCoordinate: CLLocationCoordinate2D { coordinates.first ?? CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730) }
    var endCoordinate: CLLocationCoordinate2D { coordinates.last ?? startCoordinate }

    var subtitle: String {
        "\(surface.rawValue) • \(difficulty.rawValue) • \(String(format: "%.1f", distanceKilometers)) كم"
    }

    var recommendationText: String {
        switch difficulty {
        case .easy:
            return "مناسب لمعظم السيارات عند جفاف الطريق."
        case .moderate:
            return "افحص ضغط الإطارات وخذ مسار رجعة احتياطي."
        case .technical:
            return "يفضل دفع رباعي وخبرة قيادة برية."
        case .avoid:
            return "لا ينصح به الآن إلا بعد تحديث الحالة ميدانيًا."
        }
    }

    func proximityScore(to destination: CLLocationCoordinate2D) -> Double {
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let nearestMeters = coordinates
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: destinationLocation) }
            .min() ?? .greatestFiniteMagnitude
        return nearestMeters / 1_000 + Double(difficulty.score * 3)
    }

    static func nearestRoutes(to destination: CLLocationCoordinate2D, limit: Int = 3) -> [DirtRoadRoute] {
        samples
            .sorted { $0.proximityScore(to: destination) < $1.proximityScore(to: destination) }
            .prefix(limit)
            .map { $0 }
    }

    static func route(withID id: String?) -> DirtRoadRoute? {
        guard let id else { return nil }
        return samples.first { $0.id == id }
    }

    static let samples: [DirtRoadRoute] = [
        DirtRoadRoute(
            id: "wadi-hanifah-ridge",
            name: "درب وادي حنيفة العلوي",
            summary: "مسار ترابي محاذٍ للوادي مع مخارج قريبة للطرق المعبدة.",
            surface: .compactDirt,
            difficulty: .easy,
            condition: "مناسب بعد الجفاف، انتبه للمشاة والدراجات قرب المتنزهات.",
            lastUpdated: "تحديث مجتمعي اليوم",
            distanceKilometers: 18.4,
            estimatedMinutes: 34,
            requiresFourWheelDrive: false,
            coordinates: [
                CLLocationCoordinate2D(latitude: 24.5840, longitude: 46.5400),
                CLLocationCoordinate2D(latitude: 24.5965, longitude: 46.5520),
                CLLocationCoordinate2D(latitude: 24.6120, longitude: 46.5660),
                CLLocationCoordinate2D(latitude: 24.6275, longitude: 46.5790),
                CLLocationCoordinate2D(latitude: 24.6460, longitude: 46.5960)
            ]
        ),
        DirtRoadRoute(
            id: "hidden-overlook-loop",
            name: "لفة المطل الحجري",
            summary: "طريق حصوي صاعد إلى مطلات صخرية مع انحدارات قصيرة.",
            surface: .gravel,
            difficulty: .moderate,
            condition: "حصى ظاهر وحفر متفرقة، مناسب نهارًا فقط عند الرؤية الجيدة.",
            lastUpdated: "قبل ساعتين",
            distanceKilometers: 12.7,
            estimatedMinutes: 29,
            requiresFourWheelDrive: false,
            coordinates: [
                CLLocationCoordinate2D(latitude: 24.6180, longitude: 46.5660),
                CLLocationCoordinate2D(latitude: 24.6260, longitude: 46.5530),
                CLLocationCoordinate2D(latitude: 24.6390, longitude: 46.5460),
                CLLocationCoordinate2D(latitude: 24.6500, longitude: 46.5580)
            ]
        ),
        DirtRoadRoute(
            id: "sandy-wadi-bypass",
            name: "تحويلة الوادي الرملية",
            summary: "بديل أقصر يمر ببطن وادي رملي؛ استخدمه فقط مع دفع رباعي.",
            surface: .wadiBed,
            difficulty: .technical,
            condition: "رمال ناعمة بعد المنعطف الثاني واحتمال تغريز عند الحرارة العالية.",
            lastUpdated: "قبل 35 دقيقة",
            distanceKilometers: 9.6,
            estimatedMinutes: 38,
            requiresFourWheelDrive: true,
            coordinates: [
                CLLocationCoordinate2D(latitude: 24.5950, longitude: 46.5900),
                CLLocationCoordinate2D(latitude: 24.6040, longitude: 46.5810),
                CLLocationCoordinate2D(latitude: 24.6150, longitude: 46.5730),
                CLLocationCoordinate2D(latitude: 24.6250, longitude: 46.5630)
            ]
        ),
        DirtRoadRoute(
            id: "flood-risk-cut",
            name: "مقطع السيل المنخفض",
            summary: "طريق قريب لكنه منخفض ويتأثر بسرعة عند جريان الشعاب.",
            surface: .sand,
            difficulty: .avoid,
            condition: "يُتجنب عند توقع المطر أو بعد السيول حتى لو بدا جافًا.",
            lastUpdated: "تنبيه طقس نشط",
            distanceKilometers: 7.9,
            estimatedMinutes: 32,
            requiresFourWheelDrive: true,
            coordinates: [
                CLLocationCoordinate2D(latitude: 24.6070, longitude: 46.5350),
                CLLocationCoordinate2D(latitude: 24.6155, longitude: 46.5440),
                CLLocationCoordinate2D(latitude: 24.6230, longitude: 46.5520)
            ]
        )
    ]
}

struct WildlifeGuideItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var detail: String
    var season: String
    var icon: String

    static let plants: [WildlifeGuideItem] = [
        WildlifeGuideItem(name: "الخزامى", detail: "نبات عطري يظهر بعد الأمطار في المناطق الرملية.", season: "الربيع", icon: "camera.macro"),
        WildlifeGuideItem(name: "الرمث", detail: "ينتشر في البيئات الصحراوية ويستخدم كعلامة على المراعي.", season: "طوال العام", icon: "leaf"),
        WildlifeGuideItem(name: "العرفج", detail: "نبات بري معروف في نجد ويكثر بعد الوسم.", season: "الشتاء والربيع", icon: "tree")
    ]

    static let animals: [WildlifeGuideItem] = [
        WildlifeGuideItem(name: "المها العربي", detail: "مشاهدته تكون غالبًا في المحميات والمناطق المفتوحة.", season: "طوال العام", icon: "binoculars"),
        WildlifeGuideItem(name: "الوعل", detail: "يرتبط بالمناطق الجبلية والمرتفعات الوعرة.", season: "طوال العام", icon: "mountain.2"),
        WildlifeGuideItem(name: "الأرنب البري", detail: "ينشط غالبًا في الصباح الباكر وقبل الغروب.", season: "طوال العام", icon: "pawprint")
    ]
}

enum WildlifeDangerLevel: String, CaseIterable, Identifiable {
    case low = "منخفض"
    case medium = "متوسط"
    case high = "مرتفع"
    case critical = "حرج"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .low: return .oasisTeal
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

enum WildlifeActivityPeriod: String, CaseIterable, Identifiable {
    case day = "نهاري"
    case night = "ليلي"
    case both = "نهاري وليلي"

    var id: String { rawValue }
}

struct WildlifeSpeciesProfile: Identifiable, Hashable {
    let id = UUID()
    var arabicName: String
    var scientificName: String
    var imageName: String
    var dangerLevel: WildlifeDangerLevel
    var isVenomous: Bool
    var identification: String
    var distribution: String
    var habitat: String
    var activeSeason: String
    var activityPeriod: WildlifeActivityPeriod
    var viewingAdvice: String
    var firstAid: [String]
    var emergencyNumbers: String

    static let samples: [WildlifeSpeciesProfile] = [
        WildlifeSpeciesProfile(arabicName: "الثعبان الأسود الصحراوي", scientificName: "Walterinnesia aegyptia", imageName: "snake", dangerLevel: .critical, isVenomous: true, identification: "لون داكن يميل للسواد، جسم أسطواني، ويتحرك غالبًا ليلًا قرب الجحور والشقوق.", distribution: "مناطق صحراوية وصخرية متفرقة في الجزيرة العربية.", habitat: "الشعاب، الحرات، الجحور، أطراف الأودية، والمناطق قليلة الإزعاج.", activeSeason: "الربيع والصيف، ويزيد النشاط بعد الدفء.", activityPeriod: .night, viewingAdvice: "لا تقترب ولا تحاول الإمساك به. ابتعد ببطء وأبعد الأطفال والحيوانات الأليفة.", firstAid: ["ثبّت المصاب وقلل الحركة.", "لا تشق موضع اللدغة ولا تمص السم.", "أزل الخواتم أو الأحذية الضيقة.", "اتصل بالإسعاف واتجه لأقرب منشأة طبية."], emergencyNumbers: "السعودية: الإسعاف 997، والطوارئ الموحدة 911 حيث تتوفر الخدمة."),
        WildlifeSpeciesProfile(arabicName: "أفعى الرمل", scientificName: "Cerastes gasperettii", imageName: "waveform.path.ecg.rectangle", dangerLevel: .high, isVenomous: true, identification: "لون رملي وتمويه قوي، وقد يظهر جزء من الرأس فقط فوق الرمل.", distribution: "الكثبان والمناطق الرملية في وسط وشرق وشمال المملكة والخليج.", habitat: "الرمال الناعمة، أطراف النفود، والمناطق ذات الشجيرات المتناثرة.", activeSeason: "الربيع والصيف وبداية الخريف.", activityPeriod: .night, viewingAdvice: "استخدم كشافًا ليلًا وارتد حذاءً عاليًا، ولا تمشِ حافيًا قرب المخيم.", firstAid: ["أبقِ الطرف المصاب منخفض الحركة.", "صوّر الثعبان من مسافة آمنة إن أمكن.", "لا تستخدم الرباط الضاغط الشديد.", "اطلب رعاية طبية فورًا."], emergencyNumbers: "الإسعاف 997، الدفاع المدني 998 عند وجود خطر حول المخيم."),
        WildlifeSpeciesProfile(arabicName: "العقرب الأصفر", scientificName: "Leiurus quinquestriatus", imageName: "ant", dangerLevel: .high, isVenomous: true, identification: "لون أصفر فاتح وذيل رفيع نسبيًا، يختبئ تحت الصخور والأخشاب.", distribution: "واسع الانتشار في البيئات الصحراوية والجافة.", habitat: "تحت الحجارة، الشقوق، أكوام الحطب، وأطراف المخيمات.", activeSeason: "يزداد صيفًا ومع الليالي الدافئة.", activityPeriod: .night, viewingAdvice: "افحص الحذاء والبطانيات قبل الاستخدام، ولا ترفع الصخور باليد مباشرة.", firstAid: ["نظف مكان اللدغة بالماء والصابون.", "استخدم كمادات باردة غير مباشرة.", "راقب التنفس والحساسية.", "اتصل بالإسعاف خصوصًا للأطفال وكبار السن."], emergencyNumbers: "الإسعاف 997، والطوارئ الموحدة 911 حيث تتوفر الخدمة."),
        WildlifeSpeciesProfile(arabicName: "العنكبوت الأرملة", scientificName: "Latrodectus spp.", imageName: "circle.hexagongrid", dangerLevel: .medium, isVenomous: true, identification: "جسم داكن وعلامات حمراء أو برتقالية في بعض الأنواع، يعيش في الزوايا الهادئة.", distribution: "قد يوجد قرب المخلفات، الحظائر، والأماكن المهجورة.", habitat: "تحت الأخشاب، الزوايا المظلمة، وبين المعدات المتروكة.", activeSeason: "طوال العام ويزداد في الدفء.", activityPeriod: .night, viewingAdvice: "ارتد قفازات عند ترتيب الحطب أو المعدات القديمة.", firstAid: ["اغسل موضع اللدغة.", "راقب الألم والتشنجات.", "لا تضغط موضع اللدغة بعنف.", "راجع الطبيب عند ظهور أعراض عامة."], emergencyNumbers: "الإسعاف 997 عند ظهور ألم شديد أو أعراض حساسية."),
        WildlifeSpeciesProfile(arabicName: "الذئب العربي", scientificName: "Canis lupus arabs", imageName: "pawprint", dangerLevel: .medium, isVenomous: false, identification: "كلبي نحيل، لون رملي إلى رمادي، يتحرك منفردًا أو ضمن مجموعات صغيرة.", distribution: "مناطق جبلية وصحراوية متفرقة في الجزيرة العربية.", habitat: "الجبال، الحرات، الأودية، والمناطق البعيدة عن التجمعات.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تطعمه ولا تترك بقايا الطعام مكشوفة. حافظ على مسافة آمنة.", firstAid: ["عند عضة حيوان بري اغسل الجرح جيدًا.", "غط الجرح بضماد نظيف.", "راجع أقرب مركز طبي لتقييم اللقاحات.", "أبلغ الجهات المختصة عند وجود خطر متكرر."], emergencyNumbers: "الإسعاف 997، والمركز الوطني لتنمية الحياة الفطرية عبر قنواته الرسمية."),
        WildlifeSpeciesProfile(arabicName: "الضبع المخطط", scientificName: "Hyaena hyaena", imageName: "pawprint.circle", dangerLevel: .medium, isVenomous: false, identification: "جسم مائل للانحدار للخلف، خطوط داكنة، ورأس قوي.", distribution: "مناطق جبلية وحرات وأودية بعيدة.", habitat: "الكهوف، الشعاب، والمرتفعات الهادئة.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تلاحقه ولا تحاول تصويره من قرب، وأغلق مخلفات الطعام جيدًا.", firstAid: ["ابتعد عن الحيوان بهدوء.", "عند إصابة أو عضة، نظف الجرح واطلب المساعدة الطبية.", "وثق الموقع من مسافة آمنة فقط."], emergencyNumbers: "الإسعاف 997 عند الإصابات، والجهة البيئية المختصة عند البلاغات."),
        WildlifeSpeciesProfile(arabicName: "الضب", scientificName: "Uromastyx aegyptia", imageName: "lizard", dangerLevel: .low, isVenomous: false, identification: "زاحف صحراوي بجسم عريض وذيل شوكي قصير نسبيًا.", distribution: "السهول الرملية والحصوية في مناطق واسعة من المملكة والخليج.", habitat: "الجحور المفتوحة في الأراضي الرملية المستوية.", activeSeason: "الربيع والصيف.", activityPeriod: .day, viewingAdvice: "راقبه من بعيد ولا تحفر الجحور أو تزعج الكائنات البرية.", firstAid: ["لا توجد إسعافات خاصة عادة، لكن عضة أي حيوان تستدعي تنظيف الجرح ومراقبته."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "الورل الصحراوي", scientificName: "Varanus griseus", imageName: "lizard.fill", dangerLevel: .medium, isVenomous: false, identification: "زاحف كبير نسبيًا، رقبة طويلة، وذيل طويل يتحرك بسرعة عند الخطر.", distribution: "صحارى وسهول حصوية ورملية.", habitat: "الجحور، أطراف الأودية، والمناطق المفتوحة.", activeSeason: "الربيع والصيف.", activityPeriod: .day, viewingAdvice: "لا تحاصره؛ قد يعض دفاعًا عن نفسه. اترك له طريقًا للابتعاد.", firstAid: ["نظف أي جرح جيدًا.", "راجع الطبيب عند عضة عميقة أو تورم.", "راقب علامات العدوى."], emergencyNumbers: "الإسعاف 997 عند الإصابات الشديدة."),
        WildlifeSpeciesProfile(arabicName: "الكوبرا العربية", scientificName: "Naja arabica", imageName: "exclamationmark.triangle.fill", dangerLevel: .critical, isVenomous: true, identification: "ثعبان سام يرفع مقدمة الجسم عند التهديد وقد يفرد القلنسوة، ويتطلب مسافة أمان كبيرة.", distribution: "جنوب غرب الجزيرة العربية والمناطق الجبلية والأودية الدافئة.", habitat: "الأودية الزراعية، الشعاب الرطبة نسبيًا، وحواف التجمعات المائية.", activeSeason: "الربيع والصيف والخريف.", activityPeriod: .both, viewingAdvice: "ابتعد فورًا ولا تحاول التصوير من قرب أو المطاردة. أبعد الناس عن المسار.", firstAid: ["ثبّت المصاب وقلل الحركة.", "لا تضع الثلج مباشرة ولا تستخدم الشفط.", "انقل المصاب للمستشفى فورًا.", "اتصل بالإسعاف 997."], emergencyNumbers: "الإسعاف 997 والطوارئ الموحدة 911 حيث تتوفر الخدمة."),
        WildlifeSpeciesProfile(arabicName: "الأفعى المقرنة", scientificName: "Cerastes cerastes / gasperettii", imageName: "waveform.path.ecg", dangerLevel: .high, isVenomous: true, identification: "لون رملي وقرون صغيرة فوق العينين في بعض الأفراد، وتدفن نفسها جزئيًا في الرمل.", distribution: "الكثبان والسهول الرملية في الجزيرة العربية.", habitat: "الرمال الناعمة، أطراف النفود، ومناطق الشجيرات المنخفضة.", activeSeason: "الربيع والصيف.", activityPeriod: .night, viewingAdvice: "لا تمشِ ليلًا دون إنارة، وافحص محيط المخيم قبل الجلوس.", firstAid: ["قلل حركة الطرف المصاب.", "انزع الخواتم والساعات.", "لا تستخدم رباطًا شديدًا.", "اطلب علاجًا طبيًا عاجلًا."], emergencyNumbers: "الإسعاف 997."),
        WildlifeSpeciesProfile(arabicName: "أفعى السجاد المنشارية", scientificName: "Echis coloratus", imageName: "bolt.trianglebadge.exclamationmark.fill", dangerLevel: .critical, isVenomous: true, identification: "أفعى صغيرة إلى متوسطة، تتحرك بسرعة وقد تصدر احتكاكًا عند التهديد.", distribution: "المناطق الصخرية والجبلية والحرات في غرب وشمال غرب الجزيرة العربية.", habitat: "الشعاب الصخرية، سفوح الجبال، ومجاري السيول الجافة.", activeSeason: "الربيع والصيف.", activityPeriod: .night, viewingAdvice: "لا تضع اليد بين الصخور ولا ترفع الحجارة مباشرة.", firstAid: ["اتصل بالإسعاف فورًا.", "ثبّت المصاب وقلل الحركة.", "لا تشق موضع اللدغة.", "توجه لمركز طبي يملك مضادات سموم."], emergencyNumbers: "الإسعاف 997."),
        WildlifeSpeciesProfile(arabicName: "ثعبان الدفان", scientificName: "Eryx jayakari", imageName: "circle.grid.cross", dangerLevel: .low, isVenomous: false, identification: "ثعبان قصير وغليظ نسبيًا، يدفن نفسه في الرمل ولا يملك سمًا طبيًا مهمًا.", distribution: "المناطق الرملية في المملكة والخليج.", habitat: "الكثبان والرمال الناعمة.", activeSeason: "الربيع والصيف.", activityPeriod: .night, viewingAdvice: "اتركه وشأنه ولا تمسكه حتى لو كان غير سام.", firstAid: ["نظف أي خدش أو عضة.", "راقب علامات التهاب الجلد."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "ثعبان أبو السيور", scientificName: "Psammophis schokari", imageName: "line.diagonal", dangerLevel: .low, isVenomous: false, identification: "ثعبان رشيق وسريع، خطوط طولية واضحة، وغالبًا يتجنب الإنسان.", distribution: "الأراضي المفتوحة والسهول حول الجزيرة العربية.", habitat: "البراري، أطراف المزارع، والمناطق الرملية والحصوية.", activeSeason: "الربيع والصيف.", activityPeriod: .day, viewingAdvice: "لا تطارده؛ ابتعد واترك له طريقًا للهروب.", firstAid: ["اغسل أي عضة بالماء والصابون.", "راجع الطبيب عند تورم أو ألم مستمر."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "العقرب أسود الذيل", scientificName: "Androctonus crassicauda", imageName: "ant.fill", dangerLevel: .high, isVenomous: true, identification: "عقرب داكن قوي الذيل، يختبئ في الشقوق وتحت الصخور.", distribution: "ينتشر في بيئات صحراوية وصخرية متعددة.", habitat: "الصخور، الجحور، أكوام الحطب، والمباني المهجورة.", activeSeason: "الصيف والليالي الدافئة.", activityPeriod: .night, viewingAdvice: "استخدم قفازات عند نقل الحطب وافحص الأحذية قبل لبسها.", firstAid: ["اغسل مكان اللدغة.", "راقب الألم والتنفس.", "لا تربط الطرف بشدة.", "راجع الطوارئ خصوصًا للأطفال."], emergencyNumbers: "الإسعاف 997."),
        WildlifeSpeciesProfile(arabicName: "العقرب العربي سميك الذيل", scientificName: "Androctonus spp.", imageName: "ant.circle.fill", dangerLevel: .high, isVenomous: true, identification: "ذيل عريض نسبيًا وكلابات متوسطة، وينشط حول الصخور ليلًا.", distribution: "مناطق جافة وصخرية في الجزيرة العربية.", habitat: "الحرات، الشعاب، وحواف المخيمات.", activeSeason: "الربيع والصيف.", activityPeriod: .night, viewingAdvice: "لا تجلس مباشرة على الأرض دون فحص، ولا تترك ملابس على الرمل.", firstAid: ["برّد الموضع بكمادة غير مباشرة.", "راقب أعراض الحساسية.", "اطلب إسعافًا عند ألم شديد أو تنميل عام."], emergencyNumbers: "الإسعاف 997."),
        WildlifeSpeciesProfile(arabicName: "الأرملة السوداء", scientificName: "Latrodectus tredecimguttatus", imageName: "circle.hexagongrid.fill", dangerLevel: .medium, isVenomous: true, identification: "عنكبوت داكن مع علامات حمراء، ويبني شبكًا غير منتظم في الأماكن الهادئة.", distribution: "متفرق قرب الحظائر والمخلفات والأماكن المهجورة.", habitat: "الزوايا المظلمة، الأخشاب، المعدات القديمة.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "ارتد قفازات عند تحريك المعدات ولا تلمس الشبك بيدك.", firstAid: ["اغسل اللدغة.", "راقب التشنجات والألم.", "راجع الطبيب عند ألم منتشر أو أعراض عامة."], emergencyNumbers: "الإسعاف 997 عند الأعراض الشديدة."),
        WildlifeSpeciesProfile(arabicName: "الجمل العربي", scientificName: "Camelus dromedarius", imageName: "mountain.2.fill", dangerLevel: .medium, isVenomous: false, identification: "حيوان كبير مألوف في البر، وقد يكون عدوانيًا عند الخوف أو قرب الصغار.", distribution: "الصحارى والطرق البرية والمراعي.", habitat: "المراعي المفتوحة، موارد المياه، وحواف المخيمات.", activeSeason: "طوال العام.", activityPeriod: .day, viewingAdvice: "لا تقترب من القطيع أو الصغار، وخفف السرعة عند عبور الإبل.", firstAid: ["عند الرفس أو العض اطلب تقييمًا طبيًا.", "نظف الجروح جيدًا.", "راقب النزيف والكدمات."], emergencyNumbers: "الإسعاف 997 عند الإصابات."),
        WildlifeSpeciesProfile(arabicName: "المها العربي", scientificName: "Oryx leucoryx", imageName: "scope", dangerLevel: .low, isVenomous: false, identification: "ظبي أبيض ذو قرون طويلة مستقيمة، غالبًا داخل المحميات.", distribution: "محميات ومناطق إعادة توطين في الجزيرة العربية.", habitat: "السهول الصحراوية المفتوحة.", activeSeason: "طوال العام.", activityPeriod: .day, viewingAdvice: "شاهده من مسافة آمنة ولا تطارده بالمركبة.", firstAid: ["لا توجد إسعافات خاصة؛ أبلغ الجهات المختصة عند إصابة الحيوان."], emergencyNumbers: "المركز الوطني لتنمية الحياة الفطرية عبر قنواته الرسمية."),
        WildlifeSpeciesProfile(arabicName: "غزال الريم", scientificName: "Gazella marica", imageName: "figure.walk.motion", dangerLevel: .low, isVenomous: false, identification: "غزال رملي اللون، سريع الحركة، يعيش في السهول والكثبان.", distribution: "مناطق رملية ومحميات في الجزيرة العربية.", habitat: "السهول الرملية والنفود والمراعي المفتوحة.", activeSeason: "طوال العام.", activityPeriod: .day, viewingAdvice: "لا تطارده ولا تقترب من مناطق التكاثر.", firstAid: ["عند مشاهدة إصابة، وثق الموقع وأبلغ الجهة المختصة."], emergencyNumbers: "الجهات البيئية المختصة."),
        WildlifeSpeciesProfile(arabicName: "الغزال الجبلي", scientificName: "Gazella gazella", imageName: "figure.hiking", dangerLevel: .low, isVenomous: false, identification: "غزال رشيق يرتبط بالجبال والهضاب الصخرية.", distribution: "المناطق الجبلية والغربية وبعض المحميات.", habitat: "السفوح، الهضاب، والشعاب المفتوحة.", activeSeason: "طوال العام.", activityPeriod: .day, viewingAdvice: "المشاهدة بالمنظار أفضل؛ لا تقترب بالمركبة.", firstAid: ["أبلغ الجهات المختصة عند وجود حيوان مصاب أو مطارد."], emergencyNumbers: "الجهات البيئية المختصة."),
        WildlifeSpeciesProfile(arabicName: "الوعل النوبي", scientificName: "Capra nubiana", imageName: "mountain.2.circle.fill", dangerLevel: .low, isVenomous: false, identification: "وعل جبلي بقرون مقوسة، يتحرك على الحواف الصخرية والمرتفعات.", distribution: "جبال الحجاز وعسير والمناطق الوعرة.", habitat: "الجبال الحادة، الأودية الصخرية، ومناطق الماء النادرة.", activeSeason: "طوال العام.", activityPeriod: .day, viewingAdvice: "لا تصعد خلفه أو تدفعه نحو حافة، واستخدم المنظار.", firstAid: ["في حال سقوط أو إصابة بشرية اطلب الإسعاف.", "أبلغ عن الحيوان المصاب للجهة المختصة."], emergencyNumbers: "الإسعاف 997 عند إصابات البشر."),
        WildlifeSpeciesProfile(arabicName: "الأرنب العربي", scientificName: "Lepus capensis arabicus", imageName: "hare.fill", dangerLevel: .low, isVenomous: false, identification: "أرنب صحراوي بأذنين طويلتين، يظهر غالبًا عند الفجر والغروب.", distribution: "سهول وصحارى ومزارع مفتوحة.", habitat: "الشجيرات المنخفضة والحواف الرملية.", activeSeason: "طوال العام.", activityPeriod: .both, viewingAdvice: "لا تطارده بالمركبة ولا تضيء عليه طويلًا.", firstAid: ["لا توجد إسعافات خاصة عادة."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "الثعلب الأحمر العربي", scientificName: "Vulpes vulpes arabica", imageName: "pawprint.fill", dangerLevel: .low, isVenomous: false, identification: "ثعلب صغير إلى متوسط، ذيل كثيف، ويتحرك غالبًا ليلًا حول المخيمات.", distribution: "واسع الانتشار في الصحارى والسهول وحواف المدن.", habitat: "الجحور، أطراف الأودية، وحواف المخيمات.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تطعمه ولا تترك بقايا الطعام؛ التغذية تغير سلوكه وتزيد الاقتراب.", firstAid: ["عند عضة، اغسل الجرح وراجع المركز الصحي لتقييم داء الكلب."], emergencyNumbers: "الإسعاف 997 عند إصابة شديدة."),
        WildlifeSpeciesProfile(arabicName: "ثعلب روبل", scientificName: "Vulpes rueppellii", imageName: "pawprint.circle.fill", dangerLevel: .low, isVenomous: false, identification: "ثعلب صحراوي فاتح اللون وأذنان كبيرتان نسبيًا، يتكيف مع الرمال.", distribution: "الصحارى الرملية في الجزيرة العربية.", habitat: "الكثبان والمناطق المفتوحة ذات الجحور.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "راقبه من بعد ولا تطارده أو تطعمه.", firstAid: ["نظف الجروح وراجع الطبيب عند عضة."], emergencyNumbers: "الإسعاف 997 عند الإصابات."),
        WildlifeSpeciesProfile(arabicName: "الوشق العربي", scientificName: "Caracal caracal schmitzi", imageName: "cat.fill", dangerLevel: .medium, isVenomous: false, identification: "قط بري متوسط الحجم، أذنان طويلتان تنتهيان بخصل سوداء.", distribution: "مناطق جبلية وصحراوية متفرقة.", habitat: "الشعاب، الحرات، الأودية، والمناطق الهادئة.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تقترب ولا تحاول الإمساك به أو تصويره من قرب.", firstAid: ["عند خدش أو عضة، نظف الجرح وراجع المركز الصحي.", "وثق البلاغ من مسافة آمنة."], emergencyNumbers: "الإسعاف 997 عند الإصابات."),
        WildlifeSpeciesProfile(arabicName: "القط البري العربي", scientificName: "Felis lybica", imageName: "cat.circle.fill", dangerLevel: .low, isVenomous: false, identification: "يشبه القط المنزلي لكنه أكثر نحافة وحذرًا، بخطوط خفيفة وذيل مخطط.", distribution: "البراري وحواف المزارع والمناطق الجبلية.", habitat: "الشجيرات، الصخور، وحواف الأودية.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تطعمه ولا تخلطه مع القطط المنزلية.", firstAid: ["نظف أي خدش أو عضة وراجع الطبيب عند الحاجة."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "غرير العسل", scientificName: "Mellivora capensis", imageName: "shield.lefthalf.filled", dangerLevel: .medium, isVenomous: false, identification: "حيوان قوي منخفض الجسم، لون داكن مع ظهر فاتح، معروف بالدفاع الشديد عن نفسه.", distribution: "مناطق صحراوية وجبلية متفرقة.", habitat: "الجحور، الشعاب، وحواف الأودية.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تحاصره أو تقترب منه؛ اترك له مخرجًا واضحًا.", firstAid: ["عند عضة أو خدش، نظف الجرح واطلب تقييمًا طبيًا.", "راقب علامات العدوى."], emergencyNumbers: "الإسعاف 997 عند الإصابات."),
        WildlifeSpeciesProfile(arabicName: "النمس أبيض الذيل", scientificName: "Ichneumia albicauda", imageName: "pawprint", dangerLevel: .low, isVenomous: false, identification: "حيوان ليلي بجسم طويل وذيل فاتح النهاية، يتغذى على الحشرات والزواحف الصغيرة.", distribution: "الأودية والمزارع وحواف الجبال.", habitat: "الشعاب، الحقول، وأماكن الغطاء النباتي.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تطعمه ولا تلاحقه، فهو غالبًا يبتعد سريعًا.", firstAid: ["نظف أي عضة وراجع الطبيب عند الحاجة."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "النيص الهندي", scientificName: "Hystrix indica", imageName: "circle.grid.3x3.fill", dangerLevel: .low, isVenomous: false, identification: "قارض كبير ذو أشواك طويلة، ينشط ليلًا ويترك آثار حفر قرب الجذور.", distribution: "الأودية والمزارع والجبال في أجزاء من الجزيرة العربية.", habitat: "الجحور، الأشجار، ومناطق الزراعة.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تحاول لمسه؛ الأشواك قد تسبب جروحًا مؤلمة.", firstAid: ["لا تكسر الشوكة داخل الجلد.", "نظف الجرح وراجع الطبيب لإزالة الأشواك العميقة."], emergencyNumbers: "الإسعاف 997 عند إصابة شديدة."),
        WildlifeSpeciesProfile(arabicName: "القنفذ طويل الأذن", scientificName: "Hemiechinus auritus", imageName: "circle.dotted", dangerLevel: .low, isVenomous: false, identification: "ثديي صغير شائك، أذناه واضحتان، ينشط ليلًا بحثًا عن الحشرات.", distribution: "السهول والمزارع وحواف الأودية.", habitat: "الشجيرات، الحدائق البرية، والمناطق الرملية.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تلتقطه باليد ولا تنقله من مكانه إلا للضرورة وبقفازات.", firstAid: ["نظف الخدوش البسيطة وراقبها."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "الخفاش الصحراوي", scientificName: "Chiroptera spp.", imageName: "moon.stars.fill", dangerLevel: .medium, isVenomous: false, identification: "ينشط ليلًا حول الكهوف والمباني المهجورة ومصادر الحشرات.", distribution: "الكهوف والحرات والمزارع والمناطق السكنية الهادئة.", habitat: "الكهوف، الشقوق، المباني المهجورة.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تلمسه ولا تدخل أماكن تجمعه دون حماية وتهوية.", firstAid: ["عند عضة أو ملامسة مباشرة، اغسل المكان وراجع الطبيب لتقييم اللقاحات."], emergencyNumbers: "الإسعاف 997 عند التعرض أو الإصابة."),
        WildlifeSpeciesProfile(arabicName: "الحبارى", scientificName: "Chlamydotis macqueenii", imageName: "bird.fill", dangerLevel: .low, isVenomous: false, identification: "طائر صحراوي كبير نسبيًا، لونه رملي وعنقه طويل، يشاهد في السهول المفتوحة.", distribution: "مناطق صحراوية وممرات هجرة ومحميات.", habitat: "السهول الرملية والحصوية المفتوحة.", activeSeason: "الخريف والشتاء والربيع.", activityPeriod: .day, viewingAdvice: "راقب بالمنظار ولا تزعج الطائر أو الأعشاش.", firstAid: ["لا توجد إسعافات خاصة؛ أبلغ عن الطيور المصابة للجهات المختصة."], emergencyNumbers: "الجهات البيئية المختصة."),
        WildlifeSpeciesProfile(arabicName: "القطا", scientificName: "Pterocles spp.", imageName: "bird.circle.fill", dangerLevel: .low, isVenomous: false, identification: "طائر بري يزور موارد الماء في أسراب، ألوانه مموهة مع الرمل.", distribution: "السهول الصحراوية ومناطق المياه.", habitat: "المراعي المفتوحة، موارد الماء، والأراضي الحصوية.", activeSeason: "طوال العام ويكثر بعد الأمطار.", activityPeriod: .day, viewingAdvice: "لا تقترب من موارد الماء أثناء تجمع الطيور.", firstAid: ["لا توجد إسعافات خاصة."], emergencyNumbers: "للطوارئ الطبية استخدم أرقام بلدك الرسمية."),
        WildlifeSpeciesProfile(arabicName: "العقاب الذهبي", scientificName: "Aquila chrysaetos", imageName: "binoculars.fill", dangerLevel: .low, isVenomous: false, identification: "طائر جارح كبير، يحلق فوق الجبال والحواف العالية.", distribution: "المرتفعات والمناطق الجبلية.", habitat: "الجبال، الحواف الصخرية، والأودية الواسعة.", activeSeason: "طوال العام مع اختلاف الهجرة.", activityPeriod: .day, viewingAdvice: "لا تقترب من الأعشاش أو مواقع التكاثر.", firstAid: ["عند العثور على طائر مصاب، لا تمسكه دون مختص."], emergencyNumbers: "الجهات البيئية المختصة."),
        WildlifeSpeciesProfile(arabicName: "البومة الصحراوية", scientificName: "Bubo ascalaphus / Strigiformes", imageName: "eyes", dangerLevel: .low, isVenomous: false, identification: "طائر ليلي بعيون كبيرة، يظهر قرب الصخور والأودية ليلًا.", distribution: "المناطق الصخرية والصحراوية.", habitat: "الكهوف الصغيرة، الأشجار، والحواف الصخرية.", activeSeason: "طوال العام.", activityPeriod: .night, viewingAdvice: "لا تسلط الضوء عليها طويلًا ولا تزعج أعشاشها.", firstAid: ["لا توجد إسعافات خاصة؛ أبلغ عن الإصابات للجهات المختصة."], emergencyNumbers: "الجهات البيئية المختصة.")
    ]
}

struct WildlifeRangeZone: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var species: String
    var coordinate: CLLocationCoordinate2D
    var radiusKilometers: Double
    var season: String
    var alertText: String
    var icon: String

    static let samples: [WildlifeRangeZone] = [
        WildlifeRangeZone(title: "كثبان ونفود", species: "أفاعي رملية وعقارب", coordinate: CLLocationCoordinate2D(latitude: 25.1, longitude: 44.5), radiusKilometers: 80, season: "الصيف والربيع", alertText: "يزداد النشاط ليلًا. استخدم كشافًا وافحص منطقة الجلوس.", icon: "moon.stars"),
        WildlifeRangeZone(title: "أودية وشعاب", species: "ثعابين وطيور جارحة", coordinate: CLLocationCoordinate2D(latitude: 24.4, longitude: 46.1), radiusKilometers: 45, season: "بعد الأمطار", alertText: "تجنب المشي داخل الشقوق وبين الصخور دون فحص.", icon: "mountain.2"),
        WildlifeRangeZone(title: "ممرات هجرة", species: "طيور مهاجرة", coordinate: CLLocationCoordinate2D(latitude: 26.4, longitude: 49.9), radiusKilometers: 120, season: "الخريف والربيع", alertText: "المشاهدة من مسافة آمنة دون إزعاج أو تتبع.", icon: "bird")
    ]
}

struct WildPlantProfile: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var detail: String
    var season: String
    var isProtected: Bool
    var isPoisonous: Bool
    var grazingUse: String
    var traditionalUse: String
    var icon: String

    static let samples: [WildPlantProfile] = [
        WildPlantProfile(name: "الخزامى", detail: "نبات عطري موسمي يظهر بعد الأمطار في البيئات الرملية.", season: "الربيع", isProtected: false, isPoisonous: false, grazingUse: "محدود", traditionalUse: "معلومة ثقافية عن الرائحة والاستخدامات الشعبية وليست نصيحة طبية.", icon: "camera.macro"),
        WildPlantProfile(name: "العرفج", detail: "شجيرة صحراوية معروفة في نجد وتعد مؤشرًا للبيئة البرية.", season: "الشتاء والربيع", isProtected: false, isPoisonous: false, grazingUse: "قد تصلح للرعي حسب الحالة", traditionalUse: "تذكر في التراث المحلي كوقود ومؤشر موسمي.", icon: "tree"),
        WildPlantProfile(name: "الحرمل", detail: "نبات بري يحتاج حذرًا عند التعامل معه.", season: "الربيع والصيف", isProtected: false, isPoisonous: true, grazingUse: "غير مناسب", traditionalUse: "معلوماته ثقافية فقط ولا تستخدم علاجيًا دون مختص.", icon: "exclamationmark.triangle")
    ]
}

struct ProtectedReserveInfo: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var location: String
    var area: String
    var wildlife: String
    var allowedActivities: String
    var bannedActivities: String
    var fees: String
    var hours: String
    var visitRules: String
    var officialContact: String

    static let samples: [ProtectedReserveInfo] = [
        ProtectedReserveInfo(name: "محمية نموذجية", location: "تضاف من المصدر الرسمي", area: "حسب البيانات الرسمية", wildlife: "طيور، نباتات برية، وثدييات صغيرة", allowedActivities: "المسارات المحددة والتصوير من مسافة آمنة", bannedActivities: "الصيد، إزعاج الكائنات، إشعال النار خارج المواقع المسموحة", fees: "تتحقق من الجهة الرسمية", hours: "تتحقق قبل الزيارة", visitRules: "التزم بالمسارات ولا تكشف مواقع الأعشاش أو الكائنات الحساسة.", officialContact: "قنوات الجهة الرسمية للمحمية")
    ]
}

struct RestrictedAreaInfo: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var reason: String
    var authority: String
    var permitRequirement: String
    var warning: String

    static let samples: [RestrictedAreaInfo] = [
        RestrictedAreaInfo(name: "مناطق محمية حساسة", reason: "حماية الحياة الفطرية أو مواسم التكاثر", authority: "الجهة البيئية المختصة", permitRequirement: "قد تتطلب تصريحًا مسبقًا", warning: "يعرض التطبيق المنطقة بشكل عام ولا يكشف نقاطًا حساسة."),
        RestrictedAreaInfo(name: "مناطق عسكرية أو حدودية", reason: "اعتبارات أمنية", authority: "الجهات المختصة", permitRequirement: "الدخول ممنوع أو بتصريح رسمي", warning: "لا تستخدم مسارات غير موثقة قرب هذه المناطق.")
    ]
}

struct FieldSafetyTopic: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var steps: [String]
    var firstAid: String
    var icon: String

    static let samples: [FieldSafetyTopic] = [
        FieldSafetyTopic(title: "عند مشاهدة ثعبان", steps: ["توقف ولا تقترب.", "اترك له مسار خروج.", "أبعد الأطفال بهدوء.", "لا تحاول قتله أو الإمساك به."], firstAid: "عند اللدغ: قلل الحركة، لا تشق الجرح، واتصل بالإسعاف.", icon: "figure.walk.motion"),
        FieldSafetyTopic(title: "التعامل مع العقارب", steps: ["افحص الحذاء والفراش.", "استخدم قفازات للحطب والصخور.", "ارفع المعدات عن الأرض ليلًا."], firstAid: "نظف موضع اللدغة واطلب المساعدة عند الألم الشديد أو الأعراض العامة.", icon: "hand.raised"),
        FieldSafetyTopic(title: "اختيار مكان تخييم آمن", steps: ["ابتعد عن بطون الأودية.", "تجنب الجحور والشقوق.", "اترك مسافة من الأشجار الجافة.", "افحص اتجاه الرياح ومخرج الرجوع."], firstAid: "جهز حقيبة إسعاف ورقم طوارئ وخطة إخلاء قبل النوم.", icon: "tent")
    ]
}

struct WildlifeTrackGuide: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var likelyAnimal: String
    var clues: String
    var icon: String

    static let samples: [WildlifeTrackGuide] = [
        WildlifeTrackGuide(title: "أثر أقدام كلبي", likelyAnimal: "ثعلب أو ذئب", clues: "أربع أصابع ومخالب واضحة، يختلف الحجم واتساع الخطوة.", icon: "pawprint"),
        WildlifeTrackGuide(title: "سحب ذيل على الرمل", likelyAnimal: "زاحف أو ورل", clues: "خط مركزي مع آثار أقدام جانبية متقطعة.", icon: "lizard"),
        WildlifeTrackGuide(title: "نقاط صغيرة قرب صخر", likelyAnimal: "عقارب أو حشرات", clues: "تظهر غالبًا عند مخارج الشقوق في الرمل الناعم.", icon: "ant")
    ]
}

struct WildlifeSeasonActivity: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var months: String
    var weatherTrigger: String
    var advice: String
    var icon: String

    static let samples: [WildlifeSeasonActivity] = [
        WildlifeSeasonActivity(title: "نشاط الثعابين", months: "مارس - أكتوبر", weatherTrigger: "ليال دافئة وبعد ارتفاع الحرارة", advice: "استخدم إضاءة كافية وارتد أحذية مرتفعة.", icon: "thermometer.sun"),
        WildlifeSeasonActivity(title: "نشاط العقارب", months: "أبريل - سبتمبر", weatherTrigger: "الحرارة العالية والمخيمات الصخرية", advice: "لا تترك الأحذية خارج الخيمة دون فحص.", icon: "moon"),
        WildlifeSeasonActivity(title: "هجرة الطيور", months: "الربيع والخريف", weatherTrigger: "تغير المواسم والرياح", advice: "راقب من بعد ولا تزعج مناطق الراحة.", icon: "bird")
    ]
}

struct GeologyGuideProfile: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var formation: String
    var whereToSee: String
    var safetyNote: String
    var icon: String

    static let samples: [GeologyGuideProfile] = [
        GeologyGuideProfile(title: "الكثبان الرملية", formation: "تتشكل بفعل الرياح وتراكم الرمال حول العوائق.", whereToSee: "النفود والربع الخالي والمناطق الرملية الواسعة.", safetyNote: "تجنب القيادة منفردًا في الرمال الناعمة.", icon: "mountain.2"),
        GeologyGuideProfile(title: "الحرات البركانية", formation: "تكونت من تدفقات بركانية قديمة وصخور بازلتية.", whereToSee: "حرات غرب وشمال غرب المملكة.", safetyNote: "انتبه للإطارات والصخور الحادة.", icon: "flame"),
        GeologyGuideProfile(title: "الأودية", formation: "مجاري طبيعية صنعتها السيول عبر الزمن.", whereToSee: "مناطق الجبال والهضاب والشعاب.", safetyNote: "لا تخيم في بطن الوادي عند توقع الأمطار.", icon: "water.waves")
    ]
}

struct SeasonalChallenge: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var progress: Double
    var reward: String

    static let samples: [SeasonalChallenge] = [
        SeasonalChallenge(title: "زيارة خمسة أودية", progress: 0.4, reward: "شارة مستكشف الأودية"),
        SeasonalChallenge(title: "رفع عشر صور جديدة", progress: 0.7, reward: "120 نقطة"),
        SeasonalChallenge(title: "تسجيل رحلة 500 كم", progress: 0.25, reward: "شارة الرحالة")
    ]
}

struct RouteComparison: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var distance: String
    var eta: String
    var terrain: String
    var risk: String

    static let samples: [RouteComparison] = [
        RouteComparison(name: "المسار السريع", distance: "48 كم", eta: "52 د", terrain: "معبد/ترابي", risk: "منخفض"),
        RouteComparison(name: "المسار البري", distance: "41 كم", eta: "1س 18د", terrain: "رملي/وادي", risk: "متوسط"),
        RouteComparison(name: "المسار الجبلي", distance: "55 كم", eta: "1س 35د", terrain: "صخري", risk: "مرتفع")
    ]
}

struct VehicleProfile: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var fuelEfficiency: String
    var nextService: String
    var estimatedTripCost: String

    static let samples: [VehicleProfile] = [
        VehicleProfile(name: "لاندكروزر", fuelEfficiency: "7.5 كم/لتر", nextService: "بعد 1,800 كم", estimatedTripCost: "230 ريال"),
        VehicleProfile(name: "باترول", fuelEfficiency: "6.8 كم/لتر", nextService: "تغيير زيت خلال 12 يوم", estimatedTripCost: "255 ريال")
    ]
}

struct LiveCommunitySignal: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var freshness: String
    var icon: String

    static let samples: [LiveCommunitySignal] = [
        LiveCommunitySignal(title: "رمال ناعمة", detail: "قبل مدخل وادي مخفي بـ 3 كم", freshness: "قبل 8 د", icon: "road.lanes"),
        LiveCommunitySignal(title: "صورة حديثة", detail: "مطل الحجر وقت الغروب", freshness: "قبل 21 د", icon: "photo"),
        LiveCommunitySignal(title: "شبكة ضعيفة", detail: "انقطاع متكرر بعد نقطة التخييم", freshness: "قبل 45 د", icon: "antenna.radiowaves.left.and.right"),
        LiveCommunitySignal(title: "مخيمات نشطة", detail: "3 مخيمات قريبة من الفيضة", freshness: "مباشر", icon: "tent")
    ]
}

struct FutureServiceItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var icon: String

    static let samples: [FutureServiceItem] = [
        FutureServiceItem(title: "حجز المخيمات", detail: "اختيار موقع، مدة، ومرافق المخيم", icon: "tent"),
        FutureServiceItem(title: "حجز مرشدين", detail: "مرشدون محليون لمسارات الوديان والجبال", icon: "person.text.rectangle"),
        FutureServiceItem(title: "استئجار معدات", detail: "خيام، كمبروسر، أدوات سحب، مولدات", icon: "shippingbox"),
        FutureServiceItem(title: "طلب إنقاذ", detail: "طلب مساعدة من مزود خدمة أو مستخدم قريب", icon: "lifepreserver")
    ]
}

struct SmartDestinationSuggestion: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var reason: String
    var distance: String
    var bestTime: String
    var suitability: String
    var icon: String

    static let samples: [SmartDestinationSuggestion] = [
        SmartDestinationSuggestion(
            title: "فيضة الندى",
            reason: "هادئة وقريبة من الرياض، مناسبة للعائلات بعد العصر مع توفر خدمات قريبة.",
            distance: "38 كم",
            bestTime: "بعد 4:30 م",
            suitability: "عائلات",
            icon: "leaf"
        ),
        SmartDestinationSuggestion(
            title: "نفود التطعيس",
            reason: "كثبان مفتوحة وتقييم المجتمع جيد، لكن يحتاج دفع رباعي وضغط إطارات منخفض.",
            distance: "64 كم",
            bestTime: "الصباح",
            suitability: "تطعيس",
            icon: "car.2"
        ),
        SmartDestinationSuggestion(
            title: "مطل الحجر",
            reason: "تكوينات صخرية وإضاءة غروب ممتازة للتصوير مع مسار متوسط الصعوبة.",
            distance: "42 كم",
            bestTime: "الساعة الذهبية",
            suitability: "تصوير",
            icon: "camera.aperture"
        )
    ]
}

struct SmartTripPlan: Identifiable, Hashable {
    let id = UUID()
    var startPoint: String
    var peopleCount: Int
    var vehicleType: String
    var durationHours: Int
    var budgetSAR: Int
    var route: String
    var fuelStops: [String]
    var restStops: [String]
    var campingPoints: [String]
    var departureAdvice: String
    var eta: String
    var weatherSummary: String

    static let sample = SmartTripPlan(
        startPoint: "شمال الرياض",
        peopleCount: 5,
        vehicleType: "دفع رباعي",
        durationHours: 18,
        budgetSAR: 480,
        route: "الرياض - محطة الدائري - فيضة الندى - مطل الحجر - نقطة الرجوع",
        fuelStops: ["محطة الدائري 12 كم", "محطة طريق القصيم 47 كم"],
        restStops: ["استراحة قصيرة قبل المسار الرملي", "نقطة ظل قرب الفيضة"],
        campingPoints: ["مخيم آمن شرق الفيضة", "موقع بديل قرب المطل"],
        departureAdvice: "انطلق قبل الغروب بساعتين لتجنب الحرارة ولتجهيز المخيم قبل الظلام.",
        eta: "1س 25د",
        weatherSummary: "حرارة 34°، رياح 18 كم/س، جودة هواء جيدة"
    )
}

struct SafetyAssistantFinding: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var recommendation: String
    var severity: RiskSeverity
    var icon: String

    static let samples: [SafetyAssistantFinding] = [
        SafetyAssistantFinding(title: "رياح مرتفعة", detail: "الرياح قد تصل إلى 45 كم/س في المناطق المكشوفة.", recommendation: "تجنب نصب الخيام على القمم وثبت المعدات.", severity: .warning, icon: "wind"),
        SafetyAssistantFinding(title: "تغطية ضعيفة", detail: "يوجد مقطع بطول 60 كم بتغطية محدودة حسب بلاغات المجتمع.", recommendation: "شارك الموقع قبل الدخول واحفظ نقطة الرجوع.", severity: .advisory, icon: "antenna.radiowaves.left.and.right"),
        SafetyAssistantFinding(title: "مياه إضافية", detail: "مدة الرحلة وعدد الأشخاص يتطلبان احتياطاً أعلى.", recommendation: "احمل 40 لتر ماء إضافية على الأقل.", severity: .critical, icon: "drop")
    ]
}

struct OfflineMapLayerOption: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var isEnabled: Bool
    var icon: String

    static let samples: [OfflineMapLayerOption] = [
        OfflineMapLayerOption(title: "الصور الفضائية", detail: "عرض تضاريس وصور عالية الدقة عند توفر الحزمة.", isEnabled: true, icon: "globe.americas"),
        OfflineMapLayerOption(title: "الخرائط الطبوغرافية", detail: "خطوط كنتور، أودية، جبال، وكثبان.", isEnabled: true, icon: "map"),
        OfflineMapLayerOption(title: "الخدمات", detail: "وقود، مساجد، آبار، دفاع مدني، مستشفيات، ونقاط شبكة.", isEnabled: true, icon: "point.3.connected.trianglepath.dotted"),
        OfflineMapLayerOption(title: "المسارات وGPX/KML", detail: "استيراد وتصدير المسارات الاحترافية.", isEnabled: false, icon: "point.topleft.down.curvedto.point.bottomright.up")
    ]
}

struct ExpeditionCalculatorResult: Hashable {
    var waterLiters: Int
    var fuelLiters: Int
    var reserveFuelLiters: Int
    var estimatedLoadKG: Int
    var tripCostSAR: Int

    static func estimate(people: Int, days: Int, distanceKM: Int, fuelEfficiencyKMPerLiter: Double, equipmentKG: Int) -> ExpeditionCalculatorResult {
        let water = max(people * days * 8, people * 6)
        let fuel = Int(ceil(Double(distanceKM) / max(fuelEfficiencyKMPerLiter, 1)))
        let reserve = Int(ceil(Double(fuel) * 0.35))
        let cost = Int(ceil(Double(fuel + reserve) * 2.33))
        return ExpeditionCalculatorResult(
            waterLiters: water,
            fuelLiters: fuel,
            reserveFuelLiters: reserve,
            estimatedLoadKG: equipmentKG + water,
            tripCostSAR: cost
        )
    }
}

struct AstronomyPhotographyWindow: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var time: String
    var detail: String
    var icon: String

    static let samples: [AstronomyPhotographyWindow] = [
        AstronomyPhotographyWindow(title: "الشروق", time: "05:11", detail: "إضاءة ناعمة للوديان والجبال", icon: "sunrise"),
        AstronomyPhotographyWindow(title: "الغروب", time: "18:46", detail: "أفضل زاوية تصوير باتجاه الغرب", icon: "sunset"),
        AstronomyPhotographyWindow(title: "الساعة الذهبية", time: "18:08 - 18:46", detail: "إضاءة دافئة للصور البرية", icon: "camera.filters"),
        AstronomyPhotographyWindow(title: "النجوم", time: "22:20 - 03:40", detail: "قمر بإضاءة 31% ورؤية جيدة", icon: "sparkles")
    ]
}

struct GroupTripMember: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var status: String
    var distanceFromLead: String
    var lastSeen: String

    static let samples: [GroupTripMember] = [
        GroupTripMember(name: "فهد", status: "متقدم", distanceFromLead: "0.8 كم", lastSeen: "مباشر"),
        GroupTripMember(name: "نورة", status: "ضمن المسار", distanceFromLead: "1.4 كم", lastSeen: "قبل دقيقة"),
        GroupTripMember(name: "سارة", status: "توقف قصير", distanceFromLead: "2.1 كم", lastSeen: "قبل 4 د")
    ]
}

struct ContentArticle: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var category: String
    var readTime: String
    var summary: String
    var icon: String

    static let samples: [ContentArticle] = [
        ContentArticle(title: "القيادة في الرمال", category: "مهارات", readTime: "6 د", summary: "ضغط الإطارات، اختيار المسار، وتجنب الغرز.", icon: "car"),
        ContentArticle(title: "الإسعافات الأولية في البر", category: "سلامة", readTime: "8 د", summary: "خطوات التعامل مع الجروح والإجهاد الحراري.", icon: "cross.case"),
        ContentArticle(title: "فحص السيارة قبل الرحلة", category: "مركبة", readTime: "5 د", summary: "زيوت، إطارات، تبريد، بطارية، ومعدات سحب.", icon: "wrench.and.screwdriver"),
        ContentArticle(title: "التصوير في الطبيعة", category: "تصوير", readTime: "4 د", summary: "اختيار الوقت والزاوية وحماية المعدات.", icon: "camera")
    ]
}

struct AppleIntegrationItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var status: String
    var icon: String

    static let samples: [AppleIntegrationItem] = [
        AppleIntegrationItem(title: "Apple Watch", status: "اختصارات السرعة والاتجاه والتنبيهات", icon: "applewatch"),
        AppleIntegrationItem(title: "CarPlay", status: "لوحة قيادة وملاحة صوتية داخل السيارة", icon: "car"),
        AppleIntegrationItem(title: "Siri وShortcuts", status: "أوامر: ابدأ رحلة، شارك موقعي، SOS", icon: "waveform"),
        AppleIntegrationItem(title: "Live Activities", status: "متابعة الرحلة على شاشة القفل وDynamic Island", icon: "livephoto"),
        AppleIntegrationItem(title: "Widgets", status: "الطقس، الرحلة القادمة، وأقرب خدمة", icon: "rectangle.grid.2x2")
    ]
}

enum GeospatialLayerFormat: String, CaseIterable, Identifiable {
    case wmts = "WMTS"
    case wms = "WMS"
    case pdf = "PDF"
    case mbtiles = "MBTiles"
    case vector = "GeoJSON"

    var id: String { rawValue }
}

enum GeospatialLayerStatus: String {
    case bundled
    case sourceRequired
    case readyForImport
    case offlineReady

    var title: String {
        switch self {
        case .bundled: return "مرفقة"
        case .sourceRequired: return "يتطلب مصدر مرخص"
        case .readyForImport: return "جاهزة للاستيراد"
        case .offlineReady: return "جاهزة دون اتصال"
        }
    }

    var color: Color {
        switch self {
        case .bundled: return .desertCopper
        case .sourceRequired: return .orange
        case .readyForImport: return .oasisTeal
        case .offlineReady: return .green
        }
    }
}

struct GeospatialMapLayer: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var provider: String
    var detail: String
    var format: GeospatialLayerFormat
    var status: GeospatialLayerStatus
    var recommendedScale: String
    var coverage: String
    var offlinePlan: String
    var sourceURL: String

    static let officialSamples: [GeospatialMapLayer] = [
        GeospatialMapLayer(
            title: "خرائط المساحة الجيولوجية",
            provider: "هيئة المساحة الجيولوجية السعودية SGS",
            detail: "طبقات جيولوجية وطبوغرافية للدرع العربي، الحرات، التكوينات الصخرية، المخاطر الجيولوجية، ومجاري الأودية عند توفر خدمة رسمية.",
            format: .wms,
            status: .sourceRequired,
            recommendedScale: "1:250,000 / 1:50,000",
            coverage: "المملكة العربية السعودية",
            offlinePlan: "تخزين Tiles حسب المنطقة مع فهرس بحث مكاني محلي",
            sourceURL: "https://sgs.gov.sa"
        ),
        GeospatialMapLayer(
            title: "خرائط العجاجي التفصيلية",
            provider: "Ajaji Maps",
            detail: "أسماء الشعاب، الأودية، الهضاب، الطرق البرية، المعالم المحلية، والرموز المرشدة للرحلات البرية.",
            format: .pdf,
            status: .sourceRequired,
            recommendedScale: "دقة PDF عالية",
            coverage: "حسب الترخيص الذي يتم الحصول عليه",
            offlinePlan: "استيراد PDF مرخص مع تكبير حتى 8x بعد الموافقة",
            sourceURL: "https://ajajimaps.com"
        ),
        GeospatialMapLayer(
            title: "المخططات المرشمة",
            provider: "Ajaji Maps / مصادر المستخدم المرخصة",
            detail: "طبقة مخططات مرشمة للطرق والأحياء والمعالم التفصيلية، مهيأة للعرض كملف PDF محلي أو مصدر مستورد.",
            format: .pdf,
            status: .sourceRequired,
            recommendedScale: "دقة PDF عالية",
            coverage: "مناطق عمرانية وبرية حسب الخريطة",
            offlinePlan: "استيراد ملف مرخص ثم تخزينه محليًا للمستخدم",
            sourceURL: "ملف محلي مرخص أو رابط PDF رسمي"
        ),
        GeospatialMapLayer(
            title: "حزمة Tiles برية",
            provider: "مصدر WMTS/MBTiles مرخص",
            detail: "حزمة أداء عالية للتحميل التدريجي، مناسبة للخرائط الكبيرة والتكبير السلس داخل مناطق الرحلة.",
            format: .mbtiles,
            status: .readyForImport,
            recommendedScale: "Zoom 6-17",
            coverage: "حسب المنطقة المحملة",
            offlinePlan: "MBTiles محلي + cache مشفر داخل Application Support",
            sourceURL: "يضاف من لوحة المصادر"
        ),
        GeospatialMapLayer(
            title: "فهرس الأودية والجبال المدمج",
            provider: "الدروب",
            detail: "فهرس محلي للأودية والجبال والحرات والرياض البرية لاستخدامه في البحث السريع وتحديد الوجهات دون اتصال.",
            format: .vector,
            status: .offlineReady,
            recommendedScale: "نقاط وGeoJSON",
            coverage: "مناطق برية مختارة داخل المملكة",
            offlinePlan: "يحفظ داخل التطبيق ويعمل مباشرة دون تنزيل إضافي",
            sourceURL: "Bundled Local Index"
        ),
        GeospatialMapLayer(
            title: "حزم الطرق البرية المفضلة",
            provider: "الدروب / مساهمات المجتمع",
            detail: "طبقة مبدئية للمسارات الترابية والمعالم القريبة منها، قابلة للتوسعة عند توفر مصادر مرخصة أو مشاركات موثقة.",
            format: .vector,
            status: .bundled,
            recommendedScale: "Zoom 9-16",
            coverage: "مسارات برية حول الرياض وحائل وتبوك والجنوب",
            offlinePlan: "تخزين المسارات كنقاط وخطوط محلية مرتبطة بالرحلات",
            sourceURL: "Community-reviewed local routes"
        )
    ]
}

struct GeospatialProcessingStep: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var icon: String

    static let pipeline: [GeospatialProcessingStep] = [
        GeospatialProcessingStep(title: "تحقق المصدر", detail: "اعتماد روابط رسمية أو ملفات مرخصة قبل التخزين داخل التطبيق.", icon: "checkmark.seal"),
        GeospatialProcessingStep(title: "توحيد الإحداثيات", detail: "تحويل الطبقات إلى WGS84 لتتوافق مع MapKit وCoreLocation.", icon: "globe.desk"),
        GeospatialProcessingStep(title: "تقطيع الخرائط", detail: "إنشاء Tiles أو MBTiles للتكبير السلس وتقليل زمن التحميل.", icon: "square.grid.3x3"),
        GeospatialProcessingStep(title: "فهرسة البحث", detail: "بناء فهرس أسماء الشعاب والأودية والهضاب والنقاط المهمة.", icon: "magnifyingglass"),
        GeospatialProcessingStep(title: "تشغيل دون اتصال", detail: "تخزين الحزم محليًا مع حماية كاملة للملفات ومراجعة حجم المنطقة.", icon: "icloud.and.arrow.down")
    ]
}

struct GeospatialSearchResult: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var type: String
    var coordinate: CLLocationCoordinate2D
    var source: String

    static let samples: [GeospatialSearchResult] = [
        GeospatialSearchResult(name: "وادي مخفي", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 24.61, longitude: 46.58), source: "فهرس العجاجي"),
        GeospatialSearchResult(name: "هضبة الحجر", type: "هضبة", coordinate: CLLocationCoordinate2D(latitude: 24.66, longitude: 46.53), source: "طبقة التضاريس"),
        GeospatialSearchResult(name: "شعيب الرحلة", type: "شعيب", coordinate: CLLocationCoordinate2D(latitude: 24.59, longitude: 46.56), source: "فهرس المجتمع"),
        GeospatialSearchResult(name: "وادي حنيفة", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "حافة العالم", type: "مطل", coordinate: CLLocationCoordinate2D(latitude: 24.9530, longitude: 45.9960), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبل طويق", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 24.5229, longitude: 46.2748), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "روضة خريم", type: "روضة", coordinate: CLLocationCoordinate2D(latitude: 25.3828, longitude: 47.2552), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "نفود الثويرات", type: "نفود", coordinate: CLLocationCoordinate2D(latitude: 26.0900, longitude: 44.1500), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "الدهناء", type: "صحراء", coordinate: CLLocationCoordinate2D(latitude: 24.7000, longitude: 47.9000), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "وادي الرمة", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 26.0000, longitude: 43.8000), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبال أجا", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 27.5200, longitude: 41.6900), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبال سلمى", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 27.2500, longitude: 42.1800), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "حرة خيبر", type: "حرة", coordinate: CLLocationCoordinate2D(latitude: 25.6300, longitude: 39.7500), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "حرة رهط", type: "حرة", coordinate: CLLocationCoordinate2D(latitude: 23.0000, longitude: 39.7500), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "وادي الديسة", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 27.6500, longitude: 36.4500), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبال حسمي", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 28.3000, longitude: 35.3000), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "السودة", type: "مرتفع", coordinate: CLLocationCoordinate2D(latitude: 18.2700, longitude: 42.3700), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبال فيفاء", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 17.2500, longitude: 43.1000), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "وادي لجب", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 17.6000, longitude: 42.9500), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبل شدا", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 19.8400, longitude: 41.3100), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبل ورقان", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 24.2100, longitude: 39.2700), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "وادي الفرع", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 23.1500, longitude: 39.0500), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "وادي وج", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 21.3800, longitude: 40.4300), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "وادي بيشة", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 19.9800, longitude: 42.6000), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "وادي نجران", type: "وادي", coordinate: CLLocationCoordinate2D(latitude: 17.4900, longitude: 44.1300), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "حرة كشب", type: "حرة", coordinate: CLLocationCoordinate2D(latitude: 22.8300, longitude: 41.3500), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "جبل القهر", type: "جبل", coordinate: CLLocationCoordinate2D(latitude: 17.8700, longitude: 43.0800), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "يبرين", type: "صحراء", coordinate: CLLocationCoordinate2D(latitude: 23.2500, longitude: 49.0000), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "صحراء جبة", type: "نفود", coordinate: CLLocationCoordinate2D(latitude: 28.0030, longitude: 40.9390), source: "فهرس الدروب"),
        GeospatialSearchResult(name: "العلا", type: "معلم", coordinate: CLLocationCoordinate2D(latitude: 26.6085, longitude: 37.9232), source: "فهرس الدروب")
    ]
}
