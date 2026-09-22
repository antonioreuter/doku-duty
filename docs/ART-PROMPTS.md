# Art generation prompts

Companion to `docs/ART-BRIEF.md`. That file is the commission for a human
illustrator and animator; this one is the set of prompts for generating stills
with an image model (Nano Banana / Gemini image), and the rules that keep what
comes back inside the eight-token palette.

Values here are copied from `docs/DESIGN.md` §1 and §3. If they disagree,
`docs/DESIGN.md` wins — fix this file in the same change.

---

## What an image model can and cannot deliver

**It cannot do the top of `docs/ART-BRIEF.md`'s priority list.** Priorities 1–3
there are *animation* — digit reactions, Biscuit's loops, Ace's loops — and the
technical constraint is "Rive, with runtime-controllable state machines —
reactions fire on gameplay events, not on a timeline". A still-image model
produces none of that. Generating art here **does not remove the Rive
commission**; it makes it cheaper and later.

So the work splits in two:

| | What it is | Where it goes |
|---|---|---|
| **Ships** | Static props, frames, avatar parts, loading-screen art | `assets/art/`, rendered by Flutter as images |
| **Reference** | Turnarounds, expression sheets, key poses | Handed to the Rive animator with `docs/ART-BRIEF.md`; never shipped |

The reference half is worth generating even though it never ships: a turnaround
and an expression sheet in hand turn the character commission from "design
these four" into "rig these four", which is the cheaper and faster ask.

**Do not generate node markers.** The **trail**'s **node** markers are drawn in
code (`lib/features/season_map/presentation/trail_node_marker.dart`) because
every state is carried twice — colour *and* glyph *and* size — which is
constraint 5. Replacing them with flat illustrations would put the state back
on colour alone. Props sit *beside* the trail; they never become the markers.

---

## Workflow — generate the style anchor first

Consistency across separate generations is the whole problem. Solve it by
generating **one** anchor image, then passing that image back as a reference
with every subsequent prompt.

1. Run **Prompt 0** and iterate until the result is right. This is the only
   prompt you should expect to run many times.
2. Keep the winner as `docs/art/_style-anchor.png`.
3. For every prompt after that, attach the anchor and prefix with:
   *"Match the line weight, palette, shadow treatment and level of stylisation
   of the attached reference image exactly. Same world, same artist."*
4. For a set that must be internally consistent (the six **rank** poster frames,
   the forty avatar parts), also attach the first accepted image **from that
   set** as a second reference.

---

## The style block

Paste this verbatim into every prompt below. It is written once here rather
than repeated forty times.

> **STYLE — follow exactly, do not stylise beyond this.**
> Warm cartoon *about* the American West — the look of a children's animated
> series, not a spaghetti western. Flat vector illustration. No gradients, no
> airbrushing, no texture brushes, no photorealism, no 3D render, no cel-shading
> ramps.
> **Line:** thick outer contour in dark plum-black `#2E2438`, roughly 3px per
> 100px of subject height; interior detail lines noticeably thinner, roughly
> 2px. The difference between contour and interior weight must be visible —
> uniform stroke weight is forbidden.
> **Form:** exaggerated cartoon proportions, generous curves. Asymmetric pose —
> weight on one leg, head tilted, hat off-axis. Never centred and face-on.
> Limbs and props overlap the body for depth; no flat side-by-side arrangement.
> **Shadow:** solid offset only — a hard-edged copy of the shape, offset 4px
> down and right, filled in the darker shade of the same hue. No blur, no soft
> shadow, no ambient occlusion, no drop-shadow glow.
> **Palette — use only these hex values and no other hues:**
> `#F5EBD6` bone (light surfaces, paper) · `#E4D4AE` sand (ground, dust,
> background) · `#2E2438` duskInk (every outline, all dark) · `#F2B33D`
> badgeGold (brass, stars, reward, lamplight) · `#4A3F9E` nightIndigo ·
> `#1B6661` turquoise · `#E05A2B` sunsetRed · `#4E9E62` cactusGreen
> (vegetation).
> **Offset-shadow shades only:** `#B47A15` under gold, `#A03A15` under red,
> `#2F6E3F` under green, `#2F2670` under indigo, `#C9B48C` under bone and sand.
> Paper grain at about 4% opacity across the whole image.
> **Never:** weapons drawn in anger, gunfights, alcohol, saloons, blood, smoking,
> anything adult or violent, any colour outside the list above, any lettering
> unless the prompt asks for it.

