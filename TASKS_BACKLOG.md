# TASKS_BACKLOG.md

> 自律エージェント（例: Codex）のタスク台帳。運用ルールは [`AGENTS.md`](AGENTS.md)（§4 ループ / §5 選定 / §14 記録）を参照。doing は常に1件のみ。2026-07-11 以前の詳細な検証ログと同期経緯は、git 履歴にある本ファイルの旧版を参照。

## 現在のスナップショット（2026-07-30 JST 実測）

- 対象ブランチ: `chore/upgrade-checkout-v7`（verified `main` closeout merge `c18c779` から分離）
- doing タスク: 1件（T037）。着手時の GitHub open issue / open PR: 0件
- check:all 3本（`AGENTS.md` §7）: 2026-07-30 T037 で PowerShell 7 / Windows PowerShell 5.1 ともに pass（6コマンドすべて exit 0）
- コード内 TODO / FIXME・失敗中の検証: なし

## 未完了タスク

### doing

- **T037 / Class M — checkoutをNode.js 24対応の公式v7へ更新する**
  - 目的: PR #50とpost-main Validationで実測した`actions/checkout` v4.4.0のNode.js 20非推奨annotationを解消する。
  - 影響: `.github/workflows/validation.yml`のcheckoutだけを、公式v7.0.1のverified commit `3d3c42e5aac5ba805825da76410c181273ba90b1`へ更新する。trigger / permission / job / runner / timeout / credentials / step / commandは変更しない。
  - 受け入れ条件: mutable v7、旧v4.4.0 pin、誤SHA、version comment欠落を負例で拒否し、LF / CRLFと既存top-level / job契約を維持する。PowerShell 7 / Windows PowerShell 5.1のcheck:all、PR / post-main Validationをpassし、Node.js 20非推奨annotationが再発しない。
  - ゲート: release、tag、workflow trigger / permission、外部送信、課金、secret、実データは変更しない。v0.2.0はゲート①承認待ちのまま。

### ゲート①承認待ち

