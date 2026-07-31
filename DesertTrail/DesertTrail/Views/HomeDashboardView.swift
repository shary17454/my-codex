import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct HomeDashboardView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTab: AppTab
    @State private var showingQR = false
    @State private var showingActiveTrip = false
    @State private var showingAddPlace = false
    @State private var showingCreateTrip = false
    @State private var showingGeospatialCatalog = false
    @State private var showingEnvironmentDetails = false
    @State private var selectedAlertDetail: DashboardAlertDetail?
    @State private var selectedCommunityDetail: DashboardCommunityDetail?
    @State private var statusMessage: String?
    @State private var dashboardRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header
                versionTwoHero
                mapHero
                tripMetricBar
                quickActions
                contentCards
                primaryActions
                communitySummary
                alertStrip
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 110)
        }
        .background(homeBackground)
        .overlay(alignment: .bottom) {
            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.oasisTeal.opacity(0.94), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: .black.opacity(0.26), radius: 12, y: 5)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 86)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.22), value: statusMessage)
        .sheet(isPresented: $showingQR) {
            TripQRCodeSheet(trip: appState.selectedTrip)
        }
        .sheet(isPresented: $showingAddPlace) {
            HiddenPlaceForm()
        }
        .sheet(isPresented: $showingCreateTrip) {
            CreateTripSheet()
        }
        .sheet(isPresented: $showingGeospatialCatalog) {
            GeospatialLayerCatalogView()
        }
        .sheet(isPresented: $showingEnvironmentDetails) {
            EnvironmentDetailsView()
        }
        .sheet(item: $selectedAlertDetail) { detail in
            DashboardAlertDetailSheet(detail: detail)
        }
        .sheet(item: $selectedCommunityDetail) { detail in
            DashboardCommunityDetailSheet(detail: detail)
        }
        .navigationDestination(isPresented: $showingActiveTrip) {
            ActiveTripDriveView()
        }
        .onAppear {
            if ScreenshotConfiguration.showActiveDrive {
                showingActiveTrip = true
            }
        }
        .task {
            appState.locationManager.requestNavigationAccessAndStart(userInitiated: false)
            await appState.refreshEnvironmentReport()
            if appState.locationManager.isTracking {
                centerMapOnCurrentLocation()
            }
        }
        .onChange(of: appState.locationManager.currentLocation?.timestamp) { _, _ in
            guard appState.locationManager.isTracking else { return }
            centerMapOnCurrentLocation()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                interactionFeedback()
                selectedTab = .tools
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.trailSignal.opacity(0.24), lineWidth: 1))
                    .shadow(color: Color.trailSignal.opacity(0.18), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 3) {
                HStack(spacing: 8) {
                    Text(appState.text(.appTitle))
                        .font(.title.weight(.black))
                        .foregroundStyle(trailTitleGradient)
                    Image(systemName: "mountain.2.fill")
                        .foregroundStyle(Color.trailAmber)
                }
                Text(appState.language == .arabic ? "رحلتك تبدأ من هنا" : "Your trail starts here")
                    .font(.caption)
                    .foregroundStyle(Color.trailMist.opacity(0.64))
            }

            Spacer()

            Button {
                interactionFeedback()
                selectedTab = .community
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.trailAmber.opacity(0.26), lineWidth: 1))
                        .shadow(color: Color.trailAmber.opacity(0.18), radius: 12, y: 4)
                    Circle()
                        .fill(Color.trailAmber)
                        .frame(width: 9, height: 9)
                        .offset(x: -7, y: 8)
                }
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.trailMist)
    }

    private var versionTwoHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color.trailSignal, Color.trailAmber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.trailBase)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text("إصدار 2.3")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.trailMist)
                    Text("تصميم ليلي ميداني جديد يبرز الملاحة والطقس والرحلات بوضوح أعلى.")
                        .font(.subheadline)
                        .foregroundStyle(Color.trailMist.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                trailPill("ملاحة", "location.north.fill") {
                    appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
                    selectedTab = .compass
                    showStatus("تم تشغيل أدوات الملاحة والبوصلة")
                }
                trailPill("طقس", "cloud.sun.fill") {
                    openEnvironmentDetails()
                }
                trailPill("تنبيهات", "bell.badge.fill") {
                    appState.locationManager.requestBackgroundTripUpdates()
                    showStatus("تم تفعيل تنبيهات القرب عند توفر صلاحية الموقع دائمًا")
                }
            }
        }
        .padding(16)
        .background(heroSurface, in: RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.trailSignal.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: Color.trailSignal.opacity(0.12), radius: 18, y: 8)
    }

    private var mapHero: some View {
        ZStack(alignment: .topTrailing) {
            MapCanvasView(
                region: dashboardRegion,
                route: dashboardRoute,
                dirtRoadRoutes: dashboardDirtRoutes,
                places: appState.hiddenPlaces.filter { $0.status == .approved },
                tileTemplateURL: nil,
                tileOpacity: 0.7,
                showsUserLocation: appState.locationManager.isTracking,
                userInterfaceStyle: mapUserInterfaceStyle,
                onRegionChange: { dashboardRegion = $0 }
            )
            .frame(height: 218)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.trailSignal.opacity(0.18), lineWidth: 1))

            VStack(spacing: 10) {
                mapToolButton("square.3.layers.3d", label: "طبقات الخريطة") {
                    showingGeospatialCatalog = true
                }
                mapToolButton("location", label: "إظهار موقعي") {
                    appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
                    centerMapOnCurrentLocation()
                }
                mapToolButton("plus", label: "تكبير الخريطة") {
                    zoomMap(by: 0.55)
                }
                mapToolButton("minus", label: "تصغير الخريطة") {
                    zoomMap(by: 1.8)
                }
                mapToolButton("mappin.and.ellipse", label: "حفظ موقع") {
                    showingAddPlace = true
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)

            gpsPill
                .padding(12)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    scaleBar
                        .padding(12)
                }
            }
        }
        .frame(height: 218)
    }

    private var gpsPill: some View {
        HStack(spacing: 6) {
            Text(gpsPillTitle)
                .font(.caption.weight(.bold))
            Circle()
                .fill(gpsPillColor)
                .frame(width: 7, height: 7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.62), in: Capsule())
    }

    private var scaleBar: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("1 كم")
                .font(.caption2.weight(.semibold))
            Rectangle()
                .fill(Color.trailMist)
                .frame(width: 70, height: 3)
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var tripMetricBar: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
            dashboardMetric(title: "الاتجاه", value: headingText, subtitle: headingSubtitle, icon: "safari", tint: .trailSignal) {
                selectedTab = .compass
            }
            dashboardMetric(title: "الارتفاع", value: altitudeText, subtitle: "متر", icon: "mountain.2", tint: .trailAmber) {
                appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
                showStatus("يتم تحديث الارتفاع من GPS")
            }
            dashboardMetric(title: "السرعة", value: speedText, subtitle: "كم/س", icon: "speedometer", tint: .orange) {
                openActiveTrip()
            }
            dashboardMetric(title: "المسافة", value: distanceText, subtitle: "كم", icon: "mappin", tint: .blue) {
                openActiveTrip()
            }
            dashboardMetric(title: "حالة الموقع", value: gpsStatusText, subtitle: appState.locationManager.isTracking ? "نشط" : "جاهز", icon: "location.north", tint: gpsPillColor) {
                toggleLocationTracking()
            }
        }
        .padding(10)
        .background(Color.desertPanel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.trailSignal.opacity(0.16), lineWidth: 1))
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
            quickAction(title: "البوصلة", icon: "safari", tint: .trailSignal) { selectedTab = .compass }
            quickAction(title: "لوحة القيادة", icon: "speedometer", tint: .trailAmber) { openActiveTrip() }
            quickAction(title: "الطقس", icon: "cloud.sun.fill", tint: .blue) { openEnvironmentDetails() }
            quickAction(title: "جودة الهواء", icon: "leaf.fill", tint: .green) { openEnvironmentDetails() }
            quickAction(title: "أدوات الرحلة", icon: "briefcase.fill", tint: .purple) { selectedTab = .tools }
        }
    }

    private var contentCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 12)], spacing: 12) {
            upcomingTripCard
            featuredPlaceCard
        }
    }

    private var upcomingTripCard: some View {
        DashboardCard {
            if appState.hasSelectedTrip {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(appState.selectedTrip.status == .active ? "رحلة جارية" : "رحلاتي")
                            .font(.headline)
                        Image(systemName: "map")
                            .foregroundStyle(Color.desertCopper)
                        Spacer()
                        Label(appState.selectedTrip.status.title, systemImage: appState.selectedTrip.status.icon)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(appState.selectedTrip.status.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(appState.selectedTrip.status.tint.opacity(0.14), in: Capsule())
                    }

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.desertCopper.opacity(0.85), Color.desertSand.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "car.side.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(width: 82, height: 82)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(appState.selectedTrip.title)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(2)
                        Label(String(format: "%.3f, %.3f", appState.selectedTrip.meetingPoint.latitude, appState.selectedTrip.meetingPoint.longitude), systemImage: "mappin")
                        Label("\(appState.selectedTrip.participants.count) مشاركين", systemImage: "person.2")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                ProgressView(value: tripProgress)
                    .tint(Color.desertCopper)

                    HStack(spacing: 8) {
                        Button {
                            interactionFeedback()
                            if appState.selectedTrip.status == .active {
                                appState.endSelectedTrip()
                                showStatus("تم إنهاء الرحلة")
                            } else {
                                appState.startSelectedTrip()
                                showStatus("بدأت الرحلة وتم تشغيل GPS")
                            }
                        } label: {
                            Label(appState.selectedTrip.status == .active ? "إنهاء الرحلة" : "بدء الرحلة", systemImage: appState.selectedTrip.status == .active ? "stop.circle.fill" : "play.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appState.selectedTrip.status == .active ? .red : Color.oasisTeal)

                        Button {
                            interactionFeedback()
                            openActiveTrip()
                        } label: {
                            Label("متابعة", systemImage: "arrow.left")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.desertCopper)
                    }
                    .font(.subheadline.weight(.semibold))
                }
            } else {
                ContentUnavailableView {
                    Label("لا توجد رحلة نشطة", systemImage: "map")
                } description: {
                    Text("أنشئ رحلة وحدد اسمها ووقتها، ثم اختر وجهتها لتفعيل المسافة والاتجاه والتوجيه.")
                } actions: {
                    Button("إنشاء رحلة") {
                        interactionFeedback()
                        showingCreateTrip = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.desertCopper)
                }
            }
        }
    }

    private var featuredPlaceCard: some View {
        DashboardCard {
            if let place = appState.hiddenPlaces.first(where: { $0.status == .approved }) {
                featuredPlaceContent(place)
            } else {
                ContentUnavailableView {
                    Label("لا توجد مواقع معتمدة", systemImage: "mappin.slash")
                } description: {
                    Text("أضف موقعًا جديدًا ليظهر هنا بعد حفظه.")
                } actions: {
                    Button("إضافة موقع") {
                        interactionFeedback()
                        showingAddPlace = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.desertCopper)
                }
            }
        }
    }

    private func featuredPlaceContent(_ place: HiddenPlace) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("اكتشف مواقع جديدة")
                    .font(.headline)
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Color.desertCopper)
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.62, green: 0.38, blue: 0.18), Color(red: 0.96, green: 0.68, blue: 0.34)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(place.name)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(2)
                        Text(place.notes)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    .foregroundStyle(.white)
                    .padding(10)
                }
                .frame(height: 110)

            HStack {
                Text("\(place.rating).0")
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("(\(place.points))")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .font(.caption.weight(.semibold))
        }
    }

    private var primaryActions: some View {
        HStack(spacing: 12) {
            Button {
                interactionFeedback()
                showingCreateTrip = true
            } label: {
                Label("إنشاء رحلة جديدة", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DashboardActionButtonStyle())

            Button {
                interactionFeedback()
                shareCurrentTrip()
            } label: {
                Label("مشاركة رحلة", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DashboardActionButtonStyle())
        }
    }

    private var communitySummary: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    HStack(spacing: -8) {
                        ForEach(["person.crop.circle.fill", "person.crop.circle", "person.crop.circle.badge.checkmark"], id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(Color.desertCopper)
                                .background(Color.desertSurface, in: Circle())
                        }
                    }
                    Text(localParticipantSummary)
                        .font(.caption.weight(.bold))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("المجتمع")
                            .font(.headline)
                        Text("شارك مواقعك وتجاربك مع رحالة الدروب")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    communityStat("المشاركون", "\(localParticipantCount)", "person", detail: .participants)
                    communityStat("المواقع", "\(appState.hiddenPlaces.count)", "mappin", detail: .places)
                    communityStat("الرحلات", "\(appState.trips.count)", "figure.hiking", detail: .trips)
                    communityStat("النقاط", "\(localPoints)", "trophy", detail: .points)
                }
            }
        }
    }

    private var alertStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("تنبيهات مهمة", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.desertCopper)

            if appState.environmentalReport.isLiveData {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    alertChip(
                        "AQI \(appState.environmentalReport.airQualityDisplayText)",
                        "leaf.fill",
                        appState.environmentalReport.airQualityIndex > 150 ? .red : .green,
                        detail: .airQuality
                    )
                    alertChip(
                        "\(Int(appState.environmentalReport.windSpeedKPH.rounded())) كم/س",
                        "wind",
                        appState.environmentalReport.windSpeedKPH > 35 ? .orange : .green,
                        detail: .wind
                    )
                    alertChip(
                        "\(Int(appState.environmentalReport.temperatureCelsius.rounded()))°C",
                        "thermometer.sun",
                        appState.environmentalReport.temperatureCelsius > 42 ? .red : .yellow,
                        detail: .temperature
                    )
                    alertChip(
                        appState.environmentalReport.weatherSummary,
                        "cloud.sun",
                        .blue,
                        detail: .weather
                    )
                }
            } else {
                Button {
                    interactionFeedback()
                    refreshWeather()
                } label: {
                    Label(appState.isEnvironmentRefreshing ? "جاري تحديث الطقس" : "اضغط لتحديث الطقس وجودة الهواء", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color.desertSurface, in: RoundedRectangle(cornerRadius: 8))
    }

    private var headingText: String {
        guard let heading = appState.locationManager.resolvedHeadingDegrees else { return "--" }
        return "\(Int(heading.rounded()))°"
    }

    private var headingSubtitle: String {
        if appState.locationManager.resolvedHeadingDegrees != nil {
            return "اتجاه الجهاز"
        }
        return appState.locationManager.supportsHeading ? "بانتظار البوصلة" : "تحرك لقراءة الاتجاه"
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.altitudeMeters else { return "--" }
        return "\(Int(altitude))"
    }

    private var speedText: String {
        guard let speed = appState.locationManager.speedKPH else { return "--" }
        return "\(Int(speed.rounded()))"
    }

    private var distanceText: String {
        guard appState.hasSelectedTrip else { return "--" }
        guard let current = appState.locationManager.currentLocation else { return "--" }
        let target = CLLocation(latitude: appState.selectedTrip.meetingPoint.latitude, longitude: appState.selectedTrip.meetingPoint.longitude)
        return String(format: "%.1f", current.distance(from: target) / 1000)
    }

    private var gpsStatusText: String {
        switch appState.locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return appState.locationManager.currentLocation == nil ? "ينتظر" : "جيد"
        case .denied, .restricted:
            return "مرفوض"
        default:
            return "اطلب"
        }
    }

    private var tripProgress: Double {
        if appState.selectedTrip.status == .completed { return 1 }
        if appState.selectedTrip.status == .planned { return 0 }
        let total = max(appState.selectedTrip.endDate.timeIntervalSince(appState.selectedTrip.startDate), 1)
        let elapsed = Date().timeIntervalSince(appState.selectedTrip.startDate)
        return min(max(elapsed / total, 0), 1)
    }

    private var localParticipantCount: Int {
        Set(appState.trips.flatMap(\.participants)).count
    }

    private var localParticipantSummary: String {
        localParticipantCount == 0 ? "لا يوجد مشاركون محفوظون" : "\(localParticipantCount) مشاركين محفوظين"
    }

    private var localPoints: Int {
        appState.hiddenPlaces.reduce(into: 0) { total, place in
            total += max(place.points, 0)
        }
    }

    private var dashboardRoute: [CLLocationCoordinate2D] {
        guard appState.hasSelectedTrip else {
            return appState.locationManager.currentLocation.map { [$0.coordinate] } ?? []
        }
        guard let current = appState.locationManager.currentLocation?.coordinate else {
            return [appState.selectedTrip.meetingPoint]
        }
        return [current, appState.selectedTrip.meetingPoint]
    }

    private var dashboardDirtRoutes: [DirtRoadRoute] {
        appState.suggestedDirtRoadRoutes(destination: appState.selectedTrip.meetingPoint)
    }

    private var gpsPillTitle: String {
        switch appState.locationManager.authorizationStatus {
        case .denied, .restricted: return "GPS غير مسموح"
        case .notDetermined: return "GPS يحتاج إذنًا"
        default: return appState.locationManager.currentLocation == nil ? "جاري تحديد الموقع" : "GPS متصل"
        }
    }

    private var gpsPillColor: Color {
        appState.locationManager.currentLocation == nil ? .orange : .green
    }

    private var mapUserInterfaceStyle: UIUserInterfaceStyle {
        colorScheme == .dark ? .dark : .light
    }

    private var homeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.trailBase, Color.trailNight, Color(red: 0.10, green: 0.075, blue: 0.050)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.trailSignal.opacity(0.20), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            RadialGradient(
                colors: [Color.trailAmber.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }

    private var heroSurface: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.115),
                Color.trailSignal.opacity(0.105),
                Color.trailAmber.opacity(0.075)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var trailTitleGradient: LinearGradient {
        LinearGradient(
            colors: [Color.trailMist, Color.trailAmber, Color.trailSignal],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func trailPill(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            interactionFeedback()
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.trailMist)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08), in: Capsule())
                .overlay(Capsule().stroke(Color.trailSignal.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func mapToolButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            interactionFeedback()
            action()
        } label: {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.trailMist)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.trailSignal.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.20), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func openActiveTrip() {
        guard appState.hasSelectedTrip else {
            statusMessage = "أنشئ رحلة أولًا لتفعيل لوحة القيادة والتوجيه."
            showingCreateTrip = true
            return
        }
        showingActiveTrip = true
    }

    private func shareCurrentTrip() {
        guard appState.hasSelectedTrip else {
            statusMessage = "أنشئ رحلة أولًا ثم شارك رمز QR الخاص بها."
            showingCreateTrip = true
            return
        }
        showingQR = true
    }

    private func dashboardMetric(title: String, value: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            interactionFeedback()
            action()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                    Text(value)
                        .font(.headline.monospacedDigit().weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.66))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .padding(10)
            .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value) \(subtitle)")
    }

    private func quickAction(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            interactionFeedback()
            action()
        } label: {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.16), in: Circle())
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.trailMist)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 4)
            .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func communityStat(_ title: String, _ value: String, _ icon: String, detail: DashboardCommunityDetail) -> some View {
        Button {
            interactionFeedback()
            selectedCommunityDetail = detail
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                HStack(spacing: 4) {
                    Text(value)
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Color.desertCopper)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.desertBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.desertCopper.opacity(0.16), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint("يفتح تفاصيل \(title)")
    }

    private func alertChip(_ title: String, _ icon: String, _ color: Color, detail: DashboardAlertDetail) -> some View {
        Button {
            interactionFeedback()
            selectedAlertDetail = detail
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.bold))
                    .opacity(0.72)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 8)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.22), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(detail.title): \(title)")
        .accessibilityHint("يفتح معلومات وإرشادات \(detail.title)")
    }

    private func refreshWeather() {
        appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
        showStatus("جاري تحديث بيانات الطقس وجودة الهواء")
        Task {
            await appState.refreshEnvironmentReport()
            if appState.environmentErrorMessage == nil {
                showStatus("تم تحديث الطقس: \(Int(appState.environmentalReport.temperatureCelsius))°C و AQI \(appState.environmentalReport.airQualityDisplayText)")
            } else {
                showStatus("تعذر تحديث الطقس. تحقق من الاتصال وحاول مرة أخرى")
            }
        }
    }

    private func openEnvironmentDetails() {
        showingEnvironmentDetails = true
        refreshWeather()
    }

    private func centerMapOnCurrentLocation() {
        guard let coordinate = appState.locationManager.currentLocation?.coordinate else {
            appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
            showStatus("بانتظار إشارة GPS لتحديد موقعك")
            return
        }
        dashboardRegion.center = coordinate
        dashboardRegion.span = MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
    }

    private func zoomMap(by factor: Double) {
        dashboardRegion.span.latitudeDelta = min(max(dashboardRegion.span.latitudeDelta * factor, 0.002), 90)
        dashboardRegion.span.longitudeDelta = min(max(dashboardRegion.span.longitudeDelta * factor, 0.002), 180)
    }

    private func toggleLocationTracking() {
        if appState.locationManager.isTracking {
            appState.locationManager.stopNavigation()
            showStatus("تم إيقاف تتبع الموقع")
        } else {
            appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
            showStatus("تم تشغيل تتبع الموقع")
        }
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }

    private func interactionFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private enum DashboardAlertDetail: String, Identifiable {
    case airQuality
    case wind
    case temperature
    case weather

    var id: String { rawValue }

    var title: String {
        switch self {
        case .airQuality: return "جودة الهواء"
        case .wind: return "الرياح"
        case .temperature: return "الحرارة"
        case .weather: return "حالة الطقس"
        }
    }

    var icon: String {
        switch self {
        case .airQuality: return "leaf.fill"
        case .wind: return "wind"
        case .temperature: return "thermometer.sun.fill"
        case .weather: return "cloud.sun.fill"
        }
    }

    var color: Color {
        switch self {
        case .airQuality: return .green
        case .wind: return .orange
        case .temperature: return .yellow
        case .weather: return .blue
        }
    }

    func value(from report: EnvironmentalReport) -> String {
        switch self {
        case .airQuality:
            return "AQI \(report.airQualityDisplayText)"
        case .wind:
            return "\(Int(report.windSpeedKPH.rounded())) كم/س"
        case .temperature:
            return "\(Int(report.temperatureCelsius.rounded()))°C"
        case .weather:
            return report.weatherSummary
        }
    }

    func status(from report: EnvironmentalReport) -> String {
        switch self {
        case .airQuality:
            if report.airQualityIndex >= 151 { return "غير مناسب للرحلات الطويلة" }
            if report.airQualityIndex >= 101 { return "يحتاج انتباه" }
            return "مناسب غالبًا"
        case .wind:
            if report.windSpeedKPH >= 45 { return "رياح قوية" }
            if report.windSpeedKPH >= 28 { return "رياح متوسطة" }
            return "رياح خفيفة"
        case .temperature:
            if report.temperatureCelsius >= 43 { return "حرارة عالية جدًا" }
            if report.temperatureCelsius >= 36 { return "حرارة تحتاج احتياط" }
            return "مناسبة غالبًا"
        case .weather:
            return report.weatherSummary
        }
    }

    func guidance(from report: EnvironmentalReport) -> [String] {
        switch self {
        case .airQuality:
            if report.airQualityIndex >= 151 {
                return [
                    "قلّل المشي الطويل والتعرض للغبار.",
                    "يفضل تأجيل الرحلة الحساسة للأطفال أو مرضى الربو.",
                    "تابع الجهات الرسمية إذا ظهرت عاصفة ترابية أو انخفاض رؤية."
                ]
            }
            return [
                "مؤشر جودة الهواء ضمن نطاق قابل للرحلة غالبًا.",
                "راقب التغيرات عند الاقتراب من طرق ترابية أو مناطق غبار.",
                "حدّث البيانات قبل الانطلاق وأثناء التوقفات الطويلة."
            ]
        case .wind:
            if report.windSpeedKPH >= 35 {
                return [
                    "تجنب الحواف المكشوفة وبطون الأودية وقت الغبار.",
                    "ثبّت المظلات والخيام وتحقق من اتجاه الريح قبل التخييم.",
                    "خفف السرعة على الطرق الترابية لأن الغبار قد يخفض الرؤية."
                ]
            }
            return [
                "سرعة الرياح لا تظهر خطرًا واضحًا الآن.",
                "استخدم سهم الرياح في البوصلة لمعرفة اتجاه حركة الهواء.",
                "حدّث الطقس إذا تغيّر الموقع أو بدأت الرحلة."
            ]
        case .temperature:
            if report.temperatureCelsius >= 40 {
                return [
                    "زد كمية الماء وخطط للتوقف في الظل.",
                    "تجنب المشي أو تغيير الإطارات تحت الشمس وقت الظهيرة.",
                    "راقب حرارة الأطفال وكبار السن والحيوانات المرافقة."
                ]
            }
            return [
                "درجة الحرارة مناسبة غالبًا للرحلة مع الاحتياطات المعتادة.",
                "احمل ماءً كافيًا حتى لو كانت القراءة معتدلة.",
                "راجع الحرارة مجددًا قبل المسارات الطويلة."
            ]
        case .weather:
            return [
                "هذه خلاصة سريعة من بيانات الطقس الحالية.",
                "افتح التفاصيل لتأكيد الحرارة والرياح وجودة الهواء قبل الانطلاق.",
                "لا تعتمد عليها بديلًا عن تنبيهات الجهات الرسمية عند الظروف الشديدة."
            ]
        }
    }
}

