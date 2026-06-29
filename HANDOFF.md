# HANDOFF.md

## リポジトリの目的

このリポジトリは、日本向けのWeb UI作成・レビュー時に使う Codex-style skill `japanese-web-ui-quality-gate` を公開可能な形で管理するためのものです。README、`SKILL.md`、サンプル、GitHub テンプレート、公開前チェック用 PowerShell スクリプトを含みます。

## 運用モデル（2026/06/20〜）

このリポジトリは **自律エージェント（例: Codex）が主開発者** として運用します。運用契約は [`AGENTS.md`](AGENTS.md) に記載し、エージェントは repo を開いた時点でまず `AGENTS.md` を読みます。要点:

- エージェントはタスク選定 → 実装 → 自己検証 → 日本語コミット → PR → マージまで承認なしで自走（§4）。
- フロントのビジュアルデザインはエージェントが創出せず、デザインブリーフを書いて停止し人手で外部デザイン工程へ渡す（§11・§12）。
- レビューは原則セルフ（`check:all` 緑＋敵対的セルフレビュー）。必要時のみ外部レビュー（§10・§13）。
- 4ゲートは人間承認を維持（§6）: ①デプロイ/Actions/release・tag ②課金・有料API ③secret・実素材・実データの外部送信 ④製品要件の変更。

## 現状サマリ

- 既定ブランチは `main`。2026/06/29 14:20 JST 時点で `main` は PR #12 merge commit `2be441b` まで `origin/main` と同期済み。現在の作業ブランチ `docs/sync-current-handoff-state` は、このhandoff/backlogの現状同期だけを行う。
- タスク棚卸し（`TASKS_BACKLOG.md` / 旧 `HANDOFF.md`）は PR #8 で `main` にマージ済み。棚卸し用ブランチ `chore-tasks-backlog-inventory` は削除済み。
- その後、自律運用契約 `AGENTS.md` を追加（このファイルの現状反映を含む）。
- `examples/checklist.md` に `SKILL.md` の `Design Baseline` 観点を反映しました。
- `CHANGELOG.md` の semantic versioning 説明を、v0.1.0 後の現状に合う表現へ更新しました。
- README、CONTRIBUTING、SECURITY、PR テンプレートの検証コマンド表記を canonical な `pwsh -NoProfile -ExecutionPolicy Bypass -File` 形へ統一しました。
- Claude Code の `fix/claude-scanner-hardening` を `main` に fast-forward 統合し、scanner の git-tracked 既定、secret 形式追加、行番号出力、バイナリ除外、`task-scanner` slug 偽陽性修正を反映しました。
- `TASKS_BACKLOG.md` に現在の doing タスクはありません。PR #12 の scanner hardening / cleanup境界整理は `main` に反映済み。未追跡 `docs/` の advisory docs 2件は、採用する場合も別PR候補として扱う。
- コード内 TODO / FIXME は実質的な未着手項目としては見つかっていません。
- GitHub open issues は 2026/06/29 14:20 JST 時点で 0 件。open PR も 0 件。PR #12 `fix/scanner-hardening-boundary` は `2be441b` で merge 済み。
- ローカル検証3本（§7）は 2026/06/29 に pass。PR #12 merge後の `main` push CI `Validation` run `28341292545` も success。

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
| `T011` PR #12 後の `HANDOFF.md` / `TASKS_BACKLOG.md` 現状同期 | done（このファイル） |

## 未完了 / skip タスク

該当なし。

## 既知の問題・残懸念

- UI実装はこのリポジトリには含まれないため、ブラウザ表示確認は対象外です（`AGENTS.md` §2 の二層構造・§11 参照）。
- 次の実装は `AGENTS.md` の自律ループ（§4・§5・§15）に従って進めます。

## 最終検証結果

2026/06/29 に以下を実行しました。

| コマンド | 結果 |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1` | pass: `Public readiness checks passed.` |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1` | pass: cleanup warningなし（権限付き再実行）。tracked-marker assertionも通過。 |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1` | pass: `No private or secret markers found.` |

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
| `main` | `origin/main` と同期済み。HEAD `2be441b` | v0.1.0 + タスク棚卸し + `AGENTS.md` + Claude scanner hardening / scanner cleanup境界整理まで反映済み |
| `docs/sync-current-handoff-state` | 現在の作業ブランチ | PR #12 後のhandoff/backlog現状同期のみ |

## 次にやるべき候補

1. §5 の優先度ルールに従い、既存ドキュメント/挙動の不整合・陳腐化を次の1件として探す。
2. doing は常に1件に保ち、`TASKS_BACKLOG.md` を起点に進める。現在の未追跡 `docs/` 2件は advisory docs としてこのPRから分離し、必要なら別PRで採用する。
3. §6 ゲート該当（release/tag・有料API・secret/実データ・製品要件変更）に当たったら停止して承認を仰ぐ。
