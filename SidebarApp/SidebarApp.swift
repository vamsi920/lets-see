import AppKit
import ApplicationServices
import AVFoundation
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
    private var panelController: AssistantPanelController?
    private var hotKeyMonitor: GlobalHotKeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = AssistantPanelController(model: model)
        panelController = controller
        model.connect(panelController: controller)

        menuBarButton = MenuBarButton()
        hotKeyMonitor = GlobalHotKeyMonitor {
            Task { @MainActor in
                AssistantAppModel.shared.togglePanel()
            }
        }

        model.refreshPermissions()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.model.showPanel()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
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

    let hotKeyDisplay = "Option + Command + Space"
    let hotKeySymbols = "\u{2325}\u{2318}Space"

    @Published var commandText = ""
    @Published var statusTitle = "Ready for the first command"
    @Published var statusDetail = "Type “Open Notes” to preview a real-looking desktop run, even while the executor is still stubbed."
    @Published var progressValue = 0.0
    @Published var isRunning = false
    @Published var isListening = false
    @Published private(set) var panelVisible = false
    @Published private(set) var permissionSnapshots: [PermissionSnapshot] = []
    @Published private(set) var activityItems: [ActivityItem] = []
    @Published var inputFocusTicket = UUID()

    private weak var panelController: AssistantPanelController?
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

    func connect(panelController: AssistantPanelController) {
        self.panelController = panelController
    }

    func togglePanel() {
        panelController?.toggle()
    }

    func showPanel(focusInput: Bool = true) {
        panelController?.show(focusInput: focusInput)
    }

    func hidePanel() {
        panelController?.hide()
    }

    func markPanelVisibility(_ isVisible: Bool) {
        panelVisible = isVisible

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
        showPanel(focusInput: false)

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
        showPanel(focusInput: false)

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
            detail: "Started from the open-source macOS SwiftUI template and reshaped into a floating desktop assistant.",
            symbol: "sparkles",
            tone: .info
        )
        appendActivity(
            title: "Hotkey armed",
            detail: "Press \(hotKeyDisplay) from anywhere to toggle the panel.",
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
}
