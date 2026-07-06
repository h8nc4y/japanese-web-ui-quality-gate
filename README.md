# Japanese Web UI Quality Gate

`japanese-web-ui-quality-gate` is an agent skill that acts as a **pass/fail quality gate** for Japanese web UI — it is not a visual-design generation guide. It is written in the SKILL.md format, which is readable by multiple agent runtimes (for example Codex, Claude Code, Gemini CLI, and GitHub Copilot, among others that support the same format), and the checklist can also be read and applied manually.

It turns web UI completion into 7 evidence-based evaluation axes covering Japanese-first copy, Japanese text rendering and layout, Japanese form input handling, accessibility essentials, rendered browser verification, honest reporting, and safe stop conditions — backed by 80 detailed checks in [`references/checklist.md`](references/checklist.md).

Repository: <https://github.com/h8nc4y/japanese-web-ui-quality-gate>

## When To Use

Use this skill when working on:

- Japanese web pages and apps
- React, Next.js, forms, dashboards, and admin tools
- UI review before shipping
- Browser, screenshot, responsive, or accessibility checks
- Human-facing Japanese labels, validation messages, empty states, loading states, and error states
- Japanese form input: postal code, phone number, furigana, and address fields

**Not for:**

- Generating visual design from scratch (colors, typography, layout direction) — this is a review/judgment gate, not a design generator.
- Building or extending a design system or component library.
- Producing a WCAG or JIS X 8341-3 conformance certification or legal/regulatory compliance sign-off.

## What It Enforces

Seven evaluation axes, detailed further in [`SKILL.md`](SKILL.md) and [`references/checklist.md`](references/checklist.md) (80 checks total):

1. **UI Language** — Japanese-first copy, no unexplained jargon, error text states what happened and what to do next, no 敬体/常体 mixing, screen labels match instructions.
2. **Japanese Text Rendering** — no overflow from long words/URLs, `lang="ja"`, no mojibake or missing glyphs, natural spacing, unambiguous date/currency/number formatting.
3. **Japanese Form Input** — postal code and phone fields preserve leading zeros, accept hyphen/full-width variants and paste (or error specifically), furigana fields state hiragana/katakana expectations, `autocomplete` matches actual field purpose, far-past dates avoid a bare native date picker.
4. **Accessibility Essentials** — the WCAG 2.2 subset observable in a UI review: target size, focus visibility, no redundant re-entry, consistent help placement, contrast, keyboard operability, image alt text. Not a conformance test.
5. **Rendered Verification** — build/lint/typecheck success is not UI completion; checks real viewports (project data or 375/390/414px + 768px + 1280px+) and empty/loading/error/focus/hover/disabled/destructive-action states.
6. **Honest Reporting** — states tools used, viewports checked, states checked, findings, fixes, and remaining concerns; unverified items are marked 未確認.
7. **Stop Conditions** — paid services, OAuth, secrets, and real customer data follow the active environment policy; no waiting in an auth loop.

## Installation

Clone the repository:

```bash
git clone https://github.com/h8nc4y/japanese-web-ui-quality-gate.git
```

Place `SKILL.md` (and, if your runtime supports supplementary reference files, `references/checklist.md`) in a skill directory named `japanese-web-ui-quality-gate` according to your Codex, Claude Code, Gemini CLI, GitHub Copilot, or other SKILL.md-compatible runtime's skill installation process. `SKILL.md` alone is self-sufficient; `references/checklist.md` adds the detailed 80-item checklist for runtimes that load reference files on demand.

Example layout:

```text
japanese-web-ui-quality-gate/
├── SKILL.md
└── references/
    └── checklist.md
```

For a Codex-style skill directory, one manual install shape is:

```powershell
$target = Join-Path $HOME ".agents/skills/japanese-web-ui-quality-gate"
if (Test-Path $target) {
  Write-Error "Skill already exists at $target. Review it before overwriting."
  exit 1
}
New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path ".\SKILL.md" -Destination (Join-Path $target "SKILL.md") -Force
New-Item -ItemType Directory -Force -Path (Join-Path $target "references") | Out-Null
Copy-Item -Path ".\references\checklist.md" -Destination (Join-Path $target "references\checklist.md") -Force
```

If your runtime expects a different skill root, copy `SKILL.md` (and `references/checklist.md`, if supported) into that runtime's documented skill directory instead.

