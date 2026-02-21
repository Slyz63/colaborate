import SwiftUI

struct DashboardView: View {
    @ObservedObject var coordinator: DriftCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header()

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("例: プロジェクトの要件定義をまとめる", text: $coordinator.anchorText)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))

                        Button("フォーカス開始", action: coordinator.startAnchor)
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .keyboardShortcut(.return, modifiers: [])
                            .disabled(coordinator.anchorText.isEmpty)
                            .controlSize(.large)
                    }
                    Text("ひとつの作業に集中するためのアンカーを設定します。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            } label: {
                Label("フォーカスアンカー", systemImage: "anchor")
                    .fontWeight(.bold)
            }


            HStack(spacing: 24) {
                GroupBox("現在の状態") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("アクティブなアプリ", value: coordinator.currentAppName)
                        LabeledContent("バンドルID", value: coordinator.currentAppBundleID)
                        if let until = coordinator.intentionalBreakUntil {
                            LabeledContent("休憩中 (再開)", value: until.formatted(date: .omitted, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                }

                GroupBox("今日のサマリー") {
                    HStack(alignment: .center, spacing: 16) {
                        stat(title: "検知回数", value: coordinator.summary.driftPromptCount)
                        Divider()
                        stat(title: "タスク復帰", value: coordinator.summary.recoveredCount)
                        Divider()
                        stat(title: "後で対応", value: coordinator.summary.loggedForLaterCount)
                    }
                    .frame(minHeight: 70)
                }
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if coordinator.isDriftPromptPresented {
                DriftPromptCardView(
                    onResume: coordinator.resumeAnchor,
                    onSnooze: { coordinator.snoozeDrift(minutes: 15) },
                    onLogLater: coordinator.logForLater
                )
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.5), value: coordinator.isDriftPromptPresented)
    }

    @ViewBuilder
    private func header() -> some View {
        VStack(alignment: .leading) {
            Text("Context Drift Detector")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text("ひとつのタスクに集中し、脱線を防ぐためのシンプルなツールです。")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func stat(title: String, value: Int) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .animation(.default, value: value)
    }
}
