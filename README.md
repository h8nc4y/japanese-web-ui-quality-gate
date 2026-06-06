# Japanese Web UI Quality Gate

`japanese-web-ui-quality-gate` is an agent skill for building and reviewing Japanese web UI for non-programmer users in Japan. It is written for Codex-style skill runtimes, but the checklist can also be read and applied in other agent environments.

It turns web UI completion into a rendered quality gate: Japanese-first copy, responsive viewport checks, browser evidence, accessibility basics, state coverage, and honest reporting of what was actually verified.

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

Place `SKILL.md` in a skill directory named `japanese-web-ui-quality-gate` according to your Codex or agent runtime's skill installation process.

Example layout:

```text
japanese-web-ui-quality-gate/
└── SKILL.md
```

For manual use in a different agent environment, read `SKILL.md` as the operating checklist for the UI task and keep the examples as synthetic reference prompts only.

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

Run the marker scan before publishing, opening a public pull request, or copying content into another repository:

```powershell
pwsh scripts/scan-private-markers.ps1
```

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

## License

This repository currently contains an MIT license draft. Confirm the final license choice and copyright holder before public release.
