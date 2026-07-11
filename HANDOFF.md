# HANDOFF.md

## リポジトリの目的

日本向け Web UI の作成・レビュー時に使う合否ゲート skill `japanese-web-ui-quality-gate` を公開可能な形で管理するリポジトリ。中核成果物は `SKILL.md`（v2・7軸構成）と `references/checklist.md`（80項目）。生成ガイドではなく、**日本語 UI の合否を evidence 付きで正直に報告させる契約**が差別化ポジション。

## 資料マップ（正本の所在）

| 資料 | 役割 |
| --- | --- |
| `SKILL.md` / `references/checklist.md` | 中核成果物。7軸の合否ゲート本体と80項目の詳細チェックリスト |
| `README.md` | 利用者向け説明・インストール・更新・検証手順 |
| `examples/` | 合成の適用例4件（fail 多めの適用例 / guard 適用の passing 例 / レビュー依頼 / 報告テンプレ） |
| `AGENTS.md` | 自律エージェント運用契約（自走範囲・4ゲート・check:all・公開安全規約） |
| `TASKS_BACKLOG.md` | タスク台帳。未完了タスクの受け入れ条件はここが正本 |
| `docs/requirements-redefinition-2026-07.md` | 要件判断の記録（市場・評価軸v2・成功指標・反証条件）。実装済み |
| `docs/advisory-review-disposition.md` | 過去 advisory と文書整理の処理記録 |
| `docs/CODEX_PROMPT_2026-07-12.md` | 次の自律エージェントセッション向け引き継ぎプロンプト |
| `CHANGELOG.md` | `[Unreleased]` に次リリース候補の変更を蓄積 |

## 運用モデル

自律エージェント（例: Codex）が主開発者。**最初に [`AGENTS.md`](AGENTS.md) を読むこと。** 要点:

- タスク選定 → 実装 → check:all → 敵対的セルフレビュー → 日本語コミット → PR → マージまで承認なしで自走（§4）。
- 4ゲートのみ人間承認（§6）: ①デプロイ/Actions/release・tag ②課金・有料API ③secret・実素材・実データの外部送信 ④製品要件の変更。
- 検証していない主張は書かず `未確認` と明記（§1・§8）。

## 確認済みスナップショット（2026-07-12 JST 実測）

- 既定ブランチ `main`。T001–T021 と T025 が完了済み（PR #24 merge commit `a98bc65` ＋ 本文書整理 PR）。
- open issue / open PR: 0件。doing タスク: 0件。
- `references/checklist.md` は実測80項目・7節で README の表記と一致。
- check:all 3本（§7）は 2026-07-12 に pass。CI（`validation.yml`）緑。
- 2026-07-12 に文書整理を実施: 陳腐化した tracked 文書3件を削除し（判断は `docs/advisory-review-disposition.md`）、台帳と本文書をスリム化。

## 未完了タスク（次の担当エージェントへの引き継ぎ）

受け入れ条件は `TASKS_BACKLOG.md` が正本。`AGENTS.md` §5 の優先度ルールに沿った着手順:

1. **T022**: `scripts/test-public-readiness.ps1` に `references/checklist.md` の実項目数と README の項目数表記（80 checks / 7 axes）のドリフト検出を追加。
2. **T023**: 要件再定義 §4 の反証条件ウォッチ（汎用競合 skill の日本語対応動向を時点付きで再調査・記録。出典は §8 に従い非 GitHub URL と名称のみ）。
3. **T024**: v0.2.0 リリース準備（CHANGELOG `[Unreleased]` の整理・リリースノート案・§6 形式の承認依頼文の作成まで）。**タグ発行・release 作成はゲート①のため実行せず停止**。

## 既知の問題・残懸念

- 本リポジトリに UI ソースは無いため、ブラウザ表示確認は通常対象外。ただし `AGENTS.md` §2 の二層構造に注意: skill が「適用される対象」には日本向け Web UI が含まれるため、`SKILL.md` 内の UI 検証観点を「対象外」と誤判断しない。
- `HANDOFF.md` / `TASKS_BACKLOG.md` は確認時点のスナップショット。PR番号だけを追う自己同期 PR は作らない。
- JIS X 8341-3 改正の確定内容は未確認（`docs/requirements-redefinition-2026-07.md` §9。T023 の調査対象）。

## 検証コマンド

ビルドや package manager は無し。検証は `AGENTS.md` §7 の check:all 3本:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

直近の実行結果は `TASKS_BACKLOG.md` の検証ログを参照。Windows PowerShell 互換実行例は README の `Validation` セクションを参照。

## 次にやるべきこと

1. `AGENTS.md` §15 の kickoff チェックリストに従いベースラインを実測で取り直す（本文書のスナップショットを信用しすぎない）。
2. 未完了タスクを T022 → T023 → T024 の順に、doing 1件ずつ・1 PR = 1 改善で進める。
3. §6 ゲート該当（T024 のタグ発行など）に当たったら停止して承認を仰ぐ。
