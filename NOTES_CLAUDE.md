# NOTES_CLAUDE — scanner hardening (017)

実装担当 (Claude Opus 4.8) による自走スライスのメモ。コミットはオーケストレーターが行う。

## 実装済み（自走スライス、AGENTS §6 で自走可な安全側変更）
- `scripts/scan-private-markers.ps1`
  - 新H-A: 既定で **git-tracked ファイルのみ走査**（`git ls-files -z`）。CI checkout と手元実行の対象を一致。git working tree 外/git 不在時は従来のファイルウォークにフォールバック（除外集合に `docs`/`.claude`/`.codex` を追加し .gitignore 意図と整合）。`-NoGit` スイッチでフォールバック強制（主にテスト用）。走査モードを stdout に出力。
  - 新H-B: AWS `AKIA`、GCP `AIza`、Slack `xox[pabr]-`/`xapp-`、Stripe `(sk|rk)_live_`、PEM `BEGIN (RSA|EC|OPENSSH|ENCRYPTED|DSA) PRIVATE KEY` を追加。
  - 偽陽性抑制: email に語境界(`\b`)＋allowlist（`example.*`/`noreply@`/`users.noreply.github.com`）。Bearer は値8文字以上が続く場合のみ。
  - `-Raw` 全読 → 行単位読込＋**行番号付き出力**（M2）。
  - text 限定: バイナリ拡張子除外＋NUL バイト検出でバイナリスキップ（H2）。
  - 自己免除孔なし: scanner 自身のファイルのみスキップ（020 の no-blanket-exempt 方針に整合。`scanner-marker` 行丸ごと免除のような孔は作っていない）。プレフィックスは文字列連結で分割し literal を持たない。
- `scripts/test-scan-private-markers.ps1`: 新プレフィックス各々に「検出する／値は出力に漏れない（redaction）」回帰、email allowlist/実email、bare Bearer、バイナリスキップ、行番号、git-tracked vs tracked（一時 git repo で検証、git 不在時はスキップ＝未確認表示）を追加。既存の合成 fixture スキャンは `-NoGit` 指定（fixture は未追跡 .test-tmp 配下のため）。
- `SECURITY.md`: 走査が git-tracked 既定であること＋best-effort（全 secret 形式は保証しない）注記。

## ベストエフォート検証（無課金・無ネットワーク）
- `pwsh` parser で両 ps1 構文 OK。
- `scripts/test-scan-private-markers.ps1` → 全パス（EXIT 0）。
- リポジトリルートから `scripts/scan-private-markers.ps1` → `Scan mode: git-tracked` / `No private or secret markers found` / EXIT 0。
- 未追跡 `docs/` に私的絶対パス＋私的 repo 名を置いた状態でも scan は EXIT 0（H-A 実害シナリオの解消を実証）。tracked にすると検出（テストで担保）。
- `scripts/test-public-readiness.ps1` → パス（EXIT 0）。

## ゲート④（製品要件変更）/ 人間承認待ち
- **「scan passed」の意味の変更**: 走査対象が「作業ツリー全体」→「git-tracked のみ」に変わる。これは spec の「Do not stop for（git-tracked 限定走査）」で自走可とされた範囲だが、**HANDOFF.md / CHANGELOG.md に「scan は tracked 限定」と明記する文章追記**は docs 整合作業としてオーケストレーター側で実施推奨（本スライスでは HANDOFF/CHANGELOG は未編集＝READ範囲外の台帳更新を避けた）。
- `.gitignore` は**未変更**。git-tracked 方式では docs/.claude/.codex の ignore 整合は冗長で、`docs/` を ignore すると正当な公開 docs を隠すため、あえて触っていない。除外整合を別途望むならゲート判断（人間）に委ねる。
- CI shell 統一・assert-oss-ready・空ツリーハッシュ等の drift 項目は **019 固有**で本 repo (017) には非該当（workflow は `validation.yml` 1本で既に `shell: pwsh`、assert-oss-ready.ps1 は存在しない）。

## 残リスク
- git-tracked 方式は「staging されていない作業中の秘匿ファイル」を見ない（設計通り＝CI と一致）。コミット前のローカル秘匿混入は防げないが、`git add` 済みなら検出される。SECURITY.md にその旨記載。
- Windows-absolute-path / generic path の偽陽性は据え置き（spec で誤前提と整理済み、過検知側）。doc でのパス例示制約は M1 のまま。
