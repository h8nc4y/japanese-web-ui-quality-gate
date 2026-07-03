# HANDOFF.md

## リポジトリの目的

このリポジトリは、日本向けのWeb UI作成・レビュー時に使う Codex-style skill `japanese-web-ui-quality-gate` を公開可能な形で管理するためのものです。README、`SKILL.md`、サンプル、GitHub テンプレート、公開前チェック用 PowerShell スクリプトを含みます。

## 運用モデル（2026/06/20〜）

このリポジトリは **自律エージェント（例: Codex）が主開発者** として運用します。運用契約は [`AGENTS.md`](AGENTS.md) に記載し、エージェントは repo を開いた時点でまず `AGENTS.md` を読みます。要点:

- エージェントはタスク選定 → 実装 → 自己検証 → 日本語コミット → PR → マージまで承認なしで自走（§4）。
- フロントのビジュアルデザインはエージェントが創出せず、デザインブリーフを書いて停止し人手で外部デザイン工程へ渡す（§11・§12）。
- レビューは原則セルフ（`check:all` 緑＋敵対的セルフレビュー）。必要時のみ外部レビュー（§10・§13）。
- 4ゲートは人間承認を維持（§6）: ①デプロイ/Actions/release・tag ②課金・有料API ③secret・実素材・実データの外部送信 ④製品要件の変更。

## 確認済みスナップショット

- 既定ブランチは `main`。2026-07-03 時点で、PR #19（`docs/requirements-redefinition-v2`）が `main` にマージ済みで `docs/requirements-redefinition-2026-07.md` が追加された。本ブランチ `feat/skill-v2-evaluation-axes` で T017–T019（評価軸v2の実体化: `SKILL.md` v2 / `references/checklist.md` 新設 / `examples/checklist.md` 適用例化 / README・CHANGELOG同期）を実装した。
- 既定ブランチは `main`。2026/06/30 13:20 JST 時点で、この更新ブランチ作成前の `main` は PR #17 merge commit `666dd6a` まで `origin/main` と同期済み。GitHub open issue / open PR は 0件。
- タスク棚卸し（`TASKS_BACKLOG.md` / 旧 `HANDOFF.md`）は PR #8 で `main` にマージ済み。棚卸し用ブランチ `chore-tasks-backlog-inventory` は削除済み。
- その後、自律運用契約 `AGENTS.md` を追加（このファイルの現状反映を含む）。
- `examples/checklist.md` に `SKILL.md` の `Design Baseline` 観点を反映しました。
- `CHANGELOG.md` の semantic versioning 説明を、v0.1.0 後の現状に合う表現へ更新しました。
- README、CONTRIBUTING、SECURITY、PR テンプレートの検証コマンド表記を canonical な `pwsh -NoProfile -ExecutionPolicy Bypass -File` 形へ統一しました。
- Claude Code の `fix/claude-scanner-hardening` を `main` に fast-forward 統合し、scanner の git-tracked 既定、secret 形式追加、行番号出力、バイナリ除外、`task-scanner` slug 偽陽性修正を反映しました。
- `TASKS_BACKLOG.md` の現在の doing はありません。PR #17 までの scanner hardening / cleanup境界整理 / handoff同期 / advisory disposition同期 / post-PR #16 handoff同期は `main` に反映済み。未追跡 `docs/` の advisory docs 2件は raw のまま採用せず、`.gitignore` で誤stageを防ぎ、短縮版 `docs/advisory-review-disposition.md` だけをtrackする。
- コード内 TODO / FIXME は実質的な未着手項目としては見つかっていません。
- GitHub open issues / open PR は 2026/06/30 13:20 JST 時点で 0 件。PR #17 `docs: PR #16後の引き継ぎ状態を同期` は `666dd6a` で merge 済み、Validation は `SUCCESS`。
- ローカル検証3本（§7）は 2026/06/30 02:50 JST に `pwsh` / Windows PowerShell の両方で pass。`test-scan-private-markers.ps1` は git fixture staging false negativeを避けるため権限付きで再実行した。staged secret scan / diff checkもpass。

## 完了タスク

| タスク | 状態 |
| --- | --- |
| `T001` 残タスク棚卸し結果を `TASKS_BACKLOG.md` に永続化 | done（PR #8 でマージ済み） |
| `T002` 引き継ぎ用 `HANDOFF.md` 作成・締め状態記録 | done（PR #8 でマージ済み） |
| `T003` 自律エージェント運用契約 `AGENTS.md` を追加 | done |
| `T004` `HANDOFF.md` をマージ後の現状へ更新 | done（このファイル） |
| `T005` `examples/checklist.md` に Design Baseline 観点を反映 | done |
| `T006` `CHANGELOG.md` の versioned release 表現を現状に合わせる | done |
| `T007` 検証コマンド表記を canonical な実行形へ統一 | done |
| `T008` Claude scanner hardening ブランチを検証・統合 | done |
| `T009` scanner self-test の cleanup 失敗を検証結果から分離 | done（PR #12 でマージ済み） |
| `T010` advisory docs の採用/分割方針を明示 | done（今回PRから分離） |
| `T011` PR #12 後の `HANDOFF.md` / `TASKS_BACKLOG.md` 現状同期 | done（PR #13 でマージ済み） |
| `T012` PR #13 後の `HANDOFF.md` / `TASKS_BACKLOG.md` 現状同期 | done（PR #14 でマージ済み） |
| `T013` PR #14 後の `HANDOFF.md` / `TASKS_BACKLOG.md` 現状同期 | done（PR #15 でマージ済み） |
| `T014` advisory docs raw非採用と短縮disposition記録 | done（PR #16でマージ済み） |
| `T015` PR #17 後の確認済みスナップショットを同期し、自己同期PR番号の追跡ループを避ける | done（PR #18でマージ済み） |
| `T016` 要件再定義ドキュメントを追加する（市場・競合・評価軸v2・成功指標・タスク分解） | done（PR #19でマージ済み） |
| `T017` `SKILL.md` v2: 評価軸v2（7軸構成）を反映 | done（このブランチで実装） |
| `T018` `references/checklist.md` 新設・`examples/checklist.md` を適用例へ役割変更 | done（このブランチで実装） |
| `T019` README / CHANGELOG を `SKILL.md` v2 に同期 | done（このブランチで実装） |

