import SwiftUI

struct MainView: View {
    @ObservedObject private var model = AssistantAppModel.shared
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            backgroundGlow

            VStack(alignment: .leading, spacing: 18) {
                header
                PermissionStripView(snapshots: model.permissionSnapshots)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Command")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)

                    composer
                }

                RunStateCard(
                    title: model.statusTitle,
                    detail: model.statusDetail,
                    isRunning: model.isRunning,
                    isListening: model.isListening,
                    progress: model.progressValue
                )

                ActivityFeedView(items: model.activityItems)
            }
            .padding(24)
        }
        .frame(width: 880, height: 640)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 30, y: 18)
        .padding(10)
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

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.99, green: 0.75, blue: 0.42),
                                    Color(red: 0.94, green: 0.46, blue: 0.34)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 0.17, green: 0.12, blue: 0.10))
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text("LetsSee")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Desktop assistant shell for the first 20 seconds. Hotkey, trust states, and a believable run loop are already in place.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                hotKeyBadge

                HStack(spacing: 8) {
                    metricPill(title: "Panel", value: model.panelVisible ? "Live" : "Hidden")
                    metricPill(title: "Trust", value: "\(model.grantedPermissionCount)/4")
                }

                Button {
                    model.hidePanel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.78))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    TextField("Ask the Mac to do something", text: $model.commandText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .focused($isComposerFocused)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .onSubmit {
                            model.runCurrentCommand()
                        }
                }
                .frame(height: 62)

                Button {
                    model.toggleMicrophone()
                } label: {
                    ZStack {
                        Circle()
                            .fill(model.isListening ? Color(red: 0.99, green: 0.75, blue: 0.42) : Color.white.opacity(0.09))

                        Circle()
                            .stroke(model.isListening ? Color.white.opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)

                        Image(systemName: model.isListening ? "waveform.circle.fill" : "mic.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(model.isListening ? Color(red: 0.15, green: 0.11, blue: 0.10) : .white.opacity(0.82))
                    }
                    .frame(width: 62, height: 62)
                    .scaleEffect(model.isListening ? 1.04 : 1)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: model.isListening)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                promptSuggestion("Open Notes")
                promptSuggestion("Search Downloads")
                promptSuggestion("Create reminder")

                Spacer()

                Button("Stop") {
                    model.stopRun()
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle((model.isRunning || model.isListening) ? .white : .white.opacity(0.35))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity((model.isRunning || model.isListening) ? 0.10 : 0.04), in: Capsule())
                .disabled(!model.isRunning && !model.isListening)

                Button {
                    model.runCurrentCommand()
                } label: {
                    Label(model.isRunning ? "Running" : "Run", systemImage: model.isRunning ? "bolt.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.16, green: 0.11, blue: 0.10))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.99, green: 0.75, blue: 0.42),
                                    Color(red: 0.98, green: 0.60, blue: 0.31)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .disabled(model.commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var hotKeyBadge: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("Global Hotkey")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
                .textCase(.uppercase)

            Text(model.hotKeySymbols)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
    }

    private var backgroundGlow: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.16),
                    Color(red: 0.06, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.94, green: 0.46, blue: 0.34).opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 30)
                .offset(x: -240, y: -190)

            Circle()
                .fill(Color(red: 0.36, green: 0.67, blue: 0.96).opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 26)
                .offset(x: 240, y: 170)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func promptSuggestion(_ text: String) -> some View {
        Button {
            model.commandText = text
            isComposerFocused = true
        } label: {
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
