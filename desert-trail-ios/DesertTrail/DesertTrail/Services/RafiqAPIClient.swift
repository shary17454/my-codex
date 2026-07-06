import CoreLocation
import Foundation

struct RafiqAPIClient {
    enum APIError: Error {
        case invalidURL
        case invalidResponse
        case serverMessage(String)
    }

    static let shared = RafiqAPIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = RafiqAPIClient.defaultBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func health() async throws -> RafiqHealthResponse {
        try await request(path: "/health")
    }

    func fetchPlaces(region: String? = nil, terrain: String? = nil) async throws -> [RafiqPlace] {
        var query: [URLQueryItem] = []
        if let region, !region.isEmpty {
            query.append(URLQueryItem(name: "region", value: region))
        }
        if let terrain, !terrain.isEmpty {
            query.append(URLQueryItem(name: "terrain", value: terrain))
        }
        let response: RafiqPlacesResponse = try await request(path: "/v1/places", query: query)
        return response.places
    }

    func submitPlace(_ requestBody: RafiqPlaceSubmission) async throws -> RafiqPlace {
        let response: RafiqPlaceResponse = try await request(path: "/v1/places", method: "POST", body: requestBody)
        return response.place
    }

    func createTripPlan(_ requestBody: RafiqTripPlanRequest) async throws -> RafiqTripPlan {
        let response: RafiqTripPlanResponse = try await request(path: "/v1/trips/plans", method: "POST", body: requestBody)
        return response.plan
    }

    func safetyAlerts(_ requestBody: RafiqSafetyAlertQuery) async throws -> [RafiqSafetyAlert] {
        let query = [
            URLQueryItem(name: "temperature", value: String(requestBody.temperature)),
            URLQueryItem(name: "windSpeed", value: String(requestBody.windSpeed)),
            URLQueryItem(name: "airQualityIndex", value: String(requestBody.airQualityIndex)),
            URLQueryItem(name: "rainRisk", value: requestBody.rainRisk ? "true" : "false"),
            URLQueryItem(name: "networkGapKm", value: String(requestBody.networkGapKilometers))
        ]
        let response: RafiqSafetyAlertsResponse = try await request(path: "/v1/safety/alerts", query: query)
        return response.alerts
    }

    func queueSOS(_ requestBody: RafiqSOSRequest) async throws -> RafiqSOSRecord {
        let response: RafiqSOSResponse = try await request(path: "/v1/sos", method: "POST", body: requestBody)
        return response.sos
    }

    func fetchWildlifeGuide() async throws -> [RafiqWildlifeSpecies] {
        let response: RafiqWildlifeResponse = try await request(path: "/v1/nature/wildlife")
        return response.species
    }

    func fetchOfflineMapRegions() async throws -> [RafiqOfflineMapRegion] {
        let response: RafiqOfflineRegionsResponse = try await request(path: "/v1/offline-map-regions")
        return response.regions
    }

    private func request<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        method: String = "GET"
    ) async throws -> Response {
        try await request(path: path, query: query, method: method, bodyData: nil)
    }

    private func request<RequestBody: Encodable, Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        method: String,
        body: RequestBody
    ) async throws -> Response {
        let bodyData = try encoder.encode(body)
        return try await request(path: path, query: query, method: method, bodyData: bodyData)
    }

    private func request<Response: Decodable>(
        path: String,
        query: [URLQueryItem],
        method: String,
        bodyData: Data?
    ) async throws -> Response {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        components.path = baseURL.path + normalizedPath
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        if let bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            if let message = try? decoder.decode(RafiqErrorResponse.self, from: data).error {
                throw APIError.serverMessage(message)
            }
            throw APIError.invalidResponse
        }
        return try decoder.decode(Response.self, from: data)
    }

    private static var defaultBaseURL: URL {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "RafiqAPIBaseURL") as? String,
           let url = URL(string: configured),
           !configured.isEmpty {
            return url
        }
        return URL(string: "https://api.rafiqalkhala.example")!
    }
}

