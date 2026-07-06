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
        switch (self, language) {
        case (.appTitle, .arabic): return "درب الصحراء"
        case (.appTitle, .english): return "Desert Trail"
        case (.map, .arabic): return "الخريطة"
        case (.map, .english): return "Map"
        case (.compass, .arabic): return "البوصلة"
        case (.compass, .english): return "Compass"
        case (.planner, .arabic): return "التقويم"
        case (.planner, .english): return "Planner"
        case (.community, .arabic): return "المجتمع"
        case (.community, .english): return "Community"
        case (.addPlace, .arabic): return "إضافة موقع"
        case (.addPlace, .english): return "Add Place"
        case (.weather, .arabic): return "البيئة"
        case (.weather, .english): return "Environment"
        case (.share, .arabic): return "مشاركة"
        case (.share, .english): return "Share"
        case (.offline, .arabic): return "خرائط بلا إنترنت"
        case (.offline, .english): return "Offline Maps"
        case (.reviewPending, .arabic): return "بانتظار المراجعة"
        case (.reviewPending, .english): return "Pending review"
        case (.gpsActive, .arabic): return "نشط"
        case (.gpsActive, .english): return "Active"
        case (.gpsReady, .arabic): return "جاهز"
        case (.gpsReady, .english): return "Ready"
        case (.stopNavigation, .arabic): return "إيقاف الملاحة"
        case (.stopNavigation, .english): return "Stop Navigation"
        case (.startNavigation, .arabic): return "بدء الملاحة"
        case (.startNavigation, .english): return "Start Navigation"
        case (.wind, .arabic): return "رياح"
        case (.wind, .english): return "Wind"
        case (.communityPoints, .arabic): return "نقاط المجتمع"
        case (.communityPoints, .english): return "Community Points"
        case (.searchPlaceholder, .arabic): return "ابحث عن رحلة أو موقع مخفي"
        case (.searchPlaceholder, .english): return "Search trips or hidden places"
        case (.published, .arabic): return "منشور"
        case (.published, .english): return "Published"
        case (.tripDetails, .arabic): return "تفاصيل الرحلة"
        case (.tripDetails, .english): return "Trip Details"
        case (.tripTitle, .arabic): return "اسم الرحلة"
        case (.tripTitle, .english): return "Trip Name"
        case (.start, .arabic): return "البداية"
        case (.start, .english): return "Start"
        case (.end, .arabic): return "النهاية"
        case (.end, .english): return "End"
        case (.packingNotes, .arabic): return "ملاحظات التجهيز"
        case (.packingNotes, .english): return "Packing Notes"
        case (.participants, .arabic): return "المشاركون"
        case (.participants, .english): return "Participants"
        case (.sharingPrivacy, .arabic): return "المشاركة والخصوصية"
        case (.sharingPrivacy, .english): return "Sharing and Privacy"
        case (.shareConsent, .arabic): return "أوافق على مشاركة رابط الرحلة"
        case (.shareConsent, .english): return "I agree to share the trip link"
        case (.shareLink, .arabic): return "مشاركة الرابط"
        case (.shareLink, .english): return "Share Link"
        case (.showQR, .arabic): return "إظهار رمز QR"
        case (.showQR, .english): return "Show QR Code"
        case (.done, .arabic): return "تم"
        case (.done, .english): return "Done"
        case (.hiddenPlace, .arabic): return "الموقع المخفي"
        case (.hiddenPlace, .english): return "Hidden Place"
        case (.placeName, .arabic): return "اسم الموقع"
        case (.placeName, .english): return "Place Name"
        case (.rating, .arabic): return "التقييم"
        case (.rating, .english): return "Rating"
        case (.safetyNotes, .arabic): return "ملاحظات السلامة والوصول"
        case (.safetyNotes, .english): return "Safety and Access Notes"
        case (.useCurrentLocation, .arabic): return "استخدام موقعي الحالي"
        case (.useCurrentLocation, .english): return "Use my current location"
        case (.review, .arabic): return "المراجعة"
        case (.review, .english): return "Review"
        case (.reviewMessage, .arabic): return "سيظهر الموقع للآخرين بعد مراجعته."
        case (.reviewMessage, .english): return "The place appears to others after review."
        case (.cancel, .arabic): return "إلغاء"
        case (.cancel, .english): return "Cancel"
        case (.submit, .arabic): return "إرسال"
        case (.submit, .english): return "Submit"
        case (.altitude, .arabic): return "الارتفاع"
        case (.altitude, .english): return "Altitude"
        case (.windSpeed, .arabic): return "سرعة الرياح"
        case (.windSpeed, .english): return "Wind Speed"
        case (.windDirection, .arabic): return "اتجاه الرياح"
        case (.windDirection, .english): return "Wind Direction"
        case (.magellan, .arabic): return "ماجلان"
        case (.magellan, .english): return "Magellan"
        case (.gpxReady, .arabic): return "GPX جاهز"
        case (.gpxReady, .english): return "GPX Ready"
        case (.startNavigationTools, .arabic): return "تشغيل أدوات الملاحة"
        case (.startNavigationTools, .english): return "Start Navigation Tools"
        case (.north, .arabic): return "شمال"
        case (.north, .english): return "North"
        case (.northeast, .arabic): return "شمال شرق"
        case (.northeast, .english): return "Northeast"
        case (.east, .arabic): return "شرق"
        case (.east, .english): return "East"
        case (.southeast, .arabic): return "جنوب شرق"
        case (.southeast, .english): return "Southeast"
        case (.south, .arabic): return "جنوب"
        case (.south, .english): return "South"
        case (.southwest, .arabic): return "جنوب غرب"
        case (.southwest, .english): return "Southwest"
        case (.west, .arabic): return "غرب"
        case (.west, .english): return "West"
        case (.northwest, .arabic): return "شمال غرب"
        case (.northwest, .english): return "Northwest"
        case (.poorAir, .arabic): return "جودة الهواء غير مناسبة للرحلات الطويلة"
        case (.poorAir, .english): return "Air quality is not suitable for long trips"
        case (.highHeat, .arabic): return "حرارة عالية: خطط للماء والظل"
        case (.highHeat, .english): return "High heat: plan water and shade"
        case (.goodConditions, .arabic): return "الظروف مناسبة مع متابعة التحديثات"
        case (.goodConditions, .english): return "Conditions are suitable; keep monitoring updates"
        case (.satellite, .arabic): return "قمر صناعي"
        case (.satellite, .english): return "Satellite"
        case (.ajajiMaps, .arabic): return "خرائط العجاجي"
        case (.ajajiMaps, .english): return "Ajaji Maps"
        case (.markedPlans, .arabic): return "مخططات مرشمة"
        case (.markedPlans, .english): return "Marked Plans"
        case (.ajajiSaudi, .arabic): return "السعودية"
        case (.ajajiSaudi, .english): return "Saudi Arabia"
        case (.ajajiRiyadh, .arabic): return "منطقة الرياض"
        case (.ajajiRiyadh, .english): return "Riyadh Region"
        case (.importOfficialPDF, .arabic): return "استيراد PDF رسمي"
        case (.importOfficialPDF, .english): return "Import Official PDF"
        case (.bundledPDF, .arabic): return "نسخة مرفقة"
        case (.bundledPDF, .english): return "Bundled Copy"
        case (.officialPDF, .arabic): return "PDF رسمي مستورد"
        case (.officialPDF, .english): return "Imported Official PDF"
        case (.restoreBundledPDF, .arabic): return "استعادة النسخة المرفقة"
        case (.restoreBundledPDF, .english): return "Restore Bundled Copy"
        case (.managePDFSource, .arabic): return "إدارة مصدر PDF"
        case (.managePDFSource, .english): return "Manage PDF Source"
        case (.downloadOfficialPDF, .arabic): return "تنزيل PDF رسمي"
        case (.downloadOfficialPDF, .english): return "Download Official PDF"
        case (.sourceURL, .arabic): return "رابط المصدر"
        case (.sourceURL, .english): return "Source URL"
        case (.sourceUnknown, .arabic): return "لا يوجد مصدر محفوظ"
        case (.sourceUnknown, .english): return "No saved source"
        case (.download, .arabic): return "تنزيل"
        case (.download, .english): return "Download"
        case (.importedFromFiles, .arabic): return "مستورد من الملفات"
        case (.importedFromFiles, .english): return "Imported from Files"
        default:
            return ""
        }
    }
}
