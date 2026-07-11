# HANDOFF.md

## リポジトリの目的

日本向け Web UI の作成・レビュー時に使う合否ゲート skill `japanese-web-ui-quality-gate` を公開可能な形で管理するリポジトリ。中核成果物は `SKILL.md`（v2・7軸構成）と `references/checklist.md`（80項目）。README、合成サンプル（`examples/`）、GitHub テンプレート、公開前チェック用 PowerShell スクリプト（`scripts/`）を含む。

## 運用モデル

自律エージェント（例: Codex）が主開発者。運用契約は [`AGENTS.md`](AGENTS.md) を最初に読むこと。要点:

- タスク選定 → 実装 → check:all → 敵対的セルフレビュー → 日本語コミット → PR → マージまで承認なしで自走（§4）。
- 4ゲートのみ人間承認（§6）: ①デプロイ/Actions/release・tag ②課金・有料API ③secret・実素材・実データの外部送信 ④製品要件の変更。
- 検証していない主張は書かず `未確認` と明記（§1・§8）。

## 確認済みスナップショット（2026-07-11 JST 実測）

- 既定ブランチ `main`。最新は PR #23 merge commit `efa47dd`（examples の v2 同期 = T021）。
- open issue / open PR: 0件。doing タスク: 0件。
- `SKILL.md` v2（7軸）・`references/checklist.md`（実測80項目・7節、README の表記と一致）・`examples/` 4件（fail多め適用例 / passing適用例 / v2同期済みレビュー依頼 / v2同期済み報告テンプレ）まで `main` 反映済み。
- check:all 3本（§7）は 2026-07-11 に pass。PR #23 の CI（Validation）も `SUCCESS`。
- 要件の正本: 利用者向けは `SKILL.md` / `README.md`、要件判断の記録は `docs/requirements-redefinition-2026-07.md`（評価軸v2・成功指標・非目標・反証条件）。

## 完了タスク

T001–T021 done（詳細は `TASKS_BACKLOG.md` のタスク一覧）。直近の主要マイルストーン:

- T016–T019: 要件再定義（2026-07）と `SKILL.md` v2 化・`references/checklist.md` 新設・README/CHANGELOG 同期（PR #19・#20）。
- T020: guard 適用の passing 適用例 `examples/passing-review.md`（PR #22）。
- T021: `examples/review-request.md` / `examples/final-report-template.md` の v2 7軸同期（PR #23）。

## 未完了タスク（次の担当エージェントへの引き継ぎ）

`TASKS_BACKLOG.md` に受け入れ条件つきで登録済み。§5 の優先度ルールに沿った着手順:

1. **T025**: 旧引き継ぎ文書 `docs/CLAUDECODE_FABLE5_HANDOFF.md` / `docs/CLAUDECODE_FABLE5_PROMPT.md` に「歴史的スナップショット（現状の正本は `HANDOFF.md`）」注記を追加（陳腐化解消）。
2. **T022**: `scripts/test-public-readiness.ps1` に `references/checklist.md` の実項目数と README の項目数表記（80 checks / 7 axes）のドリフト検出を追加。
3. **T023**: 要件再定義 §4 の反証条件ウォッチ（汎用競合 skill の日本語対応動向を時点付きで再調査・記録。出典は §8 に従い非 GitHub URL と名称のみ）。
4. **T024**: v0.2.0 リリース準備（CHANGELOG `[Unreleased]` の整理・リリースノート案・§6 形式の承認依頼文の作成まで）。**タグ発行・release 作成はゲート①のため実行せず停止**。

## 既知の問題・残懸念

- 本リポジトリに UI ソースは無いため、ブラウザ表示確認は通常対象外（`AGENTS.md` §2 の二層構造に注意。skill が「適用される対象」に UI が含まれることを「対象外」と誤判断しない）。
- `HANDOFF.md` / `TASKS_BACKLOG.md` は確認時点のスナップショット。PR番号だけを追う自己同期PRは作らない（実質的な不整合の解消を優先）。
- JIS X 8341-3 改正の確定内容は未確認（`docs/requirements-redefinition-2026-07.md` §9）。

## 最終検証結果（2026-07-11 JST）

| コマンド | 結果 |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | pass: `Public readiness checks passed.` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | pass: `Private marker scanner tests passed.` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | pass: `No private or secret markers found.`（git-tracked mode） |
| `git diff --check --cached` | pass |
| `gh pr list --state open` / `gh issue list --state open` | pass: いずれも 0件 |
| PR #23 statusCheckRollup | pass: `SUCCESS` |

## セットアップ・検証コマンド

ビルドや package manager は無し。検証は §7 の check:all 3本（上表のコマンド）。Windows PowerShell 互換実行例は README の `Validation` セクションを参照。

## 次にやるべきこと

1. `AGENTS.md` §15 の kickoff チェックリストに従いベースラインを実測で取り直す。
2. 上記「未完了タスク」を T025 → T022 → T023 → T024 の順に、doing 1件ずつ・1 PR = 1 改善で進める。
3. §6 ゲート該当（T024 のタグ発行など）に当たったら停止して承認を仰ぐ。
