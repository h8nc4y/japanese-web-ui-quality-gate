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

自律エージェント（例: Codex）が主開発者。資料読み順の唯一の正本は [`CODEX_START_HERE.md`](CODEX_START_HERE.md) であり、その先頭に従って **最初に [`AGENTS.md`](AGENTS.md) を読むこと。** 要点:

- タスク選定 → 実装 → check:all → 敵対的セルフレビュー → 日本語コミット → PR → マージまで承認なしで自走（§4）。
- 4ゲートのみ人間承認（§6）: ①デプロイ/Actions/release・tag ②課金・有料API ③secret・実素材・実データの外部送信 ④製品要件の変更。
- 検証していない主張は書かず `未確認` と明記（§1・§8）。

## 確認済みスナップショット（2026-07-30 JST 実測）

- 既定ブランチ `main` は T036 feature merge `3cf264c` まで確認済み。T001–T036 は統合済みで、統合後の open issue / open PR は0件。
- T036（Class M）では、Validation workflow の `name: Validation`、`pull_request`、`main` push、`permissions.contents: read` をpublic-readinessのexact contractへ追加した。workflow dispatch、schedule、追加branch、tag filter、permission欠落・write化・追加・重複を含む新規13負例は変更前parserでRED、実装後はproduction正常系とLF / CRLFを含むtable-driven 47件がPowerShell 7 / Windows PowerShell 5.1でGREEN。workflow自体、既存job / runner / timeout / action pin / credentials / step / command、release / tagは変更していない。PR #49のValidation run `30514640965` とmerge後のmain run `30514729429` はsuccess。feature branchはlocal / remoteともに削除し、feature worktreeは通常の`git worktree remove`を1回だけ実行して削除済み。
- T035（Class M）では、Validation workflow の checkout を `actions/checkout` v4.4.0 の完全SHAへ固定し、認証情報を保持せず、job timeoutを10分へ制限した。trigger / permission / job / runner / step / commandは変更していない。public-readiness のexact contractとLF / CRLFを含む34件のtable-driven fixtureも同期した。PR #47の初回run `30484328603` はCRLFで負例生成がno-opになるfixture harnessの問題によりfailure。LF正規化とCRLF正常系を追加したcommit `0acebcb` 後、PR run `30485126958` とmain run `30485204225` はsuccess。PowerShell 7 / Windows PowerShell 5.1のcheck:all 6コマンド、Gitleaks、Semgrep、独立レビューもpassした。actionlintは既知の実行ポリシー拒否により未確認（再試行・代替取得なし）。feature branchはlocal / remoteともに削除し、feature worktreeは通常の`git worktree remove`を1回だけ実行して削除済み。
- T034（Class M）では、README `Validation` 節と `AGENTS.md` §7のvisible heading＋最初のPowerShell fence/bodyをexact copy-paste契約として結び、CI `validate` job / 4 steps / 3 runも構造照合する。HTML comment/raw HTML/fence decoy、case/長いfence、無効化、余分なrun、block scalar等を含むproduction正常系1件＋table-driven 21件はfailure 0。PowerShell 7 / Windows PowerShell 5.1のcheck:all 3本も各hostでpassした。workflow、release、tag、スキル本体の挙動は変えていない。
- T033 では、資料読み順を `CODEX_START_HERE.md` の単一の正本へ集約し、`AGENTS.md` / `HANDOFF.md` / 日付付き起動プロンプトを正本参照へ変更した。public-readiness は正本の順序と各参照元を検査し、PowerShell 7 / Windows PowerShell 5.1 の両方で pass した。
- T032 では、実行中の scanner file を常時走査対象外にする blanket self-exemption を廃止し、scanner 自身へ混入した marker 候補も fail closed に検出するようにした。scratch copy 自身を走査する合成回帰で修正前 RED、値非反射、PowerShell 7 / Windows PowerShell 5.1、通常 repository scanを確認した。
- T022 では checklist 実項目数と軸数を README の数値表記と固定値なしで相互比較する public-readiness 検証を追加。
- T026 では軸数抽出を `## 1. ...` 形式の番号付き H2 に限定し、補助 H2 とコードフェンス内の見出し風テキストを除外。公開文書の読み取りを UTF-8 に固定し、PowerShell 7 / Windows PowerShell 5.1 の判定を一致させた。
- T027 では項目数抽出も top-level の番号付き評価軸内へ限定し、marker 後 indent が tab stop 換算1–4列の未チェック hyphen 項目だけを数える。受理した親項目の content column を保持し、その列以深の canonical checkbox は nested item として除外する。blank 後を含む list item 内paragraph / Setext heading / inline Type 7 HTML はtop-level scopeへ昇格させず、0–3-space fence、raw HTML block、labelがCommonMark上限の999文字以内で安全に証明できる単行 link reference subset は受理する。active axis 内の checked / 空項目、alternate marker、post-marker indented code を含む非canonicalな list / blockquote container 行と、複数行link referenceや4列/TAB開始leafなど未確定構造だけを固定エラー + 0件へ fail closed する。Setext heading は直前paragraphが top-level と証明できる場合だけ軸scopeを終了し、その後のType 7 blockは軸外として扱う。軸数と項目数は同じ構造解析から導出する。
- T028 では日付付き起動プロンプトに残っていた T024/T025 時点の完了範囲・検証日・tag/Release状態の重複スナップショットを除去した。新しいセッションは `HANDOFF.md` / `TASKS_BACKLOG.md` / check:all / Git/GitHub を起動時に実測し、古いプロンプト本文を現在値として使わない。
- T023 の 2026-07-22 再調査では、汎用 UI review skill に日本語組版と日本固有フォームの本格採用を確認できず、反証条件は非該当。
  日本語タイポグラフィの隣接資料は増えているため、既存方針どおり合否、フォーム、検証証拠、正直な報告の組み合わせを差別化の中心に維持。
