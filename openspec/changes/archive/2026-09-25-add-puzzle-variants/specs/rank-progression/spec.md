# Delta for rank-progression

## ADDED Requirements

### Requirement: A killer solve counts on the same terms as a classic one

The system MUST write a **solve record** for a completed **killer** puzzle
exactly as for a classic one, so it can raise the player's **rank** and grant a
**technique unlock** (D-102, D-104, D-128).

#### Scenario: A killer puzzle above the player's rank is solved

- **WHEN** a player completes a **killer** puzzle graded above their **rank**
- **THEN** their **rank** becomes that **rank**, as it would for a classic
  puzzle

#### Scenario: A killer puzzle needing a killer technique is solved

- **WHEN** a player completes a **killer** puzzle whose grade required the 45
  rule
- **THEN** the 45 rule's counter rises and it becomes a **technique unlock**,
  alongside any classic techniques the grade required
