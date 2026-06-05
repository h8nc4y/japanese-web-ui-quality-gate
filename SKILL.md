---
name: japanese-web-ui-quality-gate
description: Use this when building or reviewing a Web page, app, UI, React, Next.js, form, dashboard, or Japanese UI that needs rendered browser checks, screenshots, responsive checks, accessibility checks, or user-facing Japanese copy review for non-programmer users in Japan.
---

# Japanese Web UI Quality Gate

Use this skill for web pages and applications whose users are primarily non-programmers in Japan.

## UI Language

- Write user-facing UI text Japanese-first: page titles, navigation, buttons, form labels, helper text, validation errors, empty states, loading text, error text, confirmation dialogs, destructive warnings, onboarding, dashboard summaries, and toasts.
- When an English label or technical term is necessary, add a short Japanese supplement.
- Human-facing work instructions must match the exact Japanese labels visible on screen.
- If the screen label is unverified, say it is 未確認 instead of guessing.

## Design Baseline

- Prefer the existing project design system, components, tokens, and copy style.
- If no suitable design system exists and the stack supports it, use accessible primitives and stable design tokens as a base.
- Do not leave generic pasted templates in place. Adjust information architecture, spacing, hierarchy, density, copy, and states to fit the product goal.
- If design files, components, variables, layouts, or tokens are available without OAuth, secret, token, or cost blockers, use them as source of truth.
- Do not use paid or price-unconfirmed services without explicit cost confirmation.

## Rendered Verification

- Do not treat compile, lint, typecheck, or build success as UI completion.
- Verify the rendered page with an available browser, browser automation tool, or screenshot workflow when practical.
- Check responsive viewports around 390px, 768px, and 1280px or wider.
- Inspect console and network errors when the available tooling supports it.
- Check for unexpected horizontal scroll, spacing and alignment issues, weak hierarchy, unreadable text, and buttons that are too small or hard to tap.
- Check focus and hover states, empty states, loading states, and error states where relevant.
- Before reporting that the UI is acceptable, state the checked viewport sizes, tools used, actual findings, fixed visible issues, and remaining concerns.
- Do not claim screenshots, console or network inspection, or browser verification unless they actually occurred.

## Stop Conditions

- Follow the active environment policy for paid or price-unconfirmed services, OAuth, token entry, secret handling, real customer data, or billable API and cloud operations.
- If verification is blocked by OAuth, unavailable browser tooling, or a paid service, do not wait in an auth loop. Report the blocker and the smallest safe next step.
