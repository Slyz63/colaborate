import SwiftUI

struct DriftPromptCardView: View {
    var onResume: () -> Void
    var onSnooze: () -> Void
    var onLogLater: () -> Void

    private var containerShape: some Shape {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("少し脱線したかもしれません")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text("設定した集中タスクに戻りますか？")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(action: onResume) {
                    Label("タスクに戻る", systemImage: "arrow.uturn.left")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .tint(.accentColor)

                Spacer()

                Button(action: onSnooze) {
                    Label("15分後に再通知", systemImage: "timer")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("s", modifiers: .command)

                Button(action: onLogLater) {
                    Label("後で対応", systemImage: "text.badge.plus")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
            .font(.callout)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.92))
        .clipShape(containerShape)
        .overlay {
            containerShape
                .stroke(.white.opacity(0.1), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.2), radius: 12, y: 5)
        .frame(maxWidth: 420)
    }
}
