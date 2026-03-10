import AppKit
import ApplicationServices
import AVFoundation
import Carbon.HIToolbox
import CoreGraphics
import SwiftUI

@main
struct LetsSeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MainScene()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AssistantAppModel.shared
    private var menuBarButton: MenuBarButton?
    private var mainWindowController: MainWindowController?
    private var quickLauncherController: QuickLauncherController?
    private var hotKeyMonitor: GlobalHotKeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        applyAppAppearance(AppAppearanceMode.stored)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceModeDidChange(_:)),
            name: .appAppearanceModeDidChange,
            object: nil
        )

        let mainController = MainWindowController(model: model)
        let quickController = QuickLauncherController(model: model)

        mainWindowController = mainController
        quickLauncherController = quickController
        model.connect(mainWindowController: mainController, quickLauncherController: quickController)

        menuBarButton = MenuBarButton()
        hotKeyMonitor = GlobalHotKeyMonitor(
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(controlKey) | UInt32(optionKey)
        ) {
            Task { @MainActor in
                AssistantAppModel.shared.toggleQuickLauncher()
            }
        }

        model.refreshPermissions()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.model.showMainWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            model.showMainWindow()
        }

        return true
    }

    @objc
    private func handleAppearanceModeDidChange(_ notification: Notification) {
        if let mode = notification.object as? AppAppearanceMode {
            applyAppAppearance(mode)
        } else {
            applyAppAppearance(AppAppearanceMode.stored)
        }
    }
}

enum PermissionKind: String, CaseIterable, Identifiable {
    case accessibility
    case microphone
    case automation
    case screenRecording

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .microphone:
            return "Microphone"
        case .automation:
            return "Automation"
        case .screenRecording:
            return "Screen Recording"
        }
    }

    var icon: String {
        switch self {
        case .accessibility:
            return "cursorarrow.click.2"
        case .microphone:
            return "mic.fill"
        case .automation:
            return "bolt.horizontal.circle.fill"
        case .screenRecording:
            return "display"
        }
    }

    var shortLabel: String {
        switch self {
        case .screenRecording:
            return "Screen"
        default:
            return title
        }
    }

    var settingsURL: URL? {
        let path: String

        switch self {
        case .accessibility:
            path = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case .microphone:
            path = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .automation:
            path = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        case .screenRecording:
            path = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        }

        return URL(string: path)
    }
}

enum PermissionStatus: Equatable {
    case granted
    case needsAttention
    case onDemand

    var title: String {
        switch self {
        case .granted:
            return "Granted"
        case .needsAttention:
            return "Needs Review"
        case .onDemand:
            return "On Demand"
        }
    }

    var tint: Color {
        switch self {
        case .granted:
            return Color(red: 0.35, green: 0.82, blue: 0.64)
        case .needsAttention:
            return Color(red: 1.0, green: 0.76, blue: 0.38)
        case .onDemand:
            return Color(red: 0.55, green: 0.73, blue: 1.0)
        }
    }

    var nsColor: NSColor {
        switch self {
        case .granted:
            return NSColor(calibratedRed: 0.35, green: 0.82, blue: 0.64, alpha: 1)
        case .needsAttention:
            return NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.38, alpha: 1)
        case .onDemand:
            return NSColor(calibratedRed: 0.55, green: 0.73, blue: 1.0, alpha: 1)
        }
    }
}

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case dark
    case light

    static let storageKey = "appearance.mode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        }
    }

    var nsAppearanceName: NSAppearance.Name {
        switch self {
        case .dark:
            return .darkAqua
        case .light:
            return .aqua
        }
    }

    static var stored: AppAppearanceMode {
        AppAppearanceMode(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .light
    }

    static func store(_ mode: AppAppearanceMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: storageKey)
        NotificationCenter.default.post(name: .appAppearanceModeDidChange, object: mode)
    }
}

extension Notification.Name {
    static let appAppearanceModeDidChange = Notification.Name("appAppearanceModeDidChange")
}

@MainActor
func applyAppAppearance(_ mode: AppAppearanceMode) {
    NSApp.appearance = NSAppearance(named: mode.nsAppearanceName)
}