And this output block, for anything that will be cut out and composited:

> **OUTPUT:** single subject, centred, whole subject inside frame with an 8%
> margin. Flat solid magenta `#FF00FF` background — no scenery, no ground line,
> no shadow cast onto the background, no text. Square, 2048×2048.

Magenta because it appears nowhere in the palette, so keying it out cannot eat
part of the subject. **Defringe after keying** — antialiased outer contours pick
up a magenta halo that is invisible on a white page and obvious on `sand`.

---

# A. The style anchor

### Prompt 0 — anchor

> [STYLE BLOCK]
>
> A single establishing illustration: a dusty frontier main street at midday,
> seen straight on. A low timber jailhouse with a brass star over the door, a
> saguaro cactus to the left, a wooden water trough to the right, a signpost
> leaning slightly. Empty of characters. Warm, inviting, slightly absurd — the
> buildings are a little too small and a little too rounded to be real.
>
> This image defines the house style for an entire game. Prioritise: visible
> contrast between thick outer contour and thin interior line; solid offset
> shadows with hard edges; flat fills with no gradient; the exact palette.
>
> **OUTPUT:** landscape 2048×1152, full scene, `#E4D4AE` sky and ground.

Accept it only when a greyscale copy still reads clearly and no colour outside
the eight tokens survives a colour-picker check.

---

# B. Ships as-is — Dust Gulch map props

This is the set that changes the screen as it stands today. `docs/ART-BRIEF.md`
asks for "six to eight per season" and names cacti, water troughs, jailhouse,
stagecoach and mine head; the layout doc (`docs/pages/screens.html`, Screen 01)
adds a cactus, a wagon and a water trough alongside the **trail**. Props are the
cheap seasonal variable — the rig stays, these rotate.

Generate each as its own image with the OUTPUT block above.

### Prompt 1 — saguaro cactus

> [STYLE BLOCK]
> A single saguaro cactus, cartoon, two raised arms of unequal height and angle.
> Body in `#4E9E62` with a solid offset shadow in `#2F6E3F`. Thick `#2E2438`
> contour. A few short paired spine ticks as interior detail, not a texture. It
> leans very slightly off vertical. Friendly, not spiky-threatening.
> [OUTPUT BLOCK]

### Prompt 2 — water trough

> [STYLE BLOCK]
> A wooden water trough, three-quarter view, staves and two iron bands. Timber in
> `#E4D4AE` with `#C9B48C` offset shadow, bands in `#2E2438`. Water surface a
> flat `#1B6661` shape with one simple highlight notch — no ripple detail, no
> transparency, no reflection.
> [OUTPUT BLOCK]

### Prompt 3 — jailhouse

> [STYLE BLOCK]
> A small frontier jailhouse, three-quarter view, squat and a little too rounded.
> Timber walls in `#E4D4AE`, roof and door frame in `#2E2438`, one barred window,
> a brass star in `#F2B33D` over the door with a `#B47A15` offset shadow. No
> lettering. Reads as a building at thumbnail size.
> [OUTPUT BLOCK]

### Prompt 4 — stagecoach

> [STYLE BLOCK]
> A stagecoach, side-on but angled slightly, no horses. Boxy rounded body in
> `#E4D4AE`, roof rack and wheel spokes in `#2E2438`, brass lamp in `#F2B33D`.
> Wheels of visibly unequal size, front smaller than rear, exaggerated. Slight
> tilt as if mid-halt.
> [OUTPUT BLOCK]

