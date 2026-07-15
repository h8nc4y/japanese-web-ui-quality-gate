# TASKS_BACKLOG.md

> 自律エージェント（例: Codex）のタスク台帳。運用ルールは [`AGENTS.md`](AGENTS.md)（§4 ループ / §5 選定 / §14 記録）を参照。doing は常に1件のみ。2026-07-11 以前の詳細な検証ログと同期経緯は、git 履歴にある本ファイルの旧版を参照。

## 現在のスナップショット（2026-07-12 JST 実測）

- 対象ブランチ: `main`
- doing タスク: 0件。GitHub open issue / open PR: 0件
- check:all 3本（`AGENTS.md` §7）: pass。CI（`validation.yml`）: 緑
- コード内 TODO / FIXME・失敗中の検証・未コミット変更: なし

## 未完了タスク

着手順は `AGENTS.md` §5 の優先度ルールに従い **T022 → T023 → T024** を推奨。

| ID | タスク | 出典 | 優先度 | 規模 |
| --- | --- | --- | --- | --- |
| T022 | `scripts/test-public-readiness.ps1` にチェックリスト項目数のドリフト検出を追加する | 整合性の恒久化（README「80 checks / 7 axes」表記の陳腐化防止） | 高 | S |
| T023 | 要件再定義 §4 の反証条件ウォッチ（競合 skill の日本語対応動向の時点付き再調査） | `docs/requirements-redefinition-2026-07.md` §4 | 中 | S |
| T024 | v0.2.0 リリース準備（CHANGELOG 整理・リリースノート案・承認依頼文の作成まで） | `CHANGELOG.md` `[Unreleased]` の蓄積 | 中 | S |

### T022 受け入れ条件（scripts 堅牢化）

- `scripts/test-public-readiness.ps1` に、`references/checklist.md` の `- [ ]` 項目数（現在80）と `## ` 節数（現在7）を実測し、`README.md` 内の項目数・軸数の記載と一致しない場合に fail するチェックを追加する。
- 数値そのものをスクリプトへハードコードせず、checklist 実測値と README 記載値の**相互比較**にする（項目追加時に両方更新すれば緑になる形）。
- `scripts/scan-private-markers.ps1` / `scripts/test-scan-private-markers.ps1` の marker 判定ロジックには触れない。触れる場合は `AGENTS.md` §10 の外部レビュー基準に該当する。
- 意図的に README の数を壊した場合に fail することをローカルで確認してから戻す（確認結果を PR に実値で記録）。

### T023 受け入れ条件（調査・記録）

- 汎用競合 skill（web-design-guidelines 等の UI レビュー系）が日本語組版・日本のフォーム慣行を取り込んでいないかを Web で再調査し、反証条件（`docs/requirements-redefinition-2026-07.md` §4)への該当有無を判断する。
- 結果は `docs/requirements-redefinition-2026-07.md` への追記または時点付きの新規 docs として記録。出典は `AGENTS.md` §8 に従い**非 GitHub URL と名称のみ**。未確認は `未確認` と明記。
- 反証条件に該当する動きが見つかった場合は、対応方針の変更が §6 ゲート④（製品要件の変更）に当たるため、記録までで停止して承認を仰ぐ。

### T024 受け入れ条件（リリース準備・ゲート①手前まで）

- `CHANGELOG.md` `[Unreleased]` を v0.2.0 セクション案として整理し、リリースノート案を作成する。
- `AGENTS.md` §6 のフォーマットでタグ発行（`v0.2.0`）の承認依頼文を用意する。
- **タグ発行・GitHub release 作成・publish 系 Actions 追加は実行しない**（ゲート①）。承認依頼を出して停止する。

## 完了タスク

| ID | タスク | 完了 |
| --- | --- | --- |
| T001–T002 | 残タスク棚卸しの永続化・`HANDOFF.md` 作成 | PR #8 |
| T003–T007 | `AGENTS.md`（自律運用契約）追加、HANDOFF 現状化、examples への Design Baseline 反映、CHANGELOG 表現更新、検証コマンド表記統一 | 2026-06 に main 反映 |
| T008 | Claude scanner hardening ブランチの検証・統合 | fast-forward 統合 |
| T009 | scanner self-test の cleanup 失敗を検証結果から分離 | PR #12 |
| T010 | advisory docs の採用/分割方針の明示 | PR #13 で分離 |
| T011–T015 | PR #12〜#17 後の handoff/backlog 同期（以後、PR番号だけを追う自己同期はやめ、実質的な不整合の解消を優先する運用へ） | PR #13–#18 |
| T016 | 要件再定義ドキュメント `docs/requirements-redefinition-2026-07.md` 追加 | PR #19 |
| T017–T019 | `SKILL.md` v2（7軸構成）・`references/checklist.md` 新設（80項目）・README/CHANGELOG 同期 | PR #20 |
| T020 | guard 適用の passing 適用例 `examples/passing-review.md` 新設 | PR #22 |
| T021 | `examples/review-request.md` / `examples/final-report-template.md` の v2 7軸同期 | PR #23 |
| T025 | 旧引き継ぎ文書の整理。当初の「未追跡ファイルへの注記追加」は PR 化不可能な欠陥定義だったため、「tracked の陳腐化文書3件の削除」に是正して解消（`docs/advisory-review-disposition.md` に記録） | 2026-07-12 文書整理 PR |

## 検証ログ（直近のみ・過去分は git 履歴を参照）

| コマンド | 結果 |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | 2026-07-12 pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | 2026-07-12 pass |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | 2026-07-12 pass: `No private or secret markers found.`（git-tracked mode、変更ファイル stage 後に走査） |
| `git diff --check --cached` | 2026-07-12 pass |
| `gh pr list --state open` / `gh issue list --state open` | 2026-07-12 いずれも 0件 |

## skip

該当なし。

## 外部レビュー指摘の台帳（2026-07-15 maxエフォート横断レビュー）

読取専用レビュー（実行検証なし）の指摘。採否と実装は次担当が判断する。完了時は行頭を [x] にし、対応PRを追記する。

- [x] scan-private-markers.ps1:77-80 — fallback(walk)モードの除外にdocsが入っているが本repoのdocs/は追跡済み(git不在環境で検査ギャップ)。最小修正: 除外からdocsを外すかコメント修正。confidence高（除外からdocsを外し、コメントを実態へ修正。walkモードでdocs/配下のmarkerを検出する自己テスト追加）
- [x] 同:241-244 — ErrorActionPreference=Stop下のWrite-Errorはthrowし、& 呼び出し元セッションを巻き添え終了。最小修正: Write-Host+exit 1。confidence高/実害低（Write-Host+exit 1へ変更）
- [x] 同:198 — Get-Contentにエンコーディング指定なし(PS5.1でBOMなしUTF-8日本語のCJK検出劣化)。最小修正: -Encoding UTF8。confidence中（-Encoding UTF8を明示）
- [x] 同:46-47 — (ドライブ文字+Users)型パスが2ルール二重ヒットし報告重複。confidence高（汎用ルールに`(?!Users\\)`の除外を追加し専用ルールのみが報告。二重ヒット解消＋非Usersパス検出維持の自己テスト追加）
