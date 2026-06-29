# TASKS_BACKLOG.md

> このファイルは自律エージェント（例: Codex）のタスク台帳です。運用ルールは [`AGENTS.md`](AGENTS.md)（§14 記録 / §4 ループ / §5 選定）を参照。doing は常に1件のみ。

## 棚卸しサマリー

- 棚卸し日時: 2026/06/11 20:52 JST
- 最終更新: 2026/06/29 18:35 JST
- 対象ブランチ: `docs/sync-post-pr13-state`（既定ブランチ `main` は PR #13 merge commit `9f62edb` まで `origin/main` と同期済み）
- タスク管理: このファイル（`TASKS_BACKLOG.md`）＋運用契約 `AGENTS.md`
- README / docs の未完了項目: 該当なし
- コード内 TODO / FIXME: 該当なし
- 失敗しているローカル検証: 該当なし
- 未コミット変更: あり（`HANDOFF.md` / `TASKS_BACKLOG.md` の post-PR #13 現状同期のみ。未追跡 advisory docs 2件は raw 採用せず別PR候補として分離）
- GitHub open issues: 2026/06/29 18:32 JST時点0件。open PR: 0件。PR #13は `9f62edb` でmerge済み
- doing タスク: 0 件（今回の現状同期後も未追跡 advisory docs 2件は redaction 済み短縮版だけを別PR候補として扱う）

## タスク一覧

| ID | タスク名 | 出典 | 優先度 | 規模 | 状態 |
| --- | --- | --- | --- | --- | --- |
| T001 | 残タスク棚卸し結果を `TASKS_BACKLOG.md` に永続化する | ユーザー Goal / 既存タスク管理ファイルなし | 高 | S | done |
| T002 | 引き継ぎ用に `HANDOFF.md` を作成し、締め状態を記録する | ユーザー Goal / 引き継ぎ準備 | 高 | S | done |
| T003 | 自律エージェント運用契約 `AGENTS.md` を追加する | ユーザー Goal / Codex 自律主開発への移行 | 高 | M | done |
| T004 | マージ後の実状態に合わせて `HANDOFF.md` を更新する | 整合性（PR #8 マージ後の陳腐化解消） | 高 | S | done |
| T005 | `examples/checklist.md` に Design Baseline 観点を反映する | 整合性（`SKILL.md` とチェックリストの観点差分） | 高 | S | done |
| T006 | `CHANGELOG.md` の versioned release 表現を現状に合わせる | 陳腐化（v0.1.0 タグ後の表現更新） | 高 | S | done |
| T007 | 検証コマンド表記を canonical な実行形へ統一する | 整合性（README/CONTRIBUTING/SECURITY/PR template の表記揺れ） | 高 | S | done |
| T008 | Claude scanner hardening ブランチを検証し `main` へ統合する | 2026-06-21 Claude Code 実装ブランチ | 高 | S | done |
| T009 | scanner self-test の cleanup 失敗を検証結果から分離し、tracked-marker assertion は必須のまま保つ | 2026-06-29 Codex WIP | 中 | S | done(PR #12でマージ済み) |
| T010 | advisory docs (`docs/CLAUDE_CODE_REVIEW_2026-06-21.md`, `docs/codex-task-scanner-hardening.md`) の採用/分割を次コミット前に明示する | 2026-06-29 Codex WIP | 中 | S | done(split: 今回PRから分離) |
| T011 | PR #12 merge後の `HANDOFF.md` / `TASKS_BACKLOG.md` を現在状態へ同期する | 2026-06-29 Codex WIP | 高 | S | done(PR #13でマージ済み) |
| T012 | PR #13 merge後の `HANDOFF.md` / `TASKS_BACKLOG.md` を現在状態へ同期する | 2026-06-29 Codex WIP | 高 | S | done(このPR) |

## 検証ログ

| コマンド | 結果 |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | 2026/06/29 18:36 JST pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | 2026/06/29 18:37 JST pass。sandbox false negative後、権限付き再実行で tracked-marker assertionも通過 |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | 2026/06/29 18:37 JST pass |
| `git diff --check -- HANDOFF.md TASKS_BACKLOG.md` | 2026/06/29 18:37 JST pass |
| `gitleaks detect --no-git --redact --no-banner --source HANDOFF.md --source TASKS_BACKLOG.md` | 2026/06/29 18:37 JST pass |
| `gh issue list --state open --limit 50 --json number,title,url` | 2026/06/29 `[]` |
| `gh pr list --state open --json ...` | 2026/06/29 14:20 JST `[]` |
| `gh pr view 12 --json state,mergedAt,mergeCommit,...` | 2026/06/29 PR #12 `MERGED` / merge commit `2be441b` |
| `gh pr view 13 --json number,state,mergedAt,mergeCommit,title,url` | 2026/06/29 PR #13 `MERGED` / merge commit `9f62edb` |

## skip

該当なし。

- 📌 2026-06-21 Claude Code 再レビュー: High 指摘の委譲タスク仕様 `docs/codex-task-scanner-hardening.md` を参照（advisory／着手前に spec 内のコスト・secret・要件ゲート④の境界を確認）。横断索引: `CLAUDE_CODE_REVIEW_INDEX_2026-06-21.md`。


- 🔧 2026-06-23 Codex 統合: `fix/claude-scanner-hardening` を `main` へ fast-forward 統合済み。`check:all` は 3 本 pass。
- 🔧 2026-06-29 Codex 統合: PR #12 `fix/scanner-hardening-boundary` は merge commit `2be441b` で `main` に反映済み。open PR 0件。
- 🔧 2026-06-29 Codex 同期: PR #13 `docs: PR #12後の引き継ぎ状態を同期` は merge commit `9f62edb` で `main` に反映済み。未追跡 advisory docs 2件は raw 採用せず、必要なら redaction 済み短縮版だけを別PRで扱う。
