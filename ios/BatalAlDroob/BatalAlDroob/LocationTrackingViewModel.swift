import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftUI

@MainActor
@Observable
final class LocationTrackingViewModel: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pendingStartLanguage: AppLanguage?
    private var currentLanguage: AppLanguage = .arabic

    var authorization: CLAuthorizationStatus = .notDetermined
    var coordinate: CLLocationCoordinate2D?
    var altitude: CLLocationDistance?
    var horizontalAccuracy: CLLocationAccuracy?
    var headingDegrees: CLLocationDirection?
    var isTracking = false
    var locationMessage = ""
    var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
    ))

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        manager.headingFilter = 3
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = true
        authorization = manager.authorizationStatus
    }

    func requestAndStart(language: AppLanguage) {
        currentLanguage = language
        authorization = manager.authorizationStatus
        if authorization == .notDetermined {
            pendingStartLanguage = language
            locationMessage = language == .arabic ? "بانتظار موافقة الموقع..." : "Waiting for location permission..."
            manager.requestWhenInUseAuthorization()
            return
        }
        start(language: language)
    }

    func start(language: AppLanguage) {
        currentLanguage = language
        authorization = manager.authorizationStatus
        guard authorization == .authorizedAlways || authorization == .authorizedWhenInUse else {
            locationMessage = language == .arabic
                ? "فعّل صلاحية الموقع لاستخدام التتبع والبوصلة."
                : "Enable location permission to use tracking and compass."
            return
        }
        isTracking = true
        locationMessage = language == .arabic ? "التتبع يعمل" : "Tracking active"
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        } else {
            headingDegrees = nil
            locationMessage = language == .arabic
                ? "التتبع يعمل. البوصلة غير متاحة على هذا الجهاز."
                : "Tracking active. Compass is not available on this device."
        }
    }

    func stop(language: AppLanguage) {
        pauseTracking()
        locationMessage = language == .arabic ? "تم إيقاف التتبع" : "Tracking stopped"
    }

    func pauseTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if let language = self.pendingStartLanguage {
                self.pendingStartLanguage = nil
                if status == .authorizedAlways || status == .authorizedWhenInUse {
                    self.start(language: language)
                } else {
                    self.locationMessage = language == .arabic
                        ? "لم يتم منح صلاحية الموقع."
                        : "Location permission was not granted."
                }
            }
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let altitude = location.altitude
        let horizontalAccuracy = location.horizontalAccuracy
        Task { @MainActor in
            guard self.isTracking else { return }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.coordinate = coordinate
            self.altitude = altitude
            self.horizontalAccuracy = horizontalAccuracy
            self.cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.headingDegrees = value
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        let errorDescription = String(describing: error)
        Task { @MainActor in
            BatalLog.location.error("Location request failed: \(errorDescription, privacy: .public)")
            self.pauseTracking()
            self.locationMessage = self.currentLanguage == .arabic
                ? "تعذر تحديث الموقع. تحقق من الصلاحية وحاول مرة أخرى."
                : "Location could not be updated. Check permission and try again."
        }
    }
}
