# Contributing

Thank you for helping improve `japanese-web-ui-quality-gate`.

This repository is intentionally small. Good contributions keep the skill portable across Codex-style runtimes, easy to read manually, and honest about what was actually verified.

## Good Changes

- Clarify the Japanese UI quality gate in `SKILL.md`.
- Improve examples in `examples/` without adding real product, customer, credential, or private repository data.
- Strengthen validation scripts in `scripts/`.
- Improve README, security, release, or contribution guidance.
- Add checks that prevent private context, secrets, or unverifiable claims from reaching public examples.

## Before You Open a Pull Request

Run these checks locally from the repository root:

```powershell
pwsh scripts/test-public-readiness.ps1
pwsh scripts/test-scan-private-markers.ps1
pwsh scripts/scan-private-markers.ps1
```

On Windows PowerShell, use:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1
powershell -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1
powershell -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1
```

If a check fails, fix the source content when possible. Do not hide real secrets or private data with an allowlist. Rotate exposed credentials if real exposure is possible.

## Pull Request Checklist

- Keep the pull request focused on one clear improvement.
- Update `README.md`, `SKILL.md`, `examples/`, and `CHANGELOG.md` together when behavior or user guidance changes.
- Add or update validation scripts when a new public-safety rule is introduced.
- State the exact commands you ran and their results.
- Mark unverified browser checks, labels, screenshots, console output, or network output as `未確認`.
- Do not include secrets, OAuth credentials, API keys, auth cookies, customer data, private repository URLs, local absolute paths, or real operational logs.

## Issue Guidance

Use issues for reproducible documentation problems, unclear quality-gate rules, missing examples, or validation gaps. Do not use public issues to report secrets, credentials, private customer data, or vulnerability details; follow [`SECURITY.md`](SECURITY.md) instead.
