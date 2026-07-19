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

## Game-Specific Enums

| Enum | Values | Meaning |
|---|---|---|
| `Move.Action` | `Discard_1`, `Discard_2`, `Discard_3`, `Challenge` | Discard_X = player discards X cards for the table rank |
| `Player.State` | `IDLE`, `SELECT_DISCARD`, `SELECT_CHALLENGE` | Controls what input is accepted |
| `Card.Rank` | `Ace` (0) through `King` (9), `Unknown` (10) | Card rank enum |
| `Player.AI_Level` | `H` (0), `L1` (1) through `L4` (4) | Human + 4 difficulty levels |

## Data Conventions

- **`Move._table_rank`**: Always the declared table rank, never the actual card ranks of the discard
- **`Memory`**: Initialized per game in `_new_game()`, shared via `Player.memory`
- **AI class**: Static-only `class_name` — no members, only static methods
