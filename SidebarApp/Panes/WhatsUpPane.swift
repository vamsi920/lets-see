import SwiftUI

struct SpaceBackdropView: View {
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        theme.canvasTop,
                        theme.canvasMid,
                        theme.canvasBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ParticleFieldView(color: theme.starColor, count: theme.isLight ? 24 : 42)
                    .frame(width: width, height: height)

                Circle()
                    .fill(theme.warmGlow)
                    .frame(width: width * 0.42, height: width * 0.42)
                    .blur(radius: 100)
                    .offset(x: -width * 0.26, y: -height * 0.24)

                Circle()
                    .fill(theme.coolGlow)
                    .frame(width: width * 0.48, height: width * 0.48)
                    .blur(radius: 110)
                    .offset(x: width * 0.26, y: height * 0.26)

                Circle()
                    .trim(from: 0.58, to: 0.91)
                    .stroke(
                        theme.horizonEdge.opacity(theme.isLight ? 0.18 : 0.24),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: width * 0.98, height: width * 0.98)
                    .rotationEffect(.degrees(18))
                    .offset(x: -width * 0.36, y: height * 0.48)

                Circle()
                    .trim(from: 0.10, to: 0.36)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.horizonEdge.opacity(theme.isLight ? 0.34 : 0.42),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: width * 1.10, height: width * 1.10)
                    .rotationEffect(.degrees(-6))
                    .offset(x: width * 0.36, y: height * 0.40)
                    .blur(radius: 0.8)

                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.bottomFade.opacity(theme.isLight ? 0.55 : 0.70),
                        theme.bottomFade
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct FloatingAuraView: View {
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.warmGlow)
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: -150, y: 46)

            Circle()
                .fill(theme.coolGlow)
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 140, y: 72)

            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .strokeBorder(theme.surfaceStroke.opacity(theme.isLight ? 0.18 : 0.14), lineWidth: 1)
                .frame(width: 720, height: 154)
                .blur(radius: 12)
                .offset(y: 22)
        }
    }
}

struct GlassPanel<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    init(cornerRadius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        ZStack {
            VisualEffectView(
                material: theme.isLight ? .sidebar : .hudWindow,
                blendingMode: .withinWindow
            )

            LinearGradient(
                colors: [
                    theme.surfaceFill.opacity(theme.isLight ? 0.98 : 0.90),
                    theme.surfaceFill.opacity(theme.isLight ? 0.84 : 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(theme.surfaceStroke, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(theme.isLight ? 0.42 : 0.10),
                            Color.clear,
                            theme.surfaceStroke.opacity(theme.isLight ? 0.6 : 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: theme.panelShadow, radius: 34, x: 0, y: 24)
        .overlay(content)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct InsetPanel<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRawValue = AppAppearanceMode.stored.rawValue

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .light
    }

    private var theme: AppThemePalette {
        .make(appearanceMode)
    }

    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(theme.insetFill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(theme.insetStroke, lineWidth: 1)
            )
            .overlay(content)
    }
}

private struct ParticleFieldView: View {
    let color: Color
    let count: Int
    private var particles: [ParticleSpec] { (0..<count).map(ParticleSpec.init(index:)) }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for particle in particles {
                    let point = CGPoint(
                        x: particle.x * size.width,
                        y: particle.y * size.height
                    )
                    let rect = CGRect(x: point.x, y: point.y, width: particle.size, height: particle.size)
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(particle.opacity)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct ParticleSpec {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: CGFloat

    init(index: Int) {
        x = Self.noise(Double(index) * 0.91)
        y = Self.noise(Double(index) * 1.77)
        size = 1.2 + (Self.noise(Double(index) * 4.9) * 2.2)
        opacity = 0.10 + (Self.noise(Double(index) * 7.3) * 0.34)
    }

    private static func noise(_ seed: Double) -> CGFloat {
        let raw = sin(seed * 12.9898) * 43758.5453
        return CGFloat(raw - floor(raw))
    }
}

struct ActivityFeedView: View {
    let items: [ActivityItem]

    var body: some View {
        RecentActivityCard(items: items)
    }
}

struct WhatsUpPane: View {
    var body: some View {
        SpaceBackdropView()
    }
}
