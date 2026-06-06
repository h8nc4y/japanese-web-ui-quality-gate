# Japanese Web UI Quality Gate

`japanese-web-ui-quality-gate` is an agent skill for building and reviewing Japanese web UI for non-programmer users in Japan. It is written for Codex-style skill runtimes, but the checklist can also be read and applied in other agent environments.

It turns web UI completion into a rendered quality gate: Japanese-first copy, responsive viewport checks, browser evidence, accessibility basics, state coverage, and honest reporting of what was actually verified.

Repository: <https://github.com/h8nc4y/japanese-web-ui-quality-gate>

## When To Use

Use this skill when working on:

- Japanese web pages and apps
- React, Next.js, forms, dashboards, and admin tools
- UI review before shipping
- Browser, screenshot, responsive, or accessibility checks
- Human-facing Japanese labels, validation messages, empty states, loading states, and error states

## What It Enforces

- User-facing UI text should be Japanese-first for users in Japan.
- Human-facing instructions should match the labels visible on screen.
- Compile, lint, typecheck, or build success is not enough to call UI work complete.
- Rendered checks should cover viewports around 390px, 768px, and 1280px or wider when practical.
- Reports should state the tools used, viewport sizes checked, findings, fixes, and remaining concerns.
- Paid services, OAuth flows, secrets, tokens, real customer data, and billable operations must follow the active environment policy.

## Installation

Clone the repository:

```bash
git clone https://github.com/h8nc4y/japanese-web-ui-quality-gate.git
```

Place `SKILL.md` in a skill directory named `japanese-web-ui-quality-gate` according to your Codex or agent runtime's skill installation process.

Example layout:

```text
japanese-web-ui-quality-gate/
└── SKILL.md
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
```

If your runtime expects a different skill root, copy `SKILL.md` into that runtime's documented skill directory instead.

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

Restart the agent runtime or open a new chat if updated skills are not reloaded immediately.

## Manual Use

For manual use in a different agent environment, read `SKILL.md` as the operating checklist for the UI task and keep the examples as synthetic reference prompts only.

Suggested manual workflow:

1. Read `SKILL.md` before starting a Japanese web UI task.
2. Use [`examples/checklist.md`](examples/checklist.md) as the review checklist.
3. Use [`examples/final-report-template.md`](examples/final-report-template.md) when reporting what was actually checked.
4. State unavailable browser tooling, OAuth blockers, paid-service blockers, or unverified labels as `未確認` instead of guessing.

## Usage Examples

Synthetic examples are in [`examples/`](examples/):

- [`review-request.md`](examples/review-request.md)
- [`final-report-template.md`](examples/final-report-template.md)
- [`checklist.md`](examples/checklist.md)

## Limitations

- This skill is not a design system, component library, accessibility certification, legal review, or security audit.
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
pwsh scripts/test-public-readiness.ps1
pwsh scripts/test-scan-private-markers.ps1
pwsh scripts/scan-private-markers.ps1
```

The marker scan checks for common secret and private-context markers:

```powershell
pwsh scripts/scan-private-markers.ps1
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
