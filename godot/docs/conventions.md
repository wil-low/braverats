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

## Braverats Card Reference (Sprite Frames)

Card character sprites use `characters.png` where frame index = power value (0–7).
See `docs/rules.md` for card effect descriptions.

| Power | Name | Frame | Notes |
|---|---|---|---|
| 0 | Jester | 0 | — |
| 1 | Lady | 1 | — |
| 2 | Spy | 2 | — |
| 3 | Assassin | 3 | — |
| 4 | Chancellor | 4 | — |
| 5 | Magician | 5 | — |
| 6 | General | 6 | — |
| 7 | Prince | 7 | — |
