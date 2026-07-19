# Cheaters — Godot 4.7 Bluffing Card Game

Game engine: **Godot 4.7** (GL Compatibility, 672×384 viewport, 8× pixel scale)

## Navigation

| Topic | File |
|---|---|
| **Game rules** | [rules.md](rules.md) |
| **Architecture & status** | [architecture.md](architecture.md) |
| **AI strategies** | [strategy.md](strategy.md) |
| **GDScript conventions** | [docs/conventions.md](docs/conventions.md) |
| **Cross-cutting invariants** | [docs/invariants.md](docs/invariants.md) |
| **Future work / TODOs** | [docs/todo.md](docs/todo.md) |

## Quick File Reference

| What do you want to change? | Edit |
|---|---|
| **Game rules** | `rules.md` |
| **Main game loop** | `main/main.gd` |
| **Card animations** | `animator/animator.gd` |
| **Player input** | `player/player.gd` + `main/main.gd` |
| **AI decision-making** | `player/ai.gd` |
| **AI difficulty levels** | `player/ai_level_*.gd` |
| **Card data** | `card/card.gd` |
| **Deck management** | `deck/deck.gd` |
| **Move data class** | `player/move.gd` |
| **Memory system** | `player/memory.gd` |
| **Scene navigation** | `application/application.gd` |
| **Settings (AI levels + speed)** | `level_selector/*.gd` |
| **Win/loss stats** | `stats/stats.gd` |
| **Pause screen** | `pause/pause.gd` |

## Conventions

Full GDScript conventions, enums, and data patterns → [docs/conventions.md](docs/conventions.md)