## 未完了 / skip タスク

該当なし。

## 既知の問題・残懸念

- UI実装はこのリポジトリには含まれないため、ブラウザ表示確認は対象外です（`AGENTS.md` §2 の二層構造・§11 参照）。
- 次の実装は `AGENTS.md` の自律ループ（§4・§5・§15）に従って進めます。`HANDOFF.md` / `TASKS_BACKLOG.md` は確認時点のスナップショットとして扱い、この文書更新PR自身の番号だけを追い続けるための追加同期PRは作りません。

## 最終検証結果

2026/06/29 22:06 JST までに以下を実行しました。

| コマンド | 結果 |
| --- | --- |
| `gh issue list --state open --limit 50 --json number,title,url` | pass: `[]` |
| `gh pr list --state open --json number,title,url,headRefName,mergeStateStatus` | pass: `[]` |
| `gh pr view 14 --json number,state,mergedAt,mergeCommit,title,url,headRefName` | pass: PR #14 `MERGED` / merge commit `870b8c5` |
| `git diff --check -- HANDOFF.md TASKS_BACKLOG.md` | pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | pass: `Public readiness checks passed.` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | pass: sandbox は git-tracked fixture staging で false negative、権限付き再実行で `Private marker scanner tests passed.` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | pass: `No private or secret markers found.` |
| `gitleaks detect --no-git --redact --no-banner --source . --verbose` | pass: self-test由来のgitignored scratch削除後に no leaks found |

2026/06/30 02:50 JST、T014 advisory disposition branchで追加実行:

| コマンド | 結果 |
| --- | --- |
| `gh pr view 15 --json number,state,mergedAt,mergeCommit,title,url,headRefName,statusCheckRollup` | pass: PR #15 `MERGED` / merge commit `9ee95a4` / Validation `SUCCESS` |
| `gh pr view 16 --json number,state,mergedAt,mergeCommit,title,url,headRefName,statusCheckRollup` | pass: PR #16 `MERGED` / merge commit `5f6b826` / Validation `SUCCESS` |
| `gh issue list --state open --limit 50 --json number,title,url` | pass: `[]` |
| `gh pr list --state open --json number,title,url,headRefName,mergeStateStatus` | pass: `[]` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | pass（権限付き。git fixture staging false negative回避） |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | pass: scan mode `git-tracked` |
| `powershell -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | pass |
| `powershell -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | pass（権限付き。git fixture staging false negative回避） |
| `powershell -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | pass: scan mode `git-tracked` |
| `git diff --check --cached` | pass |
| `gitleaks git --staged --redact` | pass: no leaks found |

2026/06/30 13:20 JST、T015 handoff/backlog snapshot同期で追加実行:

| コマンド | 結果 |
| --- | --- |
| `gh issue list --state open --limit 50 --json number,title,url` | pass: `[]` |
| `gh pr list --state open --json number,title,url,headRefName,mergeStateStatus` | pass: `[]` |
| `gh pr view 17 --json number,state,mergedAt,mergeCommit,title,url,headRefName,statusCheckRollup` | pass: PR #17 `MERGED` / merge commit `666dd6a` / Validation `SUCCESS` |

## セットアップ・テスト・ビルドコマンド

このリポジトリは現時点で package manager や build step を持っていません。検証は PowerShell スクリプトで行います（`AGENTS.md` §7 の `check:all`）。

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

Windows PowerShell の互換実行例は README の `Validation` セクションを参照してください。

## ブランチ状況

| ブランチ | 状態 | 内容 |
| --- | --- | --- |
| `main` | PR #19（要件再定義doc）まで反映済み | v0.1.0 + タスク棚卸し + `AGENTS.md` + Claude scanner hardening / scanner cleanup境界整理 + PR #17/#18 handoff同期 + `docs/requirements-redefinition-2026-07.md` まで反映済み |
| `feat/skill-v2-evaluation-axes` | PR 提出（CI 緑・セルフレビュー合格でマージし、マージ後にブランチ削除） | T017–T019: `SKILL.md` v2（7軸構成）、`references/checklist.md` 新設（80項目）、`examples/checklist.md` の適用例化、README/CHANGELOG/HANDOFF/TASKS_BACKLOG同期 |

## 次にやるべき候補

1. T020: 適用例の拡充（日本語フォームの合成レビュー例をさらに追加。良いUIを不当に落とさない例を含む）。優先度は中。
2. §5 の優先度ルールに従い、既存ドキュメント/挙動の不整合・陳腐化を次の1件として探す。PR番号だけを追う自己同期は優先タスクにしない。
3. リリース（v0.2.0タグ等）・カタログ掲載は §6 ゲート①/Non-Goalsのため引き続きスコープ外。
4. §6 ゲート該当（release/tag・有料API・secret/実データ・製品要件変更）に当たったら停止して承認を仰ぐ。