- T024 では `CHANGELOG.md` の `[Unreleased]` を v0.2.0 candidate として明示し、リリースノート案、最終化手順、ゲート①承認依頼を `docs/release-v0.2.0-preparation.md` に整理。
  `v0.2.0` の tag と GitHub Release は作成していない。
- T029 では、番号付き軸内の有効な空白区切り thematic break（`- - -` / `* * *`）が非対応 container として固定エラーへ倒れる false positive を修正した。同一 marker 3個以上、先頭0–3 space、marker間 space / tab、末尾 whitespace だけを受理し、3個未満・末尾文字付き・通常の非canonical container は固定エラー + 0件へ fail closed する。
- T029 は PR #35（merge commit `161ddf2`）で統合済み。統合後の open issue / open PR: 0件。doing タスク: 0件。
- T030 では、`git ls-files -z` の非0終了を無視して検査対象0件を成功扱いし得る fail-open 経路を修正した。fake gitのWindows / Unix fixtureで固定メッセージ + exit 1、PATH復元、native stderr非出力を検証し、通常の空tracked listは成功のまま維持した。test harnessは現在のPowerShell実行ファイルを再利用し、Windows PowerShell 5.1検証がPowerShell 7へ委譲されないようにした。
- T030 は PR #37（merge commit `a817a57`）で統合済み。統合後の open issue / open PR: 0件。doing タスク: 0件。
- T031 では、indexではtrackedのままworking treeから欠落したscan targetを黙ってskipし、未検査の公開対象をgreenにし得るfail-open経路を修正した。actual git fixtureでworking fileだけを削除し、固定のredactedメッセージ + exit 1とpath非出力をPowerShell 7 / Windows PowerShell 5.1で検証した。
- T031 は PR #39（merge commit `132913f`）で統合済み。統合後の open issue / open PR: 0件。doing タスク: 0件。
- 最新の tag と GitHub Release は `v0.1.0`。
- `references/checklist.md` は実測80項目・7節で README の表記と一致。
- check:all 3本（§7）は 2026-07-30 T036 で PowerShell 7 / Windows PowerShell 5.1 ともにpass（6コマンドすべてexit 0）。T036はcommit `28e272a`、PR #49、merge `3cf264c`、PR / post-main Validation successまで確認済み。actionlintは未確認。
- 2026-07-12 に文書整理を実施: 陳腐化した tracked 文書3件を削除し（判断は `docs/advisory-review-disposition.md`）、台帳と本文書をスリム化。

## 未完了・承認待ち（次の担当エージェントへの引き継ぎ）

通常実装タスクのdoingは0件。未完了はゲート①承認待ちのリリース操作だけ。
次のリリース操作は `AGENTS.md` §6 のゲート①に該当する。

1. **v0.2.0 リリース最終化**: 人間がゲート①を明示承認した場合だけ、`docs/release-v0.2.0-preparation.md` の手順に従って最終化 PR、tag 発行、GitHub Release 作成を進める。
2. 承認がない場合は tag と GitHub Release を作成せず、通常のローカル安全な改善ループだけを継続する。

## 既知の問題・残懸念

- 本リポジトリに UI ソースは無いため、ブラウザ表示確認は通常対象外。ただし `AGENTS.md` §2 の二層構造に注意: skill が「適用される対象」には日本向け Web UI が含まれるため、`SKILL.md` 内の UI 検証観点を「対象外」と誤判断しない。
- `HANDOFF.md` / `TASKS_BACKLOG.md` は確認時点のスナップショット。PR番号だけを追う自己同期 PR は作らない。
- JIS X 8341-3 改正後の確定内容は未確認。WAIC の 2026-06-08 公開情報でも改正は検討段階（`docs/requirements-redefinition-2026-07.md` §4.1 / §9）。
- v0.2.0 の公開日は未確定。ゲート①承認前に changelog の日付、tag、GitHub Release を確定しない。
- `scripts/test-public-readiness.ps1` は PS 5.1 で日本語コメントを正しく解釈させるため UTF-8 BOM 付き。ほかのテキストを一括で BOM 付きへ変換しない。

## 検証コマンド

ビルドや package manager は無し。検証は `AGENTS.md` §7 の check:all 3本:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

直近の実行結果は `TASKS_BACKLOG.md` の検証ログを参照。Windows PowerShell 互換実行例は README の `Validation` セクションを参照。

## 次にやるべきこと

1. ゲート①未承認の間は v0.2.0 のtag / GitHub Releaseを作成しない。
2. 通常のローカル安全な改善候補が生じた場合は、Git / GitHub / check:allを再実測して次のtaskを採番する。
