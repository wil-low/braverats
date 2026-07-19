# GDScript Conventions

## Indentation & Syntax

- **Tabs** for indentation in GDScript files
- **`value1 if condition else value2`** as ternary expression (GDScript 2.0)

## Naming & Structure

- **`class_name`** for all reusable scripts (Card, Player, Deck, Main, Animator, Memory, etc.)
- **`_on_*`** naming for signal handler methods
- **`@onready var`** for node references resolved at `_ready()` time

## Communication

- **Signals** for cross-scene communication — never direct node references between scenes
- Signals pass actual data (cards, ranks), not indices

## Timed Sequences

- **`await Animator.flip/move_card/delay`** for all timed sequences
- **Never** use `yield` or `await get_tree().create_timer` directly

## Braverats Card Reference (in porting)

| Power | Name | characters.png frame | Effect |
|---|---|---|---|
| 0 | Jester | 0 | Round nullified → on hold. Overrides all except Magician. |
| 1 | Lady | 1 | If opponent played Prince, instant game win. |
| 2 | Spy | 2 | Next round, opponent reveals first. Both Spies = both see opponent. |
| 3 | Assassin | 3 | Lowest strength wins (inverts comparison). After other effects. |
| 4 | Counsellor | 4 | Wins 2 points if round won. Cancels if both play it. |
| 5 | Magician | 5 | Nullifies opponent's power. Does not affect General's +2. |
| 6 | General | 6 | Next card gets +2 strength. Cannot be nullified by subsequent Magician. |
| 7 | Prince | 7 | Wins round regardless of strength. Loses to Lady, loses to Assassin. |
