---
name: japanese-web-ui-quality-gate
description: Use this as a pass/fail quality gate (not a generation guide) before shipping or reviewing Japanese web UI - pages, apps, React/Next.js, forms, dashboards, admin tools - when the task needs Japanese-first copy review, Japanese text rendering/layout checks, Japanese form input handling (postal code, phone, furigana), accessibility essentials, or responsive/rendered browser verification. Do not use this for generating visual design from scratch, building a design system, or producing a WCAG/JIS conformance certification.
---

# Japanese Web UI Quality Gate

This is a quality gate, not a generation guide: it judges whether Japanese web UI is fit to ship for non-programmer users in Japan, and requires evidence for every pass. Detailed per-axis checklists live in `references/checklist.md` when that file is present, but this file is self-sufficient on its own.

## 1. UI Language

- Write user-facing text Japanese-first: titles, navigation, buttons, labels, helper text, validation errors, empty/loading states, confirmation dialogs, destructive warnings, onboarding, summaries, and toasts.
- Do not leave technical or English terms unexplained; add a short Japanese supplement when a term is necessary.
- Error text states both what happened and what to do next, not just that something failed.
- Do not mix polite (敬体) and plain (常体) forms within the same surface.
- Human-facing work instructions must match the exact labels visible on screen.
- If a screen label is unverified, say 未確認 instead of guessing.

## 2. Japanese Text Rendering

- Long unbroken English words and URLs must not overflow their container or break the layout.
- `lang="ja"` is set on Japanese-language content.
- No mojibake (文字化け) or missing-glyph boxes (豆腐).
- No unnatural letter- or line-spacing in Japanese body text.
- Dates, currency, and numbers are formatted so Japan-based users will not misread them (for example `2026年7月3日` or `2026/07/03` depending on context, not an ambiguous `07/03/2026`).

## 3. Japanese Form Input

- Postal code and phone number fields use an input type that preserves a leading zero.
- Fields accept input with and without hyphens and in both full-width and half-width characters, or paste, and either normalize it or give a specific error explaining what is wrong.
- Furigana fields state clearly whether hiragana or katakana (or both) is accepted.
- `autocomplete` values match their field's actual purpose (for example, do not reuse `name` on a furigana field).
- Split fields (family/given) and single fields are both acceptable; judge by evidence of actual input behavior, not by which shape was chosen.
- Do not default a far-past date field (such as date of birth) to a bare native date picker without a text-entry alternative or another way to reach distant years quickly.

## 4. Accessibility Essentials

This is the minimal, observable-in-a-UI-review subset of WCAG 2.2, not a conformance claim or certification.

- Interactive targets are at least 24x24 CSS px, or meet a recognized WCAG 2.2 exception (inline text links, sufficient spacing to adjacent targets, essential/legal exceptions).
- Focus is visible and never fully hidden behind other content (Focus Not Obscured).
- Users are not forced to re-enter information the system already has or previously collected in the same process (Redundant Entry).
- Help or contact entry points appear in a consistent location/order across pages (Consistent Help).
- Text and interactive elements meet contrast expectations for their role.
- All interactive functionality is reachable and operable by keyboard alone.
- Images convey their meaning through alt text (or are marked decorative when appropriate).

## 5. Rendered Verification

- Do not treat compile, lint, or typecheck success as UI completion.
- Prefer the project's own measured viewport data when available; otherwise render at one of 375/390/414px (mobile), plus 768px, plus 1280px or wider.
- Cover empty, loading, error, focus, hover, disabled, and destructive-action-confirmation states, not only the happy path.
- Check for unexpected horizontal scroll, hard-to-tap targets, and text wrapping that breaks layout.
- Check that the UI is not an unadapted generic template: layout, copy, and states reflect the actual product goal, and the project's existing design system or tokens are used when one exists.
- Only claim a browser, automation, or screenshot tool was used when it actually ran.

## 6. Honest Reporting

- State the tools actually used, the viewports actually checked, and the states actually checked.
- State findings, what was fixed, and what remains a concern.
- Mark anything not verified as 未確認 rather than guessing or omitting it.
- Do not claim screenshots, console/network inspection, or browser verification unless they actually occurred.

## 7. Stop Conditions

- Follow the active environment policy for paid or price-unconfirmed services, OAuth, token entry, secret handling, real customer data, or billable API and cloud operations.
- If verification is blocked by OAuth, unavailable browser tooling, or a paid service, do not wait in an auth loop. Report the blocker and the smallest safe next step.