struct AppThemePalette {
    let isLight: Bool
    let canvasTop: Color
    let canvasMid: Color
    let canvasBottom: Color
    let starColor: Color
    let horizonPrimary: Color
    let horizonSecondary: Color
    let horizonEdge: Color
    let warmGlow: Color
    let coolGlow: Color
    let bottomFade: Color
    let surfaceFill: Color
    let surfaceStroke: Color
    let chipFill: Color
    let chipText: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accent: Color
    let accentText: Color
    let panelShadow: Color
    let insetFill: Color
    let insetStroke: Color
    let railFill: Color
}

extension AppThemePalette {
    static func make(_ mode: AppAppearanceMode) -> AppThemePalette {
        switch mode {
        case .dark:
            return AppThemePalette(
                isLight: false,
                canvasTop: Color(red: 0.07, green: 0.09, blue: 0.13),
                canvasMid: Color(red: 0.05, green: 0.07, blue: 0.10),
                canvasBottom: Color(red: 0.08, green: 0.09, blue: 0.13),
                starColor: Color.white.opacity(0.60),
                horizonPrimary: Color(red: 0.20, green: 0.25, blue: 0.37),
                horizonSecondary: Color(red: 0.08, green: 0.11, blue: 0.17),
                horizonEdge: Color(red: 0.50, green: 0.67, blue: 0.98),
                warmGlow: Color(red: 0.74, green: 0.48, blue: 0.26).opacity(0.22),
                coolGlow: Color(red: 0.27, green: 0.42, blue: 0.82).opacity(0.20),
                bottomFade: Color.black.opacity(0.38),
                surfaceFill: Color(red: 0.07, green: 0.09, blue: 0.13).opacity(0.72),
                surfaceStroke: Color.white.opacity(0.08),
                chipFill: Color.white.opacity(0.05),
                chipText: Color.white.opacity(0.82),
                textPrimary: Color.white.opacity(0.94),
                textSecondary: Color.white.opacity(0.66),
                textTertiary: Color.white.opacity(0.42),
                accent: Color(red: 0.86, green: 0.66, blue: 0.43),
                accentText: Color(red: 0.12, green: 0.09, blue: 0.07),
                panelShadow: Color.black.opacity(0.44),
                insetFill: Color.white.opacity(0.035),
                insetStroke: Color.white.opacity(0.08),
                railFill: Color.white.opacity(0.025)
            )
        case .light:
            return AppThemePalette(
                isLight: true,
                canvasTop: Color(red: 0.95, green: 0.97, blue: 0.995),
                canvasMid: Color(red: 0.88, green: 0.92, blue: 0.97),
                canvasBottom: Color(red: 0.80, green: 0.86, blue: 0.95),
                starColor: Color.white.opacity(0.30),
                horizonPrimary: Color(red: 0.93, green: 0.96, blue: 1.0),
                horizonSecondary: Color(red: 0.74, green: 0.82, blue: 0.94),
                horizonEdge: Color(red: 0.47, green: 0.62, blue: 0.88),
                warmGlow: Color(red: 0.88, green: 0.74, blue: 0.61).opacity(0.24),
                coolGlow: Color(red: 0.52, green: 0.67, blue: 0.92).opacity(0.22),
                bottomFade: Color(red: 0.77, green: 0.84, blue: 0.94).opacity(0.36),
                surfaceFill: Color(red: 0.95, green: 0.97, blue: 0.995).opacity(0.82),
                surfaceStroke: Color(red: 0.21, green: 0.29, blue: 0.39).opacity(0.08),
                chipFill: Color(red: 0.83, green: 0.88, blue: 0.96).opacity(0.46),
                chipText: Color(red: 0.17, green: 0.22, blue: 0.30),
                textPrimary: Color(red: 0.12, green: 0.17, blue: 0.24),
                textSecondary: Color(red: 0.27, green: 0.33, blue: 0.43),
                textTertiary: Color(red: 0.42, green: 0.49, blue: 0.58),
                accent: Color(red: 0.35, green: 0.51, blue: 0.80),
                accentText: Color.white,
                panelShadow: Color(red: 0.41, green: 0.51, blue: 0.70).opacity(0.14),
                insetFill: Color(red: 0.89, green: 0.93, blue: 0.98).opacity(0.78),
                insetStroke: Color.white.opacity(0.48),
                railFill: Color(red: 0.83, green: 0.88, blue: 0.95).opacity(0.40)
            )
        }
    }
}

