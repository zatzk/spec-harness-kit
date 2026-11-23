# UI Craft & Visual Replication Standard

This normative standard defines objective **Pass / Fail** gates for visual UI design, design-system engineering (`DESIGN.md`), and faithful replication of existing designs or comps in SPEC-HARNESS-KIT.

---

## Gate 1: Incumbent & Comp Fidelity Contract (Zero Silent Redesign)
When replicating an existing page, screenshot, Figma/Stitch frame, or comp, treat it as a **measured spatial & token contract**, never a mood board.
- **Required Sequence:**
  1. **Incumbent Audit First:** Scan existing CSS custom properties (`--*`), Tailwind config, theme files, design tokens, and UI component wrappers before writing styles.
  2. **Region & Measurement Spec:** Decompose the target into named regions (`chrome`, `text`, `control`, `plate/media`) with layout geometry, typography (family, size, weight, tracking, line-height), color tokens, spacing rhythm, radii, borders, and elevation.
  3. **Media Discipline:** Keep painted/photographic/diagram media as dedicated media assets rather than crude inline SVG approximations.
  4. **Render-First Verification:** Inspect rendered output at desktop and mobile viewports via browser/screenshot/computed styles when runtime exists; mark `[UNVERIFIED-STATIC]` explicitly if no runtime is available.
- **Fail:** Silently swapping incumbent fonts/palette/layout for generic defaults, duplicating existing tokens, or claiming visual parity without checking rendered output.

## Gate 2: Surface Mode Calibration & Bottom-Up Perceptual Gates (L0–L4)
Declare the **Surface Mode** before making visual decisions:
- **`Operate`** (apps, dashboards, tables, settings): Restraint, high information density, familiar affordances, zero decorative noise.
- **`Read`** (docs, articles, long-form): 65–75ch body measure, clear typographic rhythm, uninterrupted reading path.
- **`Persuade`** (landing, marketing, onboarding): Clear visual anchor, distinct point of view, strong above-the-fold proposition.

Fix perceptual gates **bottom-up** (upstream failures block everything downstream):
1. **L0 — Cognitive Load:** ≤ 3–5 chunks per decision point; ≤ 5–7 top-level nav items; progressive disclosure for > 4–7 form fields; ≤ 2 font families (+ optional mono).
2. **L1 — First Impression (50ms):** Unmistakable visual anchor and primary CTA visible above the fold.
3. **L2 — Processing Fluency:** Coherent 4px/8px spacing rhythm; consistent radii, borders, elevation, and icon stroke weight.
4. **L3 — Copy-Visual Alignment:** Visual presentation reinforces the product's claim (no experiential self-contradiction).
5. **L4 — Decision Architecture:** High CTA signal-to-noise (`d-prime`), specific action labels, and clear wayfinding.

## Gate 3: AA-Constrained Token Ladder by Construction
- Every `(foreground-token × declared-background)` pair MUST meet **WCAG 2.1 AA** by construction: ≥ 4.5:1 for normal text & placeholders, ≥ 3:1 for large text & UI controls (aim for AAA 7:1 on medical, financial, government, or educational surfaces).
- **12px Minimum Text Floor** for readable UI copy; never rely on opacity-faded mid-grey tokens (e.g., `#6b7380` on white) or low-contrast brand colors on tinted backgrounds (ship dedicated AA text variants, reserving display brand color for non-text surfaces).
- On colored surfaces, tint secondary text from that surface's hue/foreground — never flat grey.

## Gate 4: Hard Craft Floor & AI-Slop Bans
Automatic **Fail** unless explicitly demanded by a pinned brief or incumbent design:
- Nested cards (card inside card) or uniform 3-column icon-tile + heading + paragraph card grids as default page scaffold.
- Gratuitous eyebrow/kicker labels above every heading; decorative `01 / 02 / 03` numbering without real sequence value.
- Generic purple-to-blue gradients, gradient text, decorative glassmorphism/blur, one-sided colored accent bars on rounded boxes, or zero-blur hard offset shadows (`4px 4px 0`) outside an actual neobrutalist system.
- Emoji/Unicode glyphs substituting for an icon library; monospace used as "tech" costume outside code/data/metrics; unstyled browser defaults on custom surfaces (missing `tabular-nums` on aligned numbers, clashing default focus rings/selection).
- Hardcoded hex colors bypassing project tokens/CSS variables or raw third-party primitives bypassing project wrappers (e.g., PrimeNG wrappers in Angular projects).

## Gate 5: 9-State Resilience & Ethical UI Gate
- **9-State Visual Coverage:** Every interactive screen/component accounts visually for `default`, `hover`, `focus-visible`, `active`, `disabled`, `loading/skeleton`, `empty`, `error/recovery`, and `stress/overflow` (long text truncation/wrapping, narrow mobile viewport, dark/light theme, `prefers-reduced-motion`).
- **Ethical UI Gate (Alignment, Sincerity, Golden Rule):** Refuse deceptive visual asymmetry (e.g., bright primary "Accept All" vs. low-contrast hidden "Reject/Cancel", fake urgency/scarcity badges).
