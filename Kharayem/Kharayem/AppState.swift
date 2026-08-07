import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class AppState {
    var language: AppLanguage = .arabic {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: AppStorageKey.language) }
    }
    /// Dark by default: the whole design is a night field theme (the dashboard
    /// background is dark unconditionally), so following a light system
    /// appearance left every other screen white against it. Users can still
    /// pick نهاري / حسب النظام from settings.
    var appearance: AppAppearance = .dark {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: AppStorageKey.appearance) }
    }
    var selectedTrip: TripPlan = TripPlan.draft
    var trips: [TripPlan] = []
    var hiddenPlaces: [HiddenPlace] = HiddenPlace.samples
    var environmentalReport: EnvironmentalReport = .placeholder
    var isEnvironmentRefreshing = false
    var environmentErrorMessage: String?
    /// `true` only when the current report was fetched for the device's real GPS
    /// location. When `false` the report is a fallback for the trip destination,
    /// so the UI can re-fetch once a real location fix arrives.
    private(set) var environmentReportIsForCurrentLocation = false
    var consentedToTripSharing = false {
        didSet { UserDefaults.standard.set(consentedToTripSharing, forKey: AppStorageKey.tripSharingConsent) }
    }
    var acceptedTermsAndPrivacy = false {
        didSet { UserDefaults.standard.set(acceptedTermsAndPrivacy, forKey: AppStorageKey.termsAndPrivacyAccepted) }
    }
    var preferredDirtRoadRouteID: String? {
        didSet {
            if let preferredDirtRoadRouteID {
                UserDefaults.standard.set(preferredDirtRoadRouteID, forKey: AppStorageKey.preferredDirtRoadRouteID)
            } else {
                UserDefaults.standard.removeObject(forKey: AppStorageKey.preferredDirtRoadRouteID)
            }
        }
    }
    var favoriteDirtRoadRouteIDs: [String] = [] {
        didSet { UserDefaults.standard.set(favoriteDirtRoadRouteIDs, forKey: AppStorageKey.favoriteDirtRoadRouteIDs) }
    }
    var statusMessage: String?

    let locationManager = LocationManager()
    let weatherService = WeatherService()
    let cloudStore = CloudKitStore()

    init() {
        let defaults = UserDefaults.standard
        if let rawLanguage = defaults.string(forKey: AppStorageKey.language),
           let storedLanguage = AppLanguage(rawValue: rawLanguage) {
            language = storedLanguage
        }
        if let rawAppearance = defaults.string(forKey: AppStorageKey.appearance),
           let storedAppearance = AppAppearance(rawValue: rawAppearance) {
            appearance = storedAppearance
        }

        trips = AppStateStorage.loadTrips() ?? []
        sortTripsByRecentActivity()
        if let storedHiddenPlaces = AppStateStorage.loadHiddenPlaces() {
            hiddenPlaces = Self.mergedHiddenPlaces(storedHiddenPlaces, with: HiddenPlace.samples)
            if hiddenPlaces.count != storedHiddenPlaces.count {
                AppStateStorage.saveHiddenPlaces(hiddenPlaces)
            }
        } else {
            hiddenPlaces = HiddenPlace.samples
        }

        if let selectedID = defaults.string(forKey: AppStorageKey.selectedTripID),
           let uuid = UUID(uuidString: selectedID),
           let storedTrip = trips.first(where: { $0.id == uuid }) {
            selectedTrip = storedTrip
        } else {
            selectedTrip = trips.first ?? TripPlan.draft
        }
        consentedToTripSharing = defaults.bool(forKey: AppStorageKey.tripSharingConsent)
        acceptedTermsAndPrivacy = defaults.bool(forKey: AppStorageKey.termsAndPrivacyAccepted)
        preferredDirtRoadRouteID = defaults.string(forKey: AppStorageKey.preferredDirtRoadRouteID)
        favoriteDirtRoadRouteIDs = defaults.stringArray(forKey: AppStorageKey.favoriteDirtRoadRouteIDs) ?? []
    }

    func acceptTermsAndPrivacy() {
        acceptedTermsAndPrivacy = true
        statusMessage = "تم قبول شروط الاستخدام والخصوصية"
    }

    func refreshEnvironmentReport() async {
        let coordinate: CLLocationCoordinate2D?
        let usingCurrentLocation: Bool
        if let currentCoordinate = locationManager.currentLocation?.coordinate {
            coordinate = currentCoordinate
            usingCurrentLocation = true
        } else if hasSelectedTrip {
            coordinate = selectedTrip.meetingPoint
            usingCurrentLocation = false
        } else {
            coordinate = nil
            usingCurrentLocation = false
        }

        guard let coordinate else {
            environmentErrorMessage = "فعّل الموقع أو أنشئ رحلة بوجهة محددة لتحديث الطقس وجودة الهواء."
            return
        }

        isEnvironmentRefreshing = true
        defer { isEnvironmentRefreshing = false }
        do {
            environmentalReport = try await weatherService.fetchReport(for: coordinate)
            environmentReportIsForCurrentLocation = usingCurrentLocation
            environmentErrorMessage = nil
        } catch {
            environmentErrorMessage = error.localizedDescription
        }
    }

    func startLocationAndRefreshEnvironment(userInitiated: Bool = false) async {
        locationManager.requestNavigationAccessAndStart(userInitiated: userInitiated)
        if locationManager.currentLocation == nil {
            for _ in 0..<8 where locationManager.currentLocation == nil {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
        await refreshEnvironmentReport()
    }

    func selectTrip(_ trip: TripPlan) {
        selectedTrip = trip
        persistSelectedTripID()
    }

    func saveSelectedTrip() {
        guard trips.contains(where: { $0.id == selectedTrip.id }) else { return }
        selectedTrip.updatedAt = .now
        if let index = trips.firstIndex(where: { $0.id == selectedTrip.id }) {
            trips[index] = selectedTrip
        }
        sortTripsByRecentActivity()
        persistTrips()
        persistSelectedTripID()
    }

    @discardableResult
    func createTrip(title: String, startDate: Date, endDate: Date, notes: String) -> TripPlan {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let coordinate = locationManager.currentLocation?.coordinate ?? selectedTrip.meetingPoint
        let trip = TripPlan(
            id: UUID(),
            title: cleanTitle.isEmpty ? "رحلة جديدة" : cleanTitle,
            startDate: startDate,
            endDate: max(endDate, startDate),
            meetingPoint: coordinate,
            routeName: "مسار مخصص",
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            participants: [],
            status: .planned,
            updatedAt: .now
        )
        trips.insert(trip, at: 0)
        selectedTrip = trip
        statusMessage = "تم إنشاء الرحلة"
        persistTrips()
        persistSelectedTripID()
        return trip
    }

    func addParticipant(_ name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        if !selectedTrip.participants.contains(cleanName) {
            selectedTrip.participants.append(cleanName)
            saveSelectedTrip()
        }
    }

    func removeParticipants(at offsets: IndexSet) {
        selectedTrip.participants.remove(atOffsets: offsets)
        saveSelectedTrip()
    }

    func removeTrips(at offsets: IndexSet) {
        let removedIDs = Set(offsets.compactMap { trips.indices.contains($0) ? trips[$0].id : nil })
        trips.remove(atOffsets: offsets)
        if trips.isEmpty {
            selectedTrip = TripPlan.draft
            UserDefaults.standard.removeObject(forKey: AppStorageKey.selectedTripID)
        } else if removedIDs.contains(selectedTrip.id), let firstTrip = trips.first {
            selectedTrip = firstTrip
        }
        persistTrips()
        persistSelectedTripID()
    }

    func addHiddenPlace(_ place: HiddenPlace) {
        hiddenPlaces.insert(place, at: 0)
        statusMessage = "تم حفظ الموقع وإرساله للمراجعة"
        persistHiddenPlaces()
    }

    func setTripDestination(to place: HiddenPlace) {
        guard !trips.isEmpty else {
            let trip = TripPlan(
                id: UUID(),
                title: place.name,
                startDate: .now,
                endDate: Calendar.current.date(byAdding: .hour, value: 8, to: .now) ?? .now,
                meetingPoint: place.coordinate,
                routeName: "مسار مباشر",
                notes: place.notes,
                participants: [],
                status: .planned,
                updatedAt: .now
            )
            trips.insert(trip, at: 0)
            selectedTrip = trip
            persistTrips()
            persistSelectedTripID()
            statusMessage = "تم إنشاء رحلة وتحديد الوجهة: \(place.name)"
            return
        }
        selectedTrip.meetingPoint = place.coordinate
        selectedTrip.title = selectedTrip.title.isEmpty ? place.name : selectedTrip.title
        selectedTrip.updatedAt = .now
        saveSelectedTrip()
        statusMessage = "تم تحديد الوجهة: \(place.name)"
    }

    func suggestedDirtRoadRoutes(destination: CLLocationCoordinate2D? = nil) -> [DirtRoadRoute] {
        let target = destination ?? selectedTrip.meetingPoint
        var routes = DirtRoadRoute.nearestRoutes(to: target, limit: 4)
        if let preferred = selectedDirtRoadRoute, !routes.contains(where: { $0.id == preferred.id }) {
            routes.insert(preferred, at: 0)
        }
        return routes
    }

    var selectedDirtRoadRoute: DirtRoadRoute? {
        DirtRoadRoute.route(withID: preferredDirtRoadRouteID)
    }

    func selectDirtRoadRoute(_ route: DirtRoadRoute) {
        preferredDirtRoadRouteID = route.id
        selectedTrip.meetingPoint = route.endCoordinate
        selectedTrip.routeName = route.name
        selectedTrip.updatedAt = .now
        saveSelectedTrip()
        statusMessage = "تم تفعيل \(route.name) كمسار بري مفضل"
    }

    func startSelectedTrip() {
        guard hasSelectedTrip else {
            statusMessage = "أنشئ رحلة أولًا قبل بدء الرحلة"
            return
        }
        selectedTrip.status = .active
        selectedTrip.startDate = .now
        if selectedTrip.endDate <= selectedTrip.startDate {
            selectedTrip.endDate = Calendar.current.date(byAdding: .hour, value: 8, to: selectedTrip.startDate) ?? selectedTrip.startDate
        }
        selectedTrip.updatedAt = .now
        saveSelectedTrip()
        locationManager.requestNavigationAccessAndStart(userInitiated: true)
        statusMessage = "بدأت الرحلة: \(selectedTrip.title)"
    }

    func endSelectedTrip() {
        guard hasSelectedTrip else {
            statusMessage = "لا توجد رحلة محفوظة لإنهائها"
            return
        }
        guard selectedTrip.status == .active else {
            statusMessage = "ابدأ الرحلة أولًا قبل إنهائها"
            return
        }
        selectedTrip.status = .completed
        selectedTrip.endDate = .now
        selectedTrip.updatedAt = .now
        saveSelectedTrip()
        locationManager.stopNavigation()
        statusMessage = "تم إنهاء الرحلة: \(selectedTrip.title)"
    }

    func toggleFavoriteDirtRoadRoute(_ route: DirtRoadRoute) {
        if favoriteDirtRoadRouteIDs.contains(route.id) {
            favoriteDirtRoadRouteIDs.removeAll { $0 == route.id }
            statusMessage = "تمت إزالة \(route.name) من المفضلة"
        } else {
            favoriteDirtRoadRouteIDs.insert(route.id, at: 0)
            statusMessage = "تم حفظ \(route.name) في المفضلة"
        }
    }

    func isFavoriteDirtRoadRoute(_ route: DirtRoadRoute) -> Bool {
        favoriteDirtRoadRouteIDs.contains(route.id)
    }

    func text(_ key: LocalizedKey) -> String {
        key.value(for: language)
    }

    var hasSelectedTrip: Bool {
        trips.contains(where: { $0.id == selectedTrip.id })
    }

    private func persistTrips() {
        AppStateStorage.saveTrips(trips)
    }

    private func sortTripsByRecentActivity() {
        trips.sort {
            if $0.status == .active && $1.status != .active { return true }
            if $1.status == .active && $0.status != .active { return false }
            return $0.updatedAt > $1.updatedAt
        }
    }

    private func persistHiddenPlaces() {
        AppStateStorage.saveHiddenPlaces(hiddenPlaces)
    }

    private func persistSelectedTripID() {
        guard hasSelectedTrip else {
            UserDefaults.standard.removeObject(forKey: AppStorageKey.selectedTripID)
            return
        }
        UserDefaults.standard.set(selectedTrip.id.uuidString, forKey: AppStorageKey.selectedTripID)
    }

    private static func mergedHiddenPlaces(_ stored: [HiddenPlace], with bundled: [HiddenPlace]) -> [HiddenPlace] {
        var merged = stored
        for place in bundled where !merged.contains(where: { samePlace($0, place) }) {
            merged.append(place)
        }
        return merged
    }

    private static func samePlace(_ first: HiddenPlace, _ second: HiddenPlace) -> Bool {
        let firstName = first.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ar"))
        let secondName = second.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ar"))
        let sameName = firstName == secondName

        let firstLocation = CLLocation(latitude: first.coordinate.latitude, longitude: first.coordinate.longitude)
        let secondLocation = CLLocation(latitude: second.coordinate.latitude, longitude: second.coordinate.longitude)
        return sameName && firstLocation.distance(from: secondLocation) < 1_500
    }
}

private enum AppStorageKey {
    static let language = "desertTrail.language"
    static let appearance = "desertTrail.appearance"
    static let selectedTripID = "desertTrail.selectedTripID"
    static let trips = "desertTrail.trips.v1"
    static let hiddenPlaces = "desertTrail.hiddenPlaces.v1"
    static let tripSharingConsent = "desertTrail.tripSharingConsent"
    static let termsAndPrivacyAccepted = "desertTrail.termsAndPrivacyAccepted.v1"
    static let preferredDirtRoadRouteID = "desertTrail.preferredDirtRoadRouteID"
    static let favoriteDirtRoadRouteIDs = "desertTrail.favoriteDirtRoadRouteIDs"
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch (self, language) {
        case (.system, .arabic): "حسب النظام"
        case (.light, .arabic): "نهاري"
        case (.dark, .arabic): "ليلي"
        case (.system, _): "System"
        case (.light, _): "Light"
        case (.dark, _): "Dark"
        }
    }
}