struct PermissionSnapshot: Identifiable {
    let kind: PermissionKind
    let status: PermissionStatus
    let summary: String
    let detail: String
    let actionTitle: String

    var id: PermissionKind { kind }
}

enum ActivityTone {
    case neutral
    case info
    case success
    case warning

    var tint: Color {
        switch self {
        case .neutral:
            return Color.white.opacity(0.85)
        case .info:
            return Color(red: 0.55, green: 0.73, blue: 1.0)
        case .success:
            return Color(red: 0.35, green: 0.82, blue: 0.64)
        case .warning:
            return Color(red: 1.0, green: 0.76, blue: 0.38)
        }
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let title: String
    let detail: String
    let symbol: String
    let tone: ActivityTone
}

private struct DemoStep {
    let title: String
    let detail: String
    let logTitle: String
    let logDetail: String
    let symbol: String
    let tone: ActivityTone
    let progress: Double
    let delayMilliseconds: Int
}

@MainActor
final class AssistantAppModel: ObservableObject {
    static let shared = AssistantAppModel()

    let hotKeyDisplay = "Control + Option + Space"
    let hotKeySymbols = "\u{2303}\u{2325}Space"

    @Published var commandText = ""
    @Published var statusTitle = "Ready for the first command"
    @Published var statusDetail = "Type “Open Notes” to preview a real-looking desktop run while the executor is still stubbed."
    @Published var progressValue = 0.0
    @Published var isRunning = false
    @Published var isListening = false
    @Published private(set) var panelVisible = false
    @Published private(set) var mainWindowVisible = false
    @Published private(set) var permissionSnapshots: [PermissionSnapshot] = []
    @Published private(set) var activityItems: [ActivityItem] = []
    @Published var inputFocusTicket = UUID()

    private weak var mainWindowController: MainWindowController?
    private weak var quickLauncherController: QuickLauncherController?
    private var runTask: Task<Void, Never>?
    private var listeningTask: Task<Void, Never>?

    private init() {
        refreshPermissions()
        seedActivity()
    }

    var grantedPermissionCount: Int {
        permissionSnapshots.filter { $0.status == .granted }.count
    }

    var attentionNeededCount: Int {
        permissionSnapshots.filter { $0.status == .needsAttention }.count
    }

    func connect(mainWindowController: MainWindowController, quickLauncherController: QuickLauncherController) {
        self.mainWindowController = mainWindowController
        self.quickLauncherController = quickLauncherController
    }

    func toggleQuickLauncher() {
        quickLauncherController?.toggle()
    }

    func showQuickLauncher(focusInput: Bool = true) {
        quickLauncherController?.show(focusInput: focusInput)
    }

    func hideQuickLauncher() {
        quickLauncherController?.hide()
    }

    func showMainWindow(focusInput: Bool = true) {
        quickLauncherController?.hide()
        mainWindowController?.show(focusInput: focusInput)
    }

    func hideMainWindow() {
        mainWindowController?.hide()
    }

    func markQuickLauncherVisibility(_ isVisible: Bool) {
        panelVisible = isVisible

        if isVisible {
            refreshPermissions()
            inputFocusTicket = UUID()
        }
    }

    func markMainWindowVisibility(_ isVisible: Bool) {
        mainWindowVisible = isVisible

        if isVisible {
            refreshPermissions()
            inputFocusTicket = UUID()
        }
    }

    func runCurrentCommand() {
        let trimmed = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusTitle = "Type a command to begin"
            statusDetail = "Try “Open Notes”, “Search Downloads”, or “Create a reminder”."
            inputFocusTicket = UUID()
            return
        }

