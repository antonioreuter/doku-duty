# Delta for daily-challenge

## ADDED Requirements

### Requirement: The daily is always classic

The system MUST NOT resolve a **daily challenge** to a **killer** puzzle, whether
from the published schedule or from the fallback that derives a board from the
**pack** (D-127).

#### Scenario: No schedule is published

- **WHEN** the **daily challenge** is derived from the **pack** for a date
- **THEN** it is a classic puzzle, whatever **killer** puzzles the **pack** holds
  at that day's **rank**

#### Scenario: The schedule names a killer puzzle

- **WHEN** a published schedule names a **killer** puzzle for a date
- **THEN** that entry is refused exactly as an entry naming an unknown puzzle is,
  and the date falls back to its derived classic board
