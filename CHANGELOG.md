# Changelog

All notable changes to this project are documented here.

The format follows a simple keep-a-changelog style, and this project uses semantic versioning for versioned releases.

## [Unreleased]

### Added

- `docs/requirements-redefinition-2026-07.md` recording the 2026-07 requirements redefinition (market review, evaluation axes v2, success metrics, task breakdown).
- `references/checklist.md`: a new 80-item detailed checklist covering all 7 evaluation axes in `SKILL.md` v2, split out for progressive disclosure.
- `AGENTS.md` documenting the autonomous agent development workflow, `check:all` verification, and the human-approval gates.
- `examples/passing-review.md`: a synthetic passing applied example (an invented equipment-booking dashboard) showing guard items correctly applied so a sufficiently good UI is not unfairly failed, complementing the fail-heavy example in `examples/checklist.md`.

### Changed

- `SKILL.md` rewritten as v2 around 7 evaluation axes (UI Language, Japanese Text Rendering, Japanese Form Input, Accessibility Essentials, Rendered Verification, Honest Reporting, Stop Conditions). The frontmatter `description` now states explicitly that this is a pass/fail quality gate, not a generation guide, and lists exclusion conditions. `Design Baseline` is folded into the other axes; Japanese text rendering, Japanese form input, and an observable WCAG 2.2 subset are new.
- `examples/checklist.md` changed from a generic checklist mirror into a synthetic applied example: a filled-in review of an invented Japanese member-signup form with representative pass/fail/未確認 findings across all 7 axes.
- `README.md` synced to `SKILL.md` v2: `What It Enforces` now lists the 7 axes with the 80-check total, `When To Use` gained an explicit "Not for" exclusion list, installation and update guidance now cover `references/checklist.md`, and multi-runtime portability (Codex, Claude Code, Gemini CLI, GitHub Copilot, and other SKILL.md-compatible runtimes) is stated more concretely. `Limitations` now states explicitly that this skill does not perform WCAG/JIS X 8341-3 conformance testing or legal/regulatory compliance judgment.
- The private-marker scanner now defaults to git-tracked files, skips binary-like files, reports line numbers, adds AWS/GCP/Slack/Stripe/PEM coverage, and avoids treating `task-scanner`-style slugs as OpenAI-style tokens.
- Validation command examples now use the same `pwsh -NoProfile -ExecutionPolicy Bypass -File` form across README, contribution, security, and pull request guidance.
- `CHANGELOG.md` now describes semantic versioning as active for versioned releases.
- `HANDOFF.md` and `TASKS_BACKLOG.md` updated to reflect the merged task inventory and the autonomous operating model.

## [0.1.0] - 2026-06-06

### Added

- Public-readiness validation for OSS management files, CI wiring, and stale draft-language checks.
- Regression tests for the private marker scanner.
- GitHub Actions validation workflow for pull requests and pushes.
- Contribution, security, code-of-conduct, pull request, and issue template guidance.

### Changed

- README validation and license sections now describe the repository as public MIT-licensed OSS.
- README now documents the safe update path for an existing installed skill directory.