        runTask?.cancel()
        listeningTask?.cancel()
        isListening = false
        isRunning = true
        progressValue = 0.08
        presentInteractionSurface(focusInput: false)

        appendActivity(
            title: "Command received",
            detail: trimmed,
            symbol: "text.cursor",
            tone: .neutral
        )

        let steps = buildPlan(for: trimmed)

        runTask = Task { @MainActor [weak self] in
            guard let self else { return }

            for step in steps {
                if Task.isCancelled { return }

                self.statusTitle = step.title
                self.statusDetail = step.detail
                self.progressValue = step.progress
                self.appendActivity(
                    title: step.logTitle,
                    detail: step.logDetail,
                    symbol: step.symbol,
                    tone: step.tone
                )

                do {
                    try await Task.sleep(for: .milliseconds(step.delayMilliseconds))
                } catch {
                    return
                }
            }

            if Task.isCancelled { return }

            let completion = self.completionMessage(for: trimmed)
            self.isRunning = false
            self.progressValue = 1
            self.statusTitle = completion.title
            self.statusDetail = completion.detail
            self.appendActivity(
                title: completion.logTitle,
                detail: completion.logDetail,
                symbol: "checkmark.circle.fill",
                tone: .success
            )
        }
    }

    func stopRun() {
        let wasRunning = isRunning
        let wasListening = isListening

        runTask?.cancel()
        listeningTask?.cancel()
        runTask = nil
        listeningTask = nil
        isRunning = false
        isListening = false
        progressValue = 0

        guard wasRunning || wasListening else { return }

        statusTitle = "Preview stopped"
        statusDetail = "The run loop is idle again and ready for the next command."
        appendActivity(
            title: "Execution interrupted",
            detail: "Run or voice preview stopped by the user.",
            symbol: "stop.fill",
            tone: .warning
        )
    }

    func toggleMicrophone() {
        if isListening {
            stopRun()
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            startMicrophonePreview()
        case .notDetermined:
            statusTitle = "Requesting microphone access"
            statusDetail = "macOS will ask once so the shell can be ready for real voice capture."
            appendActivity(
                title: "Microphone permission requested",
                detail: "Waiting for the system prompt to complete.",
                symbol: "mic.badge.plus",
                tone: .info
            )

            AVCaptureDevice.requestAccess(for: .audio) { granted in
                Task { @MainActor in
                    self.refreshPermissions()

                    if granted {
                        self.startMicrophonePreview()
                    } else {
                        self.statusTitle = "Microphone access denied"
                        self.statusDetail = "Typed commands still work, but voice stays disabled until permission is granted."
                        self.appendActivity(
                            title: "Microphone blocked",
                            detail: "Open the permissions window to enable voice input later.",
                            symbol: "mic.slash.fill",
                            tone: .warning
                        )
                    }
                }
            }
        case .denied, .restricted:
            statusTitle = "Microphone access needed"
            statusDetail = "Open the permissions window to enable voice input."
            appendActivity(
                title: "Microphone unavailable",
                detail: "Voice preview is waiting on system permission.",
                symbol: "mic.slash.fill",
                tone: .warning
            )
            SettingsWindow.show()
        @unknown default:
            statusTitle = "Microphone status unavailable"
            statusDetail = "The shell cannot confirm microphone access on this macOS version."
        }
    }

