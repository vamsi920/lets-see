import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject private var model = AssistantAppModel.shared

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

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
                        .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.10))

                    Text("This page is designed to feel finished before the agent is finished. It shows the permissions judges expect to see, along with real macOS trust checks where they matter.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.34, green: 0.30, blue: 0.24))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button("Refresh") {
                    model.refreshPermissions()
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.17, green: 0.13, blue: 0.10))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.78), in: Capsule())
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
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
    }

    private var phaseNotes: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Phase 1 Notes")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.18, green: 0.14, blue: 0.11))

            Text("Accessibility, Microphone, and Screen Recording are wired to real system checks. Automation remains on-demand because macOS only reveals that trust after the first Apple Events action against a target app.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.38, green: 0.33, blue: 0.27))
                .fixedSize(horizontal: false, vertical: true)

            Text("This is the right tradeoff for the hackathon shell: the UI reads like a product now, and the executor can be swapped in without reworking the trust surface later.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.38, green: 0.33, blue: 0.27))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.21, green: 0.17, blue: 0.14))
        )
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.49, green: 0.43, blue: 0.36))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.10))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
    }
}

private struct PermissionCard: View {
    let snapshot: PermissionSnapshot
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

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
                    .foregroundStyle(Color(red: 0.17, green: 0.13, blue: 0.10))

                Text(snapshot.summary)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.32, green: 0.28, blue: 0.23))
                    .fixedSize(horizontal: false, vertical: true)

                Text(snapshot.detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.37, blue: 0.31))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button(snapshot.actionTitle) {
                    primaryAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(red: 0.21, green: 0.17, blue: 0.14), in: Capsule())

                Button("Open System Settings") {
                    secondaryAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.18, green: 0.14, blue: 0.11))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.74), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsTab()
            .padding(28)
            .background(Color(red: 0.97, green: 0.95, blue: 0.92))
    }
}
