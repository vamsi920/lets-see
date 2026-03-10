import SwiftUI

struct ActivityFeedView: View {
    let items: [ActivityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity Log")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .textCase(.uppercase)

                Spacer()

                Text("\(items.count) events")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items) { item in
                            ActivityRowView(item: item)
                                .id(item.id)
                        }
                    }
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: items.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastItem = items.last else { return }

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastItem.id, anchor: .bottom)
            }
        }
    }
}

struct WhatsUpPane: View {
    @ObservedObject private var model = AssistantAppModel.shared

    var body: some View {
        ActivityFeedView(items: model.activityItems)
            .padding()
            .background(Color.black.opacity(0.92))
    }
}