private enum DashboardCommunityDetail: String, Identifiable {
    case participants
    case places
    case trips
    case points

    var id: String { rawValue }

    var title: String {
        switch self {
        case .participants: return "المشاركون"
        case .places: return "المواقع"
        case .trips: return "الرحلات"
        case .points: return "النقاط"
        }
    }

    var icon: String {
        switch self {
        case .participants: return "person.2.fill"
        case .places: return "mappin.and.ellipse"
        case .trips: return "figure.hiking"
        case .points: return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .participants: return .orange
        case .places: return .blue
        case .trips: return .green
        case .points: return .yellow
        }
    }

    @MainActor
    func value(from appState: AppState) -> String {
        switch self {
        case .participants:
            return "\(Set(appState.trips.flatMap(\.participants)).count)"
        case .places:
            return "\(appState.hiddenPlaces.count)"
        case .trips:
            return "\(appState.trips.count)"
        case .points:
            let points = appState.hiddenPlaces.reduce(into: 0) { total, place in
                total += max(place.points, 0)
            }
            return "\(points)"
        }
    }

    @MainActor
    func summary(from appState: AppState) -> String {
        switch self {
        case .participants:
            let count = Set(appState.trips.flatMap(\.participants)).count
            return count == 0 ? "لا يوجد مشاركون محفوظون بعد." : "لديك \(count) مشاركين محفوظين في رحلات الدروب."
        case .places:
            return "عدد المواقع البرية والمخفية المحفوظة في التطبيق."
        case .trips:
            return "عدد الرحلات الموجودة حاليًا، وتشمل المخططة والجارية والمكتملة."
        case .points:
            return "مجموع نقاط المجتمع المحسوبة من المواقع والمساهمات المحفوظة."
        }
    }

