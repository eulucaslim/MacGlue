import AppKit
import ApplicationServices
import Carbon.HIToolbox
import SwiftUI

@MainActor
final class MacGlueAppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    private var monitor: ClipboardMonitor?
    private var hotKey: GlobalHotKey?
    private var window: NSWindow?
    private(set) var targetApplication: NSRunningApplication?
    private var lastExternalApplication: NSRunningApplication?
    private(set) var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = ClipboardMonitor(store: store)
        monitor?.start()
        requestAccessibilityPermission()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        let contentView = ClipboardHistoryView(
            store: store,
            onPaste: { [weak self] in
                self?.pasteIntoPreviousApplication()
            },
            onControlClick: { [weak self] in
                self?.toggleEnabled()
            },
            isEnabled: isEnabled
        )
            .frame(minWidth: 360, minHeight: 480)
        let hostingView = NSHostingView(rootView: contentView)
        let historyWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        historyWindow.title = "MacGlue"
        historyWindow.titleVisibility = .hidden
        historyWindow.titlebarAppearsTransparent = true
        historyWindow.contentView = hostingView
        historyWindow.center()
        historyWindow.isReleasedWhenClosed = false
        historyWindow.makeKeyAndOrderFront(nil)
        window = historyWindow

        hotKey = GlobalHotKey { [weak self] in
            self?.toggleHistoryWindow()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func toggleEnabled() {
        isEnabled.toggle()
        if isEnabled {
            monitor?.start()
            hotKey = GlobalHotKey { [weak self] in
                self?.toggleHistoryWindow()
            }
        } else {
            monitor?.stop()
            hotKey?.unregister()
            hotKey = nil
            window?.orderOut(nil)
        }
    }

    private func requestAccessibilityPermission() {
        guard !AXIsProcessTrusted() else {
            return
        }

        let options: CFDictionary = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication,
              application != NSRunningApplication.current else {
            return
        }
        lastExternalApplication = application
    }

    private func toggleHistoryWindow() {
        guard let window else {
            return
        }

        if window.isVisible, NSApp.isActive {
            window.orderOut(nil)
            return
        }

        targetApplication = lastExternalApplication
            ?? NSWorkspace.shared.frontmostApplication
        if targetApplication == NSRunningApplication.current {
            targetApplication = nil
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func pasteIntoPreviousApplication() {
        guard let targetApplication = targetApplication ?? lastExternalApplication,
              targetApplication != NSRunningApplication.current,
              targetApplication.processIdentifier != 0 else {
            return
        }

        guard AXIsProcessTrusted() else {
            let options: CFDictionary = [
                "AXTrustedCheckOptionPrompt": true
            ] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            return
        }

        window?.orderOut(nil)
        targetApplication.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: true
            )
            let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: false
            )
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.postToPid(targetApplication.processIdentifier)
            keyUp?.postToPid(targetApplication.processIdentifier)
        }
    }
}

@main
struct MacGlueApp: App {
    @NSApplicationDelegateAdaptor(MacGlueAppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("", systemImage: "doc.on.clipboard") {
            ClipboardHistoryView(
                store: appDelegate.store,
                onPaste: {
                    appDelegate.pasteIntoPreviousApplication()
                },
                onControlClick: {
                    appDelegate.toggleEnabled()
                },
                isEnabled: appDelegate.isEnabled
            )
                .frame(width: 360, height: 480)
        }
        .menuBarExtraStyle(.window)
    }
}

struct ClipboardHistoryView: View {
    @ObservedObject var store: ClipboardStore
    let onPaste: () -> Void
    let onControlClick: () -> Void
    let isEnabled: Bool
    @State private var searchText = ""
    @State private var isVisible = false

    private var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else {
            return store.items
        }
        return store.items.filter {
            $0.text?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.on.clipboard")
                Text("MacGlue")
                    .font(.headline)
                Spacer()
                Text("⌃-clique para \(isEnabled ? "desativar" : "ativar")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if NSEvent.modifierFlags.contains(.control) {
                    onControlClick()
                }
            }

            TextField("Buscar no histórico", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.largeTitle)
                    Text("Nenhuma cópia registrada")
                        .font(.headline)
                    Text("Copie um texto ou uma imagem para começar.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredItems) { item in
                    Button {
                        copyToPasteboard(item)
                        onPaste()
                    } label: {
                        HStack(spacing: 10) {
                            ClipboardItemPreview(item: item)
                            if item.kind == .text {
                                Text(item.text ?? "")
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Imagem")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if item.isPinned {
                                Image(systemName: "pin.fill")
                                    .foregroundStyle(.secondary)
                            }
                            Button(role: .destructive) {
                                store.remove(id: item.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .help("Excluir do histórico")
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(item.isPinned ? "Desafixar" : "Fixar") {
                            store.togglePinned(id: item.id)
                        }
                        Button("Excluir", role: .destructive) {
                            store.remove(id: item.id)
                        }
                    }
                }
            }
    }
    .padding()
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.94)
    .blur(radius: isVisible ? 0 : 4)
    .animation(.easeOut(duration: 0.22), value: isVisible)
    .onAppear {
        isVisible = true
    }
    .onDisappear {
        isVisible = false
    }
}

private func copyToPasteboard(_ item: ClipboardItem) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    switch item.kind {
    case .text:
        pasteboard.setString(item.text ?? "", forType: .string)
    case .image:
        if let imageData = item.imageData {
            pasteboard.setData(imageData, forType: .tiff)
        }
    }
}
}

struct ClipboardItemPreview: View {
let item: ClipboardItem

var body: some View {
    Group {
        if item.kind == .image, let imageData = item.imageData, let image = NSImage(data: imageData) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "text.alignleft")
                .foregroundStyle(.secondary)
        }
    }
    .frame(width: 48, height: 40)
    .background(.quaternary)
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .clipped()
}
}
