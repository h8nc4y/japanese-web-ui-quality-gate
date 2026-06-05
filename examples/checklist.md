# Japanese Web UI Quality Gate Checklist

## UI Language

- [ ] Page titles, navigation, buttons, labels, helper text, validation errors, empty states, loading text, error text, confirmation dialogs, destructive warnings, onboarding text, summaries, and toasts are Japanese-first.
- [ ] Technical English terms have short Japanese supplements when needed.
- [ ] Human-facing instructions match visible Japanese labels.
- [ ] Unverified labels are reported as 未確認.

## Rendered Verification

- [ ] Build or type success is not treated as UI completion.
- [ ] A rendered page was checked when practical.
- [ ] Viewports around 390px, 768px, and 1280px or wider were checked when practical.
- [ ] Horizontal scroll, spacing, alignment, hierarchy, text readability, and tap targets were checked.
- [ ] Focus, hover, empty, loading, error, and disabled states were checked where relevant.
- [ ] Console and network errors were inspected when tooling supported it.

## Reporting

- [ ] Tools used are stated.
- [ ] Viewport sizes checked are stated.
- [ ] Findings, fixes, and remaining concerns are stated.
- [ ] Screenshots, console inspection, and network inspection are claimed only when actually performed.

## Safety

- [ ] No secrets, tokens, API keys, OAuth credentials, auth cookies, private repository URLs, local absolute paths, customer data, or real operational logs are included.
- [ ] Paid or price-unconfirmed services are not used without explicit cost confirmation.
