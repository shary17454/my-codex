import CloudKit
import CoreLocation
import Foundation

final class CloudKitStore {
    private lazy var database = CKContainer(identifier: "iCloud.com.codex.DesertTrail").privateCloudDatabase

    func saveHiddenPlaceForReview(_ place: HiddenPlace) async throws {
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
        let record = CKRecord(recordType: "TripShareConsent", recordID: CKRecord.ID(recordName: trip.id.uuidString))
        record["title"] = trip.title
        record["sharedAt"] = Date()
        record["meetingPoint"] = CLLocation(latitude: trip.meetingPoint.latitude, longitude: trip.meetingPoint.longitude)
        _ = try await database.save(record)
    }
}
