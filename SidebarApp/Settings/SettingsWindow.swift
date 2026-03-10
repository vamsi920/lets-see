import SwiftUI

struct SettingsWindow: View {
    @ObservedObject private var model = AssistantAppModel.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.95, blue: 0.92),
                    Color(red: 0.92, green: 0.90, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeneralSettingsTab()
                .padding(28)
        }
        .frame(width: 820, height: 640)
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
