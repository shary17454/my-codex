import MapKit
import PDFKit
import UIKit

/// الحدود الجغرافية لصورة خريطة ممسوحة (مثل خرائط العجاجي) حتى تُعرض
/// كطبقة فوق خريطة القمر الصناعي.
struct GeoImageBounds: Equatable {
    var north: Double
    var south: Double
    var east: Double
    var west: Double

    var isValid: Bool {
        north > south && east > west
            && (-85...85).contains(north) && (-85...85).contains(south)
            && (-180...180).contains(east) && (-180...180).contains(west)
    }

    /// حدود أولية تقريبية لخريطة المملكة الشاملة من العجاجي.
    /// ليست معايرة مساحية — تُضبط يدويًا من شاشة المعايرة حتى تنطبق المعالم.
    static let ajajiSaudiDefault = GeoImageBounds(north: 33.5, south: 12.5, east: 57.5, west: 33.0)

    /// تخزين المعايرة لكل مستند.
    static func stored(for document: PDFMapDocument) -> GeoImageBounds {
        let d = UserDefaults.standard
        let key = storageKey(for: document)
        guard let dict = d.dictionary(forKey: key) as? [String: Double],
              let n = dict["n"], let s = dict["s"], let e = dict["e"], let w = dict["w"] else {
            return .ajajiSaudiDefault
        }
        return GeoImageBounds(north: n, south: s, east: e, west: w)
    }

    func save(for document: PDFMapDocument) {
        UserDefaults.standard.set(["n": north, "s": south, "e": east, "w": west], forKey: Self.storageKey(for: document))
    }

    private static func storageKey(for document: PDFMapDocument) -> String {
        "kharayem.geoImageBounds.\(document.rawValue)"
    }
}

/// طبقة صورة جغرافية فوق MKMapView.
final class GeoImageOverlay: NSObject, MKOverlay {
    let image: UIImage
    let bounds: GeoImageBounds

    init(image: UIImage, bounds: GeoImageBounds) {
        self.image = image
        self.bounds = bounds
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (bounds.north + bounds.south) / 2,
            longitude: (bounds.east + bounds.west) / 2
        )
    }

    var boundingMapRect: MKMapRect {
        let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: bounds.north, longitude: bounds.west))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: bounds.south, longitude: bounds.east))
        return MKMapRect(
            x: topLeft.x,
            y: topLeft.y,
            width: bottomRight.x - topLeft.x,
            height: bottomRight.y - topLeft.y
        )
    }
}

/// راسم الطبقة: يقسم الصورة إلى شرائح أفقية ويرسم كل شريحة بين خطي العرض
/// المقابلين لها بعد تحويلهما إلى إسقاط ميركاتور — حتى لا تنحرف الخريطة
/// الممسوحة (المرسومة غالبًا بإسقاط متساوي المسافات) عن القمر الصناعي.
final class GeoImageOverlayRenderer: MKOverlayRenderer {
    private let bandCount = 96

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? GeoImageOverlay,
              let cgImage = overlay.image.cgImage else { return }

        let b = overlay.bounds
        let imageHeight = CGFloat(cgImage.height)
        let latSpan = b.north - b.south

        for band in 0..<bandCount {
            let topLat = b.north - latSpan * Double(band) / Double(bandCount)
            let bottomLat = b.north - latSpan * Double(band + 1) / Double(bandCount)

            let srcTop = imageHeight * CGFloat(band) / CGFloat(bandCount)
            let srcHeight = imageHeight / CGFloat(bandCount)
            guard let slice = cgImage.cropping(to: CGRect(x: 0, y: srcTop, width: CGFloat(cgImage.width), height: srcHeight)) else { continue }

            let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: topLat, longitude: b.west))
            let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: bottomLat, longitude: b.east))
            let bandMapRect = MKMapRect(
                x: topLeft.x,
                y: topLeft.y,
                width: bottomRight.x - topLeft.x,
                height: bottomRight.y - topLeft.y
            )
            guard bandMapRect.intersects(mapRect) else { continue }

            let drawRect = rect(for: bandMapRect)
            context.saveGState()
            // قلب المحور الرأسي لأن CoreGraphics يرسم من الأسفل
            context.translateBy(x: 0, y: drawRect.origin.y + drawRect.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(slice, in: CGRect(x: drawRect.origin.x, y: 0, width: drawRect.width, height: drawRect.height))
            context.restoreGState()
        }
    }
}

/// تحميل صورة الخريطة من ملف مستورد (PDF أو صورة) بدقة مناسبة للعرض.
enum GeoImageLoader {
    /// أقصى بُعد للصورة المحمّلة — يوازن بين الوضوح والذاكرة.
    private static let maxDimension: CGFloat = 4096

    static func loadImage(from url: URL) -> UIImage? {
        if url.pathExtension.lowercased() == "pdf" {
            guard let document = PDFDocument(url: url), let page = document.page(at: 0) else { return nil }
            let pageRect = page.bounds(for: .mediaBox)
            let scale = min(maxDimension / pageRect.width, maxDimension / pageRect.height)
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                ctx.cgContext.translateBy(x: 0, y: size.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
        }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}
