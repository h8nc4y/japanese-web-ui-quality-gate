# Advisory review disposition

確認日: 2026-06-30 JST（追記: 2026-07-12 文書整理）

## 結論

未追跡の advisory 原本 `docs/CLAUDE_CODE_REVIEW_2026-06-21.md` と `docs/codex-task-scanner-hardening.md` は、raw のまま公開成果物へ採用しない。PR #12〜#15 までに scanner hardening と現状同期は完了しており、残す価値があるのは「どの指摘をどう扱ったか」の短縮・redacted な判断記録だけである。

そのため、本ファイルだけを tracked docs とし、raw advisory 2件は `.gitignore` で誤stageを防ぐ。

## 原本の扱い

| ローカル原本 | 扱い | 理由 |
| --- | --- | --- |
| `docs/CLAUDE_CODE_REVIEW_2026-06-21.md` | 未追跡のまま ignore | 静的レビュー全文。古い未確認事項や再現用の説明が含まれるため、公開docsへ丸ごと採用しない |
| `docs/codex-task-scanner-hardening.md` | 未追跡のまま ignore | 017/018/019/020 横断の委譲タスク仕様。017側の該当対応はPR #12〜#15で要約済み |

## 指摘別の処理

| 指摘 / テーマ | 現在の判断 | 証跡 |
| --- | --- | --- |
| scanner の作業ツリー走査とCI checkoutの乖離 | 対応済み。現行 scanner は git-tracked default で、untracked docs は stage されるまで走査しない | `scripts/scan-private-markers.ps1`, `SECURITY.md`, `README.md` |
| secret marker recall / false positive / binary handling | 対応済み。追加marker、binary skip、line number、`task-scanner` slug false-positive抑制は現行 scripts / tests に反映済み | `scripts/test-scan-private-markers.ps1`, `scripts/scan-private-markers.ps1` |
| cleanup失敗が検証結果を隠す問題 | 対応済み。PR #12で cleanup境界を整理し、tracked-marker assertion は fail-fast のまま保持 | `TASKS_BACKLOG.md` T009, `HANDOFF.md` |
| 本レビュー追加後の `check:all` 再実行 | 対応済み。PR #15までの検証履歴に加え、本disposition PRでも再検証する | `HANDOFF.md` / `TASKS_BACKLOG.md` の検証ログ |
| GitHub private vulnerability reporting のrepo設定 | 未確認。GitHub repository settings側の状態であり、docs更新PRでは変更しない | `SECURITY.md` はprivate reportingが使える場合の導線とpublic fallbackを記載済み |

## 2026-07-12 文書整理

オーナー指示による docs 全体整理として、tracked の陳腐化文書3件を削除した。内容は git 履歴に保存されており、必要な事実は下表の反映先に残っている。

| 削除ファイル | 理由 / 反映先 |
| --- | --- |
| `NOTES_CLAUDE.md` | scanner hardening 実装スライスの作業メモ。実装内容は `scripts/` と `SECURITY.md`、判断記録は本書と `CHANGELOG.md` に反映済み |
| `docs/CLAUDECODE_HANDOFF.md` | 世代交代用の汎用引き継ぎ文書。運用契約は `AGENTS.md`、現況スナップショットは `HANDOFF.md` に一本化 |
| `docs/CODEX_PROMPT_2026-07-11.md` | `docs/CODEX_PROMPT_2026-07-12.md` へ置き換え（残タスクの変化を反映） |

未追跡・ignore 済みのローカル原本（本書「原本の扱い」の2件、および旧引き継ぎドラフト2件）の扱いは従来どおり変更しない（track しない・raw 採用しない）。

## 今後の扱い

- raw advisory 原本を後から track しない。必要な事実だけを、この disposition doc か `TASKS_BACKLOG.md` に圧縮して追記する。
- scanner のセキュリティ判定ロジックを変える場合は、`AGENTS.md` §10 の外部レビュー基準に従う。
- release/tag、workflow権限変更、UI成果物新設、secret/実データ、有料APIは引き続きゲート対象とする。