### Prompt 5 — mine head

> [STYLE BLOCK]
> A mine head: a timber A-frame headframe over a dark entrance cut into a low
> rock mound. Timbers in `#E4D4AE` with `#C9B48C` shadow, the entrance a flat
> `#2E2438` shape, a single pulley wheel in `#2E2438` with a `#F2B33D` hub. Rock
> mound in `#E4D4AE` a shade deeper. No mine cart.
> [OUTPUT BLOCK]

### Prompt 6 — buckboard wagon

> [STYLE BLOCK]
> A small buckboard wagon, side-on, no horses, parked. Bed and bench in
> `#E4D4AE`, iron work in `#2E2438`, one wheel turned slightly out of plane so it
> is not a flat disc. A rolled bedroll on the bed in `#F5EBD6`.
> [OUTPUT BLOCK]

### Prompt 7 — leaning signpost

> [STYLE BLOCK]
> A wooden signpost leaning about 8° off vertical, two blank arrow-shaped boards
> pointing opposite directions. Timber `#E4D4AE`, contour `#2E2438`, offset
> shadow `#C9B48C`. **The boards carry no lettering at all** — text is rendered
> by the app in Nunito and must not be baked into the image.
> [OUTPUT BLOCK]

### Prompt 8 — rock and scrub cluster

> [STYLE BLOCK]
> A small cluster of two rounded boulders and one low scrub bush, as a single
> composed silhouette. Boulders `#E4D4AE` with `#C9B48C` offset shadow, scrub
> `#4E9E62` with `#2F6E3F`. Asymmetric — one boulder clearly larger and set
> behind the other.
> [OUTPUT BLOCK]

**Sizing.** These render on the **trail** at roughly 80–140 logical px wide.
Generate at 2048, deliver 3x (`@3x`), 2x, and 1x. Check each at 30px before
accepting — `docs/ART-BRIEF.md` makes that the finishing test.

---

# C. Reference for the Rive animator — the cast

These **do not ship**. They go to the animator so the rig commission is a rigging
job rather than a design job. Order follows `docs/ART-BRIEF.md`'s priority,
adjusted for what a still can carry: Biscuit, Ace, the Sheriff, Number Four.

The silhouette cues below are quoted from the brief. Do not improvise on them —
the four characters have to pass the silhouette test against each other.

### Prompt 9 — Biscuit turnaround

> [STYLE BLOCK]
> Character turnaround sheet: **three** views of the same character side by side
> on one canvas — front, three-quarter, side — identical proportions and height
> across all three, standing on a common baseline.
> The character is **Biscuit**, a burro. Silhouette cues, mandatory: oversized
> ears, stocky body, a saddlebag. He is the only warm, uncomplicated presence in
> the cast — lean into it. Soft, rounded, slightly scruffy. Coat in `#E4D4AE`
> with `#C9B48C` shading, muzzle and hooves `#2E2438`, saddlebag `#E05A2B` with
> `#A03A15` offset shadow. Big dark friendly eyes.
> He never speaks — everything reads through ears and posture, so the ears must
> be expressive enough to carry a mood on their own.
> The three-quarter view is the primary game pose; make it the strongest.
> **OUTPUT:** landscape 2560×1024, flat `#F5EBD6` background, no text labels.

### Prompt 10 — Biscuit expression sheet

> [STYLE BLOCK] + attach Prompt 9's output as reference.
> Expression sheet: the head and neck of the same burro, eight times in a 4×2
> grid, identical scale and framing. The eight, in order: neutral, pleased,
> disappointed, impatient, smug, surprised, bored, delighted.
> **The ears do most of the work in every one** — he has no dialogue. Eyes and
> ear angle only; do not add props, speech bubbles, or symbols.
> **OUTPUT:** square 2048×2048, flat `#F5EBD6` background, no text labels.

### Prompt 11 — Ace turnaround

