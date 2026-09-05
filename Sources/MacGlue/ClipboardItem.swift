import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case text
        case image
    }

    let id: UUID
    let kind: Kind
    let createdAt: Date
    let text: String?
    let imageData: Data?
    var isPinned: Bool

    static func text(_ value: String) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            kind: .text,
            createdAt: Date(),
            text: value,
            imageData: nil,
            isPinned: false
        )
    }

    static func image(_ data: Data) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            kind: .image,
            createdAt: Date(),
            text: nil,
            imageData: data,
            isPinned: false
        )
    }
}
