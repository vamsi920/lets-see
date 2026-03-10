import SwiftUI

struct ActivityRowView: View {
    let item: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(item.tone.tint.opacity(0.16))

                Image(systemName: item.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(item.tone.tint)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                }

                Text(item.detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct MoreStuffPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LetsSee Shell")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("The template sidebar remains in the project as spare scaffolding, but the real product experience now lives in the floating panel.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.92))
    }
}
