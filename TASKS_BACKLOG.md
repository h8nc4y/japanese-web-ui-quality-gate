# TASKS_BACKLOG.md

> このファイルは自律エージェント（例: Codex）のタスク台帳です。運用ルールは [`AGENTS.md`](AGENTS.md)（§14 記録 / §4 ループ / §5 選定）を参照。doing は常に1件のみ。

## 棚卸しサマリー

- 棚卸し日時: 2026/06/11 20:52 JST
- 最終更新: 2026/06/21 00:03 JST
- 対象ブランチ: `main`
- タスク管理: このファイル（`TASKS_BACKLOG.md`）＋運用契約 `AGENTS.md`
- README / docs の未完了項目: 該当なし
- コード内 TODO / FIXME: 該当なし
- 失敗しているローカル検証: 該当なし
- 未コミット変更: 該当なし（マージ単位で整理）
- GitHub open issues / open PR: 0 件
- doing タスク: 0 件

## タスク一覧

| ID | タスク名 | 出典 | 優先度 | 規模 | 状態 |
| --- | --- | --- | --- | --- | --- |
| T001 | 残タスク棚卸し結果を `TASKS_BACKLOG.md` に永続化する | ユーザー Goal / 既存タスク管理ファイルなし | 高 | S | done |
| T002 | 引き継ぎ用に `HANDOFF.md` を作成し、締め状態を記録する | ユーザー Goal / 引き継ぎ準備 | 高 | S | done |
| T003 | 自律エージェント運用契約 `AGENTS.md` を追加する | ユーザー Goal / Codex 自律主開発への移行 | 高 | M | done |
| T004 | マージ後の実状態に合わせて `HANDOFF.md` を更新する | 整合性（PR #8 マージ後の陳腐化解消） | 高 | S | done |
| T005 | `examples/checklist.md` に Design Baseline 観点を反映する | 整合性（`SKILL.md` とチェックリストの観点差分） | 高 | S | done |
| T006 | `CHANGELOG.md` の versioned release 表現を現状に合わせる | 陳腐化（v0.1.0 タグ後の表現更新） | 高 | S | done |

## 検証ログ

| コマンド | 結果 |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | 2026/06/20 pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | 2026/06/20 pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | 2026/06/20 pass |
| `gh issue list --state open --limit 50` | open issue なし |
| `gh pr list --state open` | open PR なし |

## skip

該当なし。
