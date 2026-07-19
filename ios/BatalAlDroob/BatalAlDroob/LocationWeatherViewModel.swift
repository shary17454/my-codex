import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftUI

@MainActor
@Observable
final class LocationWeatherViewModel: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pendingStartLanguage: AppLanguage?
    private var lastWeatherLocation: CLLocation?
    private var lastWeatherUpdate: Date?
    private var currentLanguage: AppLanguage = .arabic
    private var weatherTask: Task<Void, Never>?

    var authorization: CLAuthorizationStatus = .notDetermined
    var coordinate: CLLocationCoordinate2D?
    var altitude: CLLocationDistance?
    var horizontalAccuracy: CLLocationAccuracy?
    var headingDegrees: CLLocationDirection?
    var isTracking = false
    var locationMessage = ""
    var weatherSummary = ""
    var weatherError: String?
    var isLoadingWeather = false
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
        weatherTask?.cancel()
        weatherTask = nil
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        isLoadingWeather = false
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
            self.scheduleWeatherLoad(for: CLLocation(latitude: latitude, longitude: longitude))
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.headingDegrees = value
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        Task { @MainActor in
            self.pauseTracking()
            self.locationMessage = self.currentLanguage == .arabic
                ? "تعذر تحديث الموقع. تحقق من الصلاحية وحاول مرة أخرى."
                : "Location could not be updated. Check permission and try again."
        }
    }

    private func scheduleWeatherLoad(for location: CLLocation) {
        if let lastWeatherLocation, let lastWeatherUpdate {
            let recentlyUpdated = Date().timeIntervalSince(lastWeatherUpdate) < 600
            let nearby = location.distance(from: lastWeatherLocation) < 1000
            if recentlyUpdated, nearby { return }
        }
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled else { return }
            await self?.loadWeather(for: location)
        }
    }

    func loadWeather(for location: CLLocation) async {
        if let lastWeatherLocation, let lastWeatherUpdate {
            let recentlyUpdated = Date().timeIntervalSince(lastWeatherUpdate) < 600
            let nearby = location.distance(from: lastWeatherLocation) < 1000
            if recentlyUpdated, nearby { return }
        }
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        do {
            let weather = try await OpenMeteoWeatherService.fetch(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            let temp = Measurement(value: weather.current.temperature2m, unit: UnitTemperature.celsius)
                .formatted(.measurement(width: .abbreviated, usage: .weather))
            weatherSummary = "\(temp) · \(weather.current.condition(language: currentLanguage))"
            weatherError = nil
            lastWeatherLocation = location
            lastWeatherUpdate = Date()
        } catch is CancellationError {
            return
        } catch {
            let errorDescription = String(describing: error)
            BatalLog.location.error("Weather request failed: \(errorDescription, privacy: .public)")
            weatherError = currentLanguage == .arabic
                ? "تعذر تحديث الطقس. تحقق من الاتصال ثم حاول مرة أخرى."
                : "Weather could not be updated. Check your connection and try again."
        }
    }
}

enum WeatherServiceError: Error {
    case invalidCoordinates
    case httpStatus(Int)
}

enum OpenMeteoWeatherService {
    static func fetch(latitude: Double, longitude: Double) async throws -> OpenMeteoWeather {
        guard (-90 ... 90).contains(latitude), (-180 ... 180).contains(longitude) else {
            throw WeatherServiceError.invalidCoordinates
        }
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code")
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)

        for attempt in 0 ..< 2 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard (200 ..< 300).contains(http.statusCode)
                else { throw WeatherServiceError.httpStatus(http.statusCode) }
                return try JSONDecoder().decode(OpenMeteoWeather.self, from: data)
            } catch {
                guard attempt == 0, shouldRetryWeatherRequest(after: error) else { throw error }
                try await Task.sleep(for: .milliseconds(400))
            }
        }
        throw URLError(.unknown)
    }
}

struct OpenMeteoWeather: Decodable {
    let current: OpenMeteoWeatherCurrent
}

struct OpenMeteoWeatherCurrent: Decodable {
    let temperature2m: Double
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
    }

    func condition(language: AppLanguage) -> String {
        switch weatherCode {
        case 0: language == .arabic ? "صحو" : "Clear"
        case 1, 2: language == .arabic ? "غائم جزئياً" : "Partly cloudy"
        case 3: language == .arabic ? "غائم" : "Cloudy"
        case 45, 48: language == .arabic ? "ضباب" : "Fog"
        case 51, 53, 55, 61, 63, 65, 80, 81, 82: language == .arabic ? "أمطار" : "Rain"
        case 95, 96, 99: language == .arabic ? "عواصف" : "Thunderstorm"
        default: language == .arabic ? "طقس محلي" : "Local weather"
        }
    }
}
