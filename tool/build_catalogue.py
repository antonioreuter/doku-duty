import json, textwrap

pos = {e['technique']: e for e in json.load(open('tool/lesson_positions.json'))}

def rc(cell):
    return f"r{cell//9+1}c{cell%9+1}"

# One sentence per step. The player is mid-puzzle; reading is not why they
# opened the app. No character speaks — the cast belongs to change 20.
COPY = {
 'hiddenSingle': ("Hidden single",
   ["Look at the {d}s already placed. They cover every cell of this box but one.",
    "So although this cell could hold several digits, it is the only place left in the box for a {d}.",
    "Place the {d}."]),
 'nakedPair': ("Naked pair",
   ["These two cells can hold nothing but {pair}.",
    "Between them they will use both digits, so no other cell in the unit can be {pair}.",
    "Take {pair} out of the rest, and this cell has only the {d2} left. Place it."]),
 'pointingPair': ("Pointing pair",
   ["Inside this box, the {d}s can only go in these cells — and they share a line.",
    "Wherever the {d} lands in the box, it is on that line, so the {d} is ruled out of the rest of the line.",
    "That leaves this cell with only the {d2}. Place it."]),
 'boxLineReduction': ("Box-line reduction",
   ["On this line, the {d}s can only go in cells that all sit inside one box.",
    "The line needs its {d}, so the {d} must be in that box — and is ruled out of the box's other cells.",
    "This cell is left with only the {d2}. Place it."]),
 'nakedTriple': ("Naked triple",
   ["These three cells hold nothing outside {pair}.",
    "Three cells, three digits: between them they use all of it, so none of the three can appear elsewhere in the unit.",
    "That clears this cell down to the {d2}. Place it."]),
 'hiddenPair': ("Hidden pair",
   ["In this unit, {pair} can only go in these two cells.",
    "So these two cells hold that pair and nothing else — every other candidate comes out of them.",
    "That settles the unit far enough to leave this cell with only the {d2}. Place it."]),
 'xWing': ("X-wing",
   ["Look at the {d}s on these two lines: each has only two places, and they line up.",
    "Whichever way the two {d}s fall, they take both of those columns — so the {d} is out everywhere else in them.",
    "This cell is left with only the {d2}. Place it."]),
 'swordfish': ("Swordfish",
   ["The same shape as an X-wing, one size larger: three lines, and the {d}s in them share three columns.",
    "Three {d}s must fill those three columns, so no other cell in them can be a {d}.",
    "That leaves this cell holding only the {d2}. Place it."]),
 'xyWing': ("XY-wing",
   ["Three cells of two candidates each: a pivot, and two others it shares a digit with.",
    "Whichever the pivot takes, one of the wings is forced to {d} — so any cell seeing both wings cannot be {d}.",
    "This cell loses its {d} and is left with the {d2}. Place it."]),
 'simpleChain': ("Simple chain",
   ["Follow the {d}s: each of these cells has only two places for it, linked end to end.",
    "The links alternate, so both ends cannot be {d} — and a cell seeing both ends cannot be {d} either.",
    "That leaves this cell with only the {d2}. Place it."]),
}

def dart_list(xs):
    return '<int>[' + ', '.join(str(x) for x in xs) + ']'

out = []
for tech, (title, steps) in COPY.items():
    e = pos[tech]
    elim_cells = sorted({x['cell'] for x in e['eliminations']})
    elim_digits = sorted({x['digit'] for x in e['eliminations']})
    wit = e['witnesses']
    d = elim_digits[0] if elim_digits else (e['placements'][0]['digit'] if e['placements'] else e['answerDigit'])
    pair = ' and '.join(str(x) for x in elim_digits[:3]) if len(elim_digits) > 1 else str(d)
    # For naked pair/triple the "pair" is the candidates the witnesses hold, not
    # the eliminated ones; the eliminated set is the same digits, so this holds.
    subs = {'d': d, 'd2': e['answerDigit'], 'pair': pair}
    rendered = [s.format(**subs) for s in steps]
    cells = [wit, elim_cells if elim_cells else wit, [e['answerCell']]]
    body = ',\n'.join(
        f"      LessonStep(\n        text: '{t.replace(chr(39), chr(92)+chr(39))}',\n        cells: {dart_list(c)},\n      )"
        for t, c in zip(rendered, cells))
    out.append(f"""  Lesson(
    id: '{tech}',
    title: '{title}',
    technique: Technique.{tech},
    grid: '{e['grid']}',
    steps: const <LessonStep>[
{body},
    ],
    placement: const LessonPlacement(cell: {e['answerCell']}, digit: {e['answerDigit']}),
  )""")

print(',\n'.join(out))
