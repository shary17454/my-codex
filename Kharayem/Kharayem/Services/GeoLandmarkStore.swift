import CoreLocation
import Foundation

/// معلم جغرافي من قاعدة GeoNames المدمجة.
struct GeoLandmark: Identifiable, Hashable {
    let id: Int
    /// الاسم — عربي إن توفر، وإلا بالحروف اللاتينية من المصدر.
    let name: String
    /// الاسم اللاتيني للبحث الثنائي.
    let asciiName: String
    let coordinate: CLLocationCoordinate2D
    /// رمز GeoNames للتضاريس (WAD, MT, DUNE…)
    let featureCode: String
    /// الارتفاع بالمتر من نموذج الارتفاعات الرقمي لدى GeoNames (قد يكون تقريبيًا).
    let elevationMeters: Int?

    static func == (lhs: GeoLandmark, rhs: GeoLandmark) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// تسمية عربية لنوع التضاريس.
    var typeName: String {
        Self.typeNames[featureCode] ?? "معلم"
    }

    private static let typeNames: [String: String] = [
        "WAD": "وادي", "WADJ": "ملتقى أودية", "WADB": "مجرى وادي", "WADM": "فم وادي", "WADS": "أودية",
        "MT": "جبل", "MTS": "جبال", "HLL": "تل", "HLLS": "تلال", "RDGE": "حافة جبلية",
        "DUNE": "كثبان رملية", "SAND": "منطقة رملية", "DSRT": "صحراء", "ERG": "عرق رملي",
        "SBKH": "سبخة", "DPR": "منخفض", "PLN": "سهل", "PLAT": "هضبة", "SCRP": "جرف",
        "WLL": "بئر", "WTRH": "مورد ماء", "SPNG": "عين ماء", "PNDI": "غدير موسمي",
        "LAVA": "حرة بركانية", "VLC": "بركان", "CLDA": "فوهة بركانية",
        "OAS": "واحة", "TRGD": "منطقة صخرية", "PROM": "رأس بارز", "PT": "نقطة",
        "ISL": "جزيرة", "RF": "شعاب", "CAPE": "رأس ساحلي", "PASS": "ممر جبلي",
        "GRGE": "مضيق", "CNYN": "أخدود", "CRTR": "فوهة", "PK": "قمة"
    ]
}

/// قاعدة المعالم السعودية المدمجة (GeoNames، رخصة CC-BY).
///
/// تُحمَّل من `landmarks_sa.json` عند أول استخدام (نحو 18.5 ألف معلم طبيعي:
/// أودية، جبال، تلال، كثبان، حرات، آبار، عيون…). البيانات من GeoNames.org
/// ويجب إبقاء الإسناد الظاهر في الواجهة عند عرض نتائجها.
final class GeoLandmarkStore: @unchecked Sendable {
    // Safe: all access to `landmarks`/`loaded` goes through `lock`.
    static let shared = GeoLandmarkStore()

    static let attribution = "بيانات المعالم: GeoNames.org (CC-BY)"

    private var landmarks: [GeoLandmark] = []
    private var loaded = false
    private let lock = NSLock()

    private init() {}

    /// عدد المعالم المتاحة (يحمّل القاعدة إذا لزم).
    var count: Int {
        ensureLoaded()
        return landmarks.count
    }

    /// بحث بالاسم (عربي أو لاتيني)، مرتب بطول الاسم فالأقصر أولاً
    /// حتى تتصدر المطابقات الأدق.
    func search(_ query: String, limit: Int = 30) -> [GeoLandmark] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return [] }
        ensureLoaded()
        let matches = landmarks.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.asciiName.localizedCaseInsensitiveContains(trimmed)
        }
        return Array(matches.sorted { $0.name.count < $1.name.count }.prefix(limit))
    }

    /// أقرب المعالم إلى إحداثية، ضمن نصف قطر بالكيلومتر.
    func nearest(to coordinate: CLLocationCoordinate2D, withinKm radius: Double = 30, limit: Int = 20) -> [GeoLandmark] {
        ensureLoaded()
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return landmarks
            .compactMap { landmark -> (GeoLandmark, CLLocationDistance)? in
                let d = origin.distance(from: CLLocation(latitude: landmark.coordinate.latitude, longitude: landmark.coordinate.longitude))
                return d <= radius * 1000 ? (landmark, d) : nil
            }
            .sorted { $0.1 < $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    private func ensureLoaded() {
        lock.lock()
        defer { lock.unlock() }
        guard !loaded else { return }
        loaded = true
        guard let url = Bundle.main.url(forResource: "landmarks_sa", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            return
        }
        landmarks = rows.enumerated().compactMap { index, row in
            guard row.count >= 6,
                  let name = row[0] as? String,
                  let ascii = row[1] as? String,
                  let lat = row[2] as? Double,
                  let lon = row[3] as? Double,
                  let code = row[4] as? String else { return nil }
            let elevation = row[5] as? Int
            return GeoLandmark(
                id: index,
                name: name,
                asciiName: ascii,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                featureCode: code,
                elevationMeters: elevation
            )
        }
    }
}
