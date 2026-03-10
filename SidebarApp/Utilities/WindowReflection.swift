import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    private let model: AssistantAppModel

    init(model: AssistantAppModel) {
        self.model = model

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1420, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.center()
        window.minSize = NSSize(width: 1120, height: 760)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.toolbarStyle = .unifiedCompact
        window.collectionBehavior = [.fullScreenPrimary]
        window.contentViewController = NSHostingController(rootView: MainView())

        super.init(window: window)

        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(focusInput: Bool = true) {
        guard let window else { return }

        if focusInput {
            model.inputFocusTicket = UUID()
        }

        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        model.markMainWindowVisibility(true)
    }

    func hide() {
        guard let window else { return }
        window.orderOut(nil)
        model.markMainWindowVisibility(false)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        model.markMainWindowVisibility(true)
    }

    func windowWillClose(_ notification: Notification) {
        model.markMainWindowVisibility(false)
    }
}

@MainActor
final class QuickLauncherController: NSWindowController, NSWindowDelegate {
    private let model: AssistantAppModel
    private var localKeyMonitor: Any?

    init(model: AssistantAppModel) {
        self.model = model

        let panel = QuickLauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 250),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.fullScreenAuxiliary, .transient, .moveToActiveSpace]
        panel.animationBehavior = .utilityWindow
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.contentViewController = NSHostingController(rootView: QuickLauncherView())

        super.init(window: panel)

        panel.delegate = self

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window?.isVisible == true else { return event }

            if event.keyCode == 53 {
                self.hide()
                return nil
            }

            return event
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
    }

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show(focusInput: Bool = true) {
        guard let window else { return }

        positionPanel()
        model.markQuickLauncherVisibility(true)

        if focusInput {
            model.inputFocusTicket = UUID()
        }

        NSApp.activate(ignoringOtherApps: true)

        if !window.isVisible {
            window.alphaValue = 0
            showWindow(nil)
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                window.animator().alphaValue = 1
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hide() {
        guard let window else { return }
        window.orderOut(nil)
        model.markQuickLauncherVisibility(false)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        model.markQuickLauncherVisibility(true)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    func windowWillClose(_ notification: Notification) {
        model.markQuickLauncherVisibility(false)
    }

    private func positionPanel() {
        guard let window else { return }

        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        guard let screen = activeScreen else { return }

        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - (window.frame.width / 2),
            y: visibleFrame.minY + 58
        )

        window.setFrameOrigin(origin)
    }
}

private final class QuickLauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
