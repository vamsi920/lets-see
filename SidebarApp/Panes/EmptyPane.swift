import SwiftUI

struct RunStateCard: View {
    let title: String
    let detail: String
    let isRunning: Bool
    let isListening: Bool
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))

                    if isRunning || isListening {
                        ProgressView()
                            .controlSize(.small)
                            .tint(accent)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(accent)
                    }
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(detail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text(statusLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(accent.opacity(0.12), in: Capsule())
            }

            ProgressView(value: max(progress, 0.02))
                .tint(accent)

            HStack(spacing: 8) {
                cardPill(text: "Overlay ready")
                cardPill(text: "Log streaming")
                cardPill(text: isListening ? "Mic preview" : "Typed command")
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var accent: Color {
        if isListening {
            return Color(red: 0.99, green: 0.75, blue: 0.42)
        }

        if isRunning {
            return Color(red: 0.56, green: 0.73, blue: 1.0)
        }

        return Color(red: 0.35, green: 0.82, blue: 0.64)
    }

    private var statusLabel: String {
        if isListening { return "Listening" }
        if isRunning { return "Running" }
        return "Ready"
    }

    private func cardPill(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.68))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.06), in: Capsule())
    }
}