private enum AppStateStorage {
    static func loadTrips() -> [TripPlan]? {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKey.trips) else { return nil }
        return try? JSONDecoder().decode([StoredTripPlan].self, from: data).map(\.trip)
    }

    static func saveTrips(_ trips: [TripPlan]) {
        guard let data = try? JSONEncoder().encode(trips.map(StoredTripPlan.init)) else { return }
        UserDefaults.standard.set(data, forKey: AppStorageKey.trips)
    }

    static func loadHiddenPlaces() -> [HiddenPlace]? {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKey.hiddenPlaces) else { return nil }
        return try? JSONDecoder().decode([StoredHiddenPlace].self, from: data).map(\.place)
    }

    static func saveHiddenPlaces(_ places: [HiddenPlace]) {
        guard let data = try? JSONEncoder().encode(places.map(StoredHiddenPlace.init)) else { return }
        UserDefaults.standard.set(data, forKey: AppStorageKey.hiddenPlaces)
    }
}

private struct StoredCoordinate: Codable {
    let latitude: Double
    let longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct StoredTripPlan: Codable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let meetingPoint: StoredCoordinate
    let routeName: String
    let notes: String
    let participants: [String]
    let status: String?
    let updatedAt: Date?

    init(_ trip: TripPlan) {
        id = trip.id
        title = trip.title
        startDate = trip.startDate
        endDate = trip.endDate
        meetingPoint = StoredCoordinate(trip.meetingPoint)
        routeName = trip.routeName
        notes = trip.notes
        participants = trip.participants
        status = trip.status.rawValue
        updatedAt = trip.updatedAt
    }