struct RafiqHealthResponse: Decodable {
    var ok: Bool
    var service: String
    var version: String
}

struct RafiqCoordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

struct RafiqPlace: Decodable, Identifiable, Hashable {
    var id: String
    var name: String
    var region: String
    var coordinate: RafiqCoordinate
    var difficulty: String
    var terrain: [String]
    var familyFriendly: Bool
    var requires4x4: Bool
    var rating: Double
    var tags: [String]
    var status: String
}

struct RafiqPlaceSubmission: Encodable {
    var name: String
    var region: String
    var coordinate: RafiqCoordinate
    var difficulty: String
    var terrain: [String]
    var familyFriendly: Bool
    var requires4x4: Bool
    var tags: [String]
    var notes: String
}

struct RafiqTripPlanRequest: Encodable {
    var peopleCount: Int
    var durationHours: Double
    var vehicleType: String
    var budgetSar: Double
    var preferences: [String: [String]]
    var temperature: Double
    var windSpeed: Double
    var airQualityIndex: Int
    var hasRainRisk: Bool
    var networkGapKm: Double
}

struct RafiqTripPlan: Decodable, Identifiable, Hashable {
    var id: String
    var title: String
    var target: RafiqPlace
    var summary: String
    var recommendedDeparture: String
    var route: RafiqRouteSummary
    var checklist: [String]
    var estimates: RafiqTripEstimates
    var warnings: [RafiqSafetyAlert]
}

struct RafiqRouteSummary: Decodable, Hashable {
    var distanceKm: Double
    var estimatedDurationMinutes: Double
    var stops: [RafiqRouteStop]
}

struct RafiqRouteStop: Decodable, Hashable {
    var type: String
    var name: String
}

struct RafiqTripEstimates: Decodable, Hashable {
    var waterLiters: Int
    var reserveWaterLiters: Int
    var estimatedFuelLiters: Int
    var budgetSar: Double
}

struct RafiqSafetyAlertQuery {
    var temperature: Double
    var windSpeed: Double
    var airQualityIndex: Int
    var rainRisk: Bool
    var networkGapKilometers: Double
}

struct RafiqSafetyAlert: Decodable, Identifiable, Hashable {
    var id: String { "\(type)-\(title)" }
    var level: String
    var type: String
    var title: String
    var message: String
}

struct RafiqSOSRequest: Encodable {
    var coordinate: RafiqCoordinate
    var batteryPercent: Double
    var heading: Double
    var message: String
    var contactIds: [String]
}

struct RafiqSOSRecord: Decodable, Identifiable, Hashable {
    var id: String
    var coordinate: RafiqCoordinate
    var batteryPercent: Double
    var heading: Double
    var message: String
    var contactIds: [String]
    var status: String
    var createdAt: String
}

struct RafiqWildlifeSpecies: Decodable, Identifiable, Hashable {
    var id: String
    var arabicName: String
    var scientificName: String
    var dangerLevel: String
    var venomous: Bool
    var habitat: String
    var activeSeason: String
    var activityTime: String
    var advice: String
    var firstAid: [String]
}

struct RafiqOfflineMapRegion: Decodable, Identifiable, Hashable {
    var id: String
    var name: String
    var sizeMb: Int
    var layers: [String]
}

private struct RafiqPlacesResponse: Decodable {
    var places: [RafiqPlace]
}

private struct RafiqPlaceResponse: Decodable {
    var place: RafiqPlace
}

private struct RafiqTripPlanResponse: Decodable {
    var plan: RafiqTripPlan
}

private struct RafiqSafetyAlertsResponse: Decodable {
    var alerts: [RafiqSafetyAlert]
}

private struct RafiqSOSResponse: Decodable {
    var sos: RafiqSOSRecord
}

private struct RafiqWildlifeResponse: Decodable {
    var species: [RafiqWildlifeSpecies]
}

private struct RafiqOfflineRegionsResponse: Decodable {
    var regions: [RafiqOfflineMapRegion]
}

private struct RafiqErrorResponse: Decodable {
    var error: String
}
