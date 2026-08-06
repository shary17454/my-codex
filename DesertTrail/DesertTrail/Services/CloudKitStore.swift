import CloudKit
import CoreLocation
import Foundation

@MainActor
final class CloudKitStore {
    private let containerIdentifier = "iCloud.com.codex.DesertTrail"

    // The container is created lazily instead of in `init`. Building `CKContainer`
    // eagerly at launch means any iCloud misconfiguration (missing entitlement,
    // container not provisioned) crashes the whole app before the UI appears.
    // Deferring creation lets the app launch and all offline features keep working;
    // CloudKit sync simply degrades gracefully when it is unavailable.
    private lazy var database: CKDatabase? = {
        guard FileManager.default.ubiquityIdentityToken != nil else { return nil }
        return CKContainer(identifier: containerIdentifier).privateCloudDatabase
    }()

    /// `true` only when the user is signed into iCloud on this device.
    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func saveHiddenPlaceForReview(_ place: HiddenPlace) async throws {
        guard let database else { return }
        let record = CKRecord(recordType: "HiddenPlace")
        record["name"] = place.name
        record["rating"] = place.rating
        record["notes"] = place.notes
        record["status"] = place.status.rawValue
        record["contributor"] = place.contributor
        record["location"] = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        _ = try await database.save(record)
    }

    func saveTripConsent(_ trip: TripPlan) async throws {
        guard let database else { return }
        let record = CKRecord(recordType: "TripShareConsent", recordID: CKRecord.ID(recordName: trip.id.uuidString))
        record["title"] = trip.title
        record["sharedAt"] = Date()
        record["meetingPoint"] = CLLocation(latitude: trip.meetingPoint.latitude, longitude: trip.meetingPoint.longitude)
        _ = try await database.save(record)
    }
}