    @MainActor
    func details(from appState: AppState) -> [String] {
        switch self {
        case .participants:
            let names = Array(Set(appState.trips.flatMap(\.participants))).sorted()
            if names.isEmpty {
                return [
                    "أضف مشاركين عند إنشاء الرحلة أو تعديلها.",
                    "تظهر هنا الأسماء المحفوظة في الرحلات المحلية.",
                    "لا تتم مشاركة الأسماء إلا عند استخدام خيار مشاركة الرحلة."
                ]
            }
            return names.prefix(6).map { "مشارك محفوظ: \($0)" } + [
                "يمكن استخدام هذه القائمة لمراجعة من شارك في الرحلات السابقة."
            ]
        case .places:
            let approved = appState.hiddenPlaces.filter { $0.status == .approved }.count
            let pending = appState.hiddenPlaces.count - approved
            return [
                "المواقع المعتمدة: \(approved)",
                "المواقع غير المعتمدة أو قيد المراجعة: \(pending)",
                "اضغط على الخريطة أو إضافة موقع لحفظ مكان جديد مع ملاحظاتك."
            ]
        case .trips:
            let active = appState.trips.filter { $0.status == .active }.count
            let planned = appState.trips.filter { $0.status == .planned }.count
            let completed = appState.trips.filter { $0.status == .completed }.count
            return [
                "رحلات جارية: \(active)",
                "رحلات مخططة: \(planned)",
                "رحلات مكتملة: \(completed)",
                "يفترض ترتيب الرحلات حسب الأحدث في شاشة الرحلات."
            ]
        case .points:
            return [
                "النقاط تزيد من المواقع ذات التقييم والمساهمات المفيدة.",
                "تستخدم النقاط كمؤشر نشاط محلي داخل التطبيق.",
                "لا تمثل النقاط مكافآت مالية أو ترتيبًا رسميًا خارج التطبيق."
            ]
        }
    }
}

