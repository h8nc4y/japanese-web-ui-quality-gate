# Changelog

All notable changes to this project are documented here.

The format follows a simple keep-a-changelog style, and this project uses semantic versioning for versioned releases.

## [Unreleased]

> v0.2.0 candidate. The `v0.2.0` tag and GitHub Release do not exist yet. Keep this section unreleased until gate ① approval, final verification, and release finalization.

### Added

- `docs/requirements-redefinition-2026-07.md` recording the 2026-07 requirements redefinition (market review, evaluation axes v2, success metrics, task breakdown).
- `references/checklist.md`: a new 80-item detailed checklist covering all 7 evaluation axes in `SKILL.md` v2, split out for progressive disclosure.
- `AGENTS.md` documenting the autonomous agent development workflow, `check:all` verification, and the human-approval gates.
- `docs/CODEX_PROMPT_2026-07-12.md`: a dated handoff prompt for the next autonomous agent session, updated after T024 to require explicit gate ① approval before v0.2.0 release finalization (supersedes the 2026-07-11 version).
- `examples/passing-review.md`: a synthetic passing applied example (an invented equipment-booking dashboard) showing guard items correctly applied so a sufficiently good UI is not unfairly failed, complementing the fail-heavy example in `examples/checklist.md`.
- `docs/release-v0.2.0-preparation.md`: the release-note draft, finalization checklist, and gate ① approval request for v0.2.0. No tag or GitHub Release is created by this preparation document.

### Changed

