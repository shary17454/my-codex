import CoreLocation
import SwiftUI
import UIKit
import UserNotifications

struct AdvancedToolsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSOS = false
    @State private var showingLiveShare = false
    @State private var showingAssistant = false
    @State private var showingTripReport = false
    @State private var showingTripCamera = false
    @State private var isRecording = false
    @State private var recordingStartedAt = Date()
    @State private var packingItems = PackingItem.samples
    @State private var downloadedRegions = OfflineRegionPack.samples
    @State private var enabledServiceCategories: Set<String> = ["وقود", "إسعاف", "تخييم"]
    @State private var voiceGuidanceEnabled = true
    @State private var prayerAlertsEnabled = false
    @State private var liveShareHours = 6.0
    @State private var aiPrompt = "أبغى مكان مناسب للعائلات قريب من الرياض"
    @State private var tripPeopleCount = 5.0
    @State private var tripDays = 2.0
    @State private var tripDistanceKM = 180.0
    @State private var fuelEfficiency = 7.5
    @State private var equipmentWeightKG = 180.0
    @State private var offlineLayerOptions = OfflineMapLayerOption.samples

    private var coordinate: CLLocationCoordinate2D {
        appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint
    }

    private var calculatorResult: ExpeditionCalculatorResult {
        ExpeditionCalculatorResult.estimate(
            people: Int(tripPeopleCount),
            days: Int(tripDays),
            distanceKM: Int(tripDistanceKM),
            fuelEfficiencyKMPerLiter: fuelEfficiency,
            equipmentKG: Int(equipmentWeightKG)
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                activeDriveCard
                platformVisionCard
                wildlifeGuideEntryCard
                smartTripPlannerCard
                aiDestinationGuideCard
                safetyAssistantCard
                advancedOfflineLayersCard
                expeditionCalculatorsCard
                advancedSearchCard
                dashboardCard
                smartAlertsCard
                tripRecorderCard
                emergencyCard
                safetyContinuityCard
                offlineMapsCard
                nearbyServicesCard
                liveShareCard
                groupTripCard
                routePlannerCard
                packingCard
                routeDifficultyCard
                reviewsAndGalleryCard
                communityMediaCard
                assistantCard
                advancedAICard
                voiceGuidanceCard
                skyAndPrayerCard
                fuelAndRoadStatusCard
                guidesCard
                tripCameraCard
                photographyPlannerCard
                autoSuggestionCard
                safetyGuideCard
                liveCommunityMapCard
                tripHistoryCard
                contentPlatformCard
                vehicleManagementCard
                futureServicesCard
                appleIntegrationCard
                advancedFutureCard
                achievementsCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingSOS) {
            SOSView(coordinate: coordinate)
        }
        .sheet(isPresented: $showingLiveShare) {
            LiveShareView(hours: liveShareHours, trip: appState.selectedTrip)
        }
        .sheet(isPresented: $showingAssistant) {
            SmartAssistantView(prompt: $aiPrompt, weather: appState.environmentalReport)
        }
        .sheet(isPresented: $showingTripReport) {
            TripReportView(startedAt: recordingStartedAt, coordinate: coordinate)
        }
        .sheet(isPresented: $showingTripCamera) {
            TripCameraPicker()
        }
    }

    private var activeDriveCard: some View {
        NavigationLink {
            ActiveTripDriveView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.driveGold, Color.desertCopper],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "car.side.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.driveBlack)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 4) {
                    Text("وضع الرحلة النشطة")
                        .font(.headline)
                    Text("واجهة قيادة فاخرة تعرض المسار، السرعة، GPS، الطقس، الخدمات، وزر بدء الرحلة.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Color.desertCopper)
            }
            .padding()
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var dashboardCard: some View {
        featureCard(title: "لوحة قيادة الرحلة", icon: "gauge.with.dots.needle.67percent", color: .oasisTeal) {
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("السرعة", "-- km/h", "speedometer")
                    metric("الاتجاه", "305°", "location.north")
                }
                GridRow {
                    metric("الارتفاع", altitudeText, "mountain.2")
                    metric("البطارية", batteryText, "battery.75percent")
                }
                GridRow {
                    metric("الطقس", "\(Int(appState.environmentalReport.temperatureCelsius))°C", "sun.max")
                    metric("GPS", appState.locationManager.isTracking ? "نشط" : "جاهز", "location")
                }
            }
        }
    }

    private var platformVisionCard: some View {
        featureCard(title: "منصة رفيق الدروب المتكاملة", icon: "square.stack.3d.up", color: .desertCopper) {
            Text("هذه الشاشة تجمع التخطيط، الملاحة، الخرائط دون اتصال، السلامة، المجتمع، الذكاء الاصطناعي، والتكامل مع أجهزة Apple في تجربة واحدة للرحلة البرية.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("AI", "تخطيط واقتراح", "sparkles")
                    metric("أوفلاين", "خرائط وطبقات", "arrow.down.app")
                }
                GridRow {
                    metric("السلامة", "SOS وتنبيهات", "shield.lefthalf.filled")
                    metric("المجتمع", "حالة مباشرة", "person.3")
                }
            }

            HStack {
                tag("خرائط")
                tag("سلامة")
                tag("مجتمع")
                tag("تصوير")
                tag("فلك")
            }
        }
    }

    private var wildlifeGuideEntryCard: some View {
        NavigationLink {
            WildlifeSafetyGuideView()
        } label: {
            featureCard(title: "دليل الحياة الفطرية", icon: "leaf.circle", color: .oasisTeal) {
                Text("دليل للطبيعة والسلامة البرية: الحيوانات والزواحف، النباتات، المحميات، المناطق المقيدة، التنبيهات حسب الموقع، آثار الحيوانات، مواسم النشاط، الفلك، والجيولوجيا.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        metric("الكائنات", "\(WildlifeSpeciesProfile.samples.count)", "pawprint")
                        metric("الانتشار", "\(WildlifeRangeZone.samples.count) مناطق", "map")
                    }
                    GridRow {
                        metric("السلامة", "\(FieldSafetyTopic.samples.count) أدلة", "cross.case")
                        metric("النباتات", "\(WildPlantProfile.samples.count)", "camera.macro")
                    }
                }

                HStack {
                    tag("حيوانات")
                    tag("نباتات")
                    tag("محميات")
                    tag("تنبيهات")
                    tag("فلك")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var smartTripPlannerCard: some View {
        let plan = SmartTripPlan.sample
        return featureCard(title: "مخطط الرحلة الذكي", icon: "wand.and.stars.inverse", color: .indigo) {
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("البداية", plan.startPoint, "location")
                    metric("الأشخاص", "\(plan.peopleCount)", "person.2")
                }
                GridRow {
                    metric("السيارة", plan.vehicleType, "car.2")
                    metric("الوصول", plan.eta, "clock")
                }
            }

            row(icon: "point.topleft.down.curvedto.point.bottomright.up", title: "المسار المقترح", subtitle: plan.route, trailing: "")
            row(icon: "fuelpump", title: "محطات الوقود", subtitle: plan.fuelStops.joined(separator: "، "), trailing: "")
            row(icon: "cup.and.saucer", title: "أماكن التوقف", subtitle: plan.restStops.joined(separator: "، "), trailing: "")
            row(icon: "tent", title: "نقاط التخييم", subtitle: plan.campingPoints.joined(separator: "، "), trailing: "")
            row(icon: "sun.max", title: "أفضل وقت للانطلاق", subtitle: plan.departureAdvice, trailing: plan.weatherSummary)
        }
    }

    private var aiDestinationGuideCard: some View {
        featureCard(title: "دليل الرحلات الذكي", icon: "sparkles", color: .purple) {
            TextField("مثال: أريد مكانًا هادئًا قريبًا من الرياض", text: $aiPrompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            ForEach(SmartDestinationSuggestion.samples) { suggestion in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(suggestion.title, systemImage: suggestion.icon)
                            .font(.headline)
                        Spacer()
                        Text(suggestion.distance)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.desertCopper)
                    }
                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        tag(suggestion.suitability)
                        tag(suggestion.bestTime)
                    }
                }
                Divider()
            }

            Button {
                showingAssistant = true
            } label: {
                Label("فتح المساعد وتحليل الطلب", systemImage: "brain.head.profile")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var safetyAssistantCard: some View {
        featureCard(title: "مساعد السلامة قبل الانطلاق", icon: "checkmark.shield", color: .red) {
            ForEach(SafetyAssistantFinding.samples) { finding in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: finding.icon)
                        .foregroundStyle(finding.severity.color)
                        .frame(width: 34, height: 34)
                        .background(finding.severity.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(finding.title)
                                .font(.headline)
                            Spacer()
                            Text(finding.severity.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(finding.severity.color)
                        }
                        Text(finding.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(finding.recommendation)
                            .font(.caption.weight(.semibold))
                    }
                }
                Divider()
            }
        }
    }

    private var advancedOfflineLayersCard: some View {
        featureCard(title: "خرائط أوفلاين وطبقات متعددة", icon: "map.fill", color: .oasisTeal) {
            ForEach($offlineLayerOptions) { $option in
                Toggle(isOn: $option.isEnabled) {
                    row(icon: option.icon, title: option.title, subtitle: option.detail, trailing: option.isEnabled ? "مفعلة" : "")
                }
            }

            Text("تدعم البنية استيراد GPX/KML، تقسيم المناطق، تخزين الحزم محليًا، وتشغيل وإيقاف طبقات الطرق والمسارات والكثبان والجبال والأودية والخدمات ونقاط الشبكة.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var expeditionCalculatorsCard: some View {
        let result = calculatorResult
        return featureCard(title: "حاسبات الرحلة الذكية", icon: "function", color: .desertCopper) {
            labeledSlider(title: "عدد الأشخاص", value: $tripPeopleCount, range: 1...12, step: 1, suffix: "أشخاص")
            labeledSlider(title: "مدة الرحلة", value: $tripDays, range: 1...7, step: 1, suffix: "أيام")
            labeledSlider(title: "المسافة", value: $tripDistanceKM, range: 20...900, step: 10, suffix: "كم")
            labeledSlider(title: "استهلاك السيارة", value: $fuelEfficiency, range: 4...14, step: 0.5, suffix: "كم/لتر")
            labeledSlider(title: "وزن المعدات", value: $equipmentWeightKG, range: 40...700, step: 10, suffix: "كجم")

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("المياه", "\(result.waterLiters) لتر", "drop")
                    metric("الوقود", "\(result.fuelLiters) لتر", "fuelpump")
                }
                GridRow {
                    metric("احتياطي", "\(result.reserveFuelLiters) لتر", "plus.circle")
                    metric("الحمولة", "\(result.estimatedLoadKG) كجم", "shippingbox")
                }
                GridRow {
                    metric("التكلفة", "\(result.tripCostSAR) ريال", "banknote")
                    metric("الهامش", "35%", "shield")
                }
            }
        }
    }

    private var advancedSearchCard: some View {
        featureCard(title: "البحث المتقدم", icon: "magnifyingglass.circle", color: .oasisTeal) {
            Text("يدعم البحث باسم المكان، الإحداثيات، نوع التضاريس، الخدمات، مستوى الصعوبة، المنطقة، والمسافة.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                tag("24.6028, 46.5535")
                tag("وادي")
                tag("دفع رباعي")
            }
            ForEach(GeospatialSearchResult.samples) { result in
                row(
                    icon: "mappin.and.ellipse",
                    title: "\(result.name) - \(result.type)",
                    subtitle: "\(result.source) · \(String(format: "%.4f", result.coordinate.latitude)), \(String(format: "%.4f", result.coordinate.longitude))",
                    trailing: "فتح"
                )
            }
        }
    }

    private var smartAlertsCard: some View {
        featureCard(title: "التنبيهات الذكية للمخاطر", icon: "exclamationmark.triangle", color: .red) {
            ForEach(RiskAlert.samples) { alert in
                HStack(spacing: 12) {
                    Image(systemName: alert.icon)
                        .foregroundStyle(alert.severity.color)
                        .frame(width: 34, height: 34)
                        .background(alert.severity.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(alert.title)
                            .font(.headline)
                        Text(alert.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(alert.severity.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(alert.severity.color)
                        Text(String(format: "%.0f كم", alert.distanceKilometers))
                            .font(.caption2)
                    }
                }
                Divider()
            }

            Button {
                scheduleRiskNotification()
            } label: {
                Label("تفعيل إشعار تجريبي", systemImage: "bell.badge")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var tripRecorderCard: some View {
        featureCard(title: "تسجيل الرحلات", icon: "record.circle", color: .desertCopper) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = isRecording ? context.date.timeIntervalSince(recordingStartedAt) : 0
                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        metric("المدة", durationText(elapsed), "timer")
                        metric("المسافة", String(format: "%.1f كم", elapsed / 850), "map")
                    }
                    GridRow {
                        metric("متوسط السرعة", isRecording ? "42 km/h" : "--", "speedometer")
                        metric("نقاط التوقف", isRecording ? "2" : "0", "mappin.and.ellipse")
                    }
                }
            }

            HStack {
                Button {
                    if isRecording {
                        showingTripReport = true
                    } else {
                        recordingStartedAt = .now
                    }
                    isRecording.toggle()
                } label: {
                    Label(isRecording ? "إنهاء وحفظ التقرير" : "بدء التسجيل", systemImage: isRecording ? "stop.fill" : "record.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingTripReport = true
                } label: {
                    Image(systemName: "doc.richtext")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("عرض تقرير الرحلة")
            }
        }
    }

    private var emergencyCard: some View {
        featureCard(title: "نظام الطوارئ SOS", icon: "sos", color: .red) {
            Text("يرسل آخر موقع معروف مع الإحداثيات والوقت والبطارية واتجاه الحركة. عند انقطاع الاتصال يحفظ الطلب للإرسال عند عودة الشبكة.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                showingSOS = true
            } label: {
                Label("فتح زر الطوارئ", systemImage: "sos.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private var safetyContinuityCard: some View {
        featureCard(title: "استمرارية السلامة والرجوع", icon: "arrow.uturn.backward.circle", color: .red) {
            row(icon: "location.fill", title: "آخر موقع معروف", subtitle: "يحفظ آخر إحداثيات ووقت وبطارية قبل ضعف الشبكة أو نفاد البطارية.", trailing: "نشط")
            row(icon: "bell.and.waves.left.and.right", title: "تنبيه عدم الحركة", subtitle: "يراقب توقف السيارة لفترة طويلة ويجهز تنبيهًا لجهات الاتصال.", trailing: "30 د")
            row(icon: "arrow.turn.up.left", title: "العودة لنقطة البداية", subtitle: "يحفظ نقطة الانطلاق ومسار الرجوع لاستخدامه عند انقطاع الإنترنت.", trailing: "جاهز")
            row(icon: "paperplane", title: "إرسال مؤجل", subtitle: "إذا لم تتوفر الشبكة، يحفظ طلب SOS ويرسله فور عودة الاتصال.", trailing: "طوارئ")
        }
    }

    private var offlineMapsCard: some View {
        featureCard(title: "الخرائط الكاملة بدون إنترنت", icon: "arrow.down.app", color: .oasisTeal) {
            ForEach($downloadedRegions) { $region in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(region.name)
                            .font(.headline)
                        Spacer()
                        Text(region.size)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: region.progress)
                    Button(region.isDownloaded ? "جاهزة للاستخدام دون إنترنت" : "تنزيل المنطقة") {
                        region.progress = 1
                        region.isDownloaded = true
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                }
                Divider()
            }
        }
    }

    private var nearbyServicesCard: some View {
        featureCard(title: "طبقات الخدمات القريبة", icon: "point.3.connected.trianglepath.dotted", color: .desertCopper) {
            let categories = Array(Set(NearbyService.samples.map(\.category))).sorted()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { category in
                        Toggle(category, isOn: Binding(
                            get: { enabledServiceCategories.contains(category) },
                            set: { enabled in
                                if enabled { enabledServiceCategories.insert(category) } else { enabledServiceCategories.remove(category) }
                            }
                        ))
                        .toggleStyle(.button)
                    }
                }
            }

            ForEach(NearbyService.samples.filter { enabledServiceCategories.contains($0.category) }) { service in
                row(icon: service.icon, title: service.name, subtitle: "\(service.category) - \(String(format: "%.1f كم", service.distanceKilometers))", trailing: "انتقال")
            }
        }
    }

    private var liveShareCard: some View {
        featureCard(title: "مشاركة الموقع المباشر", icon: "location.viewfinder", color: .oasisTeal) {
            Slider(value: $liveShareHours, in: 1...24, step: 1) {
                Text("مدة المشاركة")
            }
            Text("مدة المشاركة: \(Int(liveShareHours)) ساعات")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                showingLiveShare = true
            } label: {
                Label("إنشاء رابط وQR للمشاركة", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var groupTripCard: some View {
        featureCard(title: "نظام المجموعات والرحلات الجماعية", icon: "person.3.fill", color: .purple) {
            Text("تجربة المجموعة تجمع مشاركة الموقع، الخطة، متابعة الأعضاء، الدردشة، وتنبيهات الرحلة الجماعية.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(GroupTripMember.samples) { member in
                row(icon: "person.crop.circle", title: member.name, subtitle: "\(member.status) · يبعد \(member.distanceFromLead) عن القائد", trailing: member.lastSeen)
            }

            HStack {
                Button {
                    showingLiveShare = true
                } label: {
                    Label("مشاركة المجموعة", systemImage: "location.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                } label: {
                    Label("تنبيه جماعي", systemImage: "bell.badge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var packingCard: some View {
        featureCard(title: "قائمة تجهيز الرحلة", icon: "checklist", color: .desertCopper) {
            ForEach($packingItems) { $item in
                Toggle(isOn: $item.isChecked) {
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(item.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var routePlannerCard: some View {
        featureCard(title: "المسارات المتقدمة والمقارنة", icon: "point.topleft.down.curvedto.point.bottomright.up", color: .oasisTeal) {
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("المفضلة", "12", "star")
                    metric("Pins", "27", "mappin")
                }
                GridRow {
                    metric("قياس المسافة", "متاح", "ruler")
                    metric("GPX", "استيراد/تصدير", "doc.badge.arrow.up")
                }
            }
            ForEach(RouteComparison.samples) { route in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(route.name)
                            .font(.headline)
                        Spacer()
                        Text(route.risk)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(route.risk == "مرتفع" ? .red : route.risk == "متوسط" ? .orange : .green)
                    }
                    HStack {
                        tag(route.distance)
                        tag(route.eta)
                        tag(route.terrain)
                    }
                }
                Divider()
            }
            Text("يدعم البحث باسم الموقع أو الإحداثيات، عرض أكثر من مسار، مقارنة المسافة والزمن ونوع الطريق، وحفظ تقارير PDF/GPX.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var routeDifficultyCard: some View {
        featureCard(title: "تقييم صعوبة الطرق", icon: "road.lanes", color: .orange) {
            ForEach(RouteCondition.samples) { condition in
                row(icon: condition.icon, title: condition.title, subtitle: "\(condition.terrain) - \(condition.difficulty)", trailing: condition.lastUpdate)
            }
        }
    }

    private var reviewsAndGalleryCard: some View {
        featureCard(title: "تقييم المسارات ومعرض الصور", icon: "photo.stack", color: .oasisTeal) {
            ForEach(appState.hiddenPlaces) { place in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(place.name, systemImage: place.imageSystemName)
                            .font(.headline)
                        Spacer()
                        Label("\(place.rating).0", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                    }
                    HStack {
                        tag("عائلات")
                        tag("غروب")
                        tag("تخييم")
                        tag(place.status == .approved ? "منشور" : "قيد المراجعة")
                    }
                    HStack {
                        placeholderPhoto("sunset.fill")
                        placeholderPhoto("mountain.2.fill")
                        placeholderPhoto("tent.fill")
                    }
                }
                Divider()
            }
        }
    }

    private var communityMediaCard: some View {
        featureCard(title: "المجتمع والوسائط والمجموعات", icon: "person.3.sequence", color: .purple) {
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("تعليقات", "48", "text.bubble")
                    metric("إعجابات", "1.2K", "hand.thumbsup")
                }
                GridRow {
                    metric("مجموعات", "6", "person.3")
                    metric("رحلات جماعية", "3", "calendar.badge.plus")
                }
            }
            ForEach(["رفع صور وفيديوهات", "صور بانورامية 360 درجة", "دردشة أثناء الرحلة", "مشاركة الموقع مع المجموعة", "بلاغات الرمال والسيول والإغلاقات"], id: \.self) { item in
                row(icon: "checkmark.circle", title: item, subtitle: "مدعوم في نموذج المجتمع القابل للتوسعة", trailing: "")
            }
        }
    }

    private var assistantCard: some View {
        featureCard(title: "المساعد الذكي", icon: "sparkles", color: .purple) {
            TextField("اكتب طلبك", text: $aiPrompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            Button {
                showingAssistant = true
            } label: {
                Label("اقترح رحلة", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var advancedAICard: some View {
        featureCard(title: "قدرات الذكاء الاصطناعي الموسعة", icon: "brain.head.profile", color: .indigo) {
            ForEach([
                "اقتراح أماكن حسب المدينة والطقس والفصل",
                "اقتراح حسب نوع السيارة وعدد الأشخاص",
                "أماكن للعائلات والتطعيس والتخييم والتصوير",
                "إنشاء خطة رحلة كاملة وتقدير الوقود والتكلفة",
                "تحليل حالة الطريق واقتراح مسارات بديلة",
                "توقع صعوبة الطريق والتعرف على النباتات والحيوانات من الصور",
                "اقتراح أماكن مشابهة للموقع الحالي"
            ], id: \.self) { item in
                row(icon: "sparkles", title: item, subtitle: "جاهز للربط بمحرك AI وبيانات المجتمع", trailing: "")
            }
        }
    }

    private var voiceGuidanceCard: some View {
        featureCard(title: "المساعد الصوتي أثناء القيادة", icon: "speaker.wave.2", color: .oasisTeal) {
            Toggle("تشغيل الإرشادات الصوتية", isOn: $voiceGuidanceEnabled)
            VStack(alignment: .leading, spacing: 8) {
                Text("الأوامر الجاهزة")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("انعطف يمين بعد 500 متر")
                Text("أمامك طريق رملي")
                Text("يوجد تنبيه جوي في المنطقة")
            }
            .font(.subheadline)
        }
    }

    private var skyAndPrayerCard: some View {
        featureCard(title: "السماء والفلك والقبلة", icon: "moon.stars", color: .indigo) {
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("الشروق", "05:11", "sunrise")
                    metric("الغروب", "18:46", "sunset")
                }
                GridRow {
                    metric("القمر", "تربيع أول", "moonphase.first.quarter")
                    metric("القبلة", "244°", "safari")
                }
                GridRow {
                    metric("الفجر", "03:44", "clock")
                    metric("العشاء", "20:16", "clock")
                }
            }
            Toggle("تنبيهات مواقيت الصلاة", isOn: $prayerAlertsEnabled)
        }
    }

    private var fuelAndRoadStatusCard: some View {
        featureCard(title: "الوقود وحالة الطريق", icon: "fuelpump", color: .orange) {
            Label("أقرب محطة وقود على بعد 12.4 كم", systemImage: "fuelpump")
            Label("بعد 38 كم تدخل منطقة قليلة الخدمات", systemImage: "exclamationmark.triangle")
            Label("آخر تحديث: توجد رمال ناعمة في طريق وادي مخفي", systemImage: "person.2.wave.2")
        }
    }

    private var guidesCard: some View {
        featureCard(title: "دليل النباتات والحيوانات البرية", icon: "book", color: .green) {
            Text("النباتات")
                .font(.headline)
            ForEach(WildlifeGuideItem.plants) { item in
                row(icon: item.icon, title: item.name, subtitle: "\(item.detail) الموسم: \(item.season)", trailing: "")
            }
            Text("الحيوانات")
                .font(.headline)
            ForEach(WildlifeGuideItem.animals) { item in
                row(icon: item.icon, title: item.name, subtitle: "\(item.detail) الموسم: \(item.season)", trailing: "")
            }
            Text("الطيور والمشاهدات")
                .font(.headline)
            row(icon: "binoculars", title: "توثيق مشاهدة", subtitle: "حفظ الموقع والتاريخ والصورة وبناء خريطة للحياة الفطرية", trailing: "جديد")
            row(icon: "bird", title: "دليل الطيور", subtitle: "مواسم الظهور وأماكن المشاهدة وأفضل أوقات الرصد", trailing: "")
        }
    }

    private var tripCameraCard: some View {
        featureCard(title: "كاميرا الرحلات", icon: "camera", color: .desertCopper) {
            Text("تفتح الكاميرا أو مكتبة الصور لتوثيق الرحلة مع عرض موقع الالتقاط الحالي داخل التطبيق.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            row(icon: "mappin", title: "موقع الالتقاط", subtitle: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude), trailing: altitudeText)
            Button {
                showingTripCamera = true
            } label: {
                Label("فتح الكاميرا", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var photographyPlannerCard: some View {
        featureCard(title: "مخطط التصوير والفلك", icon: "camera.metering.matrix", color: .indigo) {
            ForEach(AstronomyPhotographyWindow.samples) { window in
                row(icon: window.icon, title: window.title, subtitle: window.detail, trailing: window.time)
            }

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("اتجاه الشمس", "غرب", "sun.max")
                    metric("اتجاه القمر", "جنوب شرق", "moon")
                }
                GridRow {
                    metric("الغيوم", "12%", "cloud")
                    metric("إضاءة القمر", "31%", "moonphase.first.quarter")
                }
            }
        }
    }

    private var autoSuggestionCard: some View {
        featureCard(title: "اقتراح رحلة تلقائي", icon: "calendar.badge.clock", color: .oasisTeal) {
            Text("أفضل اقتراح اليوم: كشتة قصيرة قرب مطل الحجر بسبب اعتدال الرياح وقرب الخدمات وتقييم المجتمع المرتفع.")
                .font(.subheadline)
            HStack {
                tag("18 كم")
                tag("رياح 18 km/h")
                tag("عائلات")
                tag("غروب")
            }
        }
    }

    private var safetyGuideCard: some View {
        featureCard(title: "دليل السلامة والنجاة", icon: "cross.case", color: .red) {
            ForEach(["الغرز في الرمال", "السيول", "الأعطال", "الإسعافات الأولية", "فقدان الطريق", "السلامة أثناء التخييم"], id: \.self) { item in
                row(icon: "checkmark.shield", title: item, subtitle: "متاح دون اتصال", trailing: "فتح")
            }
        }
    }

    private var liveCommunityMapCard: some View {
        featureCard(title: "الخريطة المجتمعية الحية", icon: "dot.radiowaves.left.and.right", color: .red) {
            Text("الميزة التنافسية: خريطة تتحدث بمساهمات المستخدمين وتعرض حالة الطريق والخدمات والصور والطقس والشبكة وآخر الزيارات في الوقت الحقيقي.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            ForEach(LiveCommunitySignal.samples) { signal in
                row(icon: signal.icon, title: signal.title, subtitle: signal.detail, trailing: signal.freshness)
            }
        }
    }

    private var tripHistoryCard: some View {
        featureCard(title: "سجل الرحلات والملف الشخصي", icon: "person.crop.rectangle.stack", color: .desertCopper) {
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    metric("الرحلات", "24", "calendar")
                    metric("المسافة", "3,840 كم", "road.lanes")
                }
                GridRow {
                    metric("القيادة", "126 س", "clock")
                    metric("الصور", "318", "photo.stack")
                }
                GridRow {
                    metric("المفضلة", "42", "star")
                    metric("التقييمات", "86", "text.bubble")
                }
            }

            row(icon: "doc.richtext", title: "تقرير رحلة محفوظ", subtitle: "التاريخ، المسار، الطقس، الصور، السرعات، ونقاط التوقف.", trailing: "PDF/GPX")
            row(icon: "seal", title: "الإنجازات", subtitle: "مستكشف الصحراء، عاشق الجبال، محترف الملاحة، قائد 100 رحلة.", trailing: "شارات")
        }
    }

    private var contentPlatformCard: some View {
        featureCard(title: "منصة المحتوى والمعرفة", icon: "newspaper", color: .oasisTeal) {
            ForEach(ContentArticle.samples) { article in
                row(icon: article.icon, title: article.title, subtitle: "\(article.category) · \(article.summary)", trailing: article.readTime)
            }
            Text("المقالات تعمل كدليل عملي داخل التطبيق، ويمكن جعل أهم إرشادات السلامة متاحة دون اتصال.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var vehicleManagementCard: some View {
        featureCard(title: "إدارة المركبات", icon: "car.2", color: .desertCopper) {
            ForEach(VehicleProfile.samples) { vehicle in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(vehicle.name, systemImage: "car.fill")
                            .font(.headline)
                        Spacer()
                        Text(vehicle.estimatedTripCost)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.oasisTeal)
                    }
                    HStack {
                        tag(vehicle.fuelEfficiency)
                        tag(vehicle.nextService)
                    }
                }
                Divider()
            }
            Text("يدعم إضافة أكثر من سيارة، حساب تكلفة الرحلة، متابعة الوقود، وتذكيرات الزيت والإطارات والصيانة.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var futureServicesCard: some View {
        featureCard(title: "الخدمات المستقبلية والسوق", icon: "bag", color: .oasisTeal) {
            ForEach(FutureServiceItem.samples) { item in
                row(icon: item.icon, title: item.title, subtitle: item.detail, trailing: "مستقبلي")
            }
            row(icon: "cart", title: "سوق المستخدمين", subtitle: "بيع وتأجير معدات الرحلات بين المستخدمين", trailing: "")
        }
    }

    private var appleIntegrationCard: some View {
        featureCard(title: "التكامل مع أجهزة Apple", icon: "apple.logo", color: .black) {
            ForEach(AppleIntegrationItem.samples) { item in
                row(icon: item.icon, title: item.title, subtitle: item.status, trailing: "خارطة")
            }
            row(icon: "icloud", title: "مزامنة iCloud", subtitle: "الرحلات، المفضلة، الصور، التقارير، وإعدادات المستخدم", trailing: "نشط")
        }
    }

    private var advancedFutureCard: some View {
        featureCard(title: "المزايا المستقبلية المتقدمة", icon: "cube.transparent", color: .indigo) {
            ForEach([
                "خرائط ثلاثية الأبعاد وتضاريس 3D",
                "واقع معزز AR لتوجيه المستخدم على الأرض",
                "دعم Drone لتوثيق المواقع والمسارات",
                "منصة ويب ولوحة تحكم للمشرفين",
                "واجهة API وتقارير وإحصائيات متقدمة",
                "نسخ احتياطي تلقائي ودعم جميع دول الخليج",
                "دعم لغات إضافية"
            ], id: \.self) { item in
                row(icon: "arrow.up.forward.app", title: item, subtitle: "ضمن خارطة النمو القادمة", trailing: "")
            }
        }
    }

    private var achievementsCard: some View {
        featureCard(title: "النقاط والإنجازات والتحديات", icon: "trophy", color: .orange) {
            HStack {
                metric("نقاطك", "820", "star.circle")
                metric("الشارات", "7", "seal")
            }
            ForEach(SeasonalChallenge.samples) { challenge in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(challenge.title)
                            .font(.headline)
                        Spacer()
                        Text(challenge.reward)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: challenge.progress)
                }
            }
        }
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.currentLocation?.altitude else { return "-- m" }
        return "\(Int(altitude)) m"
    }

    private var batteryText: String {
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return "--" }
        return "\(Int(level * 100))%"
    }

    private func featureCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func metric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.desertCopper)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func row(icon: String, title: String, subtitle: String, trailing: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.oasisTeal)
                .frame(width: 34, height: 34)
                .background(Color.oasisTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !trailing.isEmpty {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.desertCopper)
            }
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.desertSand.opacity(0.45), in: Capsule())
    }

    private func labeledSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(formattedSliderValue(value.wrappedValue, step: step)) \(suffix)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func formattedSliderValue(_ value: Double, step: Double) -> String {
        if step >= 1 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    private func placeholderPhoto(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(Color.desertCopper)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(Color.desertSand.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }

    private func scheduleRiskNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "تحذير رفيق الدروب"
            content.body = "اقتربت من مسار رملي ناعم. تحقق من ضغط الإطارات قبل الدخول."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: "desert-risk-demo", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
}

struct SOSView: View {
    let coordinate: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss

    private var message: String {
        """
        SOS رفيق الدروب
        آخر موقع معروف:
        \(coordinate.latitude), \(coordinate.longitude)
        الوقت: \(Date().formatted(date: .numeric, time: .shortened))
        البطارية: \(batteryText)
        """
    }

    private var batteryText: String {
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return "--" }
        return "\(Int(level * 100))%"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "sos.circle.fill")
                    .font(.system(size: 92))
                    .foregroundStyle(.red)
                Text("إرسال طلب طوارئ")
                    .font(.title2.weight(.bold))
                Text(message)
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                ShareLink(item: message) {
                    Label("مشاركة رسالة الطوارئ", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                Spacer()
            }
            .padding()
            .navigationTitle("SOS")
            .toolbar {
                Button("تم") { dismiss() }
            }
        }
    }
}

struct LiveShareView: View {
    let hours: Double
    let trip: TripPlan
    @Environment(\.dismiss) private var dismiss

    private var liveURL: URL {
        URL(string: "https://deserttrail.local/live/\(trip.id.uuidString)?hours=\(Int(hours))") ?? URL(fileURLWithPath: "/")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("مشاركة الموقع المباشر")
                    .font(.title2.weight(.bold))
                QRCodeGenerator.image(from: liveURL.absoluteString)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230, height: 230)
                Text("الرابط صالح لمدة \(Int(hours)) ساعات")
                    .foregroundStyle(.secondary)
                ShareLink(item: liveURL) {
                    Label("مشاركة الرابط", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .toolbar {
                Button("تم") { dismiss() }
            }
        }
    }
}

struct SmartAssistantView: View {
    @Binding var prompt: String
    let weather: EnvironmentalReport
    @Environment(\.dismiss) private var dismiss

    private var suggestion: String {
        if prompt.contains("عائ") {
            return "اقتراحي: فيضة الندى مناسبة للعائلات إذا كانت الأرض جافة. الرياح \(Int(weather.windSpeedKPH)) km/h والحرارة \(Int(weather.temperatureCelsius))°C، فاجعل الرحلة بعد العصر."
        }
        if prompt.contains("جبال") {
            return "اقتراحي: مطل الحجر، تضاريس صخرية وإطلالة مناسبة للغروب، مع ضرورة الانتباه للرياح على الحواف."
        }
        return "اقتراحي: كشتة وادي مخفي لمسار متوسط، مع تجهيز ماء إضافي وفحص تنبيهات السيول قبل الانطلاق."
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("طلبك", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
                Text(suggestion)
                    .font(.title3.weight(.semibold))
                    .padding()
                    .background(Color.desertSand.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                Label("يعتمد الاقتراح على الطقس، المسافة، حالة الطريق، وتفضيلات المستخدم.", systemImage: "sparkles")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("المساعد الذكي")
            .toolbar {
                Button("تم") { dismiss() }
            }
        }
    }
}

struct TripCameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = Self.preferredSourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    private static var preferredSourceType: UIImagePickerController.SourceType {
        UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            dismiss()
        }
    }
}

struct TripReportView: View {
    let startedAt: Date
    let coordinate: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss

    private var report: String {
        """
        تقرير رحلة رفيق الدروب
        البداية: \(startedAt.formatted(date: .numeric, time: .shortened))
        النهاية: \(Date().formatted(date: .numeric, time: .shortened))
        المسافة المقدرة: 18.6 كم
        متوسط السرعة: 42 km/h
        أعلى سرعة: 76 km/h
        آخر إحداثيات: \(coordinate.latitude), \(coordinate.longitude)
        """
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(report)
                    .font(.body.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                ShareLink(item: report) {
                    Label("تصدير أو مشاركة التقرير", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("تقرير الرحلة")
            .toolbar {
                Button("تم") { dismiss() }
            }
        }
    }
}

struct WildlifeSafetyGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedDanger: WildlifeDangerLevel?

    private var filteredSpecies: [WildlifeSpeciesProfile] {
        WildlifeSpeciesProfile.samples.filter { item in
            let matchesSearch = searchText.isEmpty
                || item.arabicName.localizedCaseInsensitiveContains(searchText)
                || item.scientificName.localizedCaseInsensitiveContains(searchText)
                || item.distribution.localizedCaseInsensitiveContains(searchText)
            let matchesDanger = selectedDanger == nil || item.dangerLevel == selectedDanger
            return matchesSearch && matchesDanger
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                heroCard
                recognitionCard
                speciesDatabaseCard
                rangeMapCard
                locationAlertsCard
                plantsCard
                reservesCard
                restrictedAreasCard
                fieldSafetyCard
                tracksCard
                seasonsCard
                sightingsCard
                astronomyCard
                geologyCard
                disclaimerCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("دليل الحياة الفطرية")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("تم") { dismiss() }
            }
        }
    }

    private var heroCard: some View {
        guideCard(title: "الطبيعة والسلامة البرية", icon: "leaf.circle.fill", color: .oasisTeal) {
            Text("قسم شامل يساعد المستخدم على التعرف على الكائنات البرية والنباتات والمحميات والمخاطر الميدانية قبل وأثناء الرحلة.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    miniMetric("كائنات", "\(WildlifeSpeciesProfile.samples.count)", "pawprint")
                    miniMetric("نباتات", "\(WildPlantProfile.samples.count)", "camera.macro")
                }
                GridRow {
                    miniMetric("مناطق", "\(WildlifeRangeZone.samples.count)", "map")
                    miniMetric("سلامة", "\(FieldSafetyTopic.samples.count)", "cross.case")
                }
            }
        }
    }

    private var recognitionCard: some View {
        guideCard(title: "التعرف بالذكاء الاصطناعي", icon: "camera.viewfinder", color: .indigo) {
            Text("يلتقط المستخدم صورة لحيوان أو أثر أو نبات، ثم يعرض التطبيق محاولة التعرف، مستوى الخطورة، وطريقة التعامل. الواجهة جاهزة للربط بنموذج رؤية حاسوبية عند تفعيل الخدمة.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: "camera")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.indigo, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text("نتيجة تجريبية")
                        .font(.headline)
                    Text("عقرب صحراوي محتمل - الخطورة مرتفعة - افحص مكان الجلوس ولا تلمسه.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private var speciesDatabaseCard: some View {
        guideCard(title: "دليل الحيوانات والزواحف", icon: "pawprint.fill", color: .desertCopper) {
            TextField("ابحث بالاسم أو البيئة أو الاسم العلمي", text: $searchText)
                .textFieldStyle(.roundedBorder)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    dangerFilterButton(title: "الكل", level: nil)
                    ForEach(WildlifeDangerLevel.allCases) { level in
                        dangerFilterButton(title: level.rawValue, level: level)
                    }
                }
            }

            ForEach(filteredSpecies) { item in
                speciesCard(item)
            }
        }
    }

    private var rangeMapCard: some View {
        guideCard(title: "خريطة انتشار تقريبية", icon: "map.fill", color: .blue) {
            Text("البيانات تقريبية وللتوعية فقط، ولا تستخدم لتحديد مواقع دقيقة للكائنات الحساسة أو الاقتراب منها.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(WildlifeRangeZone.samples) { zone in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: zone.icon)
                            .foregroundStyle(.blue)
                        Text(zone.title)
                            .font(.headline)
                        Spacer()
                        Text("\(Int(zone.radiusKilometers)) كم")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                    }
                    Text(zone.species)
                        .font(.subheadline.weight(.semibold))
                    Text(zone.alertText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("مركز تقريبي: \(zone.coordinate.latitude.formatted(.number.precision(.fractionLength(2)))), \(zone.coordinate.longitude.formatted(.number.precision(.fractionLength(2))))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var locationAlertsCard: some View {
        guideCard(title: "تنبيهات حسب الموقع", icon: "bell.badge.fill", color: .orange) {
            alertExample("تنبيه ثعابين", "هذه المنطقة تشهد نشاطًا للثعابين خلال فصل الصيف، خاصة بعد غروب الشمس. ينصح بارتداء أحذية مناسبة واستخدام كشاف قبل المشي.", "exclamationmark.triangle")
            alertExample("تنبيه عقارب", "يزداد نشاط العقارب في هذه المنطقة ليلًا. تجنب رفع الصخور أو إدخال اليد في الشقوق دون فحص.", "moon.stars")
        }
    }

    private var plantsCard: some View {
        guideCard(title: "دليل النباتات البرية", icon: "camera.macro", color: .green) {
            ForEach(WildPlantProfile.samples) { plant in
                infoBlock(icon: plant.icon, title: plant.name, subtitle: plant.detail, detail: "الموسم: \(plant.season) - الرعي: \(plant.grazingUse)\nمحمي: \(plant.isProtected ? "نعم" : "لا") - سام: \(plant.isPoisonous ? "نعم" : "لا")\n\(plant.traditionalUse)")
            }
        }
    }

    private var reservesCard: some View {
        guideCard(title: "المحميات الطبيعية", icon: "shield.lefthalf.filled", color: .oasisTeal) {
            ForEach(ProtectedReserveInfo.samples) { reserve in
                infoBlock(icon: "leaf", title: reserve.name, subtitle: reserve.location, detail: "المساحة: \(reserve.area)\nالكائنات: \(reserve.wildlife)\nالمسموح: \(reserve.allowedActivities)\nالممنوع: \(reserve.bannedActivities)\nالرسوم والساعات: \(reserve.fees)، \(reserve.hours)\nالتواصل: \(reserve.officialContact)")
            }
        }
    }

    private var restrictedAreasCard: some View {
        guideCard(title: "المناطق الممنوعة والتصاريح", icon: "hand.raised.fill", color: .red) {
            ForEach(RestrictedAreaInfo.samples) { area in
                infoBlock(icon: "lock.shield", title: area.name, subtitle: area.reason, detail: "الجهة: \(area.authority)\nالتصريح: \(area.permitRequirement)\n\(area.warning)")
            }
        }
    }

    private var fieldSafetyCard: some View {
        guideCard(title: "دليل السلامة البرية", icon: "cross.case.fill", color: .red) {
            ForEach(FieldSafetyTopic.samples) { topic in
                VStack(alignment: .leading, spacing: 8) {
                    Label(topic.title, systemImage: topic.icon)
                        .font(.headline)
                    ForEach(topic.steps, id: \.self) { step in
                        Text("• \(step)")
                            .font(.footnote)
                    }
                    Text(topic.firstAid)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .padding()
                .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var tracksCard: some View {
        guideCard(title: "آثار الحيوانات", icon: "shoeprints.fill", color: .brown) {
            ForEach(WildlifeTrackGuide.samples) { track in
                infoBlock(icon: track.icon, title: track.title, subtitle: track.likelyAnimal, detail: track.clues)
            }
        }
    }

    private var seasonsCard: some View {
        guideCard(title: "مواسم النشاط", icon: "calendar", color: .orange) {
            ForEach(WildlifeSeasonActivity.samples) { season in
                infoBlock(icon: season.icon, title: season.title, subtitle: season.months, detail: "\(season.weatherTrigger)\n\(season.advice)")
            }
        }
    }

    private var sightingsCard: some View {
        guideCard(title: "الإبلاغ عن المشاهدات", icon: "mappin.and.ellipse", color: .purple) {
            Text("يمكن للمستخدمين الإبلاغ عن ثعبان، عقرب، حيوان بري، أو نبات نادر. بعد المراجعة يعرض التطبيق البلاغ بشكل عام دون كشف مواقع حساسة أو تعريض الكائنات للإزعاج.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Label("بانتظار المراجعة", systemImage: "clock")
                Spacer()
                Label("إخفاء الموقع الدقيق", systemImage: "eye.slash")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.purple)
        }
    }

    private var astronomyCard: some View {
        guideCard(title: "دليل النجوم والفلك", icon: "moon.stars.fill", color: .indigo) {
            infoBlock(icon: "sparkles", title: "الرصد الليلي", subtitle: "النجوم والكوكبات ومراحل القمر", detail: "يعرض اتجاه الشمال، مرحلة القمر، أفضل أوقات الرصد، وأسماء الكوكبات المناسبة للرحلات البرية والتصوير.")
            infoBlock(icon: "location.north", title: "اتجاه الشمال", subtitle: "مساعدة الملاحة الطبيعية", detail: "قسم توعوي يربط الفلك بالبوصلة ومعلومات السماء عند ضعف الاتصال.")
        }
    }

    private var geologyCard: some View {
        guideCard(title: "دليل الجيولوجيا", icon: "mountain.2.fill", color: .desertCopper) {
            ForEach(GeologyGuideProfile.samples) { item in
                infoBlock(icon: item.icon, title: item.title, subtitle: item.formation, detail: "أين تشاهدها: \(item.whereToSee)\nالسلامة: \(item.safetyNote)")
            }
        }
    }

    private var disclaimerCard: some View {
        guideCard(title: "ملاحظة مهمة", icon: "info.circle.fill", color: .gray) {
            Text("هذه البيانات تعليمية وإرشادية، ويجب ربط النسخة الإنتاجية بمصادر رسمية ومراجعة مختصين قبل الاعتماد عليها في الطوارئ أو المحميات أو الأنواع الحساسة.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func speciesCard(_ item: WildlifeSpeciesProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: item.imageName)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(item.dangerLevel.color, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.arabicName)
                        .font(.headline)
                    Text(item.scientificName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.dangerLevel.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.dangerLevel.color)
                    Text(item.isVenomous ? "سام" : "غير سام")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((item.isVenomous ? Color.red : Color.oasisTeal).opacity(0.12), in: Capsule())
                }
            }

            infoLine("التعرف", item.identification)
            infoLine("الانتشار", item.distribution)
            infoLine("البيئة", item.habitat)
            infoLine("النشاط", "\(item.activeSeason) - \(item.activityPeriod.rawValue)")
            infoLine("عند المشاهدة", item.viewingAdvice)

            VStack(alignment: .leading, spacing: 4) {
                Text("الإسعافات الأولية")
                    .font(.caption.weight(.bold))
                ForEach(item.firstAid, id: \.self) { step in
                    Text("• \(step)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(item.emergencyNumbers)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func guideCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content()
        }
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.16), lineWidth: 1)
        )
    }

    private func dangerFilterButton(title: String, level: WildlifeDangerLevel?) -> some View {
        Button {
            selectedDanger = level
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background((selectedDanger == level ? (level?.color ?? .desertCopper) : Color(.tertiarySystemFill)).opacity(selectedDanger == level ? 0.22 : 1), in: Capsule())
                .foregroundStyle(selectedDanger == level ? (level?.color ?? .desertCopper) : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func miniMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func infoBlock(icon: String, title: String, subtitle: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.desertCopper)
                .frame(width: 30, height: 30)
                .background(Color.desertSand.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func alertExample(_ title: String, _ detail: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
    }

    private func infoLine(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.bold))
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
