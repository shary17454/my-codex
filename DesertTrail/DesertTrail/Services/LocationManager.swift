@preconcurrency import CoreLocation
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class LocationManager: NSObject {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var heading: CompassHeading?
    var isTracking = false
    var proximityAlertsEnabled = false

    @ObservationIgnored
    private let manager = CLLocationManager()
    @ObservationIgnored
    private let notificationCenter = UNUserNotificationCenter.current()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func startNavigation() {
        if authorizationStatus == .notDetermined {
            requestWhenInUse()
        }
        guard authorizationStatus != .denied, authorizationStatus != .restricted else {
            isTracking = false
            return
        }
        isTracking = true
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stopNavigation() {
        isTracking = false
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func requestBackgroundTripUpdates() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
        manager.allowsBackgroundLocationUpdates = authorizationStatus == .authorizedAlways
        manager.pausesLocationUpdatesAutomatically = true
        proximityAlertsEnabled = true
        startNavigation()
        requestNotificationAccess()
        configureDefaultProximityAlerts()
    }

    private func requestNotificationAccess() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func configureDefaultProximityAlerts() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }

        let regions = [
            ProximityRegion(
                identifier: "wadi-hidden",
                coordinate: CLLocationCoordinate2D(latitude: 24.64, longitude: 46.52),
                radius: 1200,
                title: "تنبيه قرب واد",
                body: "اقتربت من وادي مخفي. تحقق من الطقس ولا تخيم في بطن الوادي."
            ),
            ProximityRegion(
                identifier: "soft-sand-zone",
                coordinate: CLLocationCoordinate2D(latitude: 24.87, longitude: 46.38),
                radius: 1400,
                title: "تنبيه رمال ناعمة",
                body: "أمامك منطقة رمال ناعمة. خفف السرعة وجهز الدفع الرباعي."
            ),
            ProximityRegion(
                identifier: "reptile-activity-zone",
                coordinate: CLLocationCoordinate2D(latitude: 25.08, longitude: 46.75),
                radius: 1000,
                title: "تنبيه حياة فطرية",
                body: "هذه المنطقة قد تشهد نشاط زواحف وعقارب ليلاً. استخدم كشافاً وافحص المكان."
            )
        ]

        for region in regions {
            let circularRegion = CLCircularRegion(
                center: region.coordinate,
                radius: region.radius,
                identifier: region.identifier
            )
            circularRegion.notifyOnEntry = true
            circularRegion.notifyOnExit = false
            manager.startMonitoring(for: circularRegion)
            proximityRegionMessages[region.identifier] = (region.title, region.body)
        }
    }

    private var proximityRegionMessages: [String: (title: String, body: String)] = [:]
}

private struct ProximityRegion {
    var identifier: String
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var title: String
    var body: String
}

struct CompassHeading: Sendable {
    let trueHeading: CLLocationDirection
    let magneticHeading: CLLocationDirection
    let headingAccuracy: CLLocationDirection
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            if isTracking {
                self.manager.startUpdatingLocation()
                if CLLocationManager.headingAvailable() {
                    self.manager.startUpdatingHeading()
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            currentLocation = latest
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let headingReading = CompassHeading(
            trueHeading: newHeading.trueHeading,
            magneticHeading: newHeading.magneticHeading,
            headingAccuracy: newHeading.headingAccuracy
        )
        Task { @MainActor in
            heading = headingReading
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let identifier = region.identifier
        Task { @MainActor in
            guard proximityAlertsEnabled else { return }
            let message = proximityRegionMessages[identifier]
            let content = UNMutableNotificationContent()
            content.title = message?.title ?? "تنبيه قرب"
            content.body = message?.body ?? "اقتربت من منطقة تحتاج انتباه أثناء الرحلة."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "proximity-\(identifier)-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            try? await notificationCenter.add(request)
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }
}
