# Context Drift Detector

macOS向けの「脱線検知 + 作業復帰」アプリです。

## できること

- 戻る先アプリをアンカーとして選択
- タスク名を入力してフォーカス開始
- 脱線検知時にカード表示 (`タスクに戻る / 15分後に再通知 / 後で対応`)
- 今日のサマリー表示 (`検知回数 / タスク復帰 / 後で対応`)

## 開発実行

```bash
cd /Users/lyz/Desktop/Coding/2026/context-drift-detector
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build --scratch-path /tmp/cdd-build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run --scratch-path /tmp/cdd-build ContextDriftDetector
```

## アンカー運用のポイント

- 戻る先は**アプリ選択（プルダウン）**が基準です
- テキスト入力はタスク名で、戻る先アプリとは別です
- 戻る先アプリが一覧にない場合は `更新` を押してください

## Launchpadから起動

このリポジトリには `ContextDriftDetector` 本体（Swift実行ファイル）があり、
`~/Applications/ContextDriftDetector.app` のランチャーから起動できます。

ランチャーを再作成する場合は `scripts/install_launchpad_app.sh` を使います（この後追加）。
