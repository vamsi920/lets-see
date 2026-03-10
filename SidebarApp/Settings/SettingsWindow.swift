import SwiftUI

struct SettingsWindow: View {
    @ObservedObject private var model = AssistantAppModel.shared
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        ZStack {
            SpaceBackdropView()

            GeneralSettingsTab()
                .padding(28)
        }
        .frame(width: 820, height: 640)
        .preferredColorScheme(theme.isLight ? .light : .dark)
        .onAppear {
            model.refreshPermissions()
        }
    }

    static func show() {
        NSApp.activate(ignoringOtherApps: true)

        let selectors = [
            Selector(("showSettingsWindow:")),
            Selector(("showPreferencesWindow:"))
        ]

        for selector in selectors where NSApp.sendAction(selector, to: nil, from: nil) {
            return
        }
    }
}

struct SettingsWindow_Previews: PreviewProvider {
    static var previews: some View {
        SettingsWindow()
    }
}
