import SwiftUI

struct QuickLauncherView: View {
    @ObservedObject private var model = AssistantAppModel.shared
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue
    @FocusState private var isInputFocused: Bool

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        ZStack {
            FloatingAuraView()

            GlassPanel(cornerRadius: 30) {
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 10) {
                            BrandMark(size: 24)

                            Text("Quick Launcher")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                        }

                        Spacer()

                        Text(model.hotKeySymbols)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                    Divider()
                        .overlay(theme.surfaceStroke.opacity(theme.isLight ? 0.8 : 1))

                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Ask the Mac to do something", text: $model.commandText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 24, weight: .regular, design: .rounded))
                                .foregroundStyle(theme.textPrimary)
                                .focused($isInputFocused)
                                .onSubmit {
                                    model.runCurrentCommand()
                                }

                            Text(model.statusDetail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)

                        Button {
                            model.toggleMicrophone()
                        } label: {
                            Image(systemName: model.isListening ? "waveform.circle.fill" : "mic")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(model.isListening ? theme.accent : theme.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(theme.chipFill, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 18)

                    Divider()
                        .overlay(theme.surfaceStroke.opacity(theme.isLight ? 0.8 : 1))

                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)

                            Text(statusLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                        }

                        Spacer()

                        if model.isRunning || model.isListening {
                            Button("Stop") {
                                model.stopRun()
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(theme.chipFill, in: Capsule())
                        }

                        Button {
                            model.runCurrentCommand()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: model.isRunning ? "bolt.fill" : "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))

                                Text(model.isRunning ? "Running" : "Run")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(theme.accentText)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(theme.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(model.commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }
            .frame(width: 760, height: 210)
        }
        .frame(width: 860, height: 260)
        .preferredColorScheme(theme.isLight ? .light : .dark)
        .onAppear {
            DispatchQueue.main.async {
                isInputFocused = true
            }
        }
        .onChange(of: model.inputFocusTicket) { _ in
            DispatchQueue.main.async {
                isInputFocused = true
            }
        }
    }

    private var statusLabel: String {
        if model.isListening {
            return "Listening"
        }

        if model.isRunning {
            return "Running"
        }

        return "Ready"
    }

    private var statusColor: Color {
        if model.isListening {
            return theme.accent
        }

        if model.isRunning {
            return Color(red: 0.43, green: 0.67, blue: 0.95)
        }

        return Color(red: 0.38, green: 0.77, blue: 0.61)
    }
}

struct EmptyPane: View {
    var body: some View {
        QuickLauncherView()
            .background(Color.clear)
    }
}