> [STYLE BLOCK]
> Character turnaround sheet: front, three-quarter, side, side by side, identical
> proportions, common baseline.
> The character is **Ace**, an outlaw. Silhouette cues, mandatory: a bandana over
> the lower face, a low hat brim shading narrow eyes, a playing card tucked
> somewhere on him, lean and angular, slightly hunched.
> He is a **nuisance, not a threat** — weary and faintly smug rather than
> menacing. No weapon anywhere in frame. Bandana in `#E05A2B` with `#A03A15`
> offset shadow; coat and hat in `#2E2438`; shirt `#F5EBD6`; the playing card
> `#F5EBD6` with a small `#E05A2B` pip.
> Three-quarter is the primary game pose.
> **OUTPUT:** landscape 2560×1024, flat `#F5EBD6` background, no text labels.

### Prompt 12 — Ace expression sheet

> [STYLE BLOCK] + attach Prompt 11's output as reference.
> Expression sheet: head and shoulders, eight times in a 4×2 grid, identical
> scale. Neutral, pleased, disappointed, impatient, smug, surprised, bored,
> delighted.
> The bandana covers his mouth, so **the eyes and eyebrows carry every
> expression**, with the hat brim angle as a second channel. "Disappointed" is
> the most important of the eight — it is the face he makes when the player
> solves a puzzle cleanly, and it should read as genuinely deflated.
> **OUTPUT:** square 2048×2048, flat `#F5EBD6` background, no text labels.

### Prompt 13 — the Sheriff turnaround

> [STYLE BLOCK]
> Character turnaround sheet: front, three-quarter, side, identical proportions,
> common baseline.
> The character is **the Sheriff**, the player's grizzled boss. Silhouette cues,
> mandatory and deliberately absurd in proportion: an enormous hat, an enormous
> moustache, a barrel chest, small bowed legs, thumbs hooked into a heavy belt, a
> star badge. The hat and moustache should be comically oversized relative to the
> legs.
> Dry and hard to please, never angry. Hat and waistcoat `#2E2438`, shirt
> `#F5EBD6`, star badge `#F2B33D` with `#B47A15` offset shadow, belt `#E4D4AE`.
> No weapon.
> Three-quarter is the primary game pose.
> **OUTPUT:** landscape 2560×1024, flat `#F5EBD6` background, no text labels.

### Prompt 14 — the Sheriff expression sheet

> [STYLE BLOCK] + attach Prompt 13's output as reference.
> Expression sheet: head and shoulders, eight in a 4×2 grid, identical scale.
> Neutral, pleased, disappointed, impatient, smug, surprised, bored, delighted.
> **The moustache is the primary expressive element** — it should change shape
> meaningfully between panels — with the eyebrows second. Keep the range narrow
> and deadpan: his "pleased" is barely distinguishable from his "neutral" at a
> glance, and that restraint is the joke. Do not caricature him into broad
> comedy.
> **OUTPUT:** square 2048×2048, flat `#F5EBD6` background, no text labels.

### Prompt 15 — Number Four

> [STYLE BLOCK]
> A character who is the **numeral 4**, with a face and small limbs. Critical
> constraint: it must read as a legible digit 4 **first** and a character
> **second** — at 30 pixels tall it has to still be unmistakably the number 4.
> The face sits inside the closed triangular counter of the 4; arms and legs are
> short and stick out from the stem. Do not round the numeral into a blob or
> break its strokes.
> Numeral body in `#4A3F9E` with `#2F2670` offset shadow, contour `#2E2438`.
> Expression: mildly objecting, as if about to refuse an instruction.
> Produce **three** panels side by side: neutral standing, mid-objection with one
> arm raised, and a small satisfied bow.
> **OUTPUT:** landscape 2560×1024, flat `#F5EBD6` background, no text labels.

### Prompt 16 — digit reaction key poses *(reference for the highest-priority animation)*

