@preconcurrency import CoreLocation
import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
final class LocationManager: NSObject {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var heading: CompassHeading?
    var isTracking = false
    var proximityAlertsEnabled = false
    var locationErrorMessage: String?
    var headingErrorMessage: String?
    var inferredCourse: CLLocationDirection?
    var inferredSpeedMetersPerSecond: CLLocationSpeed?

    @ObservationIgnored
    private let manager = CLLocationManager()
    @ObservationIgnored
    private let notificationCenter = UNUserNotificationCenter.current()
    @ObservationIgnored
    private var previousLocation: CLLocation?
    private var shouldStartWhenAuthorized = false

    var supportsHeading: Bool {
        CLLocationManager.headingAvailable()
    }

    var resolvedHeadingDegrees: CLLocationDirection? {
        if let heading {
            let sensorHeading = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
            if sensorHeading >= 0, heading.headingAccuracy >= 0, heading.headingAccuracy <= 50 {
                return sensorHeading
            }
        }
        if let course = currentLocation?.course, course >= 0 {
            return course
        }
        return inferredCourse
    }

    var speedKPH: Double? {
        let speed = currentLocation?.speed ?? -1
        let resolvedSpeed: CLLocationSpeed?
        if speed >= 0 {
            resolvedSpeed = speed
        } else {
            resolvedSpeed = inferredSpeedMetersPerSecond
        }
        if resolvedSpeed == nil, isTracking, currentLocation != nil {
            // Core Location commonly reports an invalid speed while the device is
            // stationary. A valid position with no measured motion is represented
            // as zero instead of making the dashboard look disconnected.
            return 0
        }
        guard let resolvedSpeed, resolvedSpeed >= 0 else { return nil }
        return resolvedSpeed * 3.6
    }

    var altitudeMeters: CLLocationDistance? {
        guard let location = currentLocation,
              location.altitude.isFinite,
              location.verticalAccuracy >= 0 else { return nil }
        return location.altitude
    }

    var horizontalAccuracyMeters: CLLocationAccuracy? {
        guard let accuracy = currentLocation?.horizontalAccuracy, accuracy >= 0 else { return nil }
        return accuracy
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation else { return nil }
        return currentLocation.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    func bearing(to coordinate: CLLocationCoordinate2D) -> CLLocationDirection? {
        guard let start = currentLocation?.coordinate else { return nil }
        return Self.initialBearing(from: start, to: coordinate)
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10
        manager.headingFilter = 2
        manager.headingOrientation = .portrait
        manager.activityType = .otherNavigation
        authorizationStatus = manager.authorizationStatus

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        updateHeadingOrientation()
    }

    func requestWhenInUse() {
        authorizationStatus = manager.authorizationStatus
        manager.requestWhenInUseAuthorization()
    }

    func startNavigation() {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .notDetermined:
            shouldStartWhenAuthorized = false
            isTracking = false
            locationErrorMessage = "اضغط زر التشغيل للسماح بالموقع وبدء الملاحة."
            return
        case .denied, .restricted:
            shouldStartWhenAuthorized = false
            isTracking = false
            locationErrorMessage = "صلاحية الموقع غير مفعلة."
            return
        default:
            beginNavigationUpdates()
        }
    }

