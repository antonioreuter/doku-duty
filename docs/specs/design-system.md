# design-system

## Purpose

The visual and tactile vocabulary every other capability builds on: the colour
tokens, the type scale, shape and depth, motion durations, and the haptic set.

The point of it is prohibition as much as provision. `docs/DESIGN.md` holds the
values; this capability is where the rules about those values are made
enforceable, so that a later change cannot introduce a ninth hue, let a **season**
repaint a **state colour**, push an in-puzzle animation past 400ms, or rest a
state on colour alone.

Established by `add-design-system`. The palette count is fixed by D-71, the
measured corrections by D-72, the note treatment by D-73, and the typeface by
D-74.

## Requirements

### Requirement: The palette is exactly eight tokens

The system MUST expose exactly eight colour tokens — two surfaces (`bone`,
`sand`) and six carrying state (`duskInk`, `badgeGold`, `nightIndigo`,
`turquoise`, `sunsetRed`, `cactusGreen`) — with the values in `docs/DESIGN.md`
§1, and MUST NOT expose any ninth colour (D-53 as amended, D-65).

#### Scenario: Enumerating the palette

- **WHEN** another capability asks the design system for the set of colour tokens
- **THEN** exactly eight are returned, each with its documented role, and the set
  cannot be extended at runtime

#### Scenario: A colour is needed that is not a token

- **WHEN** any code under `lib/` outside the token definition constructs a colour
  literal or references a framework colour constant
- **THEN** the build fails its test suite, naming the file and the literal

#### Scenario: Derived values are reachable only through their parent

- **WHEN** a pale tint, a depth shade, or an on-colour text value is requested
- **THEN** it is reached as a member of the token it derives from, and no derived
  value exists as a token in its own right

### Requirement: Each state colour has exactly one job

The system MUST reserve each of the six state colours for a single role —
`duskInk` for outlines and primary text, `badgeGold` for selection, focus,
reward, and progress, `nightIndigo` for **settled notes** and candidate
highlighting, `turquoise` for **provisional notes** and nothing else,
`sunsetRed` for errors and duplicates, `cactusGreen` for completed **units**
(D-53, D-65).

#### Scenario: Decoration needs a colour

- **WHEN** a decorative element is styled
- **THEN** it draws from the same eight tokens, and no hue is introduced for
  decoration alone

### Requirement: A season theme repaints surfaces only

The system MUST let a **season** theme supply new values for the two surface
tokens and for prop colours, and MUST make it structurally impossible for a
season theme to supply a value for any of the six state colours (D-55).

#### Scenario: A season theme is applied

- **WHEN** a season theme other than the default is active
- **THEN** surfaces and props take the season's values and every state colour
  keeps the value it has in every other season

#### Scenario: A season theme tries to carry a state colour

- **WHEN** a season theme definition is written
- **THEN** it has no field in which a state colour could be placed

#### Scenario: A prop is painted

- **WHEN** a season paints a prop
- **THEN** it names one of the eight tokens rather than supplying a colour, so a
  season cannot introduce a hue through its scenery

#### Scenario: Values derived from a surface follow that surface

- **WHEN** a season repaints a surface and also supplies the interior grid line
  colour or the shade the surfaces cast as a shadow
- **THEN** those follow the season, because they are surface values — a season
  that changes the paper and leaves the ruling behind reads as a defect

#### Scenario: A season omits the derived surface values

- **WHEN** a season theme supplies only the two surfaces
- **THEN** the derived surface values fall back to the default season's, and the
  theme is still valid

### Requirement: Text on any token meets its contrast budget

The system MUST render every text-on-background pair drawn from the tokens at a
contrast ratio of at least 4.5:1 where the text is below 18px or below 14px bold,
and at least 3:1 otherwise.

#### Scenario: Every documented pair is measured

- **WHEN** the token set is built
- **THEN** each foreground/background pair the design uses is measured against its
  budget, and a pair below its budget fails the build rather than shipping

#### Scenario: A provisional note is read

- **WHEN** a **provisional note** is drawn at note size on any cell background —
  `bone` or any of the four pale tints
- **THEN** it meets 4.5:1 against that background

#### Scenario: A non-text token is measured

- **WHEN** the interior grid `hairline` is measured against `bone`
- **THEN** it is exempt, because it is not text and is not the cue a solver reads
  unit structure from (D-72)

### Requirement: The two note kinds are distinguishable without colour

The system MUST give **provisional notes** a signal that does not depend on hue —
an underline beneath the digit — in addition to the `turquoise` ink, and MUST
draw **settled notes** in `nightIndigo` with no such rule (D-73, constraint 5).