    func refreshPermissions() {
        let accessibilityGranted = AXIsProcessTrusted()
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        let screenRecordingGranted = CGPreflightScreenCaptureAccess()

        permissionSnapshots = [
            PermissionSnapshot(
                kind: .accessibility,
                status: accessibilityGranted ? .granted : .needsAttention,
                summary: accessibilityGranted ? "Desktop control is unlocked." : "Needed for app clicks, typing, and focus changes.",
                detail: accessibilityGranted ? "Accessibility already trusts the app, so real automation can be added without another blocker." : "macOS gates app control behind Accessibility. The shell can demo the run now and execute for real once this is granted.",
                actionTitle: accessibilityGranted ? "Open Privacy Pane" : "Request Access"
            ),
            PermissionSnapshot(
                kind: .microphone,
                status: microphoneStatus == .authorized ? .granted : .needsAttention,
                summary: microphoneStatus == .authorized ? "Voice input can be wired in immediately." : "Needed for the mic button and future transcription.",
                detail: microphoneStatus == .authorized ? "The microphone permission is already granted." : "Phase 1 uses a simulated listen state, but real voice capture still needs microphone permission.",
                actionTitle: microphoneStatus == .authorized ? "Open Privacy Pane" : "Request Access"
            ),
            PermissionSnapshot(
                kind: .automation,
                status: .onDemand,
                summary: "macOS asks the first time the assistant controls another app.",
                detail: "Automation permission is target-specific. The first Apple Events action will trigger the system prompt for Notes, Finder, or any other controlled app.",
                actionTitle: "Open Privacy Pane"
            ),
            PermissionSnapshot(
                kind: .screenRecording,
                status: screenRecordingGranted ? .granted : .needsAttention,
                summary: screenRecordingGranted ? "Ready for future visual context and OCR." : "Useful for future screen understanding and visual grounding.",
                detail: screenRecordingGranted ? "Screen capture access is already available." : "This shell does not depend on screen recording yet, but the permission surface is ready for the next phase.",
                actionTitle: screenRecordingGranted ? "Open Privacy Pane" : "Request Access"
            )
        ]
    }

