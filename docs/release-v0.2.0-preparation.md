# v0.2.0 リリース準備

作成日：2026-07-22 JST
状態：リリースノート案と実行手順の準備済み。ゲート①の承認待ち。

変更内容の正本は `CHANGELOG.md` である。
本書は GitHub Release 本文案、最終化手順、承認依頼の正本とする。

2026-07-22 の実測では、最新の tag と GitHub Release は `v0.1.0` である。
`v0.2.0` の tag と GitHub Release は作成していない。

## GitHub Release 本文案

----- GitHub Release 本文ここから -----

## v0.2.0

日本語 Web UI を「見た目の生成」ではなく、検証証拠に基づく合否ゲートとして評価する v2 です。

### 主な変更

- `SKILL.md` を 7 つの評価軸へ再構成しました。
  日本語 UI コピー、日本語の表示と組版、日本のフォーム入力、アクセシビリティの基本、レンダリング検証、正直な報告、安全な停止条件を扱います。
- `references/checklist.md` に 80 項目の詳細チェックリストを追加しました。
  `SKILL.md` 単体でも機能し、参照ファイルを読める環境では詳細項目を段階的に読み込めます。
- 郵便番号と電話番号の先頭ゼロ、ハイフンと全角半角、フリガナ、`autocomplete`、遠い日付の入力など、日本向けフォームの観測可能な基準を追加しました。
- WCAG 2.2 のうち UI review で観測できる最小集合を具体化しました。
  WCAG または JIS X 8341-3 の適合試験や適合宣言ではありません。
- 合成の fail 例と passing 例、レビュー依頼、最終報告テンプレートを v2 の 7 軸へ同期しました。

### 検証と公開安全

- private-marker scanner は git-tracked file を既定の対象にし、`git ls-files` が失敗した場合や、列挙された tracked target が working tree から欠落している場合は、未検査の対象を成功扱いせず fail closed に停止します。行番号、binary-like file の除外、主要な credential marker の検出も追加しました。
- scanner の回帰 harness は現在の PowerShell 実行ファイルを再利用し、Windows PowerShell 5.1 検証が内部で PowerShell 7 に委譲されないようにしました。
- scanner の filesystem fallback、UTF-8 読み取り、重複報告、失敗時の終了処理を修正しました。
- scanner 自身の blanket self-exemption を廃止し、scanner source に marker 候補が混入した場合も、ほかの公開対象と同じく fail closed に検出します。
- public-readiness は top-level の番号付き評価軸と、marker 後 indent が tab-stop 換算1–4列の未チェック hyphen 項目だけを構造的に数えて README の数値表記と比較します。親項目の content column 以深にあるnested checkbox、fence / HTML block 内の例示、list item 内のparagraph / Setext / Type 7をtop-level件数へ含めません。0–3-space fence、labelがCommonMark上限の999文字以内で安全に証明できる単行link reference subset、space / tab 区切りの hyphen / asterisk thematic break は受理し、active axis内の非canonical container、複数行link reference、4列/TAB開始leafなど安全に確定できない構造だけを固定エラーと0件へ fail closed します。Setext heading は直前paragraphが top-level と証明できる場合だけ軸scopeを終了します。
- 資料の読み順は `CODEX_START_HERE.md` を単一の正本とし、public-readiness はその順序に加えて、README、`AGENTS.md`、Validation workflow の copy-paste可能な検証契約を照合します。
- Validation workflow は名前、pull request と `main` push、`contents: read`、10分のtimeout、認証情報の非保持を固定し、`actions/checkout` はNode.js 24対応のv7.0.1 verified commitへpinして、mutable tag、旧pin、誤ったSHAをexact contractで拒否します。

### 利用者向け補足

- 既存のインストールを更新するときは、現在の `SKILL.md` と `references/checklist.md` を比較し、必要ならバックアップを作成してから置き換えてください。
- 本 skill はビジュアルデザイン生成、デザインシステム、法務判断、セキュリティ監査、WCAG または JIS の適合認証を提供しません。
- 詳細な変更は `CHANGELOG.md` を参照してください。

----- GitHub Release 本文ここまで -----

## 承認後の最終化手順

1. `main` を最新化し、worktree、open PR、open issue、CI を再確認する。
2. release finalization branch を作成し、`CHANGELOG.md` の v0.2.0 candidate を実際のリリース日付き `## [0.2.0] - YYYY-MM-DD` へ移す。
3. 本文案から draft 用の区切りと状態説明を除き、`docs/release-v0.2.0-notes.md` として最終化する。
4. check:all 3本、`git diff --check --cached`、global security hook、PR CI を pass させる。
5. finalization PR を merge し、clean な `main` の merge commit に annotated tag `v0.2.0` を作成する。
6. tag を push し、本文案で GitHub Release を公開する。
7. tag、Release、`main` CI、clean tree、remote branch cleanup を再確認する。

承認後に使うコマンドの骨格：

```powershell
git switch main
git pull --ff-only origin main
git switch -c docs/v0-2-0-finalize
# CHANGELOG と release note を最終化し、check:all、commit、PR、CI、merge を完了する
git switch main
git pull --ff-only origin main
git tag -a v0.2.0 -m "v0.2.0"
git push origin v0.2.0
gh release create v0.2.0 --title "v0.2.0" --notes-file docs/release-v0.2.0-notes.md
```

## ゲート①承認依頼

【承認依頼 / ゲート①】

- やりたいこと：`v0.2.0` の annotated tag を push し、GitHub Release を公開する。
- 該当ゲートと理由：release と tag の発行は `AGENTS.md` §6 のゲート①に該当するため。
- 影響範囲 / リスク：公開済みの commit が `v0.2.0` として固定され、GitHub の latest Release が更新される。誤りがあれば tag の削除ではなく、原則として修正版を追加 release する必要がある。
- 代替案（ある場合）：承認しない場合は `[Unreleased]` の v0.2.0 candidate と本文案を保持し、公開済み latest Release は `v0.1.0` のままにする。
- 承認後に実行する具体コマンド/手順：上記「承認後の最終化手順」に従い、finalization PR の merge 後に `git tag -a v0.2.0 -m "v0.2.0"`、`git push origin v0.2.0`、`gh release create v0.2.0 --title "v0.2.0" --notes-file docs/release-v0.2.0-notes.md` を実行する。
- 追加費用見込み：0円。
  GitHub の既存公開リポジトリで tag と Release を作成する操作のみで、有料 API、有料サービス、従量課金機能は使わない。
- 承認後の最初の安全なコマンド：`git switch main`。
