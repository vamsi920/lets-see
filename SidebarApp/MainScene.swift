import SwiftUI

struct MainScene: Scene {
    var body: some Scene {
        Settings {
            SettingsWindow()
        }
        .commands {
            MyCommands()

            CommandGroup(replacing: .newItem) { }
        }
    }
}
