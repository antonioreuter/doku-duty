# Delta for grid-input

## ADDED Requirements

### Requirement: Every pad key announces its name, never its glyph

The system MUST give each key on the number pad a spoken name — "Erase",
"Undo", "Notes", "Fill notes", or the digit — and MUST NOT include the symbol
drawn on it in that announcement. Each key MUST remain pressable by the
assistive technology that reads it.

The pad draws ⌫, ↶, ✎, and ⁙. Read aloud those are noise at best and nothing at
worst, and a key announced as "Notes ✎" buries the only word that carries
meaning. This is the same rule constraint 5 applies to the grid, one layer out:
the symbol is decoration, and the name is the state.

#### Scenario: A key drawn as a symbol

- **WHEN** a key whose face is a symbol is reached by a screen reader
- **THEN** it is announced by its name alone, with the symbol left unspoken

#### Scenario: A digit key

- **WHEN** a digit key is reached by a screen reader
- **THEN** it is announced as that digit, because there the face and the name
  are the same word

#### Scenario: A named key can still be pressed

- **WHEN** a key is announced by name
- **THEN** the assistive technology can activate it — naming a button that
  cannot be pressed is a worse failure than naming it badly

#### Scenario: A held key says so

- **WHEN** a digit is held in digit-first input, or notes mode is on
- **THEN** the key that is in force reports itself as selected, so the mode is
  readable without seeing which key is painted differently (constraint 5)