    func requestNavigationAccessAndStart(userInitiated: Bool = false) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .notDetermined:
            guard userInitiated else {
                shouldStartWhenAuthorized = false
                isTracking = false
                locationErrorMessage = "اضغط زر التشغيل للسماح بالموقع وبدء الملاحة."
                return
            }
            shouldStartWhenAuthorized = true
            locationErrorMessage = nil
            requestWhenInUse()
        default:
            startNavigation()
        }
    }

    private func beginNavigationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        shouldStartWhenAuthorized = false
        isTracking = true
        updateHeadingOrientation()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationErrorMessage = nil
        manager.startUpdatingLocation()
        manager.requestLocation()
        if CLLocationManager.headingAvailable() {
            headingErrorMessage = nil
            manager.startUpdatingHeading()
        } else {
            headingErrorMessage = "حساس البوصلة غير متاح. سيُستخدم اتجاه الحركة عند توفره."
        }
    }

    func stopNavigation() {
        shouldStartWhenAuthorized = false
        isTracking = false
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    @objc
    private func deviceOrientationDidChange() {
        updateHeadingOrientation()
    }

    private func updateHeadingOrientation() {
        switch UIDevice.current.orientation {
        case .portrait:
            manager.headingOrientation = .portrait
        case .portraitUpsideDown:
            manager.headingOrientation = .portraitUpsideDown
        case .landscapeLeft:
            manager.headingOrientation = .landscapeLeft
        case .landscapeRight:
            manager.headingOrientation = .landscapeRight
        default:
            break
        }
    }

    func requestBackgroundTripUpdates() {
        proximityAlertsEnabled = true
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .notDetermined {
            shouldStartWhenAuthorized = true
            manager.requestWhenInUseAuthorization()
            requestNotificationAccess()
            return
        } else if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
            authorizationStatus = manager.authorizationStatus
        }
        manager.allowsBackgroundLocationUpdates = authorizationStatus == .authorizedAlways
        manager.pausesLocationUpdatesAutomatically = true
        startNavigation()
        requestNotificationAccess()
        configureDefaultProximityAlerts()
    }

    func requestNotificationAccess() {
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
            if proximityAlertsEnabled, status == .authorizedWhenInUse {
                manager.requestAlwaysAuthorization()
            }
            manager.allowsBackgroundLocationUpdates = status == .authorizedAlways
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                locationErrorMessage = nil
                if shouldStartWhenAuthorized || isTracking {
                    beginNavigationUpdates()
                }
            case .denied, .restricted:
                shouldStartWhenAuthorized = false
                isTracking = false
                locationErrorMessage = "صلاحية الموقع غير مفعلة."
            default:
                break
            }
            if proximityAlertsEnabled, (status == .authorizedAlways || status == .authorizedWhenInUse) {
                configureDefaultProximityAlerts()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        let latitude = latest.coordinate.latitude
        let longitude = latest.coordinate.longitude
        let altitude = latest.altitude
        let horizontalAccuracy = latest.horizontalAccuracy
        let verticalAccuracy = latest.verticalAccuracy
        let course = latest.course
        let speed = latest.speed
        let timestamp = latest.timestamp
        Task { @MainActor in
            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                altitude: altitude,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                course: course,
                speed: speed,
                timestamp: timestamp
            )
            if let previousLocation, timestamp > previousLocation.timestamp {
                let elapsed = timestamp.timeIntervalSince(previousLocation.timestamp)
                let distance = location.distance(from: previousLocation)
                if speed < 0, elapsed > 0, elapsed <= 30 {
                    let calculatedSpeed = distance / elapsed
                    inferredSpeedMetersPerSecond = calculatedSpeed.isFinite ? max(0, calculatedSpeed) : nil
                }
                if course < 0, distance >= 3 {
                    inferredCourse = Self.initialBearing(
                        from: previousLocation.coordinate,
                        to: location.coordinate
                    )
                }
            }
            if speed >= 0 {
                inferredSpeedMetersPerSecond = speed
            }
            if course >= 0 {
                inferredCourse = course
            }
            previousLocation = location
            currentLocation = location
            locationErrorMessage = nil
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
            if headingReading.headingAccuracy < 0 {
                headingErrorMessage = "تعذر قراءة حساس البوصلة. حرّك الجهاز على شكل رقم 8 للمعايرة."
            } else if headingReading.headingAccuracy > 50 {
                headingErrorMessage = "دقة البوصلة منخفضة (±\(Int(headingReading.headingAccuracy))°). ابتعد عن المعادن وعاير الجهاز."
            } else {
                headingErrorMessage = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .locationUnknown {
            return
        }
        let message = error.localizedDescription
        Task { @MainActor in
            locationErrorMessage = message
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

    private static func initialBearing(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> CLLocationDirection {
        let startLatitude = start.latitude * .pi / 180
        let endLatitude = end.latitude * .pi / 180
        let longitudeDelta = (end.longitude - start.longitude) * .pi / 180
        let y = sin(longitudeDelta) * cos(endLatitude)
        let x = cos(startLatitude) * sin(endLatitude) - sin(startLatitude) * cos(endLatitude) * cos(longitudeDelta)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}
