# add-design-system

## Why

`setup-mobile-foundation` shipped a placeholder screen with whatever colour and
type Flutter gave it, and every capability from the grid onward needs the real
tokens before it draws anything. The reason this change comes second rather than
later is enforcement: the "one colour, one job" rule (D-53, D-65) has to live in
the token API itself, because once eight changes are painting cells there is no
practical way to stop a ninth hue arriving.

## What changes

- **A colour token API** built from `docs/DESIGN.md` §1: eight tokens, six
  carrying state (ink, focus, candidate, provisional, error, completion) and two
  surfaces. Derived tints, depth shades, and on-colour text values are exposed
  only as members of the token they derive from, never as free-standing colours,
  so there is no place to put a ninth hue.
- **A season theme structure** that can repaint the two surface tokens and props
  and *structurally cannot* reach the six state tokens (D-55, D-65).
- **A type scale** — the six roles in `docs/DESIGN.md` §2 — with one bundled
  open-licensed rounded UI face, chosen against written criteria and verified on
  device rather than from a specimen.
- **Shape and depth tokens**: the four radii and four stroke weights from §3, the
  rest/pressed depth values from §4, and the depth shade per token family.
- **Motion and haptic tokens**: the per-event durations, curves, and haptic
  vocabulary in §5, plus the reduce-motion and reduce-effects switches that
  disable them.
- **Shared primitives that encode §4**: a pressable surface with the 4–5px rest /
  1px pressed / 8px travel behaviour, a card with the solid offset shadow and the
  0.5–2° tilt, and the 4% paper-grain overlay. Changes 6 and 11 consume these
  rather than re-deriving them.
- **The placeholder screen is re-themed** through the token theme, replacing the
  ad-hoc styling `setup-mobile-foundation` left behind.
- **Document reconciliation.** `docs/DESIGN.md` leads. A new `D-71` amends D-53 to
  fix the count at eight tokens — six state, two surfaces — and the wording is
  corrected in `openspec/config.yaml` constraint 4, `openspec/project.md`, and
  `docs/SPEC.md` §9.8, which today say six, six-with-a-different-six, and five.
- **Glossary additions** to `openspec/project.md`: *design token*, *state colour*,
  *reduce effects*.

## Constraints

**Capabilities:** `design-system`

**Constraint 4 (one colour, one job)** is the point of the change. It is enforced
three ways rather than documented once: the token type has no public colour
constructor, the season theme type has fields for surfaces only, and a test walks
`lib/` asserting no `Color(0x…)` literal or `Colors.*` reference exists outside
the token file.

**Constraint 5 (colour is never the sole signal)** — the tokens carry no secondary
cue on their own, so this change contributes the *mechanism*: a contrast budget
enforced by test, and the reduce-effects switch. The corner marks and positional
cues belong to the changes that draw them (11 and 7).

**Constraint 2 (latency, 400ms ceiling)** — the motion tokens are the ceiling made
executable. Every duration in the table is a named token, and a test asserts none
exceeds 400ms except the two documented exceptions (cascade 520ms, puzzle
complete 1400ms, D-46/D-47). The primitives animate transform and colour only,
never layout.

**Constraint 1, 3, 6, 7, 8, 9, 10** are untouched: no puzzle, no notes, no save
state, no ad SDK, no currency.

## Technical notes

**Grid performance:** No grid yet, but the depth treatment is the trap. `docs/DESIGN.md`
§4 is explicit that depth applies to interactive chrome only and never to grid
cells — so the pressable primitive is a chrome widget, and the grid will paint its
cells from raw tokens on the canvas rather than composing 81 of these. The
primitives use a solid offset (a painted rectangle), never `BoxShadow` blur, which
is also the cheaper of the two.

**Offline, cold start, app kill:** The bundled font is an app asset, so type
resolves with no network and nothing is added to the first-frame path. Season
themes ship with a baked-in default; remote season definitions are change 4 and
must never gate a frame. No persisted state here — the reduce-effects setting is
declared as a token-layer switch but its storage is change 3.

**New dependency:** No new pub package. One new *asset*: a font family, bundled
under `assets/fonts/` and declared in `pubspec.yaml`. `google_fonts` is
deliberately not used — it fetches at runtime by default, which the offline
mandate forbids, and bundling the four static weights costs a few hundred KB and
no code.

## Open item this change must close

Measuring `docs/DESIGN.md` §1 against WCAG produced four failures, and since that
file is the values, they are fixed here rather than inherited:

| Pair | Ratio | Needs |
|---|---|---|
| `turquoise` note on `bone` | **2.61** | 4.5 — provisional notes are 11px |
| `sunsetRed` with its on-colour `#5C1409` | **3.63** | 4.5 — label/meta is 12px |
| `cactusGreen` with its on-colour `#123A1E` | **3.87** | 4.5 |
| `inkSoft` on `sand` | **4.08** | 4.5 — secondary text on the page background |

The rest pass comfortably (`duskInk` on `bone` 12.44, `nightIndigo` on `bone`
7.11, `badgeGold` on-colour 6.33). The fix is to darken the failing values in
`docs/DESIGN.md` and record it as `D-72`. Hue and role assignments do not change —
only luminance.

**Resolved during implementation, worse than estimated.** Measured against all
five cell backgrounds rather than `bone` alone, `turquoise` fails on every one
(2.21–2.70). Darkening it far enough to be legible drops its separation from
`nightIndigo` to 1.34:1 in normal vision and 1.14:1 under deuteranopia — the two
note inks become the same mark. The pairing was already failing constraint 5
before the fix (2.19:1 deutan): settled versus provisional was resting on hue
alone. Resolved as `D-73` — provisional notes carry an underline as well as the
ink — which adds a note-treatment token here and a drawing requirement to
change 9. The `hairline` at 1.33:1 is measured and deliberately exempt; it is not
text, and D-72 records why.

## Not doing

- **No grid, no cells, no number pad.** `add-grid-and-input` (change 6) owns
  everything the grid draws; this change gives it the values to draw with.
- **No completion tints applied to anything.** `greenPale` and `goldPale` exist as
  tokens and get swatch goldens; the non-additive tint behaviour, the corner mark,
  and the state-priority ordering (D-48, D-49, D-50) are change 11.
- **No effects.** The lasso, the dynamite, the digit reactions, and the particle
  budget in `docs/DESIGN.md` §6 are changes 11 and 20–21. Only their durations and
  curves are tokenised here.
- **No characters, no Rive.** Change 20.
- **No second season theme.** One default theme proves the structure; territory
  themes arrive with `add-season-map` (change 15) as data.
- **No settings screen.** Reduce-effects is a switch the token layer reads, not a
  UI to toggle it or a store to persist it.
- **No logo lettering.** `docs/DESIGN.md` §2 restricts slab and tuscan faces to the
  logo, and there is no logo yet.
- **No debug gallery route.** The re-themed placeholder is the only screen.
- **Not resolving the `docs/ART-BRIEF.md` conflict.** The Sheriff's retired
  wrong-advice gag (D-39 vs D-60) is a character-art problem, not a token problem,
  and belongs to change 20.
