# LetsSee

Native macOS assistant shell for the first hackathon phase.

This project started from the open-source [`simonweniger/swift-macos-template`](https://github.com/simonweniger/swift-macos-template) starter and was reshaped into a floating assistant panel instead of a sidebar app.

## What works in Phase 1

- Global hotkey toggles a floating overlay panel: `Option + Command + Space`
- Claude-style prompt surface with text input, mic button, run, and stop controls
- Permission status strip inside the panel
- Polished permissions window with real checks for:
  - Accessibility
  - Microphone
  - Screen Recording
- Activity log that advances through a believable stubbed run loop
- Demo flow for commands like `Open Notes`

## Notes

- The backend executor is still stubbed on purpose.
- The shell is designed to look and feel like a real desktop assistant before real automation is wired in.
- The project expects to be opened in Xcode as [`SidebarApp.xcodeproj`](/Users/vamsi/Desktop/lets-see/SidebarApp.xcodeproj).

## Running

1. Open [`SidebarApp.xcodeproj`](/Users/vamsi/Desktop/lets-see/SidebarApp.xcodeproj) in Xcode.
2. Build and run the `SidebarApp` target. The app product name is `LetsSee`.
3. On first launch, review permissions from the built-in permissions window.