- `SKILL.md` rewritten as v2 around 7 evaluation axes (UI Language, Japanese Text Rendering, Japanese Form Input, Accessibility Essentials, Rendered Verification, Honest Reporting, Stop Conditions). The frontmatter `description` now states explicitly that this is a pass/fail quality gate, not a generation guide, and lists exclusion conditions. `Design Baseline` is folded into the other axes; Japanese text rendering, Japanese form input, and an observable WCAG 2.2 subset are new.
- `examples/review-request.md` synced to `SKILL.md` v2: the synthetic request now asks for all 7 evaluation axes (adding Japanese text rendering, Japanese form input, and accessibility essentials), aligns the mobile viewport wording with 375/390/414px, and asks for honest reporting with 未確認 markers. `examples/final-report-template.md` gains an "Axes covered" line so reports trace back to the 7 axes.
- `examples/checklist.md` changed from a generic checklist mirror into a synthetic applied example: a filled-in review of an invented Japanese member-signup form with representative pass/fail/未確認 findings across all 7 axes.
- `README.md` synced to `SKILL.md` v2: `What It Enforces` now lists the 7 axes with the 80-check total, `When To Use` gained an explicit "Not for" exclusion list, installation and update guidance now cover `references/checklist.md`, and multi-runtime portability (Codex, Claude Code, Gemini CLI, GitHub Copilot, and other SKILL.md-compatible runtimes) is stated more concretely. `Limitations` now states explicitly that this skill does not perform WCAG/JIS X 8341-3 conformance testing or legal/regulatory compliance judgment.
- The private-marker scanner now defaults to git-tracked files and fails closed when `git ls-files` cannot prove the tracked scan scope or when a listed tracked target is missing from the working tree. It skips binary-like files, reports line numbers, adds AWS/GCP/Slack/Stripe/PEM coverage, and avoids treating `task-scanner`-style slugs as OpenAI-style tokens. Its regression harness reuses the current PowerShell executable so Windows PowerShell 5.1 checks no longer delegate child scanner runs to PowerShell 7.
- The private-marker scanner no longer blanket-exempts its own script file. Its split marker definitions remain safe to scan, while an accidentally embedded marker candidate in the scanner source now fails closed like any other published file.
- Private-marker scanner hardening (2026-07-15 external-review ledger): the filesystem-walk fallback no longer excludes `docs/` (tracked content must stay in scope when git is unavailable), a user-profile Windows path is reported once by the dedicated rule instead of also hitting the generic Windows-path rule, file reads pin `-Encoding UTF8`, and the failure path reports via `Write-Host` + explicit `exit 1` instead of `Write-Error` under `ErrorActionPreference=Stop`.
- Public-readiness validation now derives the checklist item and axis counts from `references/checklist.md` and fails when any numeric README count claim drifts, without hard-coded expected counts. Axis counting is limited to top-level numbered checklist sections, and item counting accepts only top-level unchecked hyphen items whose post-marker indentation is 1–4 columns. The parser tracks each accepted item’s content column, excludes nested checkbox items, and keeps list-contained paragraphs, Setext headings, and inline Type 7 HTML from changing the top-level axis scope. Valid 0–3-space fences, raw HTML blocks, a conservative complete single-line link-reference subset with CommonMark’s 999-character label limit, and hyphen / asterisk thematic breaks whose markers are separated by spaces or tabs are handled without false rejection. Noncanonical list or blockquote container lines and still-ambiguous multiline or indented leaf forms inside an active axis fail closed with the fixed unsupported-structure error and zero counts. Proven top-level Setext headings end the active scope; following blocks remain outside it. Text reads explicitly use UTF-8 for consistent PowerShell 7 / Windows PowerShell 5.1 results.
- Public-readiness validation now binds each exact README and `AGENTS.md` heading to its first visible PowerShell fence/body, excludes fenced/HTML decoys, and verifies the exact enabled CI job/step/shell/run contract. This is intentionally a copy-paste contract: quoted, case-changed, long-fence, block-scalar, disabled, reordered, missing, or extra forms fail closed even when a YAML or Markdown processor could treat them as equivalent. The production normal case plus 21 table-driven cases pass with zero failures, and all three check:all commands pass on both PowerShell 7 and Windows PowerShell 5.1.
- `docs/requirements-redefinition-2026-07.md` now records the 2026-07-22 counter-evidence watch: generic UI review skills still show no confirmed adoption of Japanese typesetting and Japan-specific form rules, an adjacent Japanese typography resource has emerged, and the JIS X 8341-3 revision remains under consideration rather than finalized.
- Validation command examples now use the same `pwsh -NoProfile -ExecutionPolicy Bypass -File` form across README, contribution, security, and pull request guidance.
- `CHANGELOG.md` now describes semantic versioning as active for versioned releases.
- The dated Codex handoff prompt no longer duplicates a fixed completed-task range, verification date, or tag/Release state. It now requires each new session to read the living sources of truth and remeasure Git/GitHub state before acting.
- The repository document reading order now has a single source of truth in `CODEX_START_HERE.md`; agent instructions, handoff guidance, and the dated Codex prompt refer to that list instead of maintaining divergent copies.
- `HANDOFF.md` and `TASKS_BACKLOG.md` updated to reflect the merged task inventory and the autonomous operating model, then streamlined in the 2026-07-12 documentation cleanup: `HANDOFF.md` gained a document map pointing to each source of truth, `TASKS_BACKLOG.md` moved historical verification logs and sync narratives to git history, and `docs/requirements-redefinition-2026-07.md` now records its implemented status per task.

### Removed

- Stale tracked documents, superseded by current sources of truth (dispositions recorded in `docs/advisory-review-disposition.md`, contents preserved in git history): `NOTES_CLAUDE.md` (scanner-hardening work notes absorbed into `scripts/`, `SECURITY.md`, and this changelog), `docs/CLAUDECODE_HANDOFF.md` (generic handoff consolidated into `AGENTS.md` and `HANDOFF.md`), and `docs/CODEX_PROMPT_2026-07-11.md` (replaced by the 2026-07-12 prompt).

## [0.1.0] - 2026-06-06

### Added

- Public-readiness validation for OSS management files, CI wiring, and stale draft-language checks.
- Regression tests for the private marker scanner.
- GitHub Actions validation workflow for pull requests and pushes.
- Contribution, security, code-of-conduct, pull request, and issue template guidance.

### Changed

- README validation and license sections now describe the repository as public MIT-licensed OSS.
- README now documents the safe update path for an existing installed skill directory.
