import Foundation
import CoreLocation

@MainActor
final class AppState: ObservableObject {
    @Published var language: AppLanguage = .arabic
    @Published var selectedTrip: TripPlan = TripPlan.sample
    @Published var hiddenPlaces: [HiddenPlace] = HiddenPlace.samples
    @Published var environmentalReport: EnvironmentalReport = .placeholder
    @Published var consentedToTripSharing = false

    let locationManager = LocationManager()
    let weatherService = WeatherService()
    let cloudStore = CloudKitStore()

    func text(_ key: LocalizedKey) -> String {
        key.value(for: language)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic
    case english

    var id: String { rawValue }
    var title: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        }
    }
}

enum LocalizedKey {
    case appTitle
    case map
    case compass
    case planner
    case community
    case addPlace
    case weather
    case share
    case offline
    case reviewPending
    case gpsActive
    case gpsReady
    case stopNavigation
    case startNavigation
    case wind
    case communityPoints
    case searchPlaceholder
    case published
    case tripDetails
    case tripTitle
    case start
    case end
    case packingNotes
    case participants
    case sharingPrivacy
    case shareConsent
    case shareLink
    case showQR
    case done
    case hiddenPlace
    case placeName
    case rating
    case safetyNotes
    case useCurrentLocation
    case review
    case reviewMessage
    case cancel
    case submit
    case altitude
    case windSpeed
    case windDirection
    case magellan
    case gpxReady
    case startNavigationTools
    case north
    case northeast
    case east
    case southeast
    case south
    case southwest
    case west
    case northwest
    case poorAir
    case highHeat
    case goodConditions
    case satellite
    case ajajiMaps
    case markedPlans
    case ajajiSaudi
    case ajajiRiyadh
    case importOfficialPDF
    case bundledPDF
    case officialPDF
    case restoreBundledPDF
    case managePDFSource
    case downloadOfficialPDF
    case sourceURL
    case sourceUnknown
    case download
    case importedFromFiles

    func value(for language: AppLanguage) -> String {
        switch language {
        case .arabic:
            return arabicValue
        case .english:
            return englishValue
        }
    }

    private var arabicValue: String {
        switch self {
        case .appTitle: return "رفيق الدروب"
        case .map: return "الخريطة"
        case .compass: return "البوصلة"
        case .planner: return "التقويم"
        case .community: return "المجتمع"
        case .addPlace: return "إضافة موقع"
        case .weather: return "البيئة"
        case .share: return "مشاركة"
        case .offline: return "خرائط بلا إنترنت"
        case .reviewPending: return "بانتظار المراجعة"
        case .gpsActive: return "نشط"
        case .gpsReady: return "جاهز"
        case .stopNavigation: return "إيقاف الملاحة"
        case .startNavigation: return "بدء الملاحة"
        case .wind: return "رياح"
        case .communityPoints: return "نقاط المجتمع"
        case .searchPlaceholder: return "ابحث عن رحلة أو موقع مخفي"
        case .published: return "منشور"
        case .tripDetails: return "تفاصيل الرحلة"
        case .tripTitle: return "اسم الرحلة"
        case .start: return "البداية"
        case .end: return "النهاية"
        case .packingNotes: return "ملاحظات التجهيز"
        case .participants: return "المشاركون"
        case .sharingPrivacy: return "المشاركة والخصوصية"
        case .shareConsent: return "أوافق على مشاركة رابط الرحلة"
        case .shareLink: return "مشاركة الرابط"
        case .showQR: return "إظهار رمز QR"
        case .done: return "تم"
        case .hiddenPlace: return "الموقع المخفي"
        case .placeName: return "اسم الموقع"
        case .rating: return "التقييم"
        case .safetyNotes: return "ملاحظات السلامة والوصول"
        case .useCurrentLocation: return "استخدام موقعي الحالي"
        case .review: return "المراجعة"
        case .reviewMessage: return "سيظهر الموقع للآخرين بعد مراجعته."
        case .cancel: return "إلغاء"
        case .submit: return "إرسال"
        case .altitude: return "الارتفاع"
        case .windSpeed: return "سرعة الرياح"
        case .windDirection: return "اتجاه الرياح"
        case .magellan: return "ماجلان"
        case .gpxReady: return "GPX جاهز"
        case .startNavigationTools: return "تشغيل أدوات الملاحة"
        case .north: return "شمال"
        case .northeast: return "شمال شرق"
        case .east: return "شرق"
        case .southeast: return "جنوب شرق"
        case .south: return "جنوب"
        case .southwest: return "جنوب غرب"
        case .west: return "غرب"
        case .northwest: return "شمال غرب"
        case .poorAir: return "جودة الهواء غير مناسبة للرحلات الطويلة"
        case .highHeat: return "حرارة عالية: خطط للماء والظل"
        case .goodConditions: return "الظروف مناسبة مع متابعة التحديثات"
        case .satellite: return "قمر صناعي"
        case .ajajiMaps: return "خرائط العجاجي"
        case .markedPlans: return "مخططات مرشمة"
        case .ajajiSaudi: return "السعودية"
        case .ajajiRiyadh: return "منطقة الرياض"
        case .importOfficialPDF: return "استيراد PDF رسمي"
        case .bundledPDF: return "نسخة مرفقة"
        case .officialPDF: return "PDF رسمي مستورد"
        case .restoreBundledPDF: return "استعادة النسخة المرفقة"
        case .managePDFSource: return "إدارة مصدر PDF"
        case .downloadOfficialPDF: return "تنزيل PDF رسمي"
        case .sourceURL: return "رابط المصدر"
        case .sourceUnknown: return "لا يوجد مصدر محفوظ"
        case .download: return "تنزيل"
        case .importedFromFiles: return "مستورد من الملفات"
        }
    }

