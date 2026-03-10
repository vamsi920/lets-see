import SwiftUI

struct MyCommands: Commands {
    private let model = AssistantAppModel.shared

    var body: some Commands {
        CommandMenu("LetsSee") {
            Button("Open Full App") {
                model.showMainWindow()
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Open Quick Launcher") {
                model.showQuickLauncher()
            }
            .keyboardShortcut(.space, modifiers: [.control, .option])

            Button("Run Current Prompt") {
                model.runCurrentCommand()
            }
            .keyboardShortcut(.return, modifiers: [.command])

            Button("Stop") {
                model.stopRun()
            }
            .keyboardShortcut(".", modifiers: [.command])
            .disabled(!model.isRunning && !model.isListening)

            Divider()

            Button("Permissions") {
                SettingsWindow.show()
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
    }
}
