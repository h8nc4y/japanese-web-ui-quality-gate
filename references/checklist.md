# Japanese Web UI Quality Gate — Detailed Checklist

This is the detailed gate checklist. For a synthetic applied example see `examples/`.

Each axis below expands the corresponding section of `SKILL.md`. Items are written as observable pass/fail conditions, not implementation mandates: judge the rendered result, not which technique produced it. Guard items are marked `(guard)` — they exist to stop the gate from failing a UI unfairly.

## 1. UI Language

- [ ] Page titles, navigation, and primary actions are in Japanese.
- [ ] Form labels, helper text, and placeholder text are in Japanese.
- [ ] Validation error messages are in Japanese.
- [ ] Empty states, loading states, and toasts are in Japanese.
- [ ] Confirmation dialogs and destructive-action warnings are in Japanese and state the consequence.
- [ ] Onboarding text and dashboard summaries are in Japanese.
- [ ] (guard) A technical English term with a short Japanese supplement (e.g. `API（外部連携の接続情報）`) is not flagged as a violation.
- [ ] Every visible error message states what happened, in terms a non-programmer understands.
- [ ] Every visible error message states the next action the user should take.
- [ ] No single screen mixes 敬体 (です/ます) and 常体 (だ/である) in body copy.
- [ ] Written work instructions (e.g. a test script or review request) use the same wording as the labels actually visible on screen, not a paraphrase.
- [ ] Any label the reviewer could not directly observe is reported as 未確認, not asserted.

## 2. Japanese Text Rendering

- [ ] A long unbroken English word or URL does not overflow its container.
- [ ] A long unbroken English word or URL does not push sibling elements out of layout.
- [ ] Japanese-language HTML (or the relevant root element) declares `lang="ja"`.
- [ ] No mojibake (garbled characters) appears anywhere in rendered Japanese text.
- [ ] No tofu / missing-glyph boxes appear in rendered Japanese text.
- [ ] Line height and letter spacing in Japanese body text look typographically normal, not artificially stretched or compressed.
- [ ] Dates are formatted in a way that is unambiguous to a Japan-based reader (e.g. `2026年7月3日`, `2026/07/03`, or `2026-07-03` with clear context), not an ambiguous `MM/DD/YYYY`.
- [ ] Currency values are labeled or formatted so a Japan-based reader will not misread the unit or magnitude.
- [ ] Large numbers use a grouping/format a Japan-based reader can parse at a glance.
- [ ] (guard) A CSS property or technique not implemented is not required by name; only the rendered outcome (no overflow, no mojibake, no unnatural spacing) is judged.

## 3. Japanese Form Input

- [ ] Postal code fields use an input type/attribute that preserves a leading zero (not a bare `type="number"`).
- [ ] Phone number fields use an input type/attribute that preserves a leading zero.
- [ ] Postal code field accepts input both with and without a hyphen.
- [ ] Phone number field accepts input both with and without hyphens.
- [ ] Fields that should accept full-width (全角) digits either normalize them or clearly error with guidance to use half-width.
- [ ] Pasting a formatted value (e.g. `123-4567`) into a postal code field is handled — accepted/normalized or rejected with a specific message — not silently broken.
- [ ] Furigana fields state whether hiragana or katakana is expected, or accept both.
- [ ] Furigana fields do not use `autocomplete="name"` or another semantically mismatched autocomplete value.
- [ ] Address fields do not force manual re-entry of information a postal-code lookup already supplied, without explanation.
- [ ] (guard) A single free-text name field and a split family/given-name field are equally acceptable; do not fail one shape in favor of the other without evidence of an actual input problem.
- [ ] (guard) A split postal-code field (two boxes) and a single field with auto-formatting are equally acceptable if both accept hyphen and non-hyphen entry.
- [ ] Date-of-birth or other far-past date fields offer a way to reach distant years without excessive scrolling/clicking through a bare native date-picker calendar (e.g. year/month select, direct text entry).
- [ ] Required-field indicators and their explanation are in Japanese and visible before submission, not only in an error state.

