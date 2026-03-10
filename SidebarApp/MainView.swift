import SwiftUI

struct MainView: View {
    @ObservedObject private var model = AssistantAppModel.shared
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue
    @FocusState private var isComposerFocused: Bool

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        ZStack {
            SpaceBackdropView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 34)
                    .padding(.top, 24)

                Spacer()

                VStack(spacing: 18) {
                    composerCard
                        .frame(maxWidth: 860)

                    suggestionRow

                    bottomRow
                        .frame(maxWidth: 920)
                }

                Spacer()
            }
            .padding(.bottom, 34)
        }
        .preferredColorScheme(theme.isLight ? .light : .dark)
        .onAppear {
            DispatchQueue.main.async {
                isComposerFocused = true
            }
        }
        .onChange(of: model.inputFocusTicket) { _ in
            DispatchQueue.main.async {
                isComposerFocused = true
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            HStack(spacing: 12) {
                BrandMark(size: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text("LetsSee")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)

                    Text("Resident Mac assistant")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                themeToggle
                topChip(icon: "keyboard", value: model.hotKeySymbols)

                Button {
                    SettingsWindow.show()
                } label: {
                    topChip(icon: "lock.shield", value: "\(model.grantedPermissionCount)/4")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var composerCard: some View {
        GlassPanel(cornerRadius: 34) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How can LetsSee help today?")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(theme.textTertiary)

                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            TextField("Ask the Mac to do something", text: $model.commandText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 34, weight: .regular, design: .rounded))
                                .foregroundStyle(theme.textPrimary)
                                .focused($isComposerFocused)
                                .onSubmit {
                                    model.runCurrentCommand()
                                }

                            Text(model.statusDetail)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(theme.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)

                        Button {
                            model.toggleMicrophone()
                        } label: {
                            Image(systemName: model.isListening ? "waveform.circle.fill" : "mic")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(model.isListening ? theme.accent : theme.textSecondary)
                                .frame(width: 48, height: 48)
                                .background(theme.chipFill, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 24)

                Divider()
                    .overlay(theme.surfaceStroke.opacity(theme.isLight ? 0.9 : 1))

                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)

                        Text(statusLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)

                        Text(model.statusTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                            .lineLimit(1)
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
                        .padding(.vertical, 10)
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
                        .padding(.vertical, 10)
                        .background(theme.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(model.commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
            }
        }
    }

    private var suggestionRow: some View {
        HStack(spacing: 10) {
            suggestionChip("Open Notes")
            suggestionChip("Search Downloads")
            suggestionChip("Create Reminder")
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .top, spacing: 14) {
            PermissionStripView(snapshots: model.permissionSnapshots, compact: true)
                .frame(maxWidth: .infinity)

            RecentActivityCard(items: model.activityItems)
                .frame(width: 280)
        }
    }

    private var themeToggle: some View {
        HStack(spacing: 4) {
            ForEach(AppAppearanceMode.allCases) { mode in
                Button {
                    setAppearance(mode)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .light ? "sun.min.fill" : "moon.fill")
                            .font(.system(size: 10, weight: .medium))

                        Text(mode.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(mode == appearanceMode ? theme.accentText : theme.chipText)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(mode == appearanceMode ? theme.accent : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(theme.chipFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(theme.surfaceStroke.opacity(theme.isLight ? 0.8 : 0.6), lineWidth: 1)
        )
    }

    private func topChip(icon: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.textSecondary)

            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(theme.chipFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(theme.surfaceStroke.opacity(theme.isLight ? 0.8 : 0.6), lineWidth: 1)
        )
    }

    private func suggestionChip(_ prompt: String) -> some View {
        Button {
            model.commandText = prompt
            isComposerFocused = true
        } label: {
            Text(prompt)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(theme.chipFill, in: Capsule())
        }
        .buttonStyle(.plain)
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

    private func setAppearance(_ mode: AppAppearanceMode) {
        AppAppearanceMode.store(mode)
        appearanceModeRawValue = mode.rawValue
    }
}

struct BrandMark: View {
    let size: CGFloat
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                .stroke(theme.textPrimary.opacity(theme.isLight ? 0.22 : 0.28), lineWidth: 1.2)
                .frame(width: size, height: size)

            RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                .stroke(theme.textPrimary.opacity(0.84), lineWidth: 1.8)
                .padding(size * 0.17)

            Circle()
                .fill(theme.accent)
                .frame(width: size * 0.20, height: size * 0.20)
                .offset(x: size * 0.08, y: -size * 0.08)
        }
        .frame(width: size, height: size)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .frame(width: 1420, height: 900)
    }
}
