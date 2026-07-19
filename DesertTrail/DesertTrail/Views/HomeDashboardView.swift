import CoreLocation
import MapKit
import SwiftUI

struct HomeDashboardView: View {
    @Environment(AppState.self) private var appState: AppState
    @Binding var selectedTab: AppTab
    @State private var showingQR = false
    @State private var showingActiveTrip = false
    @State private var showingAddPlace = false
    @State private var showingCreateTrip = false
    @State private var showingGeospatialCatalog = false
    @State private var showingEnvironmentDetails = false
    @State private var statusMessage: String?
    @State private var dashboardRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                mapHero
                tripMetricBar
                quickActions
                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.oasisTeal, in: RoundedRectangle(cornerRadius: 8))
                }
                contentCards
                primaryActions
                communitySummary
                alertStrip
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 110)
        }
        .background(Color.desertBackground.ignoresSafeArea())
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
        .navigationDestination(isPresented: $showingActiveTrip) {
            ActiveTripDriveView()
        }
        .onAppear {
            if ScreenshotConfiguration.showActiveDrive {
                showingActiveTrip = true
            }
        }
        .task {
            await appState.startLocationAndRefreshEnvironment()
            centerMapOnCurrentLocation()
        }
        .onChange(of: appState.locationManager.currentLocation?.timestamp) { _, _ in
            guard appState.locationManager.isTracking else { return }
            centerMapOnCurrentLocation()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                selectedTab = .tools
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color.desertSurface, in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 3) {
                HStack(spacing: 8) {
                    Text(appState.text(.appTitle))
                        .font(.title2.weight(.bold))
                    Image(systemName: "mountain.2.fill")
                        .foregroundStyle(Color.desertCopper)
                }
                Text(appState.language == .arabic ? "رحلتك تبدأ من هنا" : "Your trail starts here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectedTab = .community
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color.desertSurface, in: Circle())
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 9, height: 9)
                        .offset(x: -7, y: 8)
                }
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.desertInk)
    }

    private var mapHero: some View {
        ZStack(alignment: .topTrailing) {
            MapCanvasView(
                region: dashboardRegion,
                route: dashboardRoute,
                places: appState.hiddenPlaces.filter { $0.status == .approved },
                tileTemplateURL: nil,
                tileOpacity: 0.7,
                onRegionChange: { dashboardRegion = $0 }
            )
            .frame(height: 218)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 10) {
                mapToolButton("square.3.layers.3d", label: "طبقات الخريطة") {
                    showingGeospatialCatalog = true
                }
                mapToolButton("location", label: "إظهار موقعي") {
                    appState.locationManager.startNavigation()
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
                .fill(Color.desertInk)
                .frame(width: 70, height: 3)
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var tripMetricBar: some View {
        HStack(spacing: 0) {
            dashboardMetric(title: "الاتجاه", value: headingText, subtitle: headingSubtitle, icon: "safari") {
                selectedTab = .compass
            }
            Divider().frame(height: 54)
            dashboardMetric(title: "الارتفاع", value: altitudeText, subtitle: "متر", icon: "mountain.2") {
                appState.locationManager.startNavigation()
                showStatus("يتم تحديث الارتفاع من GPS")
            }
            Divider().frame(height: 54)
            dashboardMetric(title: "السرعة", value: speedText, subtitle: "كم/س", icon: "speedometer") {
                openActiveTrip()
            }
            Divider().frame(height: 54)
            dashboardMetric(title: "المسافة", value: distanceText, subtitle: "كم", icon: "mappin") {
                openActiveTrip()
            }
            Divider().frame(height: 54)
            dashboardMetric(title: "حالة الموقع", value: gpsStatusText, subtitle: appState.locationManager.isTracking ? "نشط" : "جاهز", icon: "location.north") {
                toggleLocationTracking()
            }
        }
        .padding(.vertical, 14)
        .background(Color.desertPanel, in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.white)
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
            quickAction(title: "البوصلة", icon: "safari") { selectedTab = .compass }
            quickAction(title: "لوحة القيادة", icon: "speedometer") { openActiveTrip() }
            quickAction(title: "الطقس", icon: "cloud.sun.fill") { openEnvironmentDetails() }
            quickAction(title: "جودة الهواء", icon: "leaf.fill") { openEnvironmentDetails() }
            quickAction(title: "أدوات الرحلة", icon: "briefcase.fill") { selectedTab = .tools }
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
                    Text("رحلاتي القادمة")
                        .font(.headline)
                    Image(systemName: "map")
                        .foregroundStyle(Color.desertCopper)
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

                    Button {
                        openActiveTrip()
                } label: {
                    HStack {
                        Text("متابعة الرحلة")
                        Spacer()
                        Image(systemName: "arrow.left")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.desertCopper, in: RoundedRectangle(cornerRadius: 8))
                }
                    .buttonStyle(.plain)
                }
            } else {
                ContentUnavailableView {
                    Label("لا توجد رحلة نشطة", systemImage: "map")
                } description: {
                    Text("أنشئ رحلة وحدد اسمها ووقتها، ثم اختر وجهتها لتفعيل المسافة والاتجاه والتوجيه.")
                } actions: {
                    Button("إنشاء رحلة") {
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
                showingCreateTrip = true
            } label: {
                Label("إنشاء رحلة جديدة", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DashboardActionButtonStyle())

            Button {
                showingQR = true
            } label: {
                Label("مشاركة رحلة", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DashboardActionButtonStyle())
            .disabled(!appState.hasSelectedTrip)
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
                        Text("شارك مواقعك وتجاربك مع رحالة الدرب")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    communityStat("المشاركون", "\(localParticipantCount)", "person")
                    communityStat("المواقع", "\(appState.hiddenPlaces.count)", "mappin")
                    communityStat("الرحلات", "\(appState.trips.count)", "figure.hiking")
                    communityStat("النقاط", "\(localPoints)", "trophy")
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
                    alertChip("AQI \(appState.environmentalReport.airQualityDisplayText)", "leaf.fill", appState.environmentalReport.airQualityIndex > 150 ? .red : .green)
                    alertChip("\(Int(appState.environmentalReport.windSpeedKPH.rounded())) كم/س", "wind", appState.environmentalReport.windSpeedKPH > 35 ? .orange : .green)
                    alertChip("\(Int(appState.environmentalReport.temperatureCelsius.rounded()))°C", "thermometer.sun", appState.environmentalReport.temperatureCelsius > 42 ? .red : .yellow)
                    alertChip(appState.environmentalReport.weatherSummary, "cloud.sun", .blue)
                }
            } else {
                Button(action: refreshWeather) {
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

    private func mapToolButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.desertInk)
                .frame(width: 38, height: 38)
                .background(Color.desertSurface, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func openActiveTrip() {
        guard appState.hasSelectedTrip else {
            statusMessage = "أنشئ رحلة أولًا لتفعيل التوجيه والمسافة"
            showingCreateTrip = true
            return
        }
        showingActiveTrip = true
    }

    private func dashboardMetric(title: String, value: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.76))
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.92))
                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, minHeight: 74)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value) \(subtitle)")
    }

    private func quickAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.desertCopper)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.desertInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 4)
            .background(Color.desertSurface, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func communityStat(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.desertCopper)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(Color.desertBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    private func alertChip(_ title: String, _ icon: String, _ color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 6)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private func refreshWeather() {
        appState.locationManager.startNavigation()
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
            appState.locationManager.startNavigation()
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
        appState.locationManager.startNavigation()
        Task {
            await appState.refreshEnvironmentReport()
        }
    }
}

private struct DashboardCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

private struct DashboardActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.desertInk)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(configuration.isPressed ? Color.desertSand.opacity(0.45) : Color.desertSurface, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
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
            ? UIColor(red: 0.055, green: 0.047, blue: 0.039, alpha: 1)
            : UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1)
    })
    static let desertSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let desertInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.92, blue: 0.85, alpha: 1)
            : UIColor(red: 0.20, green: 0.14, blue: 0.09, alpha: 1)
    })
    static let desertPanel = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.10, blue: 0.085, alpha: 0.96)
            : UIColor(red: 0.26, green: 0.18, blue: 0.11, alpha: 0.88)
    })
}