## 4. Accessibility Essentials

This skill checks the WCAG 2.2 subset that is observable in a UI review. It is not a conformance test or certification.

- [ ] Buttons and primary tap targets are at least 24x24 CSS px.
- [ ] (guard) A smaller inline text link within a paragraph is not failed for target size (WCAG 2.2 exception).
- [ ] (guard) A small target with at least 24px of clear space to the next target is not failed for target size (WCAG 2.2 equivalent-spacing exception).
- [ ] Keyboard focus has a visible indicator on every interactive element.
- [ ] No sticky header, footer, or overlay fully hides the focused element (Focus Not Obscured).
- [ ] A multi-step flow does not re-ask for information already entered earlier in the same flow (Redundant Entry), unless re-entry is required for security (e.g. re-entering a password) or the data was cleared intentionally.
- [ ] Help, support, or contact links appear in the same relative location/order across pages that offer them (Consistent Help).
- [ ] Body text contrast against its background meets WCAG 2.2 AA expectations.
- [ ] Interactive element contrast (borders/icons conveying state) meets WCAG 2.2 AA expectations.
- [ ] Every interactive control can be reached and activated using only the keyboard.
- [ ] Tab order follows a logical reading/visual order.
- [ ] Informative images have alt text describing their content or function.
- [ ] Purely decorative images are marked so assistive technology skips them.
- [ ] Form inputs have programmatically associated labels (not placeholder-only labeling).
- [ ] (guard) This checklist does not assert JIS X 8341-3 or WCAG conformance; findings are reported as individual observations, not a pass/fail certification.

## 5. Rendered Verification

- [ ] A passing build, lint, or typecheck run is not reported as evidence the UI itself works.
- [ ] The rendered page was actually opened in a browser, browser-automation tool, or screenshot workflow — not assumed from source review.
- [ ] If the project has measured viewport/analytics data, the top real-world width from that data was checked.
- [ ] If no project viewport data exists, one of 375px, 390px, or 414px (mobile) was checked.
- [ ] A tablet-range width (≈768px) was checked.
- [ ] A desktop-range width (≥1280px) was checked.
- [ ] Empty state was checked.
- [ ] Loading state was checked.
- [ ] Error state was checked.
- [ ] Focus state was checked.
- [ ] Hover state was checked (when the target device class supports hover).
- [ ] Disabled state was checked.
- [ ] A destructive action's confirmation step was checked, not just its trigger button.
- [ ] No unexpected horizontal scroll appears at any checked width.
- [ ] No tap target is effectively too small or too close to a neighbor to hit reliably on a touch viewport.
- [ ] Text wrapping does not break the layout at any checked width.
- [ ] The UI reuses the project's existing design system, components, or tokens when one exists, instead of introducing unexplained one-off styling.
- [ ] The UI does not read as an unadapted generic template; information architecture, copy, and states reflect the actual product.
- [ ] (guard) A tool or check not actually available in the environment is not required; its absence is reported as 未確認 or as a stated blocker instead.

## 6. Honest Reporting

- [ ] The tools actually used for verification are named in the report.
- [ ] The viewport widths actually checked are stated as specific numbers, not "responsive checks passed."
- [ ] The states actually checked (from axis 5) are listed.
- [ ] Findings are described concretely enough that another reviewer could reproduce them.
- [ ] Fixes applied during the review are distinguished from fixes only recommended.
- [ ] Remaining concerns are listed even if they were out of scope to fix.
- [ ] Anything not checked is labeled 未確認, not silently omitted.
- [ ] No claim of "screenshot taken," "console checked," or "network checked" appears unless that step actually ran.

## 7. Stop Conditions

- [ ] Paid or price-unconfirmed services were not used without explicit approval.
- [ ] OAuth, secrets, tokens, and real customer data were handled per the active environment policy, not improvised.
- [ ] If a check was blocked by auth, an unavailable tool, or a paid service, the review reports the blocker and a smallest-safe-next-step instead of retrying indefinitely.
