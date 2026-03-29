import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = CursorController()
    private var hasOpenedSettingsOnLaunch = false
    private lazy var settingsWindowController = SettingsWindowController(controller: controller)

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
        NSApp.setActivationPolicy(.regular)
        // Defer activation until the app has fully finished launching so the
        // settings window reliably becomes key/frontmost in archived builds.
        DispatchQueue.main.async { [weak self] in
            self?.openSettingsIfNeeded()
        }
    }

    func openSettingsWindow() {
        settingsWindowController.showWindow(nil)
        settingsWindowController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openSettingsIfNeeded() {
        guard !hasOpenedSettingsOnLaunch else { return }
        hasOpenedSettingsOnLaunch = true
        openSettingsWindow()
    }
}

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    init(controller: CursorController) {
        let contentView = SettingsView(controller: controller)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Cape Forge"
        window.setContentSize(NSSize(width: 920, height: 680))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}