- 対象: `v0.2.0` の tag 発行と GitHub Release 作成。
- 準備と承認依頼の正本: `docs/release-v0.2.0-preparation.md`。
- 明示承認がない間は `v0.2.0` の tag と GitHub Release を作成しない。

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
| T022 | public-readiness に、checklist から得た実項目数と軸数を README の数値表記と相互比較するドリフト検出を追加。README の件数を 81、軸数を 8 に一時変更し、いずれも期待どおり exit 1 を実測後に復元 | 2026-07-22 |
| T023 | 汎用 UI review skill 2件と日本語 UI の隣接資料を 2026-07-22 時点の公開一次情報で再調査。汎用上位 skill に日本語組版と日本固有フォームの本格採用は確認できず、反証条件には非該当。JIS X 8341-3 改正も検討段階と記録 | 2026-07-22 |
| T024 | `CHANGELOG.md` の `[Unreleased]` を v0.2.0 candidate として整理。リリースノート案、最終化手順、ゲート①承認依頼を作成し、tag と GitHub Release は未作成のまま停止 | 2026-07-22 |
| T025 | 旧引き継ぎ文書の整理。当初の「未追跡ファイルへの注記追加」は PR 化不可能な欠陥定義だったため、「tracked の陳腐化文書3件の削除」に是正して解消（`docs/advisory-review-disposition.md` に記録） | 2026-07-12 文書整理 PR |
| T026 | public-readiness の軸数抽出を番号付き H2 に限定し、補助 H2・コードフェンス内の見出しを除外。公開文書の読み取りを UTF-8 に固定し、PowerShell 7 / Windows PowerShell 5.1 の判定を一致 | 2026-07-25 |
| T027 | public-readiness の項目数抽出を top-level 番号付き軸内の未チェック hyphen 項目（marker後1–4列）へ限定。親itemのcontent columnからnested checkboxとlist内paragraph / Setext / Type 7を識別し、0–3-space fenceとlabelが999文字以内の安全に証明できる単行link reference subsetを受理。active axis内の非canonical container、複数行link reference、未確定indented leafだけを固定エラー + 0件へ fail closed。top-levelと証明したSetextだけをscope境界にし、軸数と項目数を同じ構造解析から導出 | 2026-07-26 |
| T028 | 日付付き起動プロンプトから固定の完了タスク範囲・検証日・tag/Release状態を除去。新しいセッションが living SSOT と check:all / Git / GitHub の実測から現在値を得る契約へ変更 | 2026-07-27 |
| T029 | 番号付き軸内の有効な space / tab 区切り hyphen / asterisk thematic break を非対応 container の fail-closed 判定から除外。正例と、3個未満・末尾文字付きの負例 fixture で境界を固定 | 2026-07-28 / PR #35 |
| T030 | `git ls-files -z` 失敗時の検査対象0件成功を防ぎ、固定のredactedエラー + exit 1へ fail closed。fake gitのWindows / Unix fixture、PATH復元、native stderr非出力、現在のPowerShell host再利用を回帰検証 | 2026-07-28 / PR #37 |
| T031 | indexには残るがworking treeから欠落したtracked targetを固定のredactedエラー + exit 1へ fail closed。actual git fixtureでworking fileだけを削除し、path非出力を回帰検証 | 2026-07-28 / PR #39 |
| T032 | scanner 自身の blanket self-exemption を廃止。scratch copy 自身へ runtime 合成 marker を置く回帰で修正前 RED、値非反射、通常 scan、PowerShell 7 / Windows PowerShell 5.1 を確認 | 2026-07-29 / PR #41 |
| T033 | 資料読み順を `CODEX_START_HERE.md` の単一の正本へ集約。`AGENTS.md` / `HANDOFF.md` / 日付付き起動プロンプトを正本参照へ寄せ、public-readiness に順序と参照の drift 検査を追加 | 2026-07-29 / PR #43 |
| T034 | README / AGENTS のvisible heading＋最初のPowerShell fence/bodyと、CI `validate` job / 4 steps / 3 exact runを構造照合。production正常系1件＋table-driven 21件をfailure 0で確認し、PowerShell 7 / Windows PowerShell 5.1のcheck:allもpass | 2026-07-29 |
| T035 | checkoutを公式v4.4.0の完全SHAへ固定し、credentials非保持・10分timeout・exact contractを追加。CRLF fixture harnessをLF正規化し、PR / main CI成功後にfeature branchをlocal / remoteから削除、feature worktreeを通常remove 1回で削除 | 2026-07-30 / PR #47 / feature merge `78e789e` |
| T036 | Validation workflowのname、pull-request／main push、`contents: read`をexact contractへ追加。追加trigger／branch／tag、permission欠落・拡大・重複を13負例で拒否し、両PowerShell hostの47件とcheck:allをpass。PR / main Validation成功後にfeature branch / worktreeを削除 | 2026-07-30 / PR #49 / feature merge `3cf264c` |

## 検証ログ（直近のみ・過去分は git 履歴を参照）

