import CoreLocation
import MapKit
import SwiftUI

struct DesertMapView: View {
    @EnvironmentObject private var appState: AppState
    @State private var route = GPXParser.loadRoute(named: "SampleRoute")
    @State private var showingAddPlace = false
    @State private var showingOfflineMaps = false
    @State private var showingPDFSourceManager = false
    @State private var showingGeospatialCatalog = false
    @StateObject private var pdfMapStore = PDFMapStore()
    @State private var mapLayer: DesertMapLayer = ScreenshotConfiguration.initialMapLayer
    @State private var ajajiImageIndex = ScreenshotConfiguration.initialAjajiImageIndex
    @AppStorage("wildernessTileOverlayEnabled") private var wildernessTileOverlayEnabled = false
    @AppStorage("wildernessTileTemplate") private var wildernessTileTemplate = ""
    @AppStorage("wildernessTileOpacity") private var wildernessTileOpacity = 0.72

    private let tripRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch mapLayer {
                case .satellite:
                    MapCanvasView(
                        region: tripRegion,
                        route: route,
                        places: appState.hiddenPlaces.filter { $0.status == .approved },
                        tileTemplateURL: activeTileTemplate,
                        tileOpacity: wildernessTileOpacity
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

            VStack(spacing: 12) {
                Picker("Map Layer", selection: $mapLayer) {
                    Text(appState.text(.satellite)).tag(DesertMapLayer.satellite)
                    Text(appState.text(.ajajiMaps)).tag(DesertMapLayer.ajaji)
                    Text(appState.text(.markedPlans)).tag(DesertMapLayer.markedPlans)
                }
                .pickerStyle(.segmented)

                if mapLayer == .ajaji {
                    Picker(appState.text(.ajajiMaps), selection: $ajajiImageIndex) {
                        Text(appState.text(.ajajiSaudi)).tag(0)
                        Text(appState.text(.ajajiRiyadh)).tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                if mapLayer != .satellite {
                    HStack(spacing: 10) {
                        Label(currentPDFStatus, systemImage: pdfMapStore.isImported(currentPDFDocument) ? "checkmark.seal" : "doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showingPDFSourceManager = true
                        } label: {
                            Label(appState.text(.managePDFSource), systemImage: "doc.badge.gearshape")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(10)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                }

                if mapLayer == .satellite {
                    HStack(spacing: 10) {
                        Label(activeTileTemplate == nil ? "لا توجد طبقة GIS فعالة" : "طبقة GIS فعالة", systemImage: activeTileTemplate == nil ? "square.3.layers.3d.slash" : "square.3.layers.3d")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showingGeospatialCatalog = true
                        } label: {
                            Label("إدارة الطبقات", systemImage: "slider.horizontal.3")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(10)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                }

                EnvironmentBanner(report: appState.environmentalReport)

                HStack(spacing: 10) {
                    metricTile(title: "GPS", value: appState.locationManager.isTracking ? appState.text(.gpsActive) : appState.text(.gpsReady), icon: "location")
                    metricTile(title: "ALT", value: altitudeText, icon: "mountain.2")
                    metricTile(title: "DIST", value: distanceText, icon: "point.topleft.down.curvedto.point.bottomright.up")
                }

                HStack {
                    Button {
                        appState.locationManager.isTracking ? appState.locationManager.stopNavigation() : appState.locationManager.startNavigation()
                    } label: {
                        Label(appState.locationManager.isTracking ? appState.text(.stopNavigation) : appState.text(.startNavigation), systemImage: "location.north.line")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        showingAddPlace = true
                    } label: {
                        Label(appState.text(.addPlace), systemImage: "plus")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showingOfflineMaps = true
                    } label: {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(appState.text(.offline))

                    Button {
                        showingGeospatialCatalog = true
                    } label: {
                        Image(systemName: "square.3.layers.3d")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("مصادر GIS")
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .task(id: appState.locationManager.currentLocation?.coordinate.latitude) {
            let coordinate = appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint
            appState.environmentalReport = await appState.weatherService.fetchReport(for: coordinate)
        }
        .sheet(isPresented: $showingAddPlace) {
            HiddenPlaceForm()
        }
        .sheet(isPresented: $showingOfflineMaps) {
            OfflineMapsView(region: tripRegion)
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

    private var activeTileTemplate: String? {
        let trimmed = wildernessTileTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard wildernessTileOverlayEnabled, trimmed.contains("{z}"), trimmed.contains("{x}"), trimmed.contains("{y}") else {
            return nil
        }
        return trimmed
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
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
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
    @State private var query = ""
    @State private var selectedFormat: GeospatialLayerFormat?
    @State private var layers = GeospatialMapLayer.officialSamples
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
                .font(.title3.weight(.bold))
            Text("يدير مصادر المساحة الجيولوجية، خرائط العجاجي، المخططات المرشمة، وحزم MBTiles/WMTS المرخصة قبل دمجها في MapKit وPDFKit.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
                HStack {
                    Button("الكل") {
                        selectedFormat = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedFormat == nil ? .oasisTeal : .gray)

                    ForEach(GeospatialLayerFormat.allCases) { format in
                        Button(format.rawValue) {
                            selectedFormat = format
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedFormat == format ? .oasisTeal : .gray)
                    }
                }
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

            HStack {
                Label(isTileTemplateValid ? "الرابط جاهز للتطبيق" : "الرابط يجب أن يحتوي {z} و{x} و{y}", systemImage: isTileTemplateValid ? "checkmark.circle" : "exclamationmark.triangle")
                    .foregroundStyle(isTileTemplateValid ? Color.green : Color.orange)
                Spacer()
                Button("إيقاف") {
                    wildernessTileOverlayEnabled = false
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)

            Text("استخدم هذا الحقل فقط مع مصادر مرخصة أو رسمية. يدعم MapKit قوالب Tiles/WMTS من نوع XYZ، وسيتم عرض الطبقة مباشرة عند الرجوع إلى خريطة القمر الصناعي.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                        Text(layer.status.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(layer.status.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(layer.status.color.opacity(0.12), in: Capsule())
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
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: step.icon)
                        .foregroundStyle(Color.oasisTeal)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Color.desertCopper)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.name)
                            .font(.subheadline.weight(.semibold))
                        Text("\(result.type) - \(result.source)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.4f, %.4f", result.coordinate.latitude, result.coordinate.longitude))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
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
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
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
    let places: [HiddenPlace]
    var tileTemplateURL: String?
    var tileOpacity: Double

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .realistic)
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.tileOpacity = tileOpacity
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })

        if let tileTemplateURL {
            let overlay = MKTileOverlay(urlTemplate: tileTemplateURL)
            overlay.canReplaceMapContent = false
            overlay.minimumZ = 4
            overlay.maximumZ = 18
            mapView.addOverlay(overlay, level: .aboveLabels)
        }

        if route.count > 1 {
            mapView.addOverlay(MKPolyline(coordinates: route, count: route.count), level: .aboveLabels)
        }

        let wadi = route.map { CLLocationCoordinate2D(latitude: $0.latitude + 0.004, longitude: $0.longitude - 0.003) }
        if wadi.count > 2 {
            mapView.addOverlay(MKPolygon(coordinates: wadi, count: wadi.count), level: .aboveLabels)
        }

        for place in places {
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = "★ \(place.rating) - \(place.notes)"
            annotation.coordinate = place.coordinate
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(tileOpacity: tileOpacity)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var tileOpacity: Double

        init(tileOpacity: Double) {
            self.tileOpacity = tileOpacity
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                renderer.alpha = CGFloat(tileOpacity)
                return renderer
            }
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color.oasisTeal)
                renderer.lineWidth = 5
                return renderer
            }
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor(Color.desertSand.opacity(0.32))
                renderer.strokeColor = UIColor(Color.desertCopper.opacity(0.8))
                renderer.lineWidth = 2
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