## Updating an Existing Install

If the target skill directory already exists, compare the installed skill with the repository version before replacing it:

```powershell
$target = Join-Path $HOME ".agents/skills/japanese-web-ui-quality-gate"
$installedSkill = Join-Path $target "SKILL.md"
Compare-Object `
  -ReferenceObject (Get-Content -LiteralPath $installedSkill) `
  -DifferenceObject (Get-Content -LiteralPath ".\SKILL.md")
```

If the difference is expected, create a timestamped backup and copy the repository version into the existing skill directory:

```powershell
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item -LiteralPath $installedSkill -Destination (Join-Path $target "SKILL.md.$timestamp.bak") -Force
Copy-Item -LiteralPath ".\SKILL.md" -Destination $installedSkill -Force
```

Repeat the same compare-then-backup-then-copy pattern for `references/checklist.md` if your installed copy includes it.

Restart the agent runtime or open a new chat if updated skills are not reloaded immediately.

## Manual Use

For manual use in a different agent environment, read `SKILL.md` as the operating checklist for the UI task, use `references/checklist.md` for the detailed per-axis checks, and keep `examples/` as synthetic applied examples only.

Suggested manual workflow:

1. Read `SKILL.md` before starting a Japanese web UI task.
2. Use [`references/checklist.md`](references/checklist.md) as the detailed review checklist.
3. Read [`examples/checklist.md`](examples/checklist.md) as a synthetic applied example of a filled-in review.
4. Use [`examples/final-report-template.md`](examples/final-report-template.md) when reporting what was actually checked.
5. State unavailable browser tooling, OAuth blockers, paid-service blockers, or unverified labels as `未確認` instead of guessing.

## Usage Examples

Synthetic applied examples are in [`examples/`](examples/):

- [`review-request.md`](examples/review-request.md) — a synthetic request for a review.
- [`final-report-template.md`](examples/final-report-template.md) — a synthetic honest-reporting report skeleton.
- [`checklist.md`](examples/checklist.md) — a synthetic applied example: a filled-in review of an invented Japanese member-signup form, with representative pass/fail/未確認 findings across all 7 axes.
- [`passing-review.md`](examples/passing-review.md) — a synthetic passing review of an invented equipment-booking dashboard, showing the guard items preventing unfair failures on a sufficiently good UI.

## Limitations

- This skill is not a design system, component library, legal review, or security audit.
- It does not perform WCAG or JIS X 8341-3 conformance testing and does not issue a conformance declaration or legal/regulatory compliance judgment.
- It does not replace testing with real users, product owners, or native speakers.
- It cannot verify browser state, screenshots, console output, or network behavior unless the agent actually has and uses appropriate tooling.
- It intentionally avoids environment-specific private policies, repository names, local paths, credentials, and operational logs.

## Non-Goals

- Creating public repositories, changing repository visibility, publishing packages, creating releases, or registering marketplace listings.
- Handling secrets, OAuth credentials, API keys, auth cookies, customer data, or production logs.
- Recommending paid or price-unconfirmed services without explicit approval.

## Safety Notes

Do not include secrets, tokens, OAuth credentials, API keys, auth cookies, customer data, private repository URLs, local absolute paths, or real operational logs in prompts, examples, screenshots, reports, issues, or pull requests.

If a browser check requires login, paid services, or unavailable tooling, report the blocker and the smallest safe next step instead of waiting in an auth loop.

## Validation

Run the local checks before opening a pull request, cutting a release, or copying content into another repository:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

The marker scan checks for common secret and private-context markers:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

The scan allows this repository's own GitHub URLs by default. Add only intentional public repositories with `-AllowedGitHubRepositories` when needed.

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1
powershell -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1
powershell -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

GitHub Actions runs the same public-readiness and private-marker checks for pull requests and pushes.

## Contributing

Contributions are welcome when they keep the skill portable, safe to publish, and honest about what was actually verified. Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening an issue or pull request.

## Security

Do not include secrets, tokens, OAuth credentials, API keys, auth cookies, private repository URLs, local absolute paths, customer data, or real operational logs in public issues, pull requests, screenshots, or examples. See [`SECURITY.md`](SECURITY.md) for reporting guidance.

## License

This repository is licensed under the [`MIT License`](LICENSE).
