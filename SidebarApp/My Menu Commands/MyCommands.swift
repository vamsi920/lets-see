import SwiftUI

struct MyCommands: Commands {
    private let model = AssistantAppModel.shared

    var body: some Commands {
        CommandMenu("Assistant") {
            Button("Toggle Assistant") {
                model.togglePanel()
            }
            .keyboardShortcut(.space, modifiers: [.option, .command])

            Button("Show Permissions") {
                SettingsWindow.show()
            }
            .keyboardShortcut(",", modifiers: [.command, .shift])

            Divider()

            Button("Run Current Command") {
                model.showPanel()
                model.runCurrentCommand()
            }
            .keyboardShortcut(.return, modifiers: [.command])

            Button("Stop") {
                model.stopRun()
            }
            .keyboardShortcut(".", modifiers: [.command])
            .disabled(!model.isRunning && !model.isListening)
        }
    }
}