> [STYLE BLOCK]
> A reference sheet for a two-character animation beat, four key poses left to
> right on one canvas.
> Two numerals — a **7** and a second identical **7** — drawn as characters in
> the same manner as the attached reference, sitting in two separate rounded
> square cells. The beat: both digits turn, notice each other, and react **in
> horror** — comic dismay, not fear. Poses: (1) both neutral, facing forward;
> (2) both beginning to turn toward each other; (3) full recognition, eyes wide,
> bodies recoiling apart; (4) held dismay, slight wobble.
> Cell backgrounds go from `#F5EBD6` in pose 1 to `#FBDDD6` by pose 3. Digits in
> `#2E2438`. A small `#E05A2B` exclamation mark pops above each in poses 3 and 4.
> Comic and charming, never scolding — this replaces a red error flash and must
> feel like a joke the game is making *with* the player.
> **OUTPUT:** landscape 2560×1024, flat `#E4D4AE` background.

This one is reference only, but it is the most valuable page in the pack: it is
the animation `docs/ART-BRIEF.md` ranks first and D-42 calls the clearest
expression of the product.

---

# D. Ships as-is — deputy avatar parts

`docs/ART-BRIEF.md` wants roughly forty parts at launch as **flat layers on one
rig**, which is exactly what a still model is good at. Generate them as sets, not
one at a time, so a set stays internally consistent.

Every part must be drawn to the **same head anchor**, or they will not composite.
Establish that first:

### Prompt 17 — the avatar base head

> [STYLE BLOCK]
> A blank cartoon head for a customisable player avatar, three-quarter view,
> facing slightly left. Neutral friendly expression, no hat, no facial hair, no
> accessories. Skin in `#E4D4AE` with `#C9B48C` offset shadow, contour `#2E2438`.
> The head fills exactly the centre 60% of the canvas height, centred
> horizontally, so that accessory layers generated against this same framing will
> align.
> **OUTPUT:** square 2048×2048, flat `#FF00FF` background.

Then, for each set below, attach Prompt 17's output and say: *"Draw only the
accessory, positioned exactly as it would sit on the attached head. Do not draw
the head. Output the accessory alone on flat `#FF00FF`."*

| Prompt | Set | Count | Ask for |
|---|---|---|---|
| 18 | Hats | 10 | Ten-gallon, bowler, flat cap, sombrero, straw, fur, pillbox, battered stetson, conductor's cap, no-hat-but-hair |
| 19 | Moustaches | 8 | Handlebar, walrus, pencil, horseshoe, toothbrush, muttonchops, full beard, clean-shaven |
| 20 | Kerchiefs | 6 | Plain, polka dot, striped, bandana-worn-high, loose knot, ascot |
| 21 | Badges | 6 | Five-point star, six-point star, shield, circle, ribboned, tarnished |
| 22 | Spectacles | 5 | Round wire, square wire, pince-nez, tinted, monocle |
| 23 | Waistcoats | 6 | Plain, pinstripe, brocade, leather, quilted, fringed |

Each set prompt takes the form:

> [STYLE BLOCK] + attach Prompt 17.
> Draw **only** the accessory described, positioned exactly as it would sit on
> the attached head, at the attached head's scale and three-quarter angle. Do not
> draw the head, face, neck or body.
> Produce the following as separate images, one per generation: *[name the single
> item]*.
> Colours: pick from `#E4D4AE`, `#F5EBD6`, `#2E2438`, `#F2B33D`, `#E05A2B`,
> `#4E9E62`, `#4A3F9E`, `#1B6661` only, with the matching offset-shadow shade.
> **OUTPUT:** square 2048×2048, flat `#FF00FF` background.

Generate one item per call. A prompt asking for ten hats on one sheet returns
ten hats at ten different scales and none of them composite.

---

# E. Ships as-is — posters, frames and loading screens

### Prompt 24 — wanted poster frame

> [STYLE BLOCK]
> An empty "WANTED" poster: a rectangle of aged paper in `#F5EBD6` with slightly
> torn, irregular edges, four small `#2E2438` tack marks at the corners, pinned to
> nothing. The paper is rotated about 1.5° off square.
> **The centre must be entirely empty** — a blank portrait area occupying the
> middle 60% — because a player avatar is composited into it by the app.
> **No lettering anywhere**; the app renders all text in Nunito.
> A decorative `#2E2438` double rule inside the border, top and bottom.
> **OUTPUT:** portrait 1536×2048, flat `#FF00FF` background.

