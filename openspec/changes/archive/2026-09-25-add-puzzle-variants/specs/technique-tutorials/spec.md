# Delta for technique-tutorials

## ADDED Requirements

### Requirement: Each killer technique has a lesson, whatever its rank

The system MUST provide a **lesson** for cage combination and for the 45 rule,
including cage combination although Greenhorn introduces it. A player meeting
**cage**s for the first time has not seen them at any **rank**, which is not
true of full house or naked single (D-128).

#### Scenario: The catalogue covers the killer techniques

- **WHEN** the **lesson** catalogue is read
- **THEN** it holds one **lesson** for cage combination and one for the 45 rule

#### Scenario: A killer lesson fires

- **WHEN** a **killer** puzzle that needs cage combination is opened by a player
  who has not seen its **lesson**
- **THEN** that **lesson** fires on the same terms as any other — at most one
  per opening, skippable in one tap (D-106)

#### Scenario: The cage lesson comes before a harder killer lesson

- **WHEN** a **killer** puzzle needing the 45 rule is opened by a player who has
  seen the **notes lesson** but not the cage combination **lesson**, and has
  not solved a **killer** puzzle
- **THEN** the cage combination **lesson** fires rather than the 45 rule's,
  because it is the one that explains what a **cage** is — and after that
  puzzle is solved it would never be due again

#### Scenario: A killer lesson is replayed

- **WHEN** the **lesson** list is opened from the **cabinet**
- **THEN** both **killer** **lesson**s are listed and replayable, like every
  other
