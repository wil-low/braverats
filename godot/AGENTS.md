# Braverats — Godot 4.7 Bluffing Card Game

2-player strategy card battle game · 672×384 viewport (8× scale, 84×48 logical)

---

## Navigation

| Topic | File |
|---|---|
| **Game rules** | [rules.md](docs/rules.md) |
| **Architecture & porting plan** | [architecture.md](architecture.md) |
| **AI strategies** | [docs/strategy.md](docs/strategy.md) |
| **GDScript conventions** | [docs/conventions.md](docs/conventions.md) |
| **Cross-cutting invariants** | [docs/invariants.md](docs/invariants.md) |
| **Open tasks / TODOs** | [docs/todo.md](docs/todo.md) |

## Quick File Reference

| What do you want to change? | Edit |
|---|---|
| **Game rules** | `docs/rules.md` |
| **Main game loop** | `main/main.gd` |
| **Card scene** | `card/card.tscn` + `card/card.gd` |
| **Player input** | `main/game_state.gd` (state) + new player hand scene (Phase 2) |
| **AI decision-making** | `main/game_logic.gd` (pure logic) + new `ai.gd` (Phase 3) |
| **Deck management** | `deck/deck.gd` |
| **Animation** | `animator/animator.gd` |
| **Scene navigation** | `application/application.gd` |
| **Settings (AI levels + speed)** | `level_selector/*.gd` |
| **Win/loss stats** | `stats/stats.gd` |

## GDScript Conventions (Quick Reference)

- **Tabs** for indentation; ternary: `value1 if condition else value2`
- **`class_name`** for all reusable scripts; **`_on_*`** for signal handlers
- **Signals** for cross-scene communication — never direct node references between scenes
- **`await Animator.*`** for timed sequences — never `yield` or `get_tree().create_timer`
