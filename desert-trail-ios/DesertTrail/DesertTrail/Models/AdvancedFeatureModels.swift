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
        WildlifeSpeciesProfile(arabicName: "الورل الصحراوي", scientificName: "Varanus griseus", imageName: "lizard.fill", dangerLevel: .medium, isVenomous: false, identification: "زاحف كبير نسبيًا، رقبة طويلة، وذيل طويل يتحرك بسرعة عند الخطر.", distribution: "صحارى وسهول حصوية ورملية.", habitat: "الجحور، أطراف الأودية، والمناطق المفتوحة.", activeSeason: "الربيع والصيف.", activityPeriod: .day, viewingAdvice: "لا تحاصره؛ قد يعض دفاعًا عن نفسه. اترك له طريقًا للابتعاد.", firstAid: ["نظف أي جرح جيدًا.", "راجع الطبيب عند عضة عميقة أو تورم.", "راقب علامات العدوى."], emergencyNumbers: "الإسعاف 997 عند الإصابات الشديدة.")
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
        GeospatialSearchResult(name: "شعيب الرحلة", type: "شعيب", coordinate: CLLocationCoordinate2D(latitude: 24.59, longitude: 46.56), source: "فهرس المجتمع")
    ]
}
