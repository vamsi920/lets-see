import AppKit
import SwiftUI

@MainActor
final class AssistantPanelController: NSWindowController, NSWindowDelegate {
    private let model: AssistantAppModel
    private var localKeyMonitor: Any?

    init(model: AssistantAppModel) {
        self.model = model

        let panel = AssistantPanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 660),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .moveToActiveSpace]
        panel.animationBehavior = .utilityWindow
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.delegate = nil
        panel.contentViewController = NSHostingController(rootView: MainView())

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
        model.markPanelVisibility(true)

        if focusInput {
            model.inputFocusTicket = UUID()
        }

        NSApp.activate(ignoringOtherApps: true)

        if !window.isVisible {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                window.animator().alphaValue = 1
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hide() {
        guard let window else { return }
        window.orderOut(nil)
        model.markPanelVisibility(false)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        model.markPanelVisibility(true)
    }

    func windowWillClose(_ notification: Notification) {
        model.markPanelVisibility(false)
    }

    private func positionPanel() {
        guard let window else { return }

        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        guard let screen = activeScreen else { return }

        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - (window.frame.width / 2),
            y: visibleFrame.maxY - window.frame.height - 56
        )

        window.setFrameOrigin(origin)
    }
}

private final class AssistantPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
