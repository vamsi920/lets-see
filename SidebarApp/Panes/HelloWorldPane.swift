import SwiftUI

struct PermissionStripView: View {
    let snapshots: [PermissionSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Permission Status")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .textCase(.uppercase)

                Spacer()

                Button("Review") {
                    SettingsWindow.show()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(snapshots) { snapshot in
                        Button {
                            SettingsWindow.show()
                        } label: {
                            PermissionChipView(snapshot: snapshot)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct HelloWorldPane: View {
    @ObservedObject private var model = AssistantAppModel.shared

    var body: some View {
        PermissionStripView(snapshots: model.permissionSnapshots)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.black.opacity(0.92))
    }
}

private struct PermissionChipView: View {
    let snapshot: PermissionSnapshot

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: snapshot.kind.icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(snapshot.status.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.kind.shortLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(snapshot.status.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(snapshot.status.tint)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06), in: Capsule())
    }
}
