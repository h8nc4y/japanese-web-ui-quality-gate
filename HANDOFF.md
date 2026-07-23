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
| `docs/release-v0.2.0-preparation.md` | v0.2.0 のリリースノート案、最終化手順、ゲート①承認依頼 |
| `CHANGELOG.md` | `[Unreleased]` に次リリース候補の変更を蓄積 |

## 運用モデル

自律エージェント（例: Codex）が主開発者。**最初に [`AGENTS.md`](AGENTS.md) を読むこと。** 要点:

- タスク選定 → 実装 → check:all → 敵対的セルフレビュー → 日本語コミット → PR → マージまで承認なしで自走（§4）。
- 4ゲートのみ人間承認（§6）: ①デプロイ/Actions/release・tag ②課金・有料API ③secret・実素材・実データの外部送信 ④製品要件の変更。
- 検証していない主張は書かず `未確認` と明記（§1・§8）。

## 確認済みスナップショット（2026-07-22 JST 実測）

- 既定ブランチ `main`。T001–T025 が完了済み。T022 では checklist 実項目数と軸数を README の数値表記と固定値なしで相互比較する public-readiness 検証を追加。
- T023 の 2026-07-22 再調査では、汎用 UI review skill に日本語組版と日本固有フォームの本格採用を確認できず、反証条件は非該当。
  日本語タイポグラフィの隣接資料は増えているため、既存方針どおり合否、フォーム、検証証拠、正直な報告の組み合わせを差別化の中心に維持。
- T024 では `CHANGELOG.md` の `[Unreleased]` を v0.2.0 candidate として明示し、リリースノート案、最終化手順、ゲート①承認依頼を `docs/release-v0.2.0-preparation.md` に整理。
  `v0.2.0` の tag と GitHub Release は作成していない。
- open issue / open PR: 0件。doing タスク: 0件。
- 最新の tag と GitHub Release は `v0.1.0`。
- `references/checklist.md` は実測80項目・7節で README の表記と一致。
- check:all 3本（§7）は 2026-07-22 に pass。直近の `main` CI（`validation.yml`）緑。
- 2026-07-12 に文書整理を実施: 陳腐化した tracked 文書3件を削除し（判断は `docs/advisory-review-disposition.md`）、台帳と本文書をスリム化。

## 承認待ち（次の担当エージェントへの引き継ぎ）

実装台帳の未完了タスクはない。
次の操作は `AGENTS.md` §6 のゲート①に該当する。

1. **v0.2.0 リリース最終化**: 人間がゲート①を明示承認した場合だけ、`docs/release-v0.2.0-preparation.md` の手順に従って最終化 PR、tag 発行、GitHub Release 作成を進める。
2. 承認がない場合は tag と GitHub Release を作成せず、承認依頼を報告して停止する。

## 既知の問題・残懸念

- 本リポジトリに UI ソースは無いため、ブラウザ表示確認は通常対象外。ただし `AGENTS.md` §2 の二層構造に注意: skill が「適用される対象」には日本向け Web UI が含まれるため、`SKILL.md` 内の UI 検証観点を「対象外」と誤判断しない。
- `HANDOFF.md` / `TASKS_BACKLOG.md` は確認時点のスナップショット。PR番号だけを追う自己同期 PR は作らない。
- JIS X 8341-3 改正後の確定内容は未確認。WAIC の 2026-06-08 公開情報でも改正は検討段階（`docs/requirements-redefinition-2026-07.md` §4.1 / §9）。
- v0.2.0 の公開日は未確定。ゲート①承認前に changelog の日付、tag、GitHub Release を確定しない。

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
2. ゲート①の明示承認があるか確認する。
3. 承認済みなら `docs/release-v0.2.0-preparation.md` に従ってリリースを最終化する。未承認なら同文書の承認依頼を報告し、tag と GitHub Release を作成せず停止する。
