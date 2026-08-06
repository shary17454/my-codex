import SwiftUI
import CoreLocation
import UIKit

struct CompassPanel: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var statusMessage: String?
    @State private var isRefreshingWeather = false
    @State private var selectedReading: CompassReading?
    @State private var selectedPointer: CompassPointer?
    @State private var showingCoordinateNavigation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.desertSand.opacity(0.95), Color.desertSurface, Color.desertPanel.opacity(0.18)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 130
                            )
                        )
                        .overlay(Circle().stroke(Color.desertCopper, lineWidth: 3))
                        .shadow(radius: 8)

                    ZStack {
                        ForEach(0..<12) { tick in
                            Rectangle()
                                .fill(tick % 3 == 0 ? Color.desertRock : Color.secondary)
                                .frame(width: tick % 3 == 0 ? 4 : 2, height: tick % 3 == 0 ? 24 : 12)
                                .offset(y: -122)
                                .rotationEffect(.degrees(Double(tick) * 30))
                        }

                        compassCardinal("N", y: -98)
                        compassCardinal("S", y: 98)
                        compassCardinal("E", x: 98)
                        compassCardinal("W", x: -98)
                    }
                    .environment(\.layoutDirection, .leftToRight)

                    VStack(spacing: 10) {
                        ZStack {
                            compassNeedle(
                                systemImage: "location.north.fill",
                                color: headingDegrees == nil ? .secondary : .oasisTeal,
                                rotation: northNeedleRotation,
                                size: 66,
                                label: "اتجاه الشمال",
                                pointer: .north
                            )

                            if let tripBearingDegrees {
                                compassNeedle(
                                    systemImage: "arrow.up.circle.fill",
                                    color: .desertCopper,
                                    rotation: tripBearingDegrees - (headingDegrees ?? 0),
                                    size: 40,
                                    offset: -48,
                                    label: "اتجاه الوجهة",
                                    pointer: .destination
                                )
                            }

                            flowNeedle(
                                glyph: "wind",
                                tint: [Color.trailAmber, Color.desertCopper],
                                rotation: windFlowNeedleRotation,
                                size: 30,
                                offset: 52,
                                label: "اتجاه حركة الرياح",
                                pointer: .wind,
                                isActive: appState.environmentalReport.isLiveData
                            )

                            flowNeedle(
                                glyph: "cloud.fill",
                                tint: [Color(red: 0.36, green: 0.68, blue: 0.98), Color(red: 0.16, green: 0.44, blue: 0.86)],
                                rotation: cloudDriftNeedleRotation,
                                size: 26,
                                offset: 72,
                                label: "اتجاه حركة السحب",
                                pointer: .clouds,
                                isActive: appState.environmentalReport.isLiveData
                            )

                            if let courseDegrees {
                                compassNeedle(
                                    systemImage: "car.fill",
                                    color: .green,
                                    rotation: courseDegrees - (headingDegrees ?? 0),
                                    size: 28,
                                    offset: 84,
                                    label: "اتجاه الحركة",
                                    pointer: .course
                                )
                            }
                        }
                        .frame(width: 92, height: 92)
                        .environment(\.layoutDirection, .leftToRight)
                        Text(headingDegrees.map { "\(Int($0.rounded()))°" } ?? "--°")
                            .font(.system(.largeTitle, design: .rounded).monospacedDigit().weight(.bold))
                            .foregroundStyle(.primary)
                        Text(directionName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 248, height: 248)
                .contentShape(Circle())
                .onTapGesture {
                    startCompassAndLocation()
                }

                compassLegend
                permissionNotice

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.oasisTeal, in: Capsule())
                        .transition(.opacity.combined(with: .scale))
                }

                if let locationError = appState.locationManager.locationErrorMessage {
                    Label(locationError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if let headingError = appState.locationManager.headingErrorMessage {
                    Label(headingError, systemImage: "safari")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        readingButton(title: appState.text(.altitude), value: altitudeText, icon: "mountain.2") {
                            startCompassAndLocation()
                            selectedReading = .altitude
                            showStatus("تم تشغيل الموقع لتحديث الارتفاع")
                        }
                        readingButton(title: appState.text(.windSpeed), value: windSpeedText, icon: "wind") {
                            selectedReading = .windSpeed
                            refreshWeather()
                        }
                    }
                    GridRow {
                        readingButton(title: appState.text(.windDirection), value: windDirectionText, icon: "arrow.up.right") {
                            selectedReading = .windDirection
                            refreshWeather()
                        }
                        readingButton(title: appState.text(.magellan), value: appState.text(.gpxReady), icon: "point.topleft.down.curvedto.point.bottomright.up") {
                            startCompassAndLocation()
                            showingCoordinateNavigation = true
                            showStatus("تم فتح إدارة الإحداثيات وملفات GPX")
                        }
                    }
                }

                VStack(spacing: 10) {
                    Button {
                        triggerHaptic()
                        startCompassAndLocation()
                    } label: {
                        Label(navigationButtonTitle, systemImage: "safari")
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        triggerHaptic()
                        appState.locationManager.requestBackgroundTripUpdates()
                        showStatus("تم تفعيل تنبيهات القرب عند توفر الصلاحية")
                    } label: {
                        Label("تفعيل تنبيهات قرب الأودية والخدمات", systemImage: "bell.badge")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 42)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 150)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: statusMessage)
        .sheet(item: $selectedReading) { reading in
            readingDetailSheet(for: reading)
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedPointer) { pointer in
            pointerDetailSheet(for: pointer)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingCoordinateNavigation) {
            NavigationStack {
                CoordinateNavigationView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(appState.text(.done)) {
                                showingCoordinateNavigation = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            if appState.locationManager.authorizationStatus == .authorizedWhenInUse || appState.locationManager.authorizationStatus == .authorizedAlways {
                appState.locationManager.startNavigation()
            }
        }
    }

    private var headingDegrees: Double? {
        appState.locationManager.resolvedHeadingDegrees
    }

    private var northNeedleRotation: Double {
        guard let headingDegrees else { return 0 }
        return -headingDegrees
    }

    private var courseDegrees: Double? {
        guard let course = appState.locationManager.currentLocation?.course, course >= 0 else {
            return nil
        }
        return course
    }

    private var windFlowDegrees: Double? {
        guard appState.environmentalReport.isLiveData else { return nil }
        return normalizedDegrees(appState.environmentalReport.windDirectionDegrees + 180)
    }

    private var cloudDriftDegrees: Double? {
        guard let windFlowDegrees else { return nil }
        return windFlowDegrees
    }

    private var windFlowNeedleRotation: Double {
        guard let windFlowDegrees else { return 0 }
        return windFlowDegrees - (headingDegrees ?? 0)
    }

    private var cloudDriftNeedleRotation: Double {
        guard let cloudDriftDegrees else { return 0 }
        return cloudDriftDegrees - (headingDegrees ?? 0)
    }

    private var tripBearingDegrees: Double? {
        guard appState.hasSelectedTrip,
              let currentCoordinate = appState.locationManager.currentLocation?.coordinate else {
            return nil
        }
        return bearing(from: currentCoordinate, to: appState.selectedTrip.meetingPoint)
    }

    private var compassLegend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 116), spacing: 8)], spacing: 8) {
            legendChip("الشمال", color: .oasisTeal, icon: "location.north.fill", value: headingDegrees.map { "\(Int($0.rounded()))°" } ?? "--")
            legendChip("الوجهة", color: .desertCopper, icon: "arrow.up.circle.fill", value: tripBearingDegrees.map { "\(Int($0.rounded()))°" } ?? "لا توجد")
            legendChip("الرياح", color: .orange, icon: "wind", value: appState.environmentalReport.isLiveData ? windFlowDirectionText : "--")
            legendChip("السحب", color: .blue, icon: "cloud.fill", value: appState.environmentalReport.isLiveData ? cloudDriftDirectionText : "--")
            legendChip("الحركة", color: .green, icon: "car.fill", value: courseDegrees.map { "\(Int($0.rounded()))°" } ?? "--")
        }
        .accessibilityElement(children: .contain)
    }

    private func compassNeedle(systemImage: String, color: Color, rotation: Double, size: CGFloat, offset: CGFloat = 0, label: String, pointer: CompassPointer) -> some View {
        Button {
            triggerHaptic()
            selectedPointer = pointer
            switch pointer {
            case .north, .course:
                startCompassAndLocation()
            case .wind, .clouds:
                if !appState.environmentalReport.isLiveData {
                    refreshWeather()
                }
            case .destination:
                if tripBearingDegrees == nil {
                    startCompassAndLocation()
                }
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(color)
                .frame(width: max(size + 18, 44), height: max(size + 18, 44))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .shadow(color: color.opacity(0.26), radius: 8, y: 3)
        .offset(y: offset)
        .rotationEffect(.degrees(rotation))
        .accessibilityLabel(label)
        .accessibilityHint("اضغط لعرض التفاصيل والإجراء المرتبط بهذا المؤشر")
    }

    /// Premium directional marker for wind / cloud flow: a tapered gradient arrow
    /// that points precisely along the flow direction, with an upright icon badge
    /// at its tail so the meaning stays readable at any rotation. Falls back to a
    /// muted style when live weather data is unavailable.
    private func flowNeedle(
        glyph: String,
        tint: [Color],
        rotation: Double,
        size: CGFloat,
        offset: CGFloat,
        label: String,
        pointer: CompassPointer,
        isActive: Bool
    ) -> some View {
        let arrowFill: [Color] = isActive ? tint : [Color.secondary.opacity(0.55), Color.secondary.opacity(0.3)]
        let badgeColor = isActive ? (tint.first ?? .gray) : .gray
        return Button {
            triggerHaptic()
            selectedPointer = pointer
            if !appState.environmentalReport.isLiveData {
                refreshWeather()
            }
        } label: {
            ZStack {
                FlowArrowShape()
                    .fill(LinearGradient(colors: arrowFill, startPoint: .top, endPoint: .bottom))
                    .overlay(
                        FlowArrowShape().stroke(Color.white.opacity(0.6), lineWidth: 0.8)
                    )
                    .frame(width: size * 0.66, height: size * 1.4)
                    .shadow(color: (isActive ? (tint.first ?? .clear) : .clear).opacity(0.55), radius: 5, y: 2)

                Image(systemName: glyph)
                    .font(.system(size: size * 0.4, weight: .black))
                    .foregroundStyle(.white)
                    .padding(size * 0.16)
                    .background(Circle().fill(badgeColor.gradient))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.75), lineWidth: 1))
                    .offset(y: size * 0.66)
                    .rotationEffect(.degrees(-rotation))
                    .shadow(radius: 2, y: 1)
            }
            .frame(width: max(size + 18, 44), height: max(size + 18, 44))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .offset(y: offset)
        .rotationEffect(.degrees(rotation))
        .accessibilityLabel(label)
        .accessibilityHint("اضغط لعرض التفاصيل والإجراء المرتبط بهذا المؤشر")
    }

    private func legendChip(_ title: String, color: Color, icon: String, value: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.desertSurface, in: RoundedRectangle(cornerRadius: 8))
    }

    private func compassCardinal(_ text: String, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        Text(text)
            .font(.headline.weight(.black))
            .foregroundStyle(Color.desertRock)
            .offset(x: x, y: y)
    }

    private var directionName: String {
        guard let headingDegrees else {
            return "بانتظار قراءة الاتجاه"
        }
        let directions = [
            appState.text(.north),
            appState.text(.northeast),
            appState.text(.east),
            appState.text(.southeast),
            appState.text(.south),
            appState.text(.southwest),
            appState.text(.west),
            appState.text(.northwest)
        ]
        let index = Int((headingDegrees + 22.5) / 45.0) % directions.count
        return directions[index]
    }

    private var permissionNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: permissionIcon)
                .foregroundStyle(permissionColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(permissionTitle)
                    .font(.caption.weight(.bold))
                Text(headingAccuracyText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(permissionColor)
                Text(permissionMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(permissionColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private var permissionTitle: String {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            return "تفعيل الموقع والبوصلة"
        case .restricted, .denied:
            return "الموقع غير مفعل"
        default:
            if headingDegrees != nil {
                return appState.locationManager.supportsHeading ? "البوصلة تعمل" : "اتجاه الحركة يعمل"
            }
            return appState.locationManager.isTracking ? "بانتظار قراءة الاتجاه" : "جاهز للتشغيل"
        }
    }

    private var permissionMessage: String {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            return "اضغط زر التشغيل للسماح بالموقع وتحديث الاتجاه والارتفاع أثناء الرحلة."
        case .restricted, .denied:
            return "فعّل صلاحية الموقع من إعدادات iOS حتى تظهر بيانات الارتفاع والاتجاه بدقة."
        default:
            if !appState.locationManager.supportsHeading {
                return "هذا الجهاز لا يحتوي حساس بوصلة. سيظهر اتجاه الحركة تلقائيًا بعد بدء التنقل عبر GPS."
            }
            return appState.locationManager.heading == nil ? "حرّك الجهاز على شكل 8 بعيداً عن المعادن، ثم اضغط القرص أو زر التشغيل." : "يستخدم التطبيق الموقع أثناء الاستخدام فقط، ويمكن تفعيل التحديث الدائم لتنبيهات الرحلات عند الحاجة."
        }
    }

    private var permissionIcon: String {
        switch appState.locationManager.authorizationStatus {
        case .restricted, .denied: return "location.slash"
        case .notDetermined: return "location.badge.questionmark"
        default: return "location.fill"
        }
    }

    private var permissionColor: Color {
        switch appState.locationManager.authorizationStatus {
        case .restricted, .denied: return .red
        case .notDetermined: return .orange
        default: return .oasisTeal
        }
    }

    private var navigationButtonTitle: String {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            return "السماح بالموقع وتشغيل البوصلة"
        case .restricted, .denied:
            return "صلاحية الموقع مطلوبة"
        default:
            return appState.text(.startNavigationTools)
        }
    }

    private var headingAccuracyText: String {
        guard let heading = appState.locationManager.heading else {
            return headingDegrees == nil ? "لم تصل قراءة الاتجاه بعد" : "اتجاه الحركة محسوب من GPS"
        }
        guard heading.headingAccuracy >= 0 else { return "تحتاج البوصلة إلى معايرة" }
        return "دقة الاتجاه ±\(Int(heading.headingAccuracy))°"
    }

    private func startCompassAndLocation() {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
            showStatus("تم طلب صلاحية الموقع")
        case .restricted, .denied:
            openAppSettings()
        default:
            appState.locationManager.startNavigation()
            showStatus("تم تشغيل البوصلة والتتبع")
        }
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.altitudeMeters else { return "-- m" }
        return "\(Int(altitude)) m"
    }

    private var windSpeedText: String {
        guard appState.environmentalReport.isLiveData else { return "-- km/h" }
        return "\(Int(appState.environmentalReport.windSpeedKPH.rounded())) km/h"
    }

    private var windDirectionText: String {
        guard appState.environmentalReport.isLiveData else { return "--°" }
        return "\(Int(appState.environmentalReport.windDirectionDegrees.rounded()))° \(windSourceDirectionName)"
    }

    private var windFlowDirectionText: String {
        guard let windFlowDegrees else { return "--°" }
        return "\(Int(windFlowDegrees.rounded()))° \(cardinalName(for: windFlowDegrees))"
    }

    private var cloudDriftDirectionText: String {
        guard let cloudDriftDegrees else { return "--°" }
        return "\(Int(cloudDriftDegrees.rounded()))° \(cardinalName(for: cloudDriftDegrees))"
    }

    private var windSourceDirectionName: String {
        guard appState.environmentalReport.isLiveData else { return "غير متاح" }
        return cardinalName(for: appState.environmentalReport.windDirectionDegrees)
    }

    private var windDestinationDirectionName: String {
        guard appState.environmentalReport.isLiveData else { return "غير متاح" }
        return cardinalName(for: appState.environmentalReport.windDirectionDegrees + 180)
    }

    private var windImpactText: String {
        guard appState.environmentalReport.isLiveData else {
            return "اضغط تحديث الطقس والرياح لجلب اتجاه الرياح حسب موقعك الحالي."
        }
        let speed = appState.environmentalReport.windSpeedKPH
        if speed >= 45 {
            return "رياح قوية. تجنب الشعاب المكشوفة وثبّت معدات الرحلة."
        } else if speed >= 25 {
            return "رياح متوسطة. مناسبة غالبًا مع الانتباه للغبار والمواقع المفتوحة."
        } else {
            return "رياح خفيفة. لا يوجد تنبيه واضح من سرعة الرياح الحالية."
        }
    }

    private func cardinalName(for degrees: Double) -> String {
        let positiveDegrees = normalizedDegrees(degrees)
        let directions = [
            "شمال",
            "شمال شرقي",
            "شرق",
            "جنوب شرقي",
            "جنوب",
            "جنوب غربي",
            "غرب",
            "شمال غربي"
        ]
        let index = Int((positiveDegrees + 22.5) / 45.0) % directions.count
        return directions[index]
    }

    private func normalizedDegrees(_ degrees: Double) -> Double {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        return normalized < 0 ? normalized + 360 : normalized
    }

    private func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLongitude = (end.longitude - start.longitude) * .pi / 180
        let y = sin(deltaLongitude) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLongitude)
        let degrees = atan2(y, x) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }

    private func refreshWeather() {
        guard !isRefreshingWeather else { return }
        isRefreshingWeather = true
        showStatus("جاري تحديث الرياح والطقس")
        Task {
            await appState.startLocationAndRefreshEnvironment(userInitiated: true)
            isRefreshingWeather = false
            showStatus(appState.environmentErrorMessage == nil ? "تم تحديث بيانات الرياح" : "تعذر تحديث بيانات الرياح")
        }
    }

    private func openAppSettings() {
        showStatus("افتح الإعدادات وفعّل الموقع للتطبيق")
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }

    private func readingButton(title: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(Color.desertCopper)
                    Spacer()
                    if isRefreshingWeather && (icon == "wind" || icon == "arrow.up.right") {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(value)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(accessibilityHint(for: icon))
    }

    private func accessibilityHint(for icon: String) -> String {
        switch icon {
        case "point.topleft.down.curvedto.point.bottomright.up":
            return "يفتح إدارة الإحداثيات واستيراد وتصدير ملفات GPX"
        case "arrow.up.right":
            return "يعرض تفاصيل اتجاه الرياح ويحدّث بيانات الطقس"
        case "wind":
            return "يعرض تفاصيل سرعة الرياح ويحدّث بيانات الطقس"
        default:
            return "اضغط لتحديث القراءة وعرض التفاصيل"
        }
    }

    @ViewBuilder
    private func readingDetailSheet(for reading: CompassReading) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Label(reading.title(appState: appState), systemImage: reading.icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.desertCopper)

                Text(reading.value(in: self, appState: appState))
                    .font(.system(.largeTitle, design: .rounded).monospacedDigit().weight(.black))

                Text(reading.explanation)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                readingExtraContent(for: reading)

                Button {
                    triggerHaptic()
                    runAction(for: reading)
                } label: {
                    Label(reading.actionTitle, systemImage: reading.actionIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("تفاصيل القراءة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.text(.done)) {
                        selectedReading = nil
                    }
                }
            }
        }
    }

    private func pointerDetailSheet(for pointer: CompassPointer) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Label(pointer.title, systemImage: pointer.icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(pointer.color)

                Text(pointer.value(in: self))
                    .font(.system(.largeTitle, design: .rounded).monospacedDigit().weight(.black))
                    .foregroundStyle(.primary)

                Text(pointer.explanation(in: self, appState: appState))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                pointerExtraContent(for: pointer)

                Button {
                    triggerHaptic()
                    runAction(for: pointer)
                } label: {
                    Label(pointer.actionTitle, systemImage: pointer.actionIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(pointer.color)

                Spacer()
            }
            .padding()
            .navigationTitle("تفاصيل المؤشر")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.text(.done)) {
                        selectedPointer = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pointerExtraContent(for pointer: CompassPointer) -> some View {
        switch pointer {
        case .north:
            detailCard(
                title: "معايرة الشمال",
                icon: "scope",
                message: headingAccuracyText + "\nحرّك الجهاز على شكل 8 إذا كانت الدقة منخفضة، وأبعده عن المعادن أو حامل السيارة."
            )
        case .destination:
            detailCard(
                title: "وجهة الرحلة",
                icon: "mappin.and.ellipse",
                message: appState.hasSelectedTrip
                    ? "الوجهة الحالية: \(appState.selectedTrip.title)\n\(coordinateText(appState.selectedTrip.meetingPoint))"
                    : "لا توجد رحلة محددة. افتح إدارة الإحداثيات لاختيار نقطة أو إنشاء وجهة."
            )
        case .wind:
            detailCard(
                title: "حركة الرياح",
                icon: "wind",
                message: "\(windImpactText)\nتهب من: \(windSourceDirectionName)\nتتحرك نحو: \(windDestinationDirectionName)\nالسهم البرتقالي يشير إلى جهة الحركة الفعلية للهواء."
            )
        case .clouds:
            detailCard(
                title: "حركة السحب",
                icon: "cloud.fill",
                message: appState.environmentalReport.isLiveData
                    ? "اتجاه السحب تقديري ومربوط باتجاه حركة الرياح الحالي: \(cloudDriftDirectionText).\nاستخدمه كمؤشر ميداني سريع وليس كبديل عن رادار الطقس الرسمي."
                    : "حدّث الطقس والرياح أولًا حتى يظهر مؤشر السحب واتجاهه التقديري."
            )
        case .course:
            detailCard(
                title: "اتجاه الحركة",
                icon: "car.fill",
                message: courseDegrees == nil
                    ? "يتوفر هذا السهم بعد بدء الحركة أو بعد وصول GPS إلى قراءة اتجاه موثوقة."
                    : "هذا السهم يعتمد على اتجاه حركة GPS، وهو مفيد إذا كان الجهاز لا يحتوي حساس بوصلة أو كانت قراءة البوصلة غير مستقرة."
            )
        }
    }

    private func detailCard(title: String, icon: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func readingExtraContent(for reading: CompassReading) -> some View {
        switch reading {
        case .windSpeed, .windDirection:
            VStack(alignment: .leading, spacing: 10) {
                Label("تفاصيل الرياح", systemImage: "wind")
                    .font(.headline.weight(.bold))
                HStack {
                    detailPill(title: "تهب من", value: windSourceDirectionName)
                    detailPill(title: "نحو", value: windDestinationDirectionName)
                }
                Text(windImpactText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(appState.environmentalReport.windSpeedKPH >= 45 ? .orange : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        case .gpx:
            VStack(alignment: .leading, spacing: 10) {
                Label("إدارة GPX الفعلية", systemImage: "arrow.up.arrow.down.doc")
                    .font(.headline.weight(.bold))
                Text("افتح شاشة ملاحة الإحداثيات لحفظ النقاط، اختيار وجهة، استيراد GPX، تصدير GPX، ومشاركة الملف.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink {
                    CoordinateNavigationView()
                } label: {
                    Label("فتح ملاحة الإحداثيات وملفات GPX", systemImage: "location.north.line")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.oasisTeal)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        case .altitude:
            EmptyView()
        }
    }

    private func detailPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func runAction(for reading: CompassReading) {
        switch reading {
        case .altitude:
            startCompassAndLocation()
        case .gpx:
            selectedReading = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showingCoordinateNavigation = true
            }
        case .windSpeed, .windDirection:
            refreshWeather()
        }
    }

    private func runAction(for pointer: CompassPointer) {
        switch pointer {
        case .north, .course:
            startCompassAndLocation()
        case .destination:
            selectedPointer = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showingCoordinateNavigation = true
            }
        case .wind, .clouds:
            refreshWeather()
        }
    }

    private func coordinateText(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    private func triggerHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private enum CompassPointer: String, Identifiable {
        case north
        case destination
        case wind
        case clouds
        case course

        var id: String { rawValue }

        var title: String {
            switch self {
            case .north: return "الشمال الحقيقي"
            case .destination: return "اتجاه الوجهة"
            case .wind: return "حركة الرياح"
            case .clouds: return "حركة السحب"
            case .course: return "اتجاه الحركة"
            }
        }

        var icon: String {
            switch self {
            case .north: return "location.north.fill"
            case .destination: return "arrow.up.circle.fill"
            case .wind: return "wind"
            case .clouds: return "cloud.fill"
            case .course: return "car.fill"
            }
        }

        var color: Color {
            switch self {
            case .north: return .oasisTeal
            case .destination: return .desertCopper
            case .wind: return .orange
            case .clouds: return .blue
            case .course: return .green
            }
        }

        var actionTitle: String {
            switch self {
            case .north: return "تشغيل الموقع ومعايرة البوصلة"
            case .destination: return "فتح إدارة الوجهة والإحداثيات"
            case .wind: return "تحديث الرياح والطقس"
            case .clouds: return "تحديث حركة السحب"
            case .course: return "تشغيل تتبع الحركة"
            }
        }

        var actionIcon: String {
            switch self {
            case .north: return "scope"
            case .destination: return "location.north.line"
            case .wind: return "arrow.clockwise"
            case .clouds: return "cloud.sun"
            case .course: return "figure.walk.motion"
            }
        }

        @MainActor
        func value(in panel: CompassPanel) -> String {
            switch self {
            case .north:
                return panel.headingDegrees.map { "\(Int($0.rounded()))° \(panel.directionName)" } ?? "--°"
            case .destination:
                return panel.tripBearingDegrees.map { "\(Int($0.rounded()))°" } ?? "لا توجد وجهة"
            case .wind:
                return panel.windFlowDirectionText
            case .clouds:
                return panel.cloudDriftDirectionText
            case .course:
                return panel.courseDegrees.map { "\(Int($0.rounded()))°" } ?? "--°"
            }
        }

        @MainActor
        func explanation(in panel: CompassPanel, appState: AppState) -> String {
            switch self {
            case .north:
                return "يعرض اتجاه شمال الخريطة بعد تعويض دوران الجهاز. يعتمد على حساس البوصلة، أو اتجاه الحركة عند عدم توفر الحساس."
            case .destination:
                return appState.hasSelectedTrip
                    ? "يوجهك نحو نقطة اجتماع الرحلة الحالية. إذا تغير موقعك يتحرك السهم حسب المسافة والاتجاه الحقيقيين."
                    : "هذا المؤشر يحتاج رحلة أو نقطة محفوظة حتى يحدد الاتجاه إليها."
            case .wind:
                return "يعرض اتجاه حركة الهواء بعد تحويل قراءة مصدر الرياح إلى جهة الحركة. يعتمد على بيانات الطقس للموقع الحالي أو وجهة الرحلة."
            case .clouds:
                return "يعرض اتجاه حركة السحب كتقدير مبني على حركة الرياح المتاحة. قد يختلف عن طبقات السحب العالية في الأحوال الجوية المتغيرة."
            case .course:
                return "يعرض اتجاه حركة السيارة أو المشي من GPS. يظهر عادة بعد التحرك لمسافة كافية."
            }
        }
    }

    private enum CompassReading: String, Identifiable {
        case altitude
        case windSpeed
        case windDirection
        case gpx

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .altitude: return "mountain.2"
            case .windSpeed: return "wind"
            case .windDirection: return "arrow.up.right"
            case .gpx: return "point.topleft.down.curvedto.point.bottomright.up"
            }
        }

        var actionIcon: String {
            switch self {
            case .altitude, .gpx: return "location.fill"
            case .windSpeed, .windDirection: return "arrow.clockwise"
            }
        }

        var explanation: String {
            switch self {
            case .altitude:
                return "يتم تحديث الارتفاع من GPS. في المحاكي قد تكون القراءة ثابتة أو تقريبية، وعلى الجهاز الحقيقي تعتمد على جودة إشارة الموقع."
            case .windSpeed:
                return "يتم جلب سرعة الرياح من خدمة الطقس حسب موقعك الحالي. تحتاج القراءة إلى موقع واتصال إنترنت."
            case .windDirection:
                return "يعرض اتجاه الرياح بالدرجات من بيانات الطقس للموقع الحالي، وليس اتجاه البوصلة."
            case .gpx:
                return "هذه ليست قراءة ثابتة فقط. تفتح بطاقة GPX شاشة ملاحة الإحداثيات لإدارة النقاط واستيراد وتصدير ومشاركة ملفات GPX."
            }
        }

        var actionTitle: String {
            switch self {
            case .altitude: return "تحديث الارتفاع"
            case .windSpeed, .windDirection: return "تحديث الطقس والرياح"
            case .gpx: return "فتح ملاحة الإحداثيات"
            }
        }

        @MainActor
        func title(appState: AppState) -> String {
            switch self {
            case .altitude: return appState.text(.altitude)
            case .windSpeed: return appState.text(.windSpeed)
            case .windDirection: return appState.text(.windDirection)
            case .gpx: return appState.text(.magellan)
            }
        }

        @MainActor
        func value(in panel: CompassPanel, appState: AppState) -> String {
            switch self {
            case .altitude: return panel.altitudeText
            case .windSpeed: return panel.windSpeedText
            case .windDirection: return panel.windDirectionText
            case .gpx: return appState.text(.gpxReady)
            }
        }
    }
}

/// A tapered arrow (arrowhead + stem) pointing toward the top of its frame,
/// used for the compass wind and cloud flow markers.
private struct FlowArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let headHeight = height * 0.5
        let stemHalf = width * 0.22

        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))                       // tip
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + headHeight))       // right barb
        path.addLine(to: CGPoint(x: rect.midX + stemHalf, y: rect.minY + headHeight))
        path.addLine(to: CGPoint(x: rect.midX + stemHalf, y: rect.maxY))         // stem bottom-right
        path.addLine(to: CGPoint(x: rect.midX - stemHalf, y: rect.maxY))         // stem bottom-left
        path.addLine(to: CGPoint(x: rect.midX - stemHalf, y: rect.minY + headHeight))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + headHeight))       // left barb
        path.closeSubpath()
        return path
    }
}
