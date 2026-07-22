# Codex 引き継ぎプロンプト（2026-07-12）

作成日: 2026-07-12 JST
状態更新: 2026-07-22 JST
対象モデル: Codex（GPT-5.6 Sol）
対象タスク: T023–T024（受け入れ条件の正本は `TASKS_BACKLOG.md`）
現状の正本: `HANDOFF.md`（T022 完了後の 2026-07-22 状態へ同期済み）

## 使い方

1. Codex アプリで**新規チャット**を作成する（新しい長期作業単位のため）。
2. インテリジェンス（reasoning）は **高** を選ぶ。
3. 下の Goal ブロックを通常チャット欄に貼り付ける。

## Prompt

```text
Goal
公開OSSリポジトリ japanese-web-ui-quality-gate の主開発者として開発を引き継ぎ、TASKS_BACKLOG.md の未完了タスク T023 → T024 を AGENTS.md の自律ループに従って完了させてください。報告の冒頭には現在の日本時間を YYYY/MM/DD HH:MM:SS で付けてください。

Context
- 最初に AGENTS.md（運用契約）を読む。次に HANDOFF.md（資料マップと現況）→ TASKS_BACKLOG.md（受け入れ条件の正本）→ README.md → SKILL.md → docs/requirements-redefinition-2026-07.md の順。
- 2026-07-22 時点: SKILL.md は v2（7軸構成）、references/checklist.md は80項目・7節で README の表記と一致（実測済み）。T001–T022 と T025 は done。T022 で、checklist の実項目数と軸数を README の数値表記と固定値なしで相互比較する public-readiness 検証を追加済み。
- 残タスク要約: T023=汎用競合skillの日本語対応動向を再調査し反証条件（要件再定義 §4）への該当有無を時点付きで記録、T024=v0.2.0 リリース準備（CHANGELOG整理・リリースノート案・§6形式の承認依頼文の作成まで）。

Autonomy policy
AGENTS.md §4–§10 に従い、タスク選定 → 実装 → check:all → 敵対的セルフレビュー → 日本語コミット → PR → CI緑でマージ → ブランチ削除まで承認なしで自走する。doing は常に1件、1 PR = 1 改善。HANDOFF.md / TASKS_BACKLOG.md の更新も承認不要。

Stop only when
AGENTS.md §6 の4ゲートに該当するときだけ停止する: ①release/tag発行・deploy/publish系Actions・workflow権限変更 ②課金・有料API ③secret/実素材/実データの外部送信 ④製品要件の変更。T024 はリリースノート案と承認依頼文を用意した時点で停止し、§6 のフォーマットで承認を仰ぐ（タグ発行・release 作成は実行しない）。T023 で反証条件に該当する動きを発見した場合も、記録までで停止する（対応方針の変更はゲート④）。同一の失敗が3回改善しないときも停止して報告する。

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
2. TASKS_BACKLOG.md から §5 の優先度ルールに従いタスクを1件選び、doing として記録する。
3. type/short-kebab のブランチを切り、受け入れ条件を満たす最小の変更を実装する。挙動やユーザー向け案内が変わるときは README.md / SKILL.md / examples / CHANGELOG.md をセットで更新する。
4. check:all 3本を緑にし、AGENTS.md §10 の敵対的セルフレビューを行う。
5. 日本語コミット → PRテンプレートに実測の検証結果を記入 → CI緑・セルフレビュー合格でマージ → ブランチ削除。
6. TASKS_BACKLOG.md を done に更新し、区切りで HANDOFF.md を更新して次のタスクへ進む。

Done when
- T023 が main にマージ済みで、受け入れ条件を満たしている。
- T024 のリリースノート案と §6 形式の承認依頼文が用意され、タグ発行の承認待ちで停止している。
- TASKS_BACKLOG.md / HANDOFF.md が最新状態に同期され、check:all 3本と CI が緑、open PR 0件である。
```
