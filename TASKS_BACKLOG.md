# TASKS_BACKLOG.md

## 棚卸しサマリー

- 棚卸し日時: 2026/06/11 20:52 JST
- 対象ブランチ: `chore-tasks-backlog-inventory`
- 既存タスク管理ファイル: 該当なし
- README / docs の未完了項目: 該当なし
- AGENTS.md / .codex 指示: リポジトリ内には該当ファイルなし
- コード内 TODO / FIXME: 該当なし
- 失敗しているローカル検証: 該当なし
- 未コミット変更: 該当なし
- GitHub open issues: 該当なし

## タスク一覧

| ID | タスク名 | 出典 | 優先度 | 規模 | 状態 |
| --- | --- | --- | --- | --- | --- |
| T001 | 残タスク棚卸し結果を `TASKS_BACKLOG.md` に永続化する | ユーザー Goal / 既存タスク管理ファイルなし | 高 | S | done |

## 検証ログ

| コマンド | 結果 |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | pass |
| `gh issue list --state open --limit 50` | pass / open issue なし |

## skip

該当なし。
