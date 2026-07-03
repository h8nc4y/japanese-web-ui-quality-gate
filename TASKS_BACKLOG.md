# TASKS_BACKLOG.md

> このファイルは自律エージェント（例: Codex）のタスク台帳です。運用ルールは [`AGENTS.md`](AGENTS.md)（§14 記録 / §4 ループ / §5 選定）を参照。doing は常に1件のみ。

## 棚卸しサマリー

- 棚卸し日時: 2026/06/11 20:52 JST
- 最終更新: 2026-07-03
- 対象ブランチ: `feat/skill-v2-evaluation-axes`（`main` は PR #19 merge commit まで `docs/requirements-redefinition-2026-07.md` 反映済み）
- タスク管理: このファイル（`TASKS_BACKLOG.md`）＋運用契約 `AGENTS.md`
- README / docs の未完了項目: 該当なし（T017–T019実装分はこのブランチで反映済み）
- コード内 TODO / FIXME: 該当なし
- 失敗しているローカル検証: 該当なし（2026-07-03 に check:all 3本 pass、`git diff --check` pass）
- 未コミット変更: なし（T017–T019 の変更はこのPRのコミットに含めて解消）
- GitHub open issues: 2026-07-03 時点 0件。open PR: このPR以外 0件（PR #19 はマージ済み）
- doing タスク: 0 件（T017–T019 はこのブランチで実装完了。次は T020 が候補）
- 2026-07-03: オーナー指示により要件を再定義（`docs/requirements-redefinition-2026-07.md`）。評価軸v2の実体化タスク T016–T020 を登録。T017–T019 を1PRとして実装。

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
| T012 | PR #13 merge後の `HANDOFF.md` / `TASKS_BACKLOG.md` を現在状態へ同期する | 2026-06-29 Codex WIP | 高 | S | done(PR #14でマージ済み) |
| T013 | PR #14 merge後の `HANDOFF.md` / `TASKS_BACKLOG.md` を現在状態へ同期する | 2026-06-29 Codex WIP | 高 | S | done(PR #15でマージ済み) |
| T014 | advisory docs 2件のraw非採用と短縮dispositionを記録する | 未追跡 `docs/` advisory docs / AGENTS scanner drift | 中 | S | done(PR #16でマージ済み) |
| T015 | PR #17後の確認済みスナップショットを同期し、自己同期PR番号の追跡ループを避ける | `HANDOFF.md` / `TASKS_BACKLOG.md` のPR #16時点表記 | 高 | S | done(この更新で完了) |
| T016 | 要件再定義ドキュメントを追加する（市場・競合・評価軸v2・成功指標・タスク分解） | 2026-07-03 オーナー再定義指示 / `docs/requirements-redefinition-2026-07.md` | 高 | M | done(このPR) |
| T017 | SKILL.md v2: 評価軸v2を反映（日本語表示・組版/日本のフォーム入力/WCAG 2.2観測可能集合を新設、判定フロー中心・トークン軽量） | `docs/requirements-redefinition-2026-07.md` §5 | 高 | M | done(このPRで実装) |
| T018 | `references/checklist.md` 新設と `examples/checklist.md` の適用例への役割変更 | `docs/requirements-redefinition-2026-07.md` §8 | 高 | S | done(T017と同PRで実装) |
| T019 | README / CHANGELOG を SKILL.md v2 に同期する | `docs/requirements-redefinition-2026-07.md` §8 | 高 | S | done(T017と同PRで実装) |
| T020 | 適用例の拡充（日本語フォームの合成レビュー例、false positive抑制例を含む） | `docs/requirements-redefinition-2026-07.md` §6 | 中 | S | todo |

## 検証ログ

| コマンド | 結果 |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | 2026/06/29 22:03 JST pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | 2026/06/29 22:06 JST pass。sandbox false negative後、権限付き再実行で tracked-marker assertionも通過 |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | 2026/06/29 22:03 JST pass |
| `git diff --check -- HANDOFF.md TASKS_BACKLOG.md` | 2026/06/29 22:03 JST pass |
| `gitleaks detect --no-git --redact --no-banner --source . --verbose` | 2026/06/29 22:06 JST pass。self-test由来のgitignored scratch削除後に no leaks found |
| `gh issue list --state open --limit 50 --json number,title,url` | 2026/06/29 `[]` |
| `gh pr list --state open --json ...` | 2026/06/29 21:56 JST `[]` |
| `gh pr view 12 --json state,mergedAt,mergeCommit,...` | 2026/06/29 PR #12 `MERGED` / merge commit `2be441b` |
| `gh pr view 13 --json number,state,mergedAt,mergeCommit,title,url` | 2026/06/29 PR #13 `MERGED` / merge commit `9f62edb` |
| `gh pr view 14 --json number,state,mergedAt,mergeCommit,title,url,headRefName` | 2026/06/29 PR #14 `MERGED` / merge commit `870b8c5` |
| `gh pr view 15 --json number,state,mergedAt,mergeCommit,title,url,headRefName,statusCheckRollup` | 2026/06/30 PR #15 `MERGED` / merge commit `9ee95a4` / Validation `SUCCESS` |
| `gh pr view 16 --json number,state,mergedAt,mergeCommit,title,url,headRefName,statusCheckRollup` | 2026/06/30 PR #16 `MERGED` / merge commit `5f6b826` / Validation `SUCCESS` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | 2026/06/30 02:50 JST pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | 2026/06/30 02:49 JST pass（権限付き。git fixture staging false negative回避） |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | 2026/06/30 02:49 JST pass / scan mode `git-tracked` |
| `powershell -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | 2026/06/30 02:49 JST pass |
| `powershell -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | 2026/06/30 02:50 JST pass（権限付き。git fixture staging false negative回避） |
| `powershell -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | 2026/06/30 02:50 JST pass / scan mode `git-tracked` |
| `git diff --check --cached` | 2026/06/30 02:50 JST pass |
| `gitleaks git --staged --redact` | 2026/06/30 02:50 JST pass / no leaks found |
| `gh issue list --state open --limit 50 --json number,title,url` | 2026/06/30 13:20 JST pass: `[]` |
| `gh pr list --state open --json number,title,url,headRefName,mergeStateStatus` | 2026/06/30 13:20 JST pass: `[]` |
| `gh pr view 17 --json number,state,mergedAt,mergeCommit,title,url,headRefName,statusCheckRollup` | 2026/06/30 13:20 JST pass: PR #17 `MERGED` / merge commit `666dd6a` / Validation `SUCCESS` |
| `pwsh -NoProfile -File scripts/test-public-readiness.ps1` | 2026-07-03 pass（T016 PR / T017–T019 PR の双方で実行） |
| `pwsh -NoProfile -File scripts/test-scan-private-markers.ps1` | 2026-07-03 pass |
| `pwsh -NoProfile -File scripts/scan-private-markers.ps1` | 2026-07-03 pass: `No private or secret markers found.`（git-tracked mode、新規 `references/checklist.md` はstage後に走査） |
| `git diff --check --cached` | 2026-07-03 pass |

## skip

該当なし。

- 📌 2026-06-21 Claude Code 再レビュー: High 指摘の委譲タスク仕様 `docs/codex-task-scanner-hardening.md` を参照（advisory／着手前に spec 内のコスト・secret・要件ゲート④の境界を確認）。横断索引: `CLAUDE_CODE_REVIEW_INDEX_2026-06-21.md`。


- 🔧 2026-06-23 Codex 統合: `fix/claude-scanner-hardening` を `main` へ fast-forward 統合済み。`check:all` は 3 本 pass。
- 🔧 2026-06-29 Codex 統合: PR #12 `fix/scanner-hardening-boundary` は merge commit `2be441b` で `main` に反映済み。open PR 0件。
- 🔧 2026-06-29 Codex 同期: PR #13 `docs: PR #12後の引き継ぎ状態を同期` は merge commit `9f62edb` で `main` に反映済み。未追跡 advisory docs 2件は raw 採用せず、必要なら redaction 済み短縮版だけを別PRで扱う。
- 🔧 2026-06-29 Codex 同期: PR #14 `docs: sync post-PR13 handoff state` は merge commit `870b8c5` で `main` に反映済み。未追跡 advisory docs 2件のraw採用は引き続き保留し、tracked handoff/backlogだけをpost-PR #14状態へ同期する。
- 🔧 2026-06-30 Codex 同期: PR #15 `docs: PR #14後の引き継ぎ状態を同期` は merge commit `9ee95a4` で `main` に反映済み。本T014では raw advisory 2件を ignore し、`docs/advisory-review-disposition.md` に短縮判断だけを残す。
- 🔧 2026-06-30 Codex 同期: PR #16 `docs: advisory原本の扱いを短縮記録` は merge commit `5f6b826` で `main` に反映済み。open PR 0件、doing 0件。
- 🔧 2026-06-30 Codex 同期: PR #17 `docs: PR #16後の引き継ぎ状態を同期` は merge commit `666dd6a` で `main` に反映済み。以後、文書更新PR自身の番号だけを追い続ける追加同期は作らず、次の実質的な不整合・陳腐化を優先する。