private struct DashboardCommunityDetailSheet: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let detail: DashboardCommunityDetail

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    detailList
                    actions
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(detail.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: detail.icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(detail.color)
                .frame(width: 52, height: 52)
                .background(detail.color.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(detail.value(from: appState))
                    .font(.title.weight(.black).monospacedDigit())
                Text(detail.summary(from: appState))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var detailList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("التفاصيل", systemImage: "list.bullet.rectangle")
                .font(.headline)

            ForEach(detail.details(from: appState), id: \.self) { row in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(detail.color)
                        .padding(.top, 2)
                    Text(row)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Label("العودة للرئيسية", systemImage: "house.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(detail.color)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct DashboardAlertDetailSheet: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let detail: DashboardAlertDetail

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    guidanceCard
                    sourceCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(detail.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: detail.icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(detail.color)
                    .frame(width: 50, height: 50)
                    .background(detail.color.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(detail.value(from: appState.environmentalReport))
                        .font(.title2.weight(.black))
                        .monospacedDigit()
                    Text(detail.status(from: appState.environmentalReport))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text("آخر تحديث: \(appState.environmentalReport.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var guidanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("ماذا يعني هذا؟", systemImage: "info.circle.fill")
                .font(.headline)

            ForEach(detail.guidance(from: appState.environmentalReport), id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(detail.color)
                        .padding(.top, 2)
                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("ملاحظة ميدانية", systemImage: "exclamationmark.shield.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("القراءات تعتمد على موقع الجهاز والاتصال بخدمات الطقس وجودة الهواء. استخدمها كمؤشر مساعد، وراجع التحذيرات الرسمية عند الظروف القاسية.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
                Task { await appState.refreshEnvironmentReport() }
            } label: {
                Label("تحديث البيانات", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(detail.color)
            .disabled(appState.isEnvironmentRefreshing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct EnvironmentDetailsView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    EnvironmentBanner(report: appState.environmentalReport)

                    if appState.environmentalReport.isLiveData {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            environmentMetric(
                                "الحرارة",
                                "\(Int(appState.environmentalReport.temperatureCelsius.rounded()))°C",
                                "thermometer.sun.fill"
                            )
                            environmentMetric(
                                "جودة الهواء",
                                "AQI \(appState.environmentalReport.airQualityDisplayText)",
                                "leaf.fill"
                            )
                            environmentMetric(
                                "سرعة الرياح",
                                "\(Int(appState.environmentalReport.windSpeedKPH.rounded())) كم/س",
                                "wind"
                            )
                            environmentMetric(
                                "اتجاه الرياح",
                                "\(Int(appState.environmentalReport.windDirectionDegrees.rounded()))°",
                                "location.north.fill"
                            )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("الحالة الحالية")
                                .font(.headline)
                            Text(appState.environmentalReport.weatherSummary)
                                .foregroundStyle(.secondary)
                            Text("آخر تحديث: \(appState.environmentalReport.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    } else {
                        ContentUnavailableView {
                            Label("البيانات غير متاحة", systemImage: "cloud.slash")
                        } description: {
                            Text(appState.environmentErrorMessage ?? "فعّل الموقع وتحقق من الاتصال ثم أعد المحاولة.")
                        } actions: {
                            Button("تحديث") {
                                refresh()
                            }
                        }
                    }

                    Text("تعتمد بيانات الطقس وجودة الهواء على الموقع الحالي والاتصال بخدمات الطقس العامة. لا تُستخدم كبديل عن تحذيرات الجهات الرسمية.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("الطقس وجودة الهواء")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
            .task {
                guard !appState.environmentalReport.isLiveData else { return }
                refresh()
            }
        }
    }

    private func environmentMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.desertCopper)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private func refresh() {
        appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
        Task {
            await appState.refreshEnvironmentReport()
        }
    }
}

private struct DashboardCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.white.opacity(0.085), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.trailSignal.opacity(0.13), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }
}

private struct DashboardActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.trailMist)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(
                configuration.isPressed
                ? Color.trailAmber.opacity(0.32)
                : Color.white.opacity(0.09),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.trailAmber.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
    }
}

private struct TripQRCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let trip: TripPlan

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text(trip.title)
                    .font(.title3.weight(.bold))

                QRCodeGenerator.image(from: trip.shareURL.absoluteString)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8))

                Text(trip.shareURL.absoluteString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(Color.desertBackground)
            .navigationTitle("مشاركة الرحلة")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Color {
    static let desertBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.025, green: 0.035, blue: 0.040, alpha: 1)
            : UIColor(red: 0.075, green: 0.090, blue: 0.090, alpha: 1)
    })
    static let desertSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.090, green: 0.105, blue: 0.105, alpha: 1)
            : UIColor(red: 0.105, green: 0.120, blue: 0.115, alpha: 1)
    })
    static let desertInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.88, green: 0.94, blue: 0.91, alpha: 1)
            : UIColor(red: 0.88, green: 0.94, blue: 0.91, alpha: 1)
    })
    static let desertPanel = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.080, green: 0.095, blue: 0.092, alpha: 0.96)
            : UIColor(red: 0.090, green: 0.105, blue: 0.100, alpha: 0.94)
    })
}
