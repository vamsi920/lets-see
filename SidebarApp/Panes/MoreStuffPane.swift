import SwiftUI

struct RecentActivityCard: View {
    let items: [ActivityItem]
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    private var recentItems: [ActivityItem] {
        Array(items.suffix(3).reversed())
    }

    var body: some View {
        GlassPanel(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent activity")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    Text("\(items.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                        .monospacedDigit()
                }

                if recentItems.isEmpty {
                    Text("No activity yet.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.textTertiary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(recentItems) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(itemColor(for: item))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 5)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(theme.textPrimary)
                                        .lineLimit(1)

                                    Text(item.detail)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(theme.textTertiary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func itemColor(for item: ActivityItem) -> Color {
        if case .neutral = item.tone {
            return theme.textSecondary
        }

        return item.tone.tint
    }
}

struct MoreStuffPane: View {
    @ObservedObject private var model = AssistantAppModel.shared

    var body: some View {
        RecentActivityCard(items: model.activityItems)
            .padding()
            .background(Color.clear)
    }
}
