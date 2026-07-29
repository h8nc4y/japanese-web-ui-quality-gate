# Codex 引き継ぎプロンプト（2026-07-12）

作成日: 2026-07-12 JST
状態更新: 2026-07-27 JST
対象モデル: Codex（GPT-5.6 Sol）
対象タスク: v0.2.0 リリース最終化（ゲート①の明示承認後のみ）
現状の正本: `HANDOFF.md` と `TASKS_BACKLOG.md`（本プロンプトには完了タスク範囲や検証日のスナップショットを重複保持しない）

## 使い方

インテリジェンス：高
Codexのチャット：新規チャット欄を作成

1. Codex アプリで**新規チャット**を作成する（新しい長期作業単位のため）。
2. インテリジェンス（reasoning）は **高** を選ぶ。
3. 下の Goal ブロックを通常チャット欄に貼り付ける。

## Prompt

```text
Goal
公開OSSリポジトリ japanese-web-ui-quality-gate の主開発者として開発を引き継いでください。v0.2.0 のリリース最終化は、現在のユーザーが AGENTS.md §6 のゲート①を明示承認した場合だけ実行してください。報告の冒頭には現在の日本時間を YYYY/MM/DD HH:MM:SS で付けてください。

Context
- `CODEX_START_HERE.md` の「読み順（唯一の正本）」を使う。同一覧の先頭に従って最初に `AGENTS.md` を読み、以降も列挙順に進む。このプロンプトには順序を重複保持しない。
- SKILL.md は v2（7軸構成）。checklist の実項目数・軸数、完了タスク範囲、直近検証日は、起動時の `HANDOFF.md` / `TASKS_BACKLOG.md` と check:all の実測から取得する。この日付付きプロンプトの過去スナップショットを現在値として使わない。
- `CHANGELOG.md` には v0.2.0 candidate があり、リリースノート案、最終化手順、ゲート①承認依頼の正本は `docs/release-v0.2.0-preparation.md`。内容と承認状態は起動時に読み直す。
- 最新の tag / GitHub Release と `v0.2.0` の有無は、`git tag` / `gh release list` で実測する。本文中の作成日や過去の記録だけで未作成と断定しない。

Autonomy policy
AGENTS.md §4–§10 に従い、タスク選定 → 実装 → check:all → 敵対的セルフレビュー → 日本語コミット → PR → CI緑でマージ → ブランチ削除まで承認なしで自走する。doing は常に1件、1 PR = 1 改善。HANDOFF.md / TASKS_BACKLOG.md の更新も承認不要。

Stop only when
AGENTS.md §6 の4ゲートに該当するときだけ停止する: ①release/tag発行・deploy/publish系Actions・workflow権限変更 ②課金・有料API ③secret/実素材/実データの外部送信 ④製品要件の変更。v0.2.0 の tag 発行と GitHub Release 作成はゲート①である。現在のユーザーによる明示承認がなければ、`docs/release-v0.2.0-preparation.md` の承認依頼を報告し、tag と Release を作成せず停止する。同一の失敗が3回改善しないときも停止して報告する。

Do not stop for
通常のコミット・push・PR作成・マージ・ブランチ削除、TASKS_BACKLOG.md / HANDOFF.md / CHANGELOG.md の更新、docs・examples・scripts のローカル改善、ローカル検証、Webでの無償の情報調査。

Constraints
- AGENTS.md §8 の公開安全規約を厳守: トークン・秘密鍵・メールアドレス・ローカル絶対パス・自リポジトリ以外の GitHub リポジトリURL・実顧客データを、コミット・PR・examples・issue のどこにも入れない。成果物内のパスはリポジトリ相対のみ。
- 検証していない主張は書かず「未確認」と明記する。
- git add -A を使わず変更ファイルを個別に add する。コミットは Conventional Commits の種別プレフィックス＋日本語要約（AGENTS.md §9）。
- scripts/scan-private-markers.ps1 / scripts/test-scan-private-markers.ps1 の marker 判定ロジックには触れない。触れる必要が生じたら AGENTS.md §10 の外部レビュー基準に従う。
- 検証は check:all 3本（AGENTS.md §7）: scripts/test-public-readiness.ps1 / scripts/test-scan-private-markers.ps1 / scripts/scan-private-markers.ps1 をすべて緑にしてから push する。
- タスクの受け入れ条件を変える必要が生じたら、変更前に TASKS_BACKLOG.md 上で理由つきで再定義し、ゲート④に触れないか自問する。

Work loop
1. git pull で main を最新化し、gh pr list / gh issue list / check:all 3本でベースラインを実測する（AGENTS.md §15）。文書のスナップショットより実測を正とする。
2. 現在のユーザーがゲート①を明示承認したか確認する。承認がなければ承認依頼を報告し、tag と Release を作成せず停止する。
3. 承認済みなら `docs/release-v0.2.0-preparation.md` の最終化手順に従い、release finalization branch で changelog とリリースノートを最終化する。
4. check:all 3本を緑にし、AGENTS.md §10 の敵対的セルフレビューを行う。
5. 日本語コミット → PRテンプレートに実測の検証結果を記入 → CI緑・セルフレビュー合格でマージ → ブランチ削除。
6. clean な `main` へ annotated tag を作成して push し、GitHub Release を公開する。tag、Release、CI、worktree、remote branch を実測で再確認する。

Done when
- ゲート①が未承認なら、承認依頼を報告し、`v0.2.0` の tag と GitHub Release を作成せず停止している。
- ゲート①が承認済みなら、v0.2.0 の最終化、tag 発行、GitHub Release 公開、事後検証が完了している。
- TASKS_BACKLOG.md / HANDOFF.md が最新状態に同期され、check:all 3本と CI が緑、open PR 0件である。
```
