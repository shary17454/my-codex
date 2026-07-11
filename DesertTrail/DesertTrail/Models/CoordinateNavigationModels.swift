import CoreLocation
import Foundation

struct SavedCoordinatePoint: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var note: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date

    init(id: UUID = UUID(), name: String, note: String = "", latitude: Double, longitude: Double, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var appleMapsURL: URL {
        URL(string: "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(encodedName)")!
    }

    var googleMapsURL: URL {
        URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)")!
    }

    var shareText: String {
        """
        \(name)
        \(latitude), \(longitude)
        \(note)
        Apple Maps: \(appleMapsURL.absoluteString)
        Google Maps: \(googleMapsURL.absoluteString)
        """
    }

    private var encodedName: String {
        name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Point"
    }
}

@MainActor
final class CoordinatePointStore: ObservableObject {
    @Published private(set) var points: [SavedCoordinatePoint] = []

    private let storageKey = "savedCoordinatePoints.v1"

    init() {
        load()
        if points.isEmpty {
            points = Self.seedPoints
            save()
        }
    }

    func addCurrentLocation(_ location: CLLocation?, fallback: CLLocationCoordinate2D, name: String, note: String) {
        let coordinate = location?.coordinate ?? fallback
        addPoint(name: name, note: note, coordinate: coordinate)
    }

    func addPoint(name: String, note: String, coordinate: CLLocationCoordinate2D) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let point = SavedCoordinatePoint(
            name: trimmedName.isEmpty ? "نقطة محفوظة" : trimmedName,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        points.insert(point, at: 0)
        save()
    }

    func delete(_ point: SavedCoordinatePoint) {
        points.removeAll { $0.id == point.id }
        save()
    }

    func importGPX(data: Data) -> Int {
        let imported = GPXWaypointImporter.importWaypoints(from: data)
        guard !imported.isEmpty else { return 0 }
        points.insert(contentsOf: imported, at: 0)
        save()
        return imported.count
    }

    func exportGPXURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("al-droob-saved-points-\(Int(Date().timeIntervalSince1970)).gpx")
        try gpxString().write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedCoordinatePoint].self, from: data) else {
            return
        }
        points = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(points) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func gpxString() -> String {
        let waypointXML = points.map { point in
            """
              <wpt lat="\(point.latitude)" lon="\(point.longitude)">
                <name>\(Self.xmlEscape(point.name))</name>
                <desc>\(Self.xmlEscape(point.note))</desc>
              </wpt>
            """
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="البيد" xmlns="http://www.topografix.com/GPX/1/1">
        \(waypointXML)
        </gpx>
        """
    }

    private static func xmlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static let seedPoints = [
        SavedCoordinatePoint(name: "موقع المخيم", note: "نقطة تدريبية قابلة للحذف", latitude: 24.6190, longitude: 46.5730),
        SavedCoordinatePoint(name: "نقطة العودة", note: "استخدمها لتجربة الرجوع دون إنترنت", latitude: 24.6105, longitude: 46.5860)
    ]
}

private final class GPXWaypointImporter: NSObject, XMLParserDelegate {
    private var imported: [SavedCoordinatePoint] = []
    private var currentCoordinate: CLLocationCoordinate2D?
    private var currentName = ""
    private var currentNote = ""
    private var currentElement = ""

    static func importWaypoints(from data: Data) -> [SavedCoordinatePoint] {
        let parser = XMLParser(data: data)
        let delegate = GPXWaypointImporter()
        parser.delegate = delegate
        parser.parse()
        return delegate.imported
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        guard ["wpt", "trkpt", "rtept"].contains(elementName),
              let latText = attributeDict["lat"],
              let lonText = attributeDict["lon"],
              let latitude = Double(latText),
              let longitude = Double(lonText) else {
            return
        }
        currentCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        currentName = ""
        currentNote = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentCoordinate != nil else { return }
        if currentElement == "name" {
            currentName += string
        } else if currentElement == "desc" || currentElement == "cmt" {
            currentNote += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard ["wpt", "trkpt", "rtept"].contains(elementName),
              let coordinate = currentCoordinate else {
            currentElement = ""
            return
        }
        imported.append(
            SavedCoordinatePoint(
                name: currentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "نقطة GPX" : currentName.trimmingCharacters(in: .whitespacesAndNewlines),
                note: currentNote.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
        currentCoordinate = nil
        currentElement = ""
    }
}
