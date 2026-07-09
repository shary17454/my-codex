import BackgroundTasks
import CoreLocation
import Foundation

final class WeatherService {
    static let backgroundTaskIdentifier = "com.codex.DesertTrail.environment.refresh"
    private let weatherEndpoint = URL(string: "https://api.open-meteo.com/v1/forecast") ?? URL(fileURLWithPath: "/")
    private let airQualityEndpoint = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality") ?? URL(fileURLWithPath: "/")

    func fetchReport(for coordinate: CLLocationCoordinate2D) async -> EnvironmentalReport {
        async let weather = fetchWeather(for: coordinate)
        async let aqi = fetchAirQuality(for: coordinate)
        let weatherResult = await weather
        let airQualityIndex = await aqi ?? simulatedAQI(from: weatherResult.temperatureCelsius, wind: weatherResult.windSpeedKPH)

        return EnvironmentalReport(
            temperatureCelsius: weatherResult.temperatureCelsius,
            airQualityIndex: airQualityIndex,
            weatherSummary: weatherResult.temperatureCelsius > 40 ? "حار وجاف" : "مستقر",
            windSpeedKPH: weatherResult.windSpeedKPH,
            windDirectionDegrees: weatherResult.windDirectionDegrees,
            updatedAt: .now
        )
    }

    private func fetchWeather(for coordinate: CLLocationCoordinate2D) async -> WeatherSnapshot {
        var components = URLComponents(url: weatherEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,wind_speed_10m,wind_direction_10m")
        ]

        guard let url = components.url else {
            return WeatherSnapshot(temperatureCelsius: EnvironmentalReport.placeholder.temperatureCelsius, windSpeedKPH: EnvironmentalReport.placeholder.windSpeedKPH, windDirectionDegrees: EnvironmentalReport.placeholder.windDirectionDegrees)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return WeatherSnapshot(
                temperatureCelsius: decoded.current.temperature2m,
                windSpeedKPH: decoded.current.windSpeed10m,
                windDirectionDegrees: decoded.current.windDirection10m
            )
        } catch {
            return WeatherSnapshot(temperatureCelsius: EnvironmentalReport.placeholder.temperatureCelsius, windSpeedKPH: EnvironmentalReport.placeholder.windSpeedKPH, windDirectionDegrees: EnvironmentalReport.placeholder.windDirectionDegrees)
        }
    }

    private func fetchAirQuality(for coordinate: CLLocationCoordinate2D) async -> Int? {
        var components = URLComponents(url: airQualityEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "us_aqi")
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(OpenMeteoAirQualityResponse.self, from: data)
            return decoded.current.usAQI
        } catch {
            return nil
        }
    }

    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func handleBackgroundRefresh(task: BGTask) {
        scheduleBackgroundRefresh()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        Task {
            _ = await WeatherService().fetchReport(for: CLLocationCoordinate2D(latitude: 24.6028, longitude: 46.5535))
            task.setTaskCompleted(success: true)
        }
    }

    private func simulatedAQI(from temperature: Double, wind: Double) -> Int {
        min(180, max(35, Int(temperature * 1.8 - wind)))
    }
}

private struct WeatherSnapshot {
    let temperatureCelsius: Double
    let windSpeedKPH: Double
    let windDirectionDegrees: Double
}

private struct OpenMeteoResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let temperature2m: Double
        let windSpeed10m: Double
        let windDirection10m: Double

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
        }
    }
}

private struct OpenMeteoAirQualityResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let usAQI: Int

        enum CodingKeys: String, CodingKey {
            case usAQI = "us_aqi"
        }
    }
}
