# Synthetic Review Request

Review this Japanese web form before release.

Scope:

- Login form
- Password reset form
- Account settings page

Please check, following the seven axes in `SKILL.md` (detailed items in `references/checklist.md`):

- Japanese-first labels and validation messages; error text states both what happened and what to do next; no 敬体/常体 mixing
- Japanese text rendering: `lang="ja"` is set, no mojibake or missing glyphs, long unbroken words or URLs do not overflow, dates and numbers cannot be misread by Japan-based users
- Japanese form input: postal code and phone fields preserve leading zeros; hyphen, full-width, and pasted input is accepted or produces a specific error; furigana expectations (hiragana/katakana) are stated; `autocomplete` values match each field's actual purpose
- Accessibility essentials: target size, visible and unobscured focus, no forced re-entry of known information, consistent help placement, contrast, keyboard operability, image alt text
- Rendered verification at a project-measured mobile width (or one of 375/390/414px), 768px, and 1280px or wider, covering empty, loading, error, focus, hover, disabled, and destructive-confirmation states
- Console and network errors if tooling supports it
- Whether human-facing instructions match the labels shown on screen

Report honestly: state the tools, viewports, and states actually checked, and mark anything unverified as 未確認.

Do not use paid services, real customer data, secrets, tokens, or login credentials during the review.