    var trip: TripPlan {
        TripPlan(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            meetingPoint: meetingPoint.coordinate,
            routeName: routeName,
            notes: notes,
            participants: participants,
            status: TripLifecycleStatus(rawValue: status ?? "") ?? .planned,
            updatedAt: updatedAt ?? max(startDate, endDate)
        )
    }
}

private struct StoredHiddenPlace: Codable {
    let id: UUID
    let name: String
    let coordinate: StoredCoordinate
    let rating: Int
    let imageSystemName: String
    let notes: String
    let status: String
    let contributor: String
    let points: Int

    init(_ place: HiddenPlace) {
        id = place.id
        name = place.name
        coordinate = StoredCoordinate(place.coordinate)
        rating = place.rating
        imageSystemName = place.imageSystemName
        notes = place.notes
        status = place.status.rawValue
        contributor = place.contributor
        points = place.points
    }

    var place: HiddenPlace {
        HiddenPlace(
            id: id,
            name: name,
            coordinate: coordinate.coordinate,
            rating: rating,
            imageSystemName: imageSystemName,
            notes: notes,
            status: ReviewStatus(rawValue: status) ?? .pending,
            contributor: contributor,
            points: points
        )
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic
    case english
    case french
    case spanish
    case chinese

    var id: String { rawValue }
    var title: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        case .french: return "Français"
        case .spanish: return "Español"
        case .chinese: return "中文"
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
        case .french:
            return frenchValue
        case .spanish:
            return spanishValue
        case .chinese:
            return chineseValue
        }
    }

    private var arabicValue: String {
        switch self {
        case .appTitle: return "خرايم"
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
        case .appTitle: return "Kharayem"
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

    private var frenchValue: String {
        switch self {
        case .appTitle: return "Kharayem"
        case .map: return "Carte"
        case .compass: return "Boussole"
        case .planner: return "Planificateur"
        case .community: return "Communauté"
        case .weather: return "Environnement"
        case .share: return "Partager"
        case .offline: return "Cartes hors ligne"
        case .done: return "Terminé"
        case .cancel: return "Annuler"
        case .submit: return "Envoyer"
        case .altitude: return "Altitude"
        case .windSpeed: return "Vitesse du vent"
        case .windDirection: return "Direction du vent"
        case .startNavigationTools: return "Activer les outils de navigation"
        case .gpsReady: return "Prêt"
        case .gpsActive: return "Actif"
        case .north: return "Nord"
        case .northeast: return "Nord-est"
        case .east: return "Est"
        case .southeast: return "Sud-est"
        case .south: return "Sud"
        case .southwest: return "Sud-ouest"
        case .west: return "Ouest"
        case .northwest: return "Nord-ouest"
        default: return englishValue
        }
    }

    private var spanishValue: String {
        switch self {
        case .appTitle: return "Kharayem"
        case .map: return "Mapa"
        case .compass: return "Brújula"
        case .planner: return "Planificador"
        case .community: return "Comunidad"
        case .weather: return "Entorno"
        case .share: return "Compartir"
        case .offline: return "Mapas sin conexión"
        case .done: return "Listo"
        case .cancel: return "Cancelar"
        case .submit: return "Enviar"
        case .altitude: return "Altitud"
        case .windSpeed: return "Velocidad del viento"
        case .windDirection: return "Dirección del viento"
        case .startNavigationTools: return "Activar herramientas de navegación"
        case .gpsReady: return "Listo"
        case .gpsActive: return "Activo"
        case .north: return "Norte"
        case .northeast: return "Noreste"
        case .east: return "Este"
        case .southeast: return "Sureste"
        case .south: return "Sur"
        case .southwest: return "Suroeste"
        case .west: return "Oeste"
        case .northwest: return "Noroeste"
        default: return englishValue
        }
    }

    private var chineseValue: String {
        switch self {
        case .appTitle: return "Kharayem"
        case .map: return "地图"
        case .compass: return "指南针"
        case .planner: return "行程"
        case .community: return "社区"
        case .weather: return "环境"
        case .share: return "分享"
        case .offline: return "离线地图"
        case .done: return "完成"
        case .cancel: return "取消"
        case .submit: return "提交"
        case .altitude: return "海拔"
        case .windSpeed: return "风速"
        case .windDirection: return "风向"
        case .startNavigationTools: return "启动导航工具"
        case .gpsReady: return "就绪"
        case .gpsActive: return "活动"
        case .north: return "北"
        case .northeast: return "东北"
        case .east: return "东"
        case .southeast: return "东南"
        case .south: return "南"
        case .southwest: return "西南"
        case .west: return "西"
        case .northwest: return "西北"
        default: return englishValue
        }
    }
}
