# Applied Example: Synthetic Passing Review (Equipment Booking Dashboard)

This is a synthetic, invented example. It does not describe any real product, real data, or real user. It is the counterpart to `examples/checklist.md`: instead of a UI with many failures, this shows a sufficiently good UI reviewed against `references/checklist.md`, with guard items correctly applied so the gate does not fail it unfairly.

Fictional scope: an internal-facing 社内向け備品予約ダッシュボード (office equipment booking dashboard) with a booking list, a new-booking form, and a cancellation-confirmation step, reviewed before shipping to internal non-programmer staff.

## 1. UI Language

- [x] Pass — Page title, navigation, and primary actions are Japanese ("備品予約一覧", "予約する", "キャンセルする").
- [x] Pass — Validation error on the booking form reads "この日付はすでに予約されています。別の日付を選択してください。" (states what happened and the next action).
- [x] Pass — All body copy on this screen consistently uses です/ます; no 敬体/常体 mixing observed.
- [x] Pass (guard applied) — The label "CSVエクスポート" is a technical term, but its tooltip carries a short Japanese supplement ("この一覧をCSV形式でダウンロードします"); this is not flagged, since a short Japanese supplement for a widely used technical term satisfies the axis.
- [ ] 未確認 — Could not verify the wording of the email notification sent after booking, since outbound email delivery was out of scope for this pass.

## 2. Japanese Text Rendering

- [x] Pass — `lang="ja"` is present on `<html>`.
- [x] Pass — No mojibake or tofu observed in any checked state.
- [x] Pass — Booking date is shown as `2026年7月6日（月）`, unambiguous for a Japan-based reader.
- [x] Pass (guard applied) — Japanese body text uses default browser letter-spacing with no experimental CSS (no `text-spacing-trim` or `word-break: auto-phrase`); this is not required by name, and the rendered result — normal line wrapping and no unnatural gaps — is what was judged.
- [x] Pass — A long unbroken equipment-model string ("Projector-Model-XJ4500-ULTRA-WIDE-SERIES") in the booking list wraps inside its table cell at all checked widths instead of overflowing.

## 3. Japanese Form Input

- [x] Pass — Postal code is not collected on this internal form (no applicable field); this is not treated as a defect since the form has no legitimate need for it.
- [x] Pass (guard applied) — The requester's phone number field is split into two boxes (area code / local number); both accept hyphen and non-hyphen entry, and pasting `03-1234-5678` fills both boxes correctly. The split shape is not penalized, since evidence shows no actual input problem.
- [x] Pass — Phone number field is `inputmode="tel"`, preserving any leading zero.
- [x] Pass — Requester name is a single free-text field; ordinary Japanese names of varying length were entered without truncation or corruption.
- [x] Pass — The booking-date field pairs a native date picker with a text-entry fallback (`YYYY-MM-DD`), so reaching a date months away does not require repeated clicking.
- [ ] 未確認 — Full-width digit normalization on the "利用日数" (number of days) field was not exercised in this pass; only half-width input was tested.

## 4. Accessibility Essentials

(Not a conformance test or certification — individual observations only.)

- [x] Pass — Primary "予約する" button is 44x44 CSS px, above the 24x24 minimum.
- [x] Pass (guard applied) — A small inline link ("備品管理規程はこちら") sits inside a paragraph of help text; this is within the WCAG 2.2 inline-text-link exception, so it is not counted as a target-size failure.
- [x] Pass — Focus outline is visible on all interactive elements via keyboard Tab navigation, including inside the cancellation-confirmation dialog.
- [x] Pass — The cancellation-confirmation dialog does not re-ask for the booking ID or requester name already entered earlier in the same flow (Redundant Entry respected).
- [x] Pass — A "お問い合わせ" help link appears in the same header position on the list, form, and confirmation screens (Consistent Help).
- [x] Pass — Body text contrast measured at 7.2:1 against its background, comfortably above AA expectations.
- [ ] 未確認 — Hover-state contrast for the table row highlight was not measured with a contrast tool in this pass; it was only checked visually.

## 5. Rendered Verification

- [x] Pass — Checked at 390px, 768px, and 1280px using a browser automation tool.
- [x] Pass — Empty (no bookings), loading, error, focus, disabled, and destructive-action-confirmation (cancel) states were all checked.
- [x] Pass — No horizontal scroll at any checked width; the equipment-model wrapping fix (axis 2) confirmed this directly.
- [x] Pass — The dashboard reuses the project's existing component library (buttons, table, dialog) rather than introducing one-off styling.
- [ ] 未確認 (guard applied, not a fail) — This device class is a shared touch-screen kiosk in a supply room; hover state was not exercised because the target environment is touch-only. This is reported honestly as 未確認, not marked as a failure, since hover is not applicable to the actual usage context.

## 6. Honest Reporting

- Tools used: browser automation tool with viewport resize and a color-contrast measurement tool for the one contrast check performed; no email-delivery tool was available in this environment.
- Viewports checked: 390px, 768px, 1280px.
- States checked: empty, loading, error, disabled, focus (keyboard), destructive-action confirmation. Hover not checked — touch-only kiosk target (未確認, not a fail).
- Findings: 0 fail items in this pass. All guard items above were applied deliberately, with the reasoning for each recorded rather than assumed.
- Fixed during this review: none required — the reviewed UI was already at a shippable state; the long-string wrapping check (axis 2) confirmed an existing fix rather than introducing a new one.
- Remaining concerns: email notification wording unverified; full-width digit input on the days-count field unverified; hover-state contrast unmeasured (reported as 未確認 above rather than omitted).
- A pass on this checklist is not a conformance or legal-compliance declaration; it is a synthetic evidence-based review only.

## 7. Stop Conditions

- No paid services, OAuth flows, secrets, or real customer/employee data were used; all data in this review is synthetic.
