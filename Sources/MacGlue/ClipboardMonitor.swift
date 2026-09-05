import AppKit
import Foundation

@MainActor
final class ClipboardMonitor {
    private let pasteboard: NSPasteboard
    private let store: ClipboardStore
    private var timer: Timer?
    private var changeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        store: ClipboardStore
    ) {
        self.pasteboard = pasteboard
        self.store = store
        self.changeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard pasteboard.changeCount != changeCount else {
            return
        }
        changeCount = pasteboard.changeCount

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            store.add(.text(text))
        } else if let imageData = pasteboard.data(forType: .tiff) {
            store.add(.image(imageData))
        }
    }
}
