import SwiftUI

struct PermissionStripView: View {
    let snapshots: [PermissionSnapshot]
    var compact: Bool = false
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        GlassPanel(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Permissions")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    Button("Review") {
                        SettingsWindow.show()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(snapshots) { snapshot in
                        Button {
                            SettingsWindow.show()
                        } label: {
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(snapshot.status.tint)
                                    .frame(width: 7, height: 7)

                                Image(systemName: snapshot.kind.icon)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(theme.textSecondary)

                                Text(snapshot.kind.shortLabel)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(theme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(theme.chipFill, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
        }
    }
}

struct HelloWorldPane: View {
    @ObservedObject private var model = AssistantAppModel.shared

    var body: some View {
        PermissionStripView(snapshots: model.permissionSnapshots)
            .padding()
            .background(Color.clear)
    }
}
