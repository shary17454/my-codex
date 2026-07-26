import CoreLocation
import MapKit
import SwiftUI

struct DesertMapView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var showingAddPlace = false
    @State private var showingOfflineMaps = false
    @State private var showingPDFSourceManager = false
    @State private var showingGeospatialCatalog = false
    @State private var mapStatusMessage: String?
    @StateObject private var pdfMapStore = PDFMapStore()
    @State private var mapLayer: DesertMapLayer = ScreenshotConfiguration.initialMapLayer
    @State private var ajajiImageIndex = ScreenshotConfiguration.initialAjajiImageIndex
    @AppStorage("wildernessTileOverlayEnabled") private var wildernessTileOverlayEnabled = false
    @AppStorage("wildernessTileTemplate") private var wildernessTileTemplate = ""
    @AppStorage("wildernessTileOpacity") private var wildernessTileOpacity = 0.72
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch mapLayer {
                case .satellite:
                    MapCanvasView(
                        region: mapRegion,
                        route: navigationRoute,
                        dirtRoadRoutes: visibleDirtRoadRoutes,
                        places: appState.hiddenPlaces.filter { $0.status == .approved },
                        tileTemplateURL: activeTileTemplate,
                        tileOpacity: wildernessTileOpacity,
                        showsUserLocation: appState.locationManager.isTracking,
                        onRegionChange: { mapRegion = $0 }
                    )
                case .ajaji:
                    if ajajiPDFURLs.isEmpty {
                        LicensedMapPlaceholderView(
                            title: "خرائط العجاجي",
                            message: "هذه الخرائط لا تُضمّن في نسخة الإطلاق حتى تصل موافقة أو ترخيص مكتوب. يمكنك استيراد PDF مرخص من إدارة المصدر.",
                            actionTitle: appState.text(.managePDFSource),
                            action: { showingPDFSourceManager = true }
                        )
                    } else {
                        PDFMapView(documentURLs: ajajiPDFURLs, selectedDocumentIndex: $ajajiImageIndex)
                    }
                case .markedPlans:
                    if markedPlanPDFURLs.isEmpty {
                        LicensedMapPlaceholderView(
                            title: "مخططات مرشمة",
                            message: "المخططات المرشمة متاحة كميزة استيراد بعد توفر ملف مرخص، ولا تُضمّن حاليًا داخل التطبيق.",
                            actionTitle: appState.text(.managePDFSource),
                            action: { showingPDFSourceManager = true }
                        )
                    } else {
                        PDFMapView(documentURLs: markedPlanPDFURLs, selectedDocumentIndex: .constant(0))
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            mapControlPanel
        }
        .task {
            await appState.refreshEnvironmentReport()
            if appState.locationManager.isTracking {
                centerMapOnCurrentLocation()
            }
        }
        .sheet(isPresented: $showingAddPlace) {
            HiddenPlaceForm()
        }
        .sheet(isPresented: $showingOfflineMaps) {
            OfflineMapsView(region: mapRegion)
        }
        .sheet(isPresented: $showingPDFSourceManager) {
            PDFSourceManagerView(store: pdfMapStore, document: currentPDFDocument)
        }
        .sheet(isPresented: $showingGeospatialCatalog) {
            GeospatialLayerCatalogView()
        }
    }

    private var ajajiPDFURLs: [URL] {
        [PDFMapDocument.ajajiSaudi, .ajajiRiyadhRegion].compactMap { pdfMapStore.url(for: $0) }
    }

    private var markedPlanPDFURLs: [URL] {
        [PDFMapDocument.ajajiMarkedPlans].compactMap { pdfMapStore.url(for: $0) }
    }

    private var currentPDFDocument: PDFMapDocument {
        switch mapLayer {
        case .satellite:
            return .ajajiRiyadhRegion
        case .ajaji:
            return ajajiImageIndex == 0 ? .ajajiSaudi : .ajajiRiyadhRegion
        case .markedPlans:
            return .ajajiMarkedPlans
        }
    }

    private var currentPDFStatus: String {
        pdfMapStore.isImported(currentPDFDocument) ? appState.text(.officialPDF) : appState.text(.bundledPDF)
    }

    private var mapControlPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                Picker("Map Layer", selection: $mapLayer) {
                    Text(appState.text(.satellite)).tag(DesertMapLayer.satellite)
                    Text(appState.text(.ajajiMaps)).tag(DesertMapLayer.ajaji)
                    Text(appState.text(.markedPlans)).tag(DesertMapLayer.markedPlans)
                }
                .pickerStyle(.segmented)
                .font(.caption.weight(.semibold))

                if mapLayer == .ajaji {
                    Picker(appState.text(.ajajiMaps), selection: $ajajiImageIndex) {
                        Text(appState.text(.ajajiSaudi)).tag(0)
                        Text(appState.text(.ajajiRiyadh)).tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                mapSourceStatusRow
                EnvironmentBanner(report: appState.environmentalReport)
                dirtRoadRoutesPanel
                statusMessageView

                HStack(spacing: 8) {
                    metricTile(title: "GPS", value: appState.locationManager.isTracking ? appState.text(.gpsActive) : appState.text(.gpsReady), icon: "location")
                    metricTile(title: "ALT", value: altitudeText, icon: "mountain.2")
                    metricTile(title: "DIST", value: distanceText, icon: "point.topleft.down.curvedto.point.bottomright.up")
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                    compactMapActionButton(
                        title: appState.locationManager.isTracking ? appState.text(.stopNavigation) : appState.text(.startNavigation),
                        icon: "location.north.line",
                        isPrimary: true
                    ) {
                        if appState.locationManager.isTracking {
                            appState.locationManager.stopNavigation()
                            showMapStatus("تم إيقاف الملاحة")
                        } else {
                            appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
                            showMapStatus("تم تشغيل GPS والبوصلة")
                        }
                    }
                    compactMapActionButton(title: appState.text(.addPlace), icon: "plus") {
                        showingAddPlace = true
                    }
                    compactMapActionButton(title: appState.text(.offline), icon: "icloud.and.arrow.down") {
                        showingOfflineMaps = true
                    }
                    compactMapActionButton(title: "GIS", icon: "square.3.layers.3d") {
                        showingGeospatialCatalog = true
                    }
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 430)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 104)
    }

    private var mapSourceStatusRow: some View {
        HStack(spacing: 10) {
            if mapLayer == .satellite {
                Label(activeTileTemplate == nil ? "لا توجد طبقة GIS فعالة" : "طبقة GIS فعالة", systemImage: activeTileTemplate == nil ? "square.3.layers.3d.slash" : "square.3.layers.3d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label(currentPDFStatus, systemImage: pdfMapStore.isImported(currentPDFDocument) ? "checkmark.seal" : "doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button {
                if mapLayer == .satellite {
                    showingGeospatialCatalog = true
                } else {
                    showingPDFSourceManager = true
                }
            } label: {
                Label(mapLayer == .satellite ? "إدارة الطبقات" : appState.text(.managePDFSource), systemImage: mapLayer == .satellite ? "slider.horizontal.3" : "doc.badge.gearshape")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusMessageView: some View {
        if let mapStatusMessage {
            Text(mapStatusMessage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.oasisTeal, in: RoundedRectangle(cornerRadius: 8))
                .transition(.opacity)
        }
    }

    private var activeTileTemplate: String? {
        let trimmed = wildernessTileTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard wildernessTileOverlayEnabled, trimmed.contains("{z}"), trimmed.contains("{x}"), trimmed.contains("{y}") else {
            return nil
        }
        return trimmed
    }

    private var navigationRoute: [CLLocationCoordinate2D] {
        guard let current = appState.locationManager.currentLocation?.coordinate else {
            return [appState.selectedTrip.meetingPoint]
        }
        return [current, appState.selectedTrip.meetingPoint]
    }

    private var visibleDirtRoadRoutes: [DirtRoadRoute] {
        appState.suggestedDirtRoadRoutes(destination: appState.selectedTrip.meetingPoint)
    }

    private var dirtRoadRoutesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("الطرق الترابية المقترحة", systemImage: "road.lanes")
                    .font(.subheadline.weight(.bold))
                Spacer(minLength: 0)
                Text("\(visibleDirtRoadRoutes.count) بدائل")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.oasisTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.oasisTeal.opacity(0.12), in: Capsule())
            }

            ForEach(visibleDirtRoadRoutes) { route in
                dirtRoadRouteRow(route)
            }
        }
        .padding(10)
        .background(Color(.systemBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 12))
    }

    private func dirtRoadRouteRow(_ route: DirtRoadRoute) -> some View {
        let isSelected = appState.preferredDirtRoadRouteID == route.id
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(route.difficulty.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)
                VStack(alignment: .leading, spacing: 3) {
                    Text(route.name)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(route.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Label("مفعل", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.oasisTeal)
                }
            }

            Text(route.condition)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            HStack(spacing: 8) {
                Button {
                    appState.selectDirtRoadRoute(route)
                    mapRegion.center = route.endCoordinate
                    mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    showMapStatus("تم اختيار \(route.name) وعرضه على الخريطة")
                } label: {
                    Label("اعتماد", systemImage: "location.north.line")
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                }
                .buttonStyle(.borderedProminent)
                .tint(route.difficulty.color)

                Button {
                    appState.toggleFavoriteDirtRoadRoute(route)
                    showMapStatus(appState.isFavoriteDirtRoadRoute(route) ? "تم حفظ المسار في المفضلة" : "تمت إزالة المسار من المفضلة")
                } label: {
                    Label(appState.isFavoriteDirtRoadRoute(route) ? "محفوظ" : "حفظ", systemImage: appState.isFavoriteDirtRoadRoute(route) ? "star.fill" : "star")
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)

                Text("\(route.estimatedMinutes) د")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? route.difficulty.color.opacity(0.13) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? route.difficulty.color.opacity(0.55) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(route.name)، \(route.subtitle)، \(route.condition)")
    }

    private func centerMapOnCurrentLocation() {
        guard let coordinate = appState.locationManager.currentLocation?.coordinate else { return }
        mapRegion.center = coordinate
        mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.currentLocation?.altitude else { return "-- m" }
        return "\(Int(altitude)) m"
    }

    private var distanceText: String {
        guard let current = appState.locationManager.currentLocation else { return "-- km" }
        let target = CLLocation(latitude: appState.selectedTrip.meetingPoint.latitude, longitude: appState.selectedTrip.meetingPoint.longitude)
        return String(format: "%.1f km", current.distance(from: target) / 1000)
    }

    private func metricTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.oasisTeal)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit().weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.56)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func compactMapActionButton(
        title: String,
        icon: String,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.58)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isPrimary ? .white : Color.desertCopper)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isPrimary ? Color.desertCopper : Color(.systemBackground).opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.desertCopper.opacity(isPrimary ? 0.0 : 0.35), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel(title)
    }

    private func showMapStatus(_ message: String) {
        mapStatusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if mapStatusMessage == message {
                mapStatusMessage = nil
            }
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

struct LicensedMapPlaceholderView: View {
    var title: String
    var message: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.desertSand.opacity(0.25), Color.oasisTeal.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 14) {
                Image(systemName: "lock.doc")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.desertCopper)
                Text(title)
                    .font(.title2.weight(.bold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button {
                    action()
                } label: {
                    Label(actionTitle, systemImage: "doc.badge.gearshape")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct GeospatialLayerCatalogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var query = ""
    @State private var selectedFormat: GeospatialLayerFormat?
    @State private var layers = GeospatialMapLayer.officialSamples
    @State private var statusMessage: String?
    @AppStorage("wildernessTileOverlayEnabled") private var wildernessTileOverlayEnabled = false
    @AppStorage("wildernessTileTemplate") private var wildernessTileTemplate = ""
    @AppStorage("wildernessTileName") private var wildernessTileName = "طبقة برية مخصصة"
    @AppStorage("wildernessTileOpacity") private var wildernessTileOpacity = 0.72

    private var filteredLayers: [GeospatialMapLayer] {
        layers.filter { layer in
            let matchesQuery = query.isEmpty
                || layer.title.localizedCaseInsensitiveContains(query)
                || layer.provider.localizedCaseInsensitiveContains(query)
                || layer.detail.localizedCaseInsensitiveContains(query)
                || layer.coverage.localizedCaseInsensitiveContains(query)
            let matchesFormat = selectedFormat == nil || layer.format == selectedFormat
            return matchesQuery && matchesFormat
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    liveTileOverlayPanel
                    searchPanel
                    sourceLayersPanel
                    processingPanel
                    searchResultsPanel
                    performancePanel
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("مصادر الخرائط البرية")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("كتالوج GIS عالي الدقة", systemImage: "map")
                .font(.headline.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text("يدير مصادر المساحة الجيولوجية، خرائط العجاجي، المخططات المرشمة، وحزم MBTiles/WMTS المرخصة قبل دمجها في MapKit وPDFKit.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("ابحث باسم الطبقة، المصدر، الوادي، الشعيب أو الهضبة", text: $query)
                .textFieldStyle(.roundedBorder)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton("الكل", isSelected: selectedFormat == nil) {
                        selectedFormat = nil
                    }

                    ForEach(GeospatialLayerFormat.allCases) { format in
                        filterButton(format.rawValue, isSelected: selectedFormat == format) {
                            selectedFormat = format
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var liveTileOverlayPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("طبقة Tiles فعلية فوق الخريطة")

            TextField("اسم الطبقة", text: $wildernessTileName)
                .textFieldStyle(.roundedBorder)

            TextField("https://server/tiles/{z}/{x}/{y}.png", text: $wildernessTileTemplate)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.caption.monospaced())

            Toggle("تفعيل الطبقة فوق القمر الصناعي", isOn: $wildernessTileOverlayEnabled)
                .disabled(!isTileTemplateValid)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("شفافية الطبقة")
                    Spacer()
                    Text("\(Int(wildernessTileOpacity * 100))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $wildernessTileOpacity, in: 0.2...1.0, step: 0.05)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(isTileTemplateValid ? "الرابط جاهز للتطبيق" : "الرابط يجب أن يحتوي {z} و{x} و{y}", systemImage: isTileTemplateValid ? "checkmark.circle" : "exclamationmark.triangle")
                    .foregroundStyle(isTileTemplateValid ? Color.green : Color.orange)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ],
                        spacing: 8
                    ) {
                        mapSourceSmallButton("تجربة") { applyDemoTileTemplate() }
                        mapSourceSmallButton("تطبيق") { applyTileTemplate() }
                            .disabled(!isTileTemplateValid)
                        mapSourceSmallButton("إيقاف") { disableTileOverlay() }
                    }
            }
            .font(.caption)

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.oasisTeal, in: Capsule())
                    .transition(.opacity)
            }

            Text("استخدم هذا الحقل فقط مع مصادر مرخصة أو رسمية. يدعم MapKit قوالب Tiles/WMTS من نوع XYZ، وسيتم عرض الطبقة مباشرة عند الرجوع إلى خريطة القمر الصناعي.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var sourceLayersPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("مصادر وطبقات الخرائط")
            ForEach(filteredLayers) { layer in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(layer.title)
                                .font(.headline)
                            Text(layer.provider)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            handleLayerAction(layer)
                        } label: {
                            Text(layer.status.title)
                                .font(.caption2.weight(.bold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.68)
                                .foregroundStyle(layer.status.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(layer.status.color.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(layer.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            layerMetric("الصيغة", layer.format.rawValue)
                            layerMetric("المقياس", layer.recommendedScale)
                        }
                        GridRow {
                            layerMetric("التغطية", layer.coverage)
                            layerMetric("دون اتصال", layer.offlinePlan)
                        }
                    }

                    Text(layer.sourceURL)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Button {
                            handleLayerAction(layer)
                        } label: {
                            Label(layerActionTitle(layer), systemImage: layerActionIcon(layer))
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(layer.status.color)

                        Button {
                            openLayerSource(layer)
                        } label: {
                            Label("فتح المصدر", systemImage: "safari")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .disabled(!isHTTPSource(layer.sourceURL))
                    }
                }
                .padding()
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var processingPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("معالجة البيانات الجغرافية")
            ForEach(GeospatialProcessingStep.pipeline) { step in
                Button {
                    showCatalogStatus("\(step.title): جاهز ضمن مسار تجهيز الخرائط")
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: step.icon)
                            .foregroundStyle(Color.oasisTeal)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            Text(step.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                Divider()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var searchResultsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("بحث جغرافي متقدم")
            ForEach(GeospatialSearchResult.samples) { result in
                Button {
                    query = result.name
                    showCatalogStatus("تم تحديد \(result.name) عند \(coordinateText(result.coordinate))")
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Color.desertCopper)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            Text("\(result.type) - \(result.source)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.4f", result.coordinate.latitude))
                            Text(String(format: "%.4f", result.coordinate.longitude))
                        }
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("الأداء والكفاءة")
            Label("تحميل تدريجي للخرائط الكبيرة عبر Tiles بدل فتح صورة ضخمة دفعة واحدة.", systemImage: "speedometer")
            Label("تخزين محلي محمي للـ PDF وMBTiles داخل Application Support.", systemImage: "lock.doc")
            Label("جاهزية للعمل دون اتصال عند توفر الحزمة المرخصة أو الملف الرسمي المستورد.", systemImage: "wifi.slash")
            Label("توافق الإحداثيات مع WGS84 وMapKit وCoreLocation.", systemImage: "location")
        }
        .font(.footnote)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var isTileTemplateValid: Bool {
        wildernessTileTemplate.contains("{z}") && wildernessTileTemplate.contains("{x}") && wildernessTileTemplate.contains("{y}")
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.60)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(isSelected ? Color.oasisTeal : Color(.tertiarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func mapSourceSmallButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.58)
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.bordered)
    }

    private func applyDemoTileTemplate() {
        wildernessTileName = "طبقة OpenStreetMap تجريبية"
        wildernessTileTemplate = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        wildernessTileOverlayEnabled = true
        showCatalogStatus("تم تفعيل طبقة تجريبية فوق القمر الصناعي")
    }

    private func applyTileTemplate() {
        wildernessTileOverlayEnabled = true
        showCatalogStatus("تم تطبيق الطبقة. ارجع للخريطة لمشاهدتها.")
    }

    private func disableTileOverlay() {
        wildernessTileOverlayEnabled = false
        showCatalogStatus("تم إيقاف الطبقة")
    }

    private func handleLayerAction(_ layer: GeospatialMapLayer) {
        switch layer.format {
        case .wms, .wmts, .mbtiles, .vector:
            if layer.status == .readyForImport {
                applyDemoTileTemplate()
            } else {
                openLayerSource(layer)
            }
        case .pdf:
            openLayerSource(layer)
        }
    }

    private func layerActionTitle(_ layer: GeospatialMapLayer) -> String {
        switch layer.status {
        case .readyForImport, .offlineReady:
            return "تجهيز الطبقة"
        case .bundled:
            return "عرض"
        case .sourceRequired:
            return "طلب المصدر"
        }
    }

    private func layerActionIcon(_ layer: GeospatialMapLayer) -> String {
        switch layer.status {
        case .readyForImport, .offlineReady:
            return "checkmark.circle"
        case .bundled:
            return "eye"
        case .sourceRequired:
            return "link"
        }
    }

    private func openLayerSource(_ layer: GeospatialMapLayer) {
        guard isHTTPSource(layer.sourceURL), let url = URL(string: layer.sourceURL) else {
            showCatalogStatus("هذا المصدر يحتاج ملفاً مرخصاً من إدارة الخرائط")
            return
        }
        openURL(url)
    }

    private func isHTTPSource(_ source: String) -> Bool {
        source.lowercased().hasPrefix("http://") || source.lowercased().hasPrefix("https://")
    }

    private func coordinateText(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    private func showCatalogStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }

    private func layerMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(3)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

enum DesertMapLayer: String, CaseIterable, Identifiable {
    case satellite
    case ajaji
    case markedPlans

    var id: String { rawValue }
}

struct MapCanvasView: UIViewRepresentable {
    let region: MKCoordinateRegion
    let route: [CLLocationCoordinate2D]
    var dirtRoadRoutes: [DirtRoadRoute] = []
    let places: [HiddenPlace]
    var tileTemplateURL: String?
    var tileOpacity: Double
    var showsUserLocation = false
    var onRegionChange: ((MKCoordinateRegion) -> Void)? = nil

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.mapType = .hybrid
        mapView.showsUserLocation = showsUserLocation
        mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .flat)
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.tileOpacity = tileOpacity
        context.coordinator.onRegionChange = onRegionChange
        mapView.showsUserLocation = showsUserLocation
        mapView.mapType = .hybrid
        mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .flat)
        let nextRegionKey = context.coordinator.regionKey(region)
        if context.coordinator.regionRenderKey != nextRegionKey {
            mapView.setRegion(region, animated: false)
            context.coordinator.regionRenderKey = nextRegionKey
        }

        let nextSignature = context.coordinator.signature(
            region: region,
            route: route,
            dirtRoadRoutes: dirtRoadRoutes,
            places: places,
            tileTemplateURL: tileTemplateURL,
            tileOpacity: tileOpacity
        )
        guard context.coordinator.renderSignature != nextSignature else {
            return
        }
        context.coordinator.renderSignature = nextSignature
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })

        if let tileTemplateURL {
            let overlay = MKTileOverlay(urlTemplate: tileTemplateURL)
            overlay.canReplaceMapContent = false
            overlay.minimumZ = 4
            overlay.maximumZ = 18
            mapView.addOverlay(overlay, level: .aboveLabels)
        }

        for dirtRoute in dirtRoadRoutes where dirtRoute.coordinates.count > 1 {
            let polyline = StyledMapPolyline(coordinates: dirtRoute.coordinates, count: dirtRoute.coordinates.count)
            polyline.routeID = dirtRoute.id
            polyline.strokeColor = UIColor(dirtRoute.difficulty.color)
            polyline.lineWidth = context.coordinator.dirtRoadLineWidth(routeID: dirtRoute.id)
            polyline.isDirtRoad = true
            mapView.addOverlay(polyline, level: .aboveRoads)
            context.coordinator.addDirtRoadAnnotation(dirtRoute, to: mapView)
        }

        if route.count > 1 {
            let polyline = StyledMapPolyline(coordinates: route, count: route.count)
            polyline.strokeColor = UIColor(Color.oasisTeal)
            polyline.lineWidth = 5
            mapView.addOverlay(polyline, level: .aboveLabels)
        }

        for place in places {
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = "★ \(place.rating) - \(place.notes)"
            annotation.coordinate = place.coordinate
            mapView.addAnnotation(annotation)
        }

        if let destination = route.last {
            let annotation = MKPointAnnotation()
            annotation.title = "الوجهة"
            annotation.subtitle = "نقطة الوصول المحددة للرحلة"
            annotation.coordinate = destination
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(tileOpacity: tileOpacity, onRegionChange: onRegionChange)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var tileOpacity: Double
        var regionRenderKey = ""
        var renderSignature = ""
        var onRegionChange: ((MKCoordinateRegion) -> Void)?

        init(tileOpacity: Double, onRegionChange: ((MKCoordinateRegion) -> Void)?) {
            self.tileOpacity = tileOpacity
            self.onRegionChange = onRegionChange
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let nextKey = regionKey(mapView.region)
            guard nextKey != regionRenderKey else { return }
            regionRenderKey = nextKey
            onRegionChange?(mapView.region)
        }

        func regionKey(_ region: MKCoordinateRegion) -> String {
            "\(region.center.latitude.rounded(toPlaces: 5)),\(region.center.longitude.rounded(toPlaces: 5)),\(region.span.latitudeDelta.rounded(toPlaces: 5)),\(region.span.longitudeDelta.rounded(toPlaces: 5))"
        }

        func signature(
            region: MKCoordinateRegion,
            route: [CLLocationCoordinate2D],
            dirtRoadRoutes: [DirtRoadRoute],
            places: [HiddenPlace],
            tileTemplateURL: String?,
            tileOpacity: Double
        ) -> String {
            let routeStart = route.first.map { "\($0.latitude),\($0.longitude)" } ?? "none"
            let routeEnd = route.last.map { "\($0.latitude),\($0.longitude)" } ?? "none"
            let dirtRouteIDs = dirtRoadRoutes.map { "\($0.id):\($0.coordinates.count)" }.joined(separator: ",")
            let placeIDs = places.map(\.id.uuidString).sorted().joined(separator: ",")
            return "\(regionKey(region))|\(tileTemplateURL ?? "none")|\(tileOpacity)|\(route.count)|\(routeStart)|\(routeEnd)|\(dirtRouteIDs)|\(placeIDs)"
        }

        func addDirtRoadAnnotation(_ route: DirtRoadRoute, to mapView: MKMapView) {
            guard let coordinate = route.coordinates.dropFirst().first ?? route.coordinates.first else { return }
            let annotation = MKPointAnnotation()
            annotation.title = route.name
            annotation.subtitle = "\(route.difficulty.rawValue) - \(route.condition)"
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }

        func dirtRoadLineWidth(routeID: String) -> CGFloat {
            4.5
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                renderer.alpha = CGFloat(tileOpacity)
                return renderer
            }
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if let styled = overlay as? StyledMapPolyline {
                    renderer.strokeColor = styled.strokeColor
                    renderer.lineWidth = styled.lineWidth
                    renderer.lineDashPattern = styled.isDirtRoad ? [9, 6] : nil
                } else {
                    renderer.strokeColor = UIColor(Color.oasisTeal)
                    renderer.lineWidth = 5
                }
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let identifier = "HiddenPlace"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.markerTintColor = UIColor(Color.desertCopper)
            view.glyphImage = UIImage(systemName: "mappin.and.ellipse")
            view.canShowCallout = true
            return view
        }
    }
}

final class StyledMapPolyline: MKPolyline {
    var routeID: String?
    var strokeColor = UIColor(Color.oasisTeal)
    var lineWidth: CGFloat = 5
    var isDirtRoad = false
}
