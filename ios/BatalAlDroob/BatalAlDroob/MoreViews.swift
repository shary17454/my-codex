import MapKit
import PhotosUI
import SwiftUI

struct MoreView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var locationTracking = LocationTrackingViewModel()
    @State private var descriptionQuery = ""
    @State private var oldTireSize = "265/70R16"
    @State private var newTireSize = "285/75R16"
    @State private var tireResult = ""
    @State private var maintenanceTitle = ""
    @State private var maintenanceOdometer = ""
    @State private var maintenanceNotes = ""

    var body: some View {
        let photoPickerTitle = viewModel.text(ar: "اختيار صورة كمرجع", en: "Choose reference photo")
        return NavigationStack {
            List {
                Section(viewModel.text(ar: "اللغة", en: "Language")) { LanguageMenu(viewModel: viewModel) }
                Section(viewModel.text(ar: "مسارات سريعة", en: "Quick paths")) {
                    NavigationLink {
                        SharedFitmentContent(viewModel: viewModel)
                            .navigationTitle(viewModel.text(ar: "القطع المشتركة", en: "Shared fitment"))
                    } label: {
                        Label(
                            viewModel.text(ar: "القطع المشتركة", en: "Shared fitment"),
                            systemImage: "point.3.connected.trianglepath.dotted"
                        )
                    }
                    NavigationLink {
                        MaintenanceContent(
                            viewModel: viewModel,
                            title: $maintenanceTitle,
                            odometer: $maintenanceOdometer,
                            notes: $maintenanceNotes
                        )
                        .navigationTitle(viewModel.text(ar: "الصيانة", en: "Maintenance"))
                    } label: {
                        Label(viewModel.text(ar: "الصيانة", en: "Maintenance"), systemImage: "wrench.adjustable")
                    }
                }
                Section(viewModel.text(ar: "بحث بالوصف والصورة", en: "Description and photo search")) {
                    TextField(
                        viewModel.text(ar: "اكتب وصف العطل أو القطعة", en: "Describe the fault or part"),
                        text: $descriptionQuery,
                        axis: .vertical
                    )
                    Button { viewModel.applyDescriptionSearch(descriptionQuery) } label: {
                        Label(
                            viewModel.text(ar: "بحث بالوصف", en: "Search by description"),
                            systemImage: "text.magnifyingglass"
                        )
                    }
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        Label(photoPickerTitle, systemImage: "photo")
                    }
                    .task(id: viewModel.selectedPhoto) {
                        guard let item = viewModel.selectedPhoto else { return }
                        await viewModel.analyzePhoto(item)
                    }
                    if viewModel.isAnalyzingPhoto {
                        ProgressView(viewModel.text(ar: "تحليل الصورة على الجهاز", en: "Analyzing on device"))
                    }
                    if let selectedPhotoName = viewModel.selectedPhotoName {
                        Text(selectedPhotoName).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section(viewModel.text(ar: "حاسبة الكفرات", en: "Tire calculator")) {
                    TextField(viewModel.text(ar: "المقاس القديم", en: "Old size"), text: $oldTireSize)
                    TextField(viewModel.text(ar: "المقاس الجديد", en: "New size"), text: $newTireSize)
                    Button(viewModel.text(ar: "احسب الفرق", en: "Calculate difference")) {
                        tireResult = viewModel.tireDifference(oldSize: oldTireSize, newSize: newTireSize)
                    }
                    if !tireResult.isEmpty { Text(tireResult).font(.headline) }
                }
                Section(viewModel.text(ar: "قائمة الرغبات", en: "Wishlist")) {
                    if viewModel.wishlistParts.isEmpty {
                        EmptyStateView(
                            symbol: "heart",
                            title: viewModel.text(ar: "قائمة الرغبات فارغة", en: "Wishlist is empty"),
                            message: viewModel.text(
                                ar: "افتح أي قطعة واضغط القلب لحفظها هنا.",
                                en: "Open a part and tap the heart to save it here."
                            )
                        )
                    } else {
                        ForEach(viewModel.wishlistParts) { part in
                            NavigationLink(value: part) {
                                PartRow(part: part, viewModel: viewModel)
                            }
                        }
                    }
                }
                Section(viewModel.text(ar: "المتاجر الموثقة", en: "Verified stores")) {
                    ForEach(viewModel.stores) { store in
                        Button { viewModel.openStore(store, part: nil) } label: { Label(
                            store.name(language: viewModel.language),
                            systemImage: "link"
                        ) }
                    }
                }
                Section {
                    Map(position: $locationTracking.cameraPosition) {
                        if let coordinate = locationTracking.coordinate {
                            Marker(viewModel.text(ar: "موقعي", en: "My location"), coordinate: coordinate)
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: BatalDesign.cardRadius))

                    HStack {
                        Button { locationTracking.requestAndStart(language: viewModel.language) } label: {
                            Label(
                                viewModel.text(ar: "تشغيل التتبع", en: "Start tracking"),
                                systemImage: "location.fill"
                            )
                        }
                        Button { locationTracking.stop(language: viewModel.language) } label: {
                            Label(viewModel.text(ar: "إيقاف", en: "Stop"), systemImage: "pause.circle")
                        }
                    }
                    if let coordinate = locationTracking.coordinate {
                        LabeledContent(
                            viewModel.text(ar: "الإحداثيات", en: "Coordinates"),
                            value: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
                        )
                    }
                    if let heading = locationTracking.headingDegrees {
                        LabeledContent(
                            viewModel.text(ar: "البوصلة", en: "Compass"),
                            value: String(format: "%.0f°", heading)
                        )
                        CompassDial(degrees: heading)
                            .frame(height: 120)
                            .accessibilityLabel(viewModel.text(ar: "اتجاه البوصلة", en: "Compass heading"))
                    }
                    if !locationTracking.locationMessage.isEmpty {
                        Text(locationTracking.locationMessage).font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text(viewModel.text(ar: "التتبع والبوصلة", en: "Tracking and compass"))
                        .accessibilityIdentifier("more.section.tracking")
                }
                Section(viewModel.text(ar: "سياسة البيانات", en: "Data policy")) {
                    Text(viewModel.text(
                        ar: "التطبيق مستقل ولا يتبع نيسان، ولا ينسخ أسعار المتاجر أو مخزونها. " +
                            "تُفتح روابط المتاجر الموثقة لإكمال البحث أو الشراء خارج التطبيق. " +
                            "لا يرسل التطبيق صور البحث أو بيانات السيارة والصيانة أو إحداثيات التتبع " +
                            "إلى خادم تابع لنا.",
                        en: "This app is independent from Nissan and does not copy store prices or inventory. " +
                            "Verified store links open externally to continue searching or purchasing. " +
                            "The app does not send reference photos, vehicle details, maintenance entries, " +
                            "or tracking coordinates to a developer-operated server."
                    ))
                }
            }
            .navigationTitle(viewModel.text(ar: "المزيد", en: "More"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in
                PartDetailView(part: part, viewModel: viewModel)
            }
            .onDisappear { locationTracking.pauseTracking() }
        }
    }
}

struct CompassDial: View {
    let degrees: CLLocationDirection
    var body: some View {
        ZStack {
            Circle().stroke(.secondary.opacity(0.35), lineWidth: 2)
            ForEach(0 ..< 12) { tick in
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 2, height: tick % 3 == 0 ? 14 : 8)
                    .offset(y: -48)
                    .rotationEffect(.degrees(Double(tick) * 30))
            }
            Image(systemName: "location.north.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.red)
                .rotationEffect(.degrees(degrees))
            Text(String(format: "%.0f°", degrees))
                .font(.caption.monospacedDigit().bold())
                .offset(y: 44)
        }
        .padding(8)
    }
}

struct LanguageMenu: View {
    @Bindable var viewModel: CatalogViewModel
    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    viewModel.language = language
                } label: {
                    if viewModel.language == language {
                        Label(language.title, systemImage: "checkmark")
                    } else {
                        Text(language.title)
                    }
                }
                .accessibilityIdentifier("language.option.\(language.rawValue)")
            }
        } label: { Label(viewModel.language.title, systemImage: "globe") }
            .accessibilityIdentifier("language.menu")
            .accessibilityLabel(viewModel.text(ar: "تغيير اللغة", en: "Change language"))
    }
}

struct LoadingOverlay: View {
    let message: String
    var body: some View {
        ZStack {
            Rectangle().fill(.black.opacity(0.25)).ignoresSafeArea()
            VStack(spacing: 14) { ProgressView(); Text(message).font(.headline) }
                .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
        }
    }
}

struct PrivacyShieldView: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.fill").font(.largeTitle)
            Text(language == .arabic ? "المحتوى محمي" : "Content protected").font(.title.bold())
            Text(language == .arabic ? "تم حجب الكتالوج عندما لا يكون التطبيق نشطًا." :
                "The catalog is hidden while the app is inactive.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .center, spacing: BatalDesign.compactSpacing) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BatalDesign.sectionSpacing)
        .accessibilityElement(children: .combine)
    }
}

struct PaymentBanner: View {
    let message: String?
    let dismissLabel: String
    let dismiss: () -> Void

    var body: some View {
        if let message, !message.isEmpty {
            HStack(spacing: 10) {
                Text(message)
                    .font(.footnote.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dismissLabel)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 560)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
}
