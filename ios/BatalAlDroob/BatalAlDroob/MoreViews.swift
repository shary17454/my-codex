import MapKit
import PhotosUI
import SwiftUI

struct MoreView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var locationWeather = LocationWeatherViewModel()
    @State private var descriptionQuery = ""
    @State private var oldTireSize = "265/70R16"
    @State private var newTireSize = "285/75R16"
    @State private var tireResult = ""

    var body: some View {
        let photoPickerTitle = viewModel.text(ar: "اختيار صورة كمرجع", en: "Choose reference photo")
        return NavigationStack {
            List {
                Section(viewModel.text(ar: "اللغة", en: "Language")) { LanguageMenu(viewModel: viewModel) }
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
                Section(viewModel.text(ar: "التتبع والبوصلة والطقس", en: "Tracking, compass, and weather")) {
                    Map(position: $locationWeather.cameraPosition) {
                        if let coordinate = locationWeather.coordinate {
                            Marker(viewModel.text(ar: "موقعي", en: "My location"), coordinate: coordinate)
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: BatalDesign.cardRadius))

                    HStack {
                        Button { locationWeather.requestAndStart(language: viewModel.language) } label: {
                            Label(
                                viewModel.text(ar: "تشغيل التتبع", en: "Start tracking"),
                                systemImage: "location.fill"
                            )
                        }
                        Button { locationWeather.stop(language: viewModel.language) } label: {
                            Label(viewModel.text(ar: "إيقاف", en: "Stop"), systemImage: "pause.circle")
                        }
                    }
                    if let coordinate = locationWeather.coordinate {
                        LabeledContent(
                            viewModel.text(ar: "الإحداثيات", en: "Coordinates"),
                            value: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
                        )
                    }
                    if let heading = locationWeather.headingDegrees {
                        LabeledContent(
                            viewModel.text(ar: "البوصلة", en: "Compass"),
                            value: String(format: "%.0f°", heading)
                        )
                        CompassDial(degrees: heading)
                            .frame(height: 120)
                            .accessibilityLabel(viewModel.text(ar: "اتجاه البوصلة", en: "Compass heading"))
                    }
                    if !locationWeather.weatherSummary.isEmpty {
                        LabeledContent(
                            viewModel.text(ar: "الطقس", en: "Weather"),
                            value: locationWeather.weatherSummary
                        )
                        if let attributionURL = URL(string: "https://open-meteo.com/") {
                            Link(destination: attributionURL) {
                                Label(
                                    viewModel.text(ar: "بيانات الطقس: Open-Meteo", en: "Weather data: Open-Meteo"),
                                    systemImage: "arrow.up.right.square"
                                )
                            }
                            .font(.caption)
                        }
                    }
                    if locationWeather.isLoadingWeather {
                        HStack {
                            ProgressView()
                            Text(viewModel.text(ar: "جاري تحديث الطقس...", en: "Updating weather..."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let weatherError = locationWeather.weatherError {
                        Text(viewModel.text(ar: "تعذر تحميل الطقس: ", en: "Weather unavailable: ") + weatherError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                        if let coordinate = locationWeather.coordinate {
                            Button {
                                Task {
                                    await locationWeather.loadWeather(
                                        for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                    )
                                }
                            } label: {
                                Label(viewModel.text(ar: "إعادة المحاولة", en: "Retry"), systemImage: "arrow.clockwise")
                            }
                        }
                    }
                    if !locationWeather.locationMessage.isEmpty {
                        Text(locationWeather.locationMessage).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section(viewModel.text(ar: "سياسة البيانات", en: "Data policy")) {
                    Text(viewModel.text(
                        ar: "التطبيق مستقل ولا يتبع نيسان، ولا ينسخ أسعار المتاجر أو مخزونها. " +
                            "تُفتح روابط المتاجر الموثقة لإكمال البحث أو الشراء خارج التطبيق. " +
                            "تبقى صور البحث وبيانات السيارة والصيانة على الجهاز. عند طلب الطقس فقط، " +
                            "تُرسل إحداثيات الموقع الدقيقة إلى Open-Meteo لتقديم النتيجة.",
                        en: "This app is independent from Nissan and does not copy store prices or inventory. " +
                            "Verified store links open externally to continue searching or purchasing. " +
                            "Reference photos, vehicle details, and maintenance entries stay on device. " +
                            "Only when weather is requested, precise coordinates are sent to Open-Meteo."
                    ))
                }
            }
            .navigationTitle(viewModel.text(ar: "المزيد", en: "More"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in
                PartDetailView(part: part, viewModel: viewModel)
            }
            .onDisappear { locationWeather.pauseTracking() }
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
            }
        } label: { Label(viewModel.language.title, systemImage: "globe") }
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
