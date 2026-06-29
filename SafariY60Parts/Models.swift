import Foundation

struct PartsSeed: Codable {
    let vehicle: VehicleProfile
    let systems: [PartSystem]
    let parts: [PartRecord]
}

struct VehicleProfile: Codable {
    let name: String
    let chassisNumber: String
    let modelCode: String
    let productionDate: String
    let registrationModel: String
    let engine: String
    let transmission: String
    let market: String
}

struct PartSystem: Codable, Identifiable, Hashable {
    var id: String { key }
    let key: String
    let nameAr: String
}

struct PartRecord: Codable, Identifiable, Hashable {
    let id: String
    let partNumber: String
    let name: String
    let nameAr: String
    let diagramCode: String
    let quantity: String
    let application: String
    let specification: String
    let dateRange: String
    let compatibleYears: [Int]
    let engineTags: [String]
    let condition: String
    let systemKey: String
    let systemNameAr: String
    let sourceCategory: String
    let unitTitle: String
    let unitInfo: String
    let unitIndex: Int?
    let unitId: String
    let unitUrl: String
    let diagramImageURL: String
}

struct PartNote: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

struct PartPhoto: Codable, Identifiable, Hashable {
    let id: UUID
    let filename: String
    let createdAt: Date

    init(id: UUID = UUID(), filename: String, createdAt: Date = .now) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
    }
}

struct PartUserContent: Codable, Hashable {
    var notes: [PartNote] = []
    var photos: [PartPhoto] = []
}