`docs/ART-BRIEF.md` wants these "progressively more disreputable as rank rises".
Run this six times, once per **rank** — Greenhorn, Deputy, Sheriff, Marshal,
Ranger, Legend — attaching the previous one each time and asking for *"the same
poster, one step more weathered, more torn, more tacked-over"*. Greenhorn is
crisp and new; Legend is a much-abused survivor.

### Prompt 25 — telegram slip *(loading screen, change 22)*

> [STYLE BLOCK]
> A telegram slip: a small rectangle of `#F5EBD6` paper with a printed header
> band in `#E4D4AE`, a row of punched holes down the left edge, one corner
> slightly curled, rotated 1° off square. Solid offset shadow in `#C9B48C`.
> **No lettering** — the app renders the message text.
> **OUTPUT:** landscape 2048×1152, flat `#FF00FF` background.

### Prompt 26 — newspaper front page *(loading screen, change 22)*

> [STYLE BLOCK]
> A folded frontier newspaper seen front-on, `#F5EBD6` paper, a heavy `#2E2438`
> masthead rule across the top and column rules below it. **Body text is
> represented as plain grey-ink rules only, never as legible or pseudo-legible
> letterforms** — no lorem ipsum, no scribbled glyphs. A single empty rectangular
> hole in the upper-left column where a photograph would sit.
> Rotated 1.5° off square, one soft fold crease.
> **OUTPUT:** portrait 1536×2048, flat `#FF00FF` background.

### Prompt 27 — season key art, Dust Gulch

> [STYLE BLOCK] + attach Prompt 0.
> A wide banner illustration of the Dust Gulch territory: a dusty gulch with low
> mesas on both sides receding into a `#E4D4AE` sky, a winding pale trail through
> the middle distance, a saguaro and a jailhouse small in the frame.
> **Empty of characters.** Composition must leave the upper-left third visually
> quiet — a season title and progress counter are drawn over it.
> **OUTPUT:** landscape 2048×1152, full-bleed, no background keying.

---

## Technical acceptance

Check every delivered asset against all five. Anything that fails goes back.

1. **Palette.** Colour-pick at least six points. Every one must be a value from
   `docs/DESIGN.md` §1 or a straight blend of two of them. A ninth hue violates
   constraint 3, and no amount of "it looks better" overrides that.
2. **30px.** Scale to 30px tall. If you cannot tell what it is,
   `docs/ART-BRIEF.md` says the design is not finished.
3. **Silhouette.** Fill solid black. The four characters must be tellable apart
   from each other; a prop must still read as its object.
4. **Greyscale.** Desaturate. Nothing important may disappear — colour is never
   the sole signal for a state (constraint 3).
5. **Shadow.** Every shadow must be hard-edged and offset. A blurred shadow
   means the model ignored the style block; regenerate rather than retouch, or
   the next asset will drift too.

## Delivery

- Cut out the magenta, **defringe the edges**, export PNG with real alpha.
- Land them under `assets/art/<set>/` and declare them in `pubspec.yaml`. The
  `assets:` block there lists **individual files, not directories**, and the
  comment beside `frontier-1.json` says why: a directory entry sweeps the notes
  and licence files sitting next to the assets into the binary. Either keep
  listing files one by one, or add `assets/art/<set>/` as a directory only once
  that folder holds nothing but shipped images.
- Provide `@1x`, `@2x`, `@3x` per Flutter's convention.
- Keep the 2048px masters out of the app bundle.

## What this still does not cover

Sound. `docs/DESIGN.md` §6 specifies per-event audio, `openspec/BACKLOG.md`
records that no change owns it and no audio package is chosen, and an image
model does not help. It needs a decision and a change of its own.
