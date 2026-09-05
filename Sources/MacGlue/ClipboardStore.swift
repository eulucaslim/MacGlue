import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let limit: Int
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(limit: Int = 200, fileManager: FileManager = .default) {
        self.limit = limit
        let supportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("MacGlue", isDirectory: true)
        self.fileURL = supportDirectory.appendingPathComponent("clipboard-history.json")
        load(fileManager: fileManager)
    }

    func add(_ item: ClipboardItem) {
        guard !items.contains(where: { $0.kind == item.kind && $0.text == item.text && $0.imageData == item.imageData }) else {
            return
        }

        items.insert(item, at: 0)
        trim()
        save()
    }

    func remove(id: ClipboardItem.ID) {
        items.removeAll { $0.id == id }
        save()
    }

    func togglePinned(id: ClipboardItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }
        items[index].isPinned.toggle()
        save()
    }

    func removeAll() {
        items.removeAll { !$0.isPinned }
        save()
    }

    private func trim() {
        guard items.count > limit else {
            return
        }

        let pinned = items.filter(\.isPinned)
        let unpinned = items.filter { !$0.isPinned }.prefix(max(0, limit - pinned.count))
        items = pinned + unpinned
    }

    private func load(fileManager: FileManager) {
        guard let data = try? Data(contentsOf: fileURL),
              let savedItems = try? decoder.decode([ClipboardItem].self, from: data) else {
            return
        }
        items = savedItems
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try encoder.encode(items).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Unable to save clipboard history: \(error)")
        }
    }
}
