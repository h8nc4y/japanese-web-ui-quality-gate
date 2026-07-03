# Applied Example: Synthetic Member Signup Form Review

This is a synthetic, invented example. It does not describe any real product, real data, or real user. It exists to show what a filled-in review looks like: representative items from each axis in `references/checklist.md`, marked pass, fail (with a concrete finding), or 未確認 (not verified), in the spirit of the Honest Reporting axis.

Fictional scope: a Japanese member-signup form with name, furigana, postal code, address, phone number, and a submit step, reviewed before shipping.

## 1. UI Language

- [x] Pass — Page title, labels, and button text are Japanese ("会員登録", "次へ").
- [ ] Fail — The "パスワード" field's error message reads only "エラーが発生しました" (an error occurred); it does not say what was wrong or what to do next. Should state e.g. "パスワードは8文字以上で入力してください".
- [x] Pass — No mixing of 敬体/常体 observed on this screen; all body copy uses です/ます.
- [ ] 未確認 — Could not verify onboarding tooltip copy; the tooltip did not render in the automated pass.

## 2. Japanese Text Rendering

- [x] Pass — `lang="ja"` is present on `<html>`.
- [ ] Fail — A long unbroken email address in the confirmation summary overflows its card at 375px width, pushing the "戻る" button off-screen.
- [x] Pass — No mojibake or tofu observed in any checked state.
- [x] Pass — Date of registration confirmation shown as `2026年7月3日`, unambiguous for a Japan-based reader.

## 3. Japanese Form Input

- [x] Pass — Postal code field is `inputmode="numeric"` with a `pattern`, not `type="number"`, so a leading zero is preserved.
- [x] Pass — Postal code field accepts both `1234567` and `123-4567`.
- [ ] Fail — Pasting `123-4567` into the phone number field strips the value entirely instead of normalizing or erroring with a specific message.
- [x] Pass — Furigana field label states "フリガナ（カタカナ）", and katakana-only input is accepted; hiragana input shows a specific inline error explaining katakana is expected.
- [ ] Fail — Furigana field uses `autocomplete="name"`, which mismatches its actual purpose.
- [x] Pass (guard applied) — Name is a single free-text field rather than split family/given; this was not treated as a defect since it accepts normal Japanese names without truncation or corruption.
- [ ] Fail — Date-of-birth field is a bare native `<input type="date">` calendar with no year text entry, making a user born decades ago scroll through months one click at a time.

## 4. Accessibility Essentials

(Not a conformance test or certification — individual observations only.)

- [x] Pass — Primary "次へ" button is 48x48 CSS px, well above the 24x24 minimum.
- [x] Pass (guard applied) — The inline "利用規約" link inside a paragraph is small, but this is within the WCAG 2.2 inline-text-link exception, so it is not counted as a target-size failure.
- [x] Pass — Focus outline is visible on all form fields via keyboard Tab navigation.
- [ ] Fail — On the confirmation step, a sticky footer covers the focused "送信" button when focus reaches it via keyboard, hiding it from view (Focus Not Obscured).
- [x] Pass — Address fields are pre-filled from the postal-code lookup rather than asking the user to retype the prefecture and city (Redundant Entry respected).
- [ ] 未確認 — Could not verify contrast ratio precisely without a color-contrast tool in this environment; visually appears adequate but is not confirmed.

## 5. Rendered Verification

- [x] Pass — Checked at 390px, 768px, and 1280px using a browser automation tool.
- [x] Pass — Empty, loading, error, and disabled states were checked for the submit button.
- [ ] Fail — At 390px, the address line 2 field causes horizontal scroll on the confirmation screen.
- [ ] 未確認 — Hover state not checked; this review only exercised touch/keyboard interaction paths.

## 6. Honest Reporting

- Tools used: browser automation tool with viewport resize; no color-contrast analyzer available in this environment.
- Viewports checked: 390px, 768px, 1280px.
- States checked: empty, loading, error, disabled, focus (via keyboard). Hover not checked (未確認).
- Findings: 7 fail items above (error message clarity, email overflow, phone paste handling, furigana autocomplete, date-of-birth picker, focus obscured by sticky footer, horizontal scroll at 390px).
- Fixed during this review: none — this was a review pass only, findings were reported back rather than patched.
- Remaining concerns: contrast ratio unverified; onboarding tooltip copy unverified.
- 未確認 items are listed explicitly above rather than omitted.

## 7. Stop Conditions

- No paid services, OAuth flows, secrets, or real customer data were used; all data in this review is synthetic.