    func handlePermissionAction(for kind: PermissionKind) {
        switch kind {
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            appendActivity(
                title: "Accessibility prompt opened",
                detail: "Review the system dialog, then return to the panel.",
                symbol: "lock.open.display",
                tone: .info
            )
            refreshPermissions()
        case .microphone:
            if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
                toggleMicrophone()
            } else {
                openPrivacyPane(for: kind)
            }
        case .automation:
            openPrivacyPane(for: kind)
            appendActivity(
                title: "Automation guidance opened",
                detail: "The system pane explains which apps already trust automation.",
                symbol: "bolt.horizontal.circle",
                tone: .info
            )
        case .screenRecording:
            _ = CGRequestScreenCaptureAccess()
            appendActivity(
                title: "Screen recording prompt opened",
                detail: "Grant access in System Settings if visual context is needed next.",
                symbol: "display.badge.plus",
                tone: .info
            )
            refreshPermissions()
        }
    }

    func openPrivacyPane(for kind: PermissionKind) {
        guard let url = kind.settingsURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func startMicrophonePreview() {
        runTask?.cancel()
        listeningTask?.cancel()

        isRunning = false
        isListening = true
        progressValue = 0.22
        statusTitle = "Listening for a voice prompt"
        statusDetail = "Phase 1 simulates capture so the shell feels alive before transcription is wired in."
        presentInteractionSurface(focusInput: false)

        appendActivity(
            title: "Voice preview started",
            detail: "Mic animation is live and waiting on a future transcription backend.",
            symbol: "waveform.and.mic",
            tone: .info
        )

        listeningTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .seconds(1.6))
            } catch {
                return
            }

            if Task.isCancelled { return }

            self.isListening = false
            self.progressValue = 0.45

            if self.commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.commandText = "Open Notes"
            }

            self.statusTitle = "Voice preview complete"
            self.statusDetail = "The mic flow is stubbed, so the panel primed a sample command instead of a real transcript."
            self.appendActivity(
                title: "Voice prompt staged",
                detail: "“Open Notes” is ready to run so the UI demo stays moving.",
                symbol: "waveform.circle.fill",
                tone: .neutral
            )
            self.inputFocusTicket = UUID()
        }
    }

    private func seedActivity() {
        appendActivity(
            title: "Assistant shell booted",
            detail: "Started from the open-source macOS SwiftUI template and reshaped into a resident Mac assistant.",
            symbol: "sparkles",
            tone: .info
        )
        appendActivity(
            title: "Hotkey armed",
            detail: "Press \(hotKeyDisplay) from anywhere to open the quick launcher.",
            symbol: "keyboard",
            tone: .neutral
        )
        appendActivity(
            title: "Permissions snapshot captured",
            detail: "Accessibility, microphone, automation, and screen capture states are ready for review.",
            symbol: "checklist",
            tone: .neutral
        )
    }

    private func buildPlan(for command: String) -> [DemoStep] {
        let accessibilityReady = permissionSnapshots.first(where: { $0.kind == .accessibility })?.status == .granted
        let trimmedTarget = targetApp(in: command)

        var steps = [
            DemoStep(
                title: "Understanding intent",
                detail: "Reading the request and classifying the next desktop action.",
                logTitle: "Intent parsed",
                logDetail: command,
                symbol: "brain",
                tone: .neutral,
                progress: 0.18,
                delayMilliseconds: 650
            ),
            DemoStep(
                title: "Checking trust boundary",
                detail: accessibilityReady ? "Accessibility is already available for future desktop control." : "Accessibility still needs approval before a real app action can fire.",
                logTitle: accessibilityReady ? "Accessibility ready" : "Accessibility still blocked",
                logDetail: accessibilityReady ? "The shell can move to a real automation bridge next." : "The panel keeps the illusion alive while the executor waits on system trust.",
                symbol: "lock.shield",
                tone: accessibilityReady ? .success : .warning,
                progress: 0.39,
                delayMilliseconds: 800
            )
        ]

        if let target = trimmedTarget, !target.isEmpty {
            steps.append(
                DemoStep(
                    title: "Preparing \(target)",
                    detail: "Resolving the app target and shaping a launch handoff.",
                    logTitle: "Target app resolved",
                    logDetail: "\(target) is queued as the execution destination.",
                    symbol: "app.badge.checkmark",
                    tone: .info,
                    progress: 0.67,
                    delayMilliseconds: 850
                )
            )
        } else {
            steps.append(
                DemoStep(
                    title: "Mapping the workflow",
                    detail: "Turning the request into a short execution plan for the desktop bridge.",
                    logTitle: "Workflow staged",
                    logDetail: "The shell has a coherent plan even before the backend is live.",
                    symbol: "list.bullet.rectangle.portrait",
                    tone: .info,
                    progress: 0.67,
                    delayMilliseconds: 850
                )
            )
        }

        steps.append(
            DemoStep(
                title: "Staging automation",
                detail: "Phase 1 stops at the final safe stub before a real system action.",
                logTitle: "Stub handoff ready",
                logDetail: "The experience now reads like a live assistant, even though execution is still mocked.",
                symbol: "bolt.horizontal.circle",
                tone: .success,
                progress: 0.92,
                delayMilliseconds: 900
            )
        )

        return steps
    }

    private func completionMessage(for command: String) -> (title: String, detail: String, logTitle: String, logDetail: String) {
        if let target = targetApp(in: command), !target.isEmpty {
            let needsAccessibility = permissionSnapshots.first(where: { $0.kind == .accessibility })?.status != .granted
            return (
                title: "Ready to open \(target) for real",
                detail: needsAccessibility ? "The UI, hotkey, and handoff states are in place. Grant Accessibility and wire the executor next." : "The UI shell is complete. The next step is replacing the stub with a real \(target) automation call.",
                logTitle: "Demo ready for \(target)",
                logDetail: "The run reached the backend stub without breaking the illusion."
            )
        }

        return (
            title: "Execution preview complete",
            detail: "The shell behaved like a real product end-to-end. Replace the stubbed handoff when the backend is ready.",
            logTitle: "Run preview complete",
            logDetail: "The floating shell, permissions strip, and log all advanced through a believable execution cycle."
        )
    }

    private func targetApp(in command: String) -> String? {
        let lowered = command.lowercased()
        guard lowered.hasPrefix("open ") else { return nil }

        let suffix = String(command.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
        return suffix.isEmpty ? nil : suffix
    }

    private func appendActivity(title: String, detail: String, symbol: String, tone: ActivityTone) {
        activityItems.append(
            ActivityItem(
                title: title,
                detail: detail,
                symbol: symbol,
                tone: tone
            )
        )
    }

    private func presentInteractionSurface(focusInput: Bool) {
        if mainWindowVisible {
            showMainWindow(focusInput: focusInput)
        } else {
            showQuickLauncher(focusInput: focusInput)
        }
    }
}
