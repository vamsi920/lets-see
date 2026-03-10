import AppKit
import Combine

@MainActor
final class MenuBarButton: NSObject {
    private let statusItem: NSStatusItem
    private let model = AssistantAppModel.shared
    private var cancellables = Set<AnyCancellable>()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.squareLength))
        super.init()

        guard let button = statusItem.button else { return }

        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "LetsSee"

        bindModel()
        updateAppearance()
    }

    @objc
    private func handleClick(_ sender: AnyObject?) {
        switch NSApp.currentEvent?.type {
        case .leftMouseUp:
            model.togglePanel()
        case .rightMouseUp:
            showMenu()
        default:
            break
        }
    }

    private func bindModel() {
        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateAppearance()
            }
            .store(in: &cancellables)
    }

    private func updateAppearance() {
        guard let button = statusItem.button else { return }

        let symbolName: String
        let tintColor: NSColor

        if model.isRunning || model.isListening {
            symbolName = "bolt.circle.fill"
            tintColor = NSColor(calibratedRed: 0.99, green: 0.74, blue: 0.40, alpha: 1)
        } else if model.attentionNeededCount > 0 {
            symbolName = "exclamationmark.shield.fill"
            tintColor = NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.44, alpha: 1)
        } else {
            symbolName = "sparkles"
            tintColor = NSColor.white
        }

        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "LetsSee")
        button.contentTintColor = tintColor
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        addItem("Toggle Assistant", action: #selector(toggleAssistant), key: "", to: menu)
        addItem("Permissions…", action: #selector(showPermissions), key: ",", to: menu)
        let shouldStop = model.isRunning || model.isListening
        addItem(shouldStop ? "Stop Preview" : "Run Preview", action: shouldStop ? #selector(stopPreview) : #selector(runPreview), key: "", to: menu)
        menu.addItem(.separator())
        addItem("Quit", action: #selector(quit), key: "q", to: menu)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func addItem(_ title: String, action: Selector?, key: String, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    @objc
    private func toggleAssistant() {
        model.togglePanel()
    }

    @objc
    private func showPermissions() {
        SettingsWindow.show()
    }

    @objc
    private func runPreview() {
        model.showPanel()
        model.runCurrentCommand()
    }

    @objc
    private func stopPreview() {
        model.stopRun()
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }
}
