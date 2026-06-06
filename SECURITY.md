# Security Policy

## Supported Scope

Security support covers the current `main` branch and the latest GitHub release once releases are published. Older forks or copied versions may not receive updates.

## Reporting a Vulnerability

Do not report secrets in public issues.

If you find a vulnerability, secret exposure, private repository URL, credential, customer-data leak, or prompt content that should not be public:

1. Use GitHub private vulnerability reporting if it is available for this repository.
2. If private reporting is unavailable, open a public issue with only a short non-sensitive summary and ask for a private maintainer contact path.
3. Do not paste tokens, API keys, OAuth credentials, auth cookies, private logs, customer data, screenshots containing sensitive data, or full exploit details into public issues or pull requests.

## Maintainer Handling

Maintainers should remove or redact sensitive public content when possible, preserve enough context to fix the issue, and recommend credential rotation when a real secret may have been exposed.

## Validation

Run these checks before publishing changes:

```powershell
pwsh scripts/test-public-readiness.ps1
pwsh scripts/test-scan-private-markers.ps1
pwsh scripts/scan-private-markers.ps1
```
