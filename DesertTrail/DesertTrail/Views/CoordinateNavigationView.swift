import CoreLocation
import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct CoordinateNavigationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL
    @StateObject private var store = CoordinatePointStore()
    @State private var selectedPointID: SavedCoordinatePoint.ID?
    @State private var pointName = "موقعي الحالي"
    @State private var pointNote = ""
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""
    @State private var statusMessage: String?
    @State private var showingImporter = false
    @State private var exportURL: URL?

    private var selectedPoint: SavedCoordinatePoint? {
        store.points.first { $0.id == selectedPointID } ?? store.points.first
    }

    private var currentLocation: CLLocation? {
        appState.locationManager.currentLocation
    }

    private var destinationLocation: CLLocation? {
        guard let selectedPoint else { return nil }
        return CLLocation(latitude: selectedPoint.latitude, longitude: selectedPoint.longitude)
    }

    private var distanceMeters: CLLocationDistance? {
        guard let currentLocation, let destinationLocation else { return nil }
        return currentLocation.distance(from: destinationLocation)
    }

    private var bearingDegrees: Double? {
        guard let current = currentLocation?.coordinate,
              let destination = selectedPoint?.coordinate else { return nil }
        return CoordinateMath.bearing(from: current, to: destination)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                liveNavigationCard
                savePointCard
                offlineGridCard
                pointsCard
                exportImportCard
                privacyCard
            }
            .padding()
            .padding(.bottom, 84)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ملاحة الإحداثيات")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.xml, UTType(filenameExtension: "gpx") ?? .data]) { result in
            handleImport(result)
        }
        .task {
            appState.locationManager.startNavigation()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("مدل ملاحة ميداني دون تعقيد", systemImage: "location.north.circle.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.desertCopper)
            Text("احفظ إحداثياتك، ارجع للنقاط، شاركها، وافتحها في خرائط Apple أو Google. تبقى النقاط والمسافة والاتجاه والشبكة المحلية متاحة دون حساب أو إعلانات.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            permissionRow
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var permissionRow: some View {
        HStack(spacing: 10) {
            Image(systemName: appState.locationManager.authorizationStatus == .denied ? "location.slash" : "location.fill")
                .foregroundStyle(appState.locationManager.authorizationStatus == .denied ? .red : Color.oasisTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(locationStatusTitle)
                    .font(.caption.weight(.bold))
                Text("دقة GPS: \(gpsAccuracyText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("تشغيل") {
                appState.locationManager.startNavigation()
                showStatus("تم طلب/تشغيل GPS والبوصلة")
            }
            .font(.caption.weight(.bold))
            .buttonStyle(.borderedProminent)
            .tint(Color.oasisTeal)
        }
    }

    private var liveNavigationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("التوجيه إلى الوجهة", systemImage: "safari")
                    .font(.headline.weight(.bold))
                Spacer()
                if let selectedPoint {
                    Text(selectedPoint.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.desertCopper)
                        .lineLimit(1)
                }
            }

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.desertSand.opacity(0.92), .white], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(Color.desertCopper, lineWidth: 2))
                ForEach(0..<8) { tick in
                    Rectangle()
                        .fill(Color.desertRock.opacity(0.72))
                        .frame(width: 3, height: tick % 2 == 0 ? 20 : 10)
                        .offset(y: -92)
                        .rotationEffect(.degrees(Double(tick) * 45))
                }
                Image(systemName: "location.north.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Color.oasisTeal)
                    .rotationEffect(.degrees(compassArrowRotation))
                VStack {
                    Spacer()
                    Text(bearingText)
                        .font(.headline.monospacedDigit().weight(.bold))
                        .padding(.bottom, 30)
                }
            }
            .frame(width: 220, height: 220)
            .frame(maxWidth: .infinity)

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    navMetric("المسافة", distanceText, "ruler")
                    navMetric("الاتجاه", bearingText, "location.north")
                }
                GridRow {
                    navMetric("موقعي", coordinateText(currentLocation?.coordinate), "dot.scope")
                    navMetric("GPS", gpsAccuracyText, "antenna.radiowaves.left.and.right")
                }
            }

            if let distanceMeters, distanceMeters <= 100 {
                Label("اقتربت من الوجهة: أقل من 100 متر", systemImage: "bell.badge")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var savePointCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("حفظ إحداثية", systemImage: "mappin.and.ellipse")
                .font(.headline.weight(.bold))
            TextField("اسم النقطة", text: $pointName)
                .textFieldStyle(.roundedBorder)
            TextField("ملاحظات اختيارية", text: $pointNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    TextField("Latitude", text: $manualLatitude)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(.roundedBorder)
                    TextField("Longitude", text: $manualLongitude)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 8) {
                Button {
                    store.addCurrentLocation(currentLocation, fallback: appState.selectedTrip.meetingPoint, name: pointName, note: pointNote)
                    selectedPointID = store.points.first?.id
                    showStatus("تم حفظ الموقع الحالي")
                } label: {
                    Label("حفظ موقعي", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.desertCopper)

                Button {
                    saveManualPoint()
                } label: {
                    Label("حفظ يدوي", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            statusBanner
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var offlineGridCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("شبكة محلية دون إنترنت", systemImage: "grid")
                .font(.headline.weight(.bold))
            Text("عند ضعف الإنترنت تبقى الإحداثيات، المسافة، الاتجاه، والبوصلة تعمل محلياً حسب استقبال GPS وحساسات الجهاز.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    localGridCell("الشمال", "N", "arrow.up")
                    localGridCell("الشرق", "E", "arrow.right")
                    localGridCell("الوجهة", selectedPoint?.name ?? "--", "flag")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var pointsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("النقاط المحفوظة", systemImage: "list.bullet.rectangle")
                .font(.headline.weight(.bold))
            ForEach(store.points) { point in
                pointRow(point)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var exportImportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("استيراد وتصدير GPX", systemImage: "arrow.up.arrow.down.doc")
                .font(.headline.weight(.bold))

            HStack(spacing: 8) {
                Button {
                    showingImporter = true
                } label: {
                    Label("استيراد GPX", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    prepareExport()
                } label: {
                    Label("تصدير GPX", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.oasisTeal)
            }

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("مشاركة ملف GPX", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.desertCopper)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("الخصوصية", systemImage: "lock.shield")
                .font(.headline.weight(.bold))
            Text("النقاط محفوظة محلياً على الجهاز. لا يتطلب التطبيق حساباً، ولا إعلانات أو تتبع. يمكن لاحقاً تفعيل نسخة iCloud اختيارية للنسخ الاحتياطي.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let statusMessage {
            Text(statusMessage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.oasisTeal, in: Capsule())
        }
    }

    private func pointRow(_ point: SavedCoordinatePoint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                selectedPointID = point.id
                appState.locationManager.startNavigation()
                showStatus("تم اختيار \(point.name) كوجهة")
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: selectedPoint?.id == point.id ? "flag.fill" : "mappin")
                        .foregroundStyle(Color.desertCopper)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(point.name)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                        Text(coordinateText(point.coordinate))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if !point.note.isEmpty {
                            Text(point.note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Text(distanceText(to: point))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.oasisTeal)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                ShareLink(item: point.shareText) {
                    Label("مشاركة", systemImage: "square.and.arrow.up")
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)

                Button {
                    openURL(point.appleMapsURL)
                } label: {
                    Label("Apple", systemImage: "map")
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)

                Button {
                    openURL(point.googleMapsURL)
                } label: {
                    Label("Google", systemImage: "link")
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    store.delete(point)
                    showStatus("تم حذف النقطة")
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func navMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.desertCopper)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.56)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(8)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func localGridCell(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(Color.oasisTeal)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(8)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var locationStatusTitle: String {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined: return "الموقع يحتاج سماح"
        case .denied, .restricted: return "الموقع غير مفعل"
        default: return appState.locationManager.isTracking ? "GPS يعمل" : "GPS جاهز"
        }
    }

    private var gpsAccuracyText: String {
        guard let accuracy = currentLocation?.horizontalAccuracy, accuracy >= 0 else { return "--" }
        return "±\(Int(accuracy)) م"
    }

    private var distanceText: String {
        guard let distanceMeters else { return "--" }
        if distanceMeters >= 1000 {
            return String(format: "%.2f كم", distanceMeters / 1000)
        }
        return "\(Int(distanceMeters)) م"
    }

    private var bearingText: String {
        guard let bearingDegrees else { return "--°" }
        return "\(Int(bearingDegrees.rounded()))°"
    }

    private var compassArrowRotation: Double {
        let heading = appState.locationManager.heading?.trueHeading ?? appState.locationManager.heading?.magneticHeading ?? 0
        return (bearingDegrees ?? 0) - max(heading, 0)
    }

    private func coordinateText(_ coordinate: CLLocationCoordinate2D?) -> String {
        guard let coordinate else { return "--" }
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }

    private func distanceText(to point: SavedCoordinatePoint) -> String {
        guard let currentLocation else { return "--" }
        let distance = currentLocation.distance(from: CLLocation(latitude: point.latitude, longitude: point.longitude))
        return distance >= 1000 ? String(format: "%.1f كم", distance / 1000) : "\(Int(distance)) م"
    }

    private func saveManualPoint() {
        guard let latitude = Double(manualLatitude.trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double(manualLongitude.trimmingCharacters(in: .whitespacesAndNewlines)),
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            showStatus("أدخل إحداثيات صحيحة")
            return
        }
        store.addPoint(name: pointName, note: pointNote, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        selectedPointID = store.points.first?.id
        showStatus("تم حفظ الإحداثية اليدوية")
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else {
                showStatus("تعذر فتح الملف")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            let count = store.importGPX(data: data)
            showStatus(count > 0 ? "تم استيراد \(count) نقطة" : "لم يتم العثور على نقاط GPX")
        } catch {
            showStatus("فشل استيراد GPX")
        }
    }

    private func prepareExport() {
        do {
            exportURL = try store.exportGPXURL()
            showStatus("تم تجهيز ملف GPX للمشاركة")
        } catch {
            showStatus("تعذر تجهيز ملف GPX")
        }
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }
}

private enum CoordinateMath {
    static func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude.degreesToRadians
        let lat2 = end.latitude.degreesToRadians
        let deltaLongitude = (end.longitude - start.longitude).degreesToRadians
        let y = sin(deltaLongitude) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLongitude)
        let degrees = atan2(y, x).radiansToDegrees
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
