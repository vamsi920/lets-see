import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject private var model = AssistantAppModel.shared
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(model.permissionSnapshots) { snapshot in
                        PermissionCard(snapshot: snapshot) {
                            model.handlePermissionAction(for: snapshot.kind)
                        } secondaryAction: {
                            model.openPrivacyPane(for: snapshot.kind)
                        }
                    }
                }

                phaseNotes
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Permissions & Trust")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)

                    Text("This page is designed to feel finished before the agent is finished. It shows the permissions judges expect to see, along with real macOS trust checks where they matter.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: 10) {
                    themeToggle

                    Button("Refresh") {
                        model.refreshPermissions()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.chipFill, in: Capsule())
                }
            }

            HStack(spacing: 12) {
                summaryPill(title: "Granted", value: "\(model.grantedPermissionCount)")
                summaryPill(title: "Needs Review", value: "\(model.attentionNeededCount)")
                summaryPill(title: "Hotkey", value: model.hotKeySymbols)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(theme.surfaceFill.opacity(theme.isLight ? 0.96 : 0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.surfaceStroke.opacity(theme.isLight ? 1 : 0.85), lineWidth: 1)
        )
    }

    private var phaseNotes: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Phase 1 Notes")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text("Accessibility, Microphone, and Screen Recording are wired to real system checks. Automation remains on-demand because macOS only reveals that trust after the first Apple Events action against a target app.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("This is the right tradeoff for the hackathon shell: the UI reads like a product now, and the executor can be swapped in without reworking the trust surface later.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surfaceFill.opacity(theme.isLight ? 0.84 : 0.72))
        )
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textTertiary)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.chipFill)
        )
    }

    private var themeToggle: some View {
        HStack(spacing: 4) {
            ForEach(AppAppearanceMode.allCases) { mode in
                Button {
                    setAppearance(mode)
                } label: {
                    Text(mode.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(mode == appearanceMode ? theme.accentText : theme.chipText)
                        .padding(.horizontal, 12)
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
        .background(theme.chipFill, in: Capsule())
        .overlay(
            Capsule()
                .stroke(theme.surfaceStroke.opacity(theme.isLight ? 0.9 : 0.7), lineWidth: 1)
        )
    }

    private func setAppearance(_ mode: AppAppearanceMode) {
        AppAppearanceMode.store(mode)
        appearanceModeRawValue = mode.rawValue
    }
}

private struct PermissionCard: View {
    let snapshot: PermissionSnapshot
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(snapshot.status.tint.opacity(0.18))

                    Image(systemName: snapshot.kind.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(snapshot.status.tint)
                }
                .frame(width: 48, height: 48)

                Spacer()

                Text(snapshot.status.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(snapshot.status.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(snapshot.status.tint.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.kind.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                Text(snapshot.summary)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(snapshot.detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button(snapshot.actionTitle) {
                    primaryAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accentText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.accent, in: Capsule())

                Button("Open System Settings") {
                    secondaryAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.chipFill, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.surfaceFill.opacity(theme.isLight ? 0.94 : 0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.surfaceStroke.opacity(theme.isLight ? 0.95 : 0.8), lineWidth: 1)
        )
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsTab()
            .padding(28)
            .background(Color.clear)
    }
}