    private var englishValue: String {
        switch self {
        case .appTitle: return "Rafiq Al Khala"
        case .map: return "Map"
        case .compass: return "Compass"
        case .planner: return "Planner"
        case .community: return "Community"
        case .addPlace: return "Add Place"
        case .weather: return "Environment"
        case .share: return "Share"
        case .offline: return "Offline Maps"
        case .reviewPending: return "Pending review"
        case .gpsActive: return "Active"
        case .gpsReady: return "Ready"
        case .stopNavigation: return "Stop Navigation"
        case .startNavigation: return "Start Navigation"
        case .wind: return "Wind"
        case .communityPoints: return "Community Points"
        case .searchPlaceholder: return "Search trips or hidden places"
        case .published: return "Published"
        case .tripDetails: return "Trip Details"
        case .tripTitle: return "Trip Name"
        case .start: return "Start"
        case .end: return "End"
        case .packingNotes: return "Packing Notes"
        case .participants: return "Participants"
        case .sharingPrivacy: return "Sharing and Privacy"
        case .shareConsent: return "I agree to share the trip link"
        case .shareLink: return "Share Link"
        case .showQR: return "Show QR Code"
        case .done: return "Done"
        case .hiddenPlace: return "Hidden Place"
        case .placeName: return "Place Name"
        case .rating: return "Rating"
        case .safetyNotes: return "Safety and Access Notes"
        case .useCurrentLocation: return "Use my current location"
        case .review: return "Review"
        case .reviewMessage: return "The place appears to others after review."
        case .cancel: return "Cancel"
        case .submit: return "Submit"
        case .altitude: return "Altitude"
        case .windSpeed: return "Wind Speed"
        case .windDirection: return "Wind Direction"
        case .magellan: return "Magellan"
        case .gpxReady: return "GPX Ready"
        case .startNavigationTools: return "Start Navigation Tools"
        case .north: return "North"
        case .northeast: return "Northeast"
        case .east: return "East"
        case .southeast: return "Southeast"
        case .south: return "South"
        case .southwest: return "Southwest"
        case .west: return "West"
        case .northwest: return "Northwest"
        case .poorAir: return "Air quality is not suitable for long trips"
        case .highHeat: return "High heat: plan water and shade"
        case .goodConditions: return "Conditions are suitable; keep monitoring updates"
        case .satellite: return "Satellite"
        case .ajajiMaps: return "Ajaji Maps"
        case .markedPlans: return "Marked Plans"
        case .ajajiSaudi: return "Saudi Arabia"
        case .ajajiRiyadh: return "Riyadh Region"
        case .importOfficialPDF: return "Import Official PDF"
        case .bundledPDF: return "Bundled Copy"
        case .officialPDF: return "Imported Official PDF"
        case .restoreBundledPDF: return "Restore Bundled Copy"
        case .managePDFSource: return "Manage PDF Source"
        case .downloadOfficialPDF: return "Download Official PDF"
        case .sourceURL: return "Source URL"
        case .sourceUnknown: return "No saved source"
        case .download: return "Download"
        case .importedFromFiles: return "Imported from Files"
        }
    }
}
