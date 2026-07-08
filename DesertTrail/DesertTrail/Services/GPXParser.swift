import CoreLocation
import Foundation

final class GPXParser: NSObject, XMLParserDelegate {
    private var coordinates: [CLLocationCoordinate2D] = []

    static func loadRoute(named resourceName: String) -> [CLLocationCoordinate2D] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "gpx"),
              let parser = XMLParser(contentsOf: url) else {
            return []
        }
        let delegate = GPXParser()
        parser.delegate = delegate
        parser.parse()
        return delegate.coordinates
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        guard elementName == "trkpt",
              let latText = attributeDict["lat"],
              let lonText = attributeDict["lon"],
              let latitude = Double(latText),
              let longitude = Double(lonText) else {
            return
        }
        coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
}