#### Scenario: A player cannot distinguish the two inks

- **WHEN** the two note kinds are rendered for a player with any form of colour
  vision deficiency, or with colour otherwise unavailable
- **THEN** the **provisional note** is still identifiable by its underline alone

#### Scenario: The underline does not move the digit

- **WHEN** a **provisional note** is drawn in one of the nine fixed positional
  slots
- **THEN** the digit sits in the same place it would as a **settled note**, and
  no other candidate in the cell moves (D-10)

### Requirement: Type is six named roles on a bundled face

The system MUST expose six type roles — grid value, grid note, screen title, body,
label/meta, and character line — at the sizes and weights in `docs/DESIGN.md` §2,
rendered in a font family bundled with the app, and MUST scale them with the
platform's dynamic type setting.

#### Scenario: The app runs with no network

- **WHEN** the app is launched on a device in airplane mode on a fresh install
- **THEN** all six roles render in the bundled face, with no fallback to a platform
  face and no network request for a font

#### Scenario: The player enlarges system text

- **WHEN** the platform text-size setting is increased
- **THEN** every role scales with it and no text is clipped or truncated

#### Scenario: Digits are unambiguous

- **WHEN** the digits 1 to 9 are rendered at grid value size and at grid note size
- **THEN** each is distinguishable from every other, and 1, 4, 6, 7, and 9 are
  distinguishable from one another at note size

#### Scenario: Digits do not shift as the board fills

- **WHEN** values or notes are placed and removed in a column of cells
- **THEN** every digit occupies the same width as every other, so no already
  placed digit moves

### Requirement: Shape and depth are tokens, and depth never touches the grid

The system MUST expose the four corner radii and five stroke weights in
`docs/DESIGN.md` §3 — the fifth being the dashed **cage** outline (D-129) — and
MUST apply the depth treatment — solid offset shadow, never a blur — to
interactive chrome only.

#### Scenario: A button is pressed

- **WHEN** a pressable surface is pressed
- **THEN** it translates down 4px and its depth drops from its rest value to 1px,
  and on release it returns

#### Scenario: A grid cell is drawn

- **WHEN** a cell of the grid is drawn
- **THEN** it carries no offset shadow and no thick border

#### Scenario: A cage is drawn

- **WHEN** a **cage** outline is drawn
- **THEN** it uses the **cage** stroke token and a colour already assigned to
  outlines, and no new colour is introduced

### Requirement: Motion durations are bounded and named

The system MUST expose every in-puzzle motion duration as a named token, none
exceeding 400ms except the cascade and the puzzle-completion sequence, which are
recorded as deliberate exceptions (D-46, D-47).

#### Scenario: A duration token is added

- **WHEN** the set of motion tokens is built
- **THEN** any in-puzzle duration above 400ms that is not one of the two recorded
  exceptions fails the build

#### Scenario: An animation is running

- **WHEN** any tokenised animation is in flight
- **THEN** the next input is accepted immediately and the animation does not delay it

### Requirement: Reduce motion and reduce effects both silence motion

The system MUST disable tokenised motion when the platform's reduce-motion setting
is on, and MUST provide an independent in-app **reduce effects** switch with the
same result, leaving instant state changes intact.

#### Scenario: The platform setting is on

- **WHEN** reduce motion is enabled in the OS
- **THEN** tokenised animations resolve to their end state instantly, and every
  state remains readable

#### Scenario: The in-app switch is on and the platform setting is off

- **WHEN** **reduce effects** is enabled in the app while the OS setting is off
- **THEN** tokenised animations resolve instantly, with no dependence on the OS
  setting

#### Scenario: Nothing is lost by turning motion off

- **WHEN** either switch is on
- **THEN** no information conveyed by an animation becomes unavailable, and no
  action becomes impossible or slower to reach

### Requirement: A haptic vocabulary, not ad-hoc calls

The system MUST expose the haptics in `docs/DESIGN.md` §5 as a fixed named set —
selection tick, light impact, medium impact, light double tap, and success pattern
— and MUST fire nothing on **settled note** or **provisional note** entry (D-52).

#### Scenario: A note is entered

- **WHEN** a note is added or removed
- **THEN** no haptic fires

#### Scenario: The device cannot produce a haptic

- **WHEN** a haptic is requested on a device without the hardware, or with system
  haptics disabled
- **THEN** the app continues with no error and no visible difference other than the
  missing haptic

#### Scenario: A haptic with a gap in it

- **WHEN** a haptic made of more than one pulse is requested
- **THEN** the request returns as soon as the first pulse is dispatched, so the
  gap between pulses is felt by the player and never waited on by the caller
