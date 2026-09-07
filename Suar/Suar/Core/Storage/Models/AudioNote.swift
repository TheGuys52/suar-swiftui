import Foundation
import SwiftData

@Model
public final class AudioNote {
    @Attribute(.unique) public var id: UUID
    public var number: Int
    public var createdAt: Date
    public var duration: TimeInterval
    public var fileName: String
    public var customTitle: String?
    public var page: ScriptPage?

    public var title: String { customTitle ?? "Catatan \(number)" }

    public init(
        id: UUID, number: Int, createdAt: Date, duration: TimeInterval,
        fileName: String, page: ScriptPage
    ) {
        self.id = id
        self.number = number
        self.createdAt = createdAt
        self.duration = duration
        self.fileName = fileName
        self.page = page
    }
}
