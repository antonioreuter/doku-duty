---
paths:
  - "docs/specs/**"
  - "docs/changes/**"
---

# Writing specs

`docs/specs/<capability>.md` is the permanent record of what a player or another
capability can observe. One file per capability; the names are fixed in
`docs/BACKLOG.md` and match `lib/features/<capability>/` (kebab-case →
snake_case). Do not invent a capability without adding it to the backlog.

- **Observable behaviour only.** Internal refactors, dependency bumps and CI
  work get no requirement. When in doubt, write it — an unnecessary requirement
  is cheaper than a capability with no record.
- Each requirement is a `### Requirement: <name>` heading, phrased
  `The system MUST …`, and carries at least one `#### Scenario:` with
  `- **WHEN**` / `- **THEN**` bullets.
- A requirement that encodes a product decision cites its `D-NN` from
  `docs/DECISIONS.md` rather than restating the argument.
- Use `docs/GLOSSARY.md` terms exactly, in bold on first use in a requirement.
  If the requirement needs a word the glossary does not define, or uses a term
  beyond its definition, settle it first (`mattpocock-skills:domain-modeling`)
  and add it to `docs/GLOSSARY.md` in the same change. A spec built on an
  undefined word cannot be reviewed against anything.
- Add a scenario for the offline case whenever the change touches network, and
  one for the non-punitive default wherever a penalty could be inferred.
- Edit the capability file in place. There are no delta files: the diff is the
  delta. Rewrite a changed requirement in full; delete a removed one and say
  why in the change's proposal.
- If the developer ran a grilling session for this change, re-read its output
  from disk, not from memory. A precise answer — an ordering guarantee, a
  numeric default, a negative requirement — softened into weaker prose is how
  this step fails. Say so if one does not survive into a requirement.
- When code and spec disagree, stop and ask. Change the spec deliberately;
  never let the code quietly become the spec. If the decision behind it is
  wrong, amend `docs/DECISIONS.md` first, then the spec.
