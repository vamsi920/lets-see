import AppKit
import Combine

@MainActor
final class MenuBarButton: NSObject {
    private let statusItem: NSStatusItem
    private let model = AssistantAppModel.shared
    private var cancellables = Set<AnyCancellable>()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        super.init()

        guard let button = statusItem.button else { return }

        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.target = self
        button.action = #selector(showMenu(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "LetsSee"

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceModeDidChange),
            name: .appAppearanceModeDidChange,
            object: nil
        )

        bindModel()
        updateAppearance()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func bindModel() {
        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateAppearance()
            }
            .store(in: &cancellables)
    }

    @objc
    private func handleAppearanceModeDidChange(_ notification: Notification) {
        updateAppearance()
    }

    private func updateAppearance() {
        guard let button = statusItem.button else { return }

        let appearanceMode = AppAppearanceMode.stored
        let labelColor = NSColor.white
        let accentColor = appearanceMode == .light
            ? NSColor(calibratedRed: 0.38, green: 0.53, blue: 0.82, alpha: 1)
            : NSColor(calibratedRed: 0.96, green: 0.66, blue: 0.38, alpha: 1)

        let symbolName: String
        let tintColor: NSColor
        let title: String

        if model.isRunning || model.isListening {
            symbolName = "bolt.circle.fill"
            tintColor = accentColor
            title = "Live"
        } else if model.mainWindowVisible || model.panelVisible {
            symbolName = "sparkles"
            tintColor = labelColor
            title = "LS"
        } else {
            symbolName = "sparkles"
            tintColor = accentColor
            title = "LS"
        }

        let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "LetsSee")?
            .withSymbolConfiguration(configuration)

        button.image = image
        button.contentTintColor = tintColor
        button.attributedTitle = NSAttributedString(
            string: " \(title)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
        )
    }

    @objc
    private func showMenu(_ sender: AnyObject?) {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let statusTitle = model.mainWindowVisible || model.panelVisible
            ? "LetsSee is open"
            : "LetsSee is running in the background"
        let stateItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(.separator())

        addItem("Open Full App", action: #selector(openFullApp), key: "", to: menu)
        addItem("Open Quick Launcher", action: #selector(openQuickLauncher), key: "", to: menu)

        if model.mainWindowVisible || model.panelVisible {
            addItem("Hide LetsSee", action: #selector(hideAllSurfaces), key: "", to: menu)
        }

        menu.addItem(.separator())
        addThemeItem(.light, title: "Use Light Theme", to: menu)
        addThemeItem(.dark, title: "Use Dark Theme", to: menu)
        menu.addItem(.separator())
        addItem("Permissions…", action: #selector(showPermissions), key: "", to: menu)
        menu.addItem(.separator())
        addItem("Quit LetsSee", action: #selector(quit), key: "q", to: menu)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func addItem(_ title: String, action: Selector?, key: String, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    private func addThemeItem(_ mode: AppAppearanceMode, title: String, to menu: NSMenu) {
        let action: Selector = mode == .light ? #selector(selectLightTheme) : #selector(selectDarkTheme)
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = AppAppearanceMode.stored == mode ? .on : .off
        menu.addItem(item)
    }

    @objc
    private func openFullApp() {
        model.showMainWindow()
    }

    @objc
    private func openQuickLauncher() {
        model.showQuickLauncher()
    }

    @objc
    private func hideAllSurfaces() {
        model.hideQuickLauncher()
        model.hideMainWindow()
    }

    @objc
    private func selectLightTheme() {
        AppAppearanceMode.store(.light)
        updateAppearance()
    }

    @objc
    private func selectDarkTheme() {
        AppAppearanceMode.store(.dark)
        updateAppearance()
    }

    @objc
    private func showPermissions() {
        SettingsWindow.show()
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }
}
