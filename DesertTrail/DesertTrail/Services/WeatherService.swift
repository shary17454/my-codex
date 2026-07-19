@preconcurrency import BackgroundTasks
import CoreLocation
import Foundation

actor WeatherService {
    static let backgroundTaskIdentifier = "com.codex.DesertTrail.environment.refresh"
    private let weatherEndpoint = "https://api.open-meteo.com/v1/forecast"
    private let airQualityEndpoint = "https://air-quality-api.open-meteo.com/v1/air-quality"
    private let session: URLSession
    private var cachedReports: [String: EnvironmentalReport] = [:]

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 12
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        self.session = URLSession(configuration: configuration)
    }

    func fetchReport(for coordinate: CLLocationCoordinate2D) async throws -> EnvironmentalReport {
        let cacheKey = cacheKey(for: coordinate)
        if let cached = cachedReports[cacheKey], Date().timeIntervalSince(cached.updatedAt) < 10 * 60 {
            return cached
        }

        let weatherResult = try await fetchWeather(for: coordinate)
        let fetchedAirQualityIndex = await fetchAirQuality(for: coordinate)
        let airQualityIndex = max(0, fetchedAirQualityIndex ?? 0)

        let report = EnvironmentalReport(
            temperatureCelsius: weatherResult.temperatureCelsius,
            airQualityIndex: airQualityIndex,
            weatherSummary: weatherResult.temperatureCelsius > 40 ? "حار وجاف" : "مستقر",
            windSpeedKPH: weatherResult.windSpeedKPH,
            windDirectionDegrees: weatherResult.windDirectionDegrees,
            updatedAt: .now,
            isLiveData: true,
            isAirQualityAvailable: fetchedAirQualityIndex != nil
        )
        cachedReports[cacheKey] = report
        return report
    }

    private func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherSnapshot {
        guard var components = URLComponents(string: weatherEndpoint) else {
            throw WeatherServiceError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,wind_speed_10m,wind_direction_10m")
        ]

        guard let url = components.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw WeatherServiceError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return WeatherSnapshot(
            temperatureCelsius: decoded.current.temperature2m,
            windSpeedKPH: decoded.current.windSpeed10m,
            windDirectionDegrees: decoded.current.windDirection10m
        )
    }

    private func fetchAirQuality(for coordinate: CLLocationCoordinate2D) async -> Int? {
        guard var components = URLComponents(string: airQualityEndpoint) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "us_aqi")
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
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
        Task { @MainActor in
            do {
                _ = try await WeatherService().fetchReport(for: CLLocationCoordinate2D(latitude: 24.6028, longitude: 46.5535))
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }

    private func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        "\(Int(coordinate.latitude * 100)):\(Int(coordinate.longitude * 100))"
    }
}

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "تعذر تكوين عنوان خدمة الطقس."
        case .invalidResponse:
            return "خدمة الطقس لم تُرجع استجابة صالحة."
        }
    }
}

private struct WeatherSnapshot: Sendable {
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