| コマンド | 結果 |
| --- | --- |
| T037 TDD RED | v7.0.1 exact contractを先行させ、旧v4.4.0 workflowがPowerShell 7 / Windows PowerShell 5.1で各1件failすることを確認 |
| T037 focused GREEN | v7.0.1 workflow、mutable v7、旧v4.4.0 pin、誤SHA、comment欠落を含むtable-driven 48件が両PowerShell hostでpass、failure 0 |
| T037 PowerShell 7 / Windows PowerShell 5.1 check:all | 2026-07-30 pass（6コマンドすべて exit 0） |
| T037 Gitleaks / Semgrep / actionlint | Gitleaks worktree / 61 commitsはfinding 0。Semgrepは対象拡張子なし。actionlintは未確認 |
| T036 TDD RED | 新規top-level負例13件が変更前parserでfail-openすることをfocused harnessで確認 |
| T036 focused GREEN | production正常系、LF / CRLFを含むtable-driven 47件がPowerShell 7 / Windows PowerShell 5.1でpass、failure 0 |
| T036 PowerShell 7 / Windows PowerShell 5.1 check:all | 2026-07-30 pass（6コマンドすべて exit 0） |
| T036 PR #49 / `main` Validation | feature commit `28e272a`のPR run `30514640965`、merge `3cf264c`のmain run `30514729429` ともに success |
| T036 security / cleanup | private marker 0、Gitleaks worktree / history 0、Semgrep対象なし、global hook pass。feature branchはlocal / remoteともに不存在、feature worktreeは通常remove 1回で削除。actionlintは未確認 |
| PR #47 初回 Validation | run `30484328603` failure: CRLFで`missing timeout` / `missing checkout credentials block`の負例生成がno-op。production parserのfailureではない |
| PR #47 更新 / `main` Validation | corrective run `30485126958`、feature merge `78e789e` のmain run `30485204225` ともに success |
| T035 feature cleanup | feature branchはlocal / remoteともに不存在、feature worktreeは通常の`git worktree remove`を1回だけ実行して削除 |
| T035 check:all contract focused assertion | production正常系1件＋LF / CRLFを含むtable-driven 34件がpass、failure 0 |
| T035 PowerShell 7 / Windows PowerShell 5.1 check:all | 2026-07-30 pass（6コマンドすべて exit 0） |
| T035 workflow不変条件比較 | trigger / permission / job / runner / 4 steps / 3 commandsの維持と、timeout / checkout pin / credentials無効化だけの追加を確認 |
| T035 Gitleaks / Semgrep | Gitleaks directory scan: no leaks、Semgrep local security rules: exit 0 |
| T035 actionlint | 既知の実行ポリシー拒否により未確認（再試行・代替取得なし） |
| T034 check:all contract focused assertion | production正常系1件＋table-driven 21件がpass、failure 0 |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | 2026-07-29 T034 pass: `Public readiness checks passed.` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | 2026-07-29 T034 pass: `Private marker scanner tests passed.` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | 2026-07-29 T034 pass: `No private or secret markers found.` |
| Windows PowerShell 5.1 による check:all 3本 | 2026-07-29 T034 pass（PowerShell 7と合わせた6コマンドすべて exit 0） |
| T033 staged security checks | Gitleaks pass（no leaks）、Semgrep skip（対象拡張子なし）、global hook pass |
| PR #43 / `main` Validation | PR run `30424681772`、merge commit run `30424727678` ともに success |
| T033 `git diff --check` / `git diff --cached --check` | 2026-07-29 pass |
| `gh pr list --state open` / `gh issue list --state open` | 2026-07-29 T033 統合後はいずれも 0件 |

## skip

該当なし。

## 外部レビュー指摘の台帳（2026-07-15 maxエフォート横断レビュー）

読取専用レビュー（実行検証なし）の指摘。採否と実装は次担当が判断する。完了時は行頭を [x] にし、対応PRを追記する。4件とも PR #28 で対応済み。

- [x] scan-private-markers.ps1:77-80 — fallback(walk)モードの除外にdocsが入っているが本repoのdocs/は追跡済み(git不在環境で検査ギャップ)。最小修正: 除外からdocsを外すかコメント修正。confidence高（除外からdocsを外し、コメントを実態へ修正。walkモードでdocs/配下のmarkerを検出する自己テスト追加）
- [x] 同:241-244 — ErrorActionPreference=Stop下のWrite-Errorはthrowし、& 呼び出し元セッションを巻き添え終了。最小修正: Write-Host+exit 1。confidence高/実害低（Write-Host+exit 1へ変更）
- [x] 同:198 — Get-Contentにエンコーディング指定なし(PS5.1でBOMなしUTF-8日本語のCJK検出劣化)。最小修正: -Encoding UTF8。confidence中（-Encoding UTF8を明示）
- [x] 同:46-47 — (ドライブ文字+Users)型パスが2ルール二重ヒットし報告重複。confidence高（汎用ルールに`(?!Users\\)`の除外を追加し専用ルールのみが報告。二重ヒット解消＋非Usersパス検出維持の自己テスト追加）
