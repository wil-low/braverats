# Braverats — Architecture & Porting Plan

## Project Structure

```
src/
├── project.godot           # Godot 4.7 config, 672×384 viewport, GL compat
├── application/            # Application root (SceneTree controller)
│   ├── application.gd      # Manages Start↔Main↔Pause↔Settings↔Stats flow, AI levels, config, speed, stats tracking
│   └── application.tscn    # Root node with Start, Main, Pause, LevelSelector, Stats, Help children
├── start/                  # Start screen
│   ├── start.gd            # Start class: emits play_pressed, settings_pressed, stats_pressed, help_pressed
│   └── start.tscn          # Title + PLAY/SETTINGS/STATS/HELP buttons
├── main/                   # Main game scene + logic — ✅ FULLY IMPLEMENTED
│   ├── main.gd             # Complete Cheaters game loop: init_players, deal, new_turn, table_rank (first-player-set),
│   │                         # discard flow, challenge resolution, pile draw, forced 4-of-a-kind discard, win check,
│   │                         # round_over, auto-run game_counter
│   └── main.tscn           # Player0-3, Deck, CentralDisplay, LastDeck, TableRank label,
│   │                         # Discard/Challenge buttons, MenuButton, MessageBox overlay, AudioPlayers, AnimationLayer
├── pause/                  # Pause overlay
│   ├── pause.gd            # Pause class: resume, stats, help, exit signals
│   └── pause.tscn          # Resume/STATS/HELP/EXIT buttons
├── level_selector/         # Settings: AI level + speed selection
│   ├── level_selector.gd   # LevelSelector class: aggregates PlayerLevel nodes + SpeedLevel, emits levels_changed
│   ├── level_selector.tscn # BackButton, Levels (P_0, P_1, P_2, P_3), SpeedLevel
│   ├── player_level.gd     # PlayerLevel: per-player AI level selector (Human/1/2/3/4), ± buttons
│   ├── player_level.tscn   # Title + LeftButton + Level label + RightButton
│   ├── speed_level.gd      # SpeedLevel: animation speed selector (1-5), ± buttons
│   ├── speed_level.tscn    # Title "SPEED:" + LeftButton + Level label + RightButton
│   ├── digit_button.gd     # DigitButton class: TextureButton with frame enum (0-9, H, :, <, >, back, reset)
│   └── digit_button.tscn   # 9×9 button with DigitSprite child, hframes=16
├── stats/                  # Win/Loss statistics screen
│   ├── stats.gd            # Stats class: tracks totals_and_wins array per AI level, update_labels, reset
│   └── stats.tscn          # BackButton, ResetButton, L_H/L_1/L_2/L_3/L_4 stat labels
├── deck/                   # Deck class
│   ├── deck.gd             # class_name Deck, prepare_cheaters() — 9 ranks × 4 minus 1 random = 35 cards,
│   │                         # card_scene/fan_offset exports, pop() draws, clear(), shift_to() animates cards
│   └── deck.tscn           # Sprite2D with card back, card_scene reference
├── card/                   # Card class
│   ├── card.gd             # class_name Card extends Area2D, Rank enum (Ace=0..King=9, Unknown=10),
│   │                         # RANK_NAMES array, rank/faceup props, _update_display() switches sprite & label,
│   │                         # get_rank_char() returns "A"/"6"/.../"K"/"?"
│   ├── card.tscn           # Area2D + Sprite2D + Value Label, hframes=2 (face/face-down)
│   └── cards.png           # Card spritesheet: 9 ranks face-up + 1 face-down back
├── player/                 # Player class + AI strategy + Memory — ✅ FULLY IMPLEMENTED
│   ├── player.gd           # class_name Player, AI_Level (H/L1-L4), hand (Deck),
│   │                         # memory (Memory), idx, badge display, card input handler
│   │                         # Signals: cards_discarded(count, table_rank, cards), challenge_declared, move_chosen
│   │                         # States: IDLE, SELECT_DISCARD, SELECT_CHALLENGE
│   ├── player.tscn         # Node2D + Hand (Deck) + Badge Sprite2D + Current marker (ColorRect) + Score label
│   ├── memory.gd           # class_name Memory — 2D array max_card_count[player][rank],
│   │                         # set_guess(player, rank, count) / get_guess(player, rank) helpers
│   ├── ai.gd               # class_name AI (static-only) — dispatches to level strategies via:
│   │                         #   select_discard(memory, my_hand, ai_level, table_rank) → Move
│   │                         #   should_challenge(memory, ai_level) → bool
│   │                         #   _random_discard() fallback, _argmax_score() utility
│   ├── move.gd             # class_name Move (RefCounted), Action enum (Discard_1..Discard_3, Challenge),
│   │                         # _action / _table_rank / _cards / _score, ACTION_NAMES, ACTION_DISCARD_COUNT
│   ├── ai_level_1.gd       # L1: Weighted random discard (30% prefer matching table rank), 10% challenge rate
│   ├── ai_level_2.gd       # L2: Prefers 2-3 of table rank if available, bluffs with fewer cards (1-2 random)
│   ├── ai_level_3.gd       # L3: Heuristic — safe discards (2+ matching), bluffs prefer singletons over pairs
│   └── ai_level_4.gd       # L4: Delegates to L3 (MCTS too complex for bluffing)
├── animator/               # Animation helper
│   ├── animator.gd         # class_name Animator (Node), _speed variable (default 2, 0=disabled),
│   │                         # helpers: delay, all (combines signals), flip, reveal_hand, move_card, flash
│   │                         # _d() speed divisor, _immediate() for instant signals, _WaitAll for parallel waits
│   └── animator.tscn       # Singleton autoload node
├── digit_sprite/           # Digit display
│   ├── digit_sprite.gd     # class_name DigitSprite extends Sprite2D
│   ├── digit_sprite.tscn   # Sprite2D with digits.png, hframes=16 (used by digit_button)
│   └── digits.png          # 48×5 digit spritesheet
├── tres/                   # Shared resources
│   └── label_settings.tres # Gamebuino pixel font settings
├── audio/                  # Sound effects
│   ├── card-slide-6.ogg    # Card slide sound
│   ├── GameWon.ogg         # Game won fanfare
│   ├── RoundWon.ogg        # Round won fanfare
│   └── jingles-retro_*.ogg # Retro jingles
├── Gamebuino.ttf           # Pixel font
├── rules.md                # Game rules reference
├── plan.md                 # Implementation plan
└── architecture.md         # This file
```

## Key Classes

| Class | Type | Role |
|-------|------|------|
| `Deck` | `class_name` | `prepare_cheaters()` — 9 ranks × 4 minus 1 random = 35 cards; `pop()` draws; `clear()`; `shift_to()` animates; `card_scene`/`fan_offset` exports |
| `MultiCard` | `class_name Node2D` | Groups up to 4 cards of the same rank. Two sprite states: `_available` (not selected) + `_selected` (selected). `_available.frame + _selected.frame = total cards of rank`. Click toggles; fully-selected click deselects all. Visible when `_available.frame > 0` |
| `MultiDeck` | `class_name Deck` | Parent of 9 MultiCard nodes (one per rank). Used in compact mode: `hand` is a `MultiDeck` instead of `Deck`. `get_selected_cards()` extracts selected cards, resets `_selected.frame`, sets visibility per rank |
| `Card` | `class_name Area2D` | `Rank` enum (Ace=0..King=9, Unknown=10); `RANK_NAMES`; `rank`/`faceup` props; `_update_display()` switches sprite frame & label; `get_rank_char()` |
| `Memory` | `class_name RefCounted` | 2D array `max_card_count[player][rank]`; `set_guess(player, rank, count)` tightens estimate (never increases); `get_guess(player, rank)` returns -1 for unknown |
| `Player` | `class_name Node2D` | `AI_Level` (H/L1-L4), `hand` (Deck), `memory` (Memory), `idx`, badge display, card input handler; States: IDLE, SELECT_DISCARD, SELECT_CHALLENGE |
| `AI` | `class_name` (static) | `select_discard(memory, my_hand, ai_level, table_rank)` dispatches to L1-L4; `should_challenge(memory, ai_level)` dispatches to L1-L4; `_random_discard()`, `_argmax_score()` |
| `Move.Action` | enum | Discard_1, Discard_2, Discard_3, Challenge — unified action enum |
| `Move` | `class_name RefCounted` | `_action` / `_table_rank` / `_cards` / `_score`; `ACTION_NAMES`, `ACTION_DISCARD_COUNT`; `_to_string()` for debugging |
| `Main` | `class_name Node2D` | Game loop: `init_players`, `_new_game`, `_new_round` (deal 35 cards, table_rank=Unknown), `new_turn`, `_state_discard()`, `_state_force_challenge()`, `_on_cards_discarded()`, `_execute_discard_move()`, `_execute_challenge()`, `_resolve_challenge_won()`, `_draw_pile()`, `_force_4_of_a_kind_discard()`, `_check_winner()`, `_round_over()`, `_on_discard_pressed()`, `_on_challenge_pressed()` |
| `Animator` | `class_name Node` (autoload) | `_speed` variable; `delay`, `all`, `flip`, `reveal_hand`, `move_card`, `flash` |

## Scene Layout

- **Player0** (human): left-bottom, visible hand row, current mark (ColorRect), AI badge (if AI)
- **Player1** (AI): bottom-right, face-down hand, AI badge
- **Player2** (AI): top-right, face-down hand, AI badge
- **Player3** (AI): top-left, face-down hand, AI badge
- **Center**: CentralDisplay (accumulated discards, fanned) + LastDeck (current player's discard, fanned)
- **Deck**: Remaining cards (source)
- **TableRank** (Label): Shows the table rank character (e.g., "K"), left of center pile
- **Discard** button (D): For human player to confirm discard selection
- **Challenge** button (C): For human player to challenge the most recent discard
- **Top-right**: MenuButton (texture-based) to return to settings
- **MessageBox overlay**: Centered ColorRect with MessageLabel ("PLAYER X WINS!") + MessageButton (continue)
- **AnimationLayer**: Node2D for card movement animations (reparented during moves)

## Implementation Status

### ✅ Completed
1. **Deck.gd** — `prepare_cheaters()`: 9 ranks × 4 minus 1 random = 35 cards; `pop()` draws; `clear()`; `shift_to()` animation; `card_scene`/`fan_offset` exports
2. **Card.gd + Card.tscn** — `Area2D` with `Rank` enum (Ace=0..King=9, Unknown=10); `RANK_NAMES`; `rank`/`faceup` props; `_update_display()` switches sprite frame & value label; `get_rank_char()`
3. **Main.gd + Main.tscn** — Complete Cheaters game loop: `init_players`, `_new_game`, `_new_round` (deal all 35 cards, table_rank=Unknown), `new_turn`, `_state_discard()`, `_state_force_challenge()`, `_on_cards_discarded()` (first discard sets table rank), `_execute_discard_move()`, `_execute_challenge()` (reveal LastDeck, check bluff), `_resolve_challenge_won()` (loser draws both decks, forced 4-of-a-kind discard), `_force_4_of_a_kind_discard()`, `_check_winner()`, `_round_over()`, `_on_discard_pressed()`, `_on_challenge_pressed()`, `Memory` initialization, `_move_to_last_deck()`, `_move_last_to_central()`, `game_counter` (auto-run), `MessageBox` overlay, AudioPlayers
4. **Player.gd + Player.tscn** — Full player state: hand tracking, `memory` (Memory), AI level badge, card input (select 1-3 cards, no same-rank requirement), States (IDLE, SELECT_DISCARD, SELECT_CHALLENGE); `ai_discard(table_rank)`, `ai_challenge(last_discard_rank)` entry points; signals: `cards_discarded`, `challenge_declared`, `move_chosen`
5. **Memory.gd** — 2D array `max_card_count[player][rank]`; `set_guess()` tightens estimate; `get_guess()` returns -1 for unknown
6. **Player/ai.gd** — AI strategy engine: `select_discard(memory, my_hand, ai_level, table_rank)` dispatches by level; `should_challenge(memory, ai_level)` dispatches by level; `_random_discard()` fallback; `_argmax_score()` utility
7. **Player/move.gd** — Move data class with `Discard_1`/`Discard_2`/`Discard_3`/`Challenge` actions; `_table_rank` / `_cards` / `_score`; `ACTION_NAMES`, `ACTION_DISCARD_COUNT`
8. **Player/ai_level_1.gd** — L1: Weighted random discard (30% prefer matching table rank), 10% challenge rate
9. **Player/ai_level_2.gd** — L2: Prefers 2-3 of table rank if available, bluffs with 1-2 random cards
10. **Player/ai_level_3.gd** — L3: Heuristic — safe discards (2+ matching), bluffs prefer singletons over pairs
11. **Player/ai_level_4.gd** — L4: Delegates to L3
12. **Start.gd + Start.tscn** — Start screen with PLAY/SETTINGS/STATS/HELP buttons and signals
13. **Pause.gd + Pause.tscn** — Pause overlay with RESUME/STATS/HELP/EXIT buttons and signals
14. **Application.gd** — Full scene tree controller (Start→Main↔Pause↔LevelSelector↔Stats), config save/load, speed_run mode
15. **Animator.gd** — Speed-controlled helpers: `delay`, `all`, `flip`, `reveal_hand`, `move_card`, `flash`
16. **LevelSelector.gd/tscn + PlayerLevel.gd/tscn + SpeedLevel.gd/tscn** — Full settings UI for 4-player AI level selection and animation speed
17. **Stats.gd/tscn** — Win/loss tracking per AI level, display and reset
18. **Deck.gd** — `card_scene` export, `fan_offset` export, `shift_to()` animation

### ✅ Code Cleanup Done
- Removed `valid_moves` concept — any 1-3 cards can be discarded (no same-rank requirement)
- Removed `_find_valid_discard_moves()`, `_find_valid_challenge_moves()` from main.gd
- Removed `rank_remaining()` from ai.gd (replaced by Memory-based estimation)
- AI level files no longer receive `valid_moves` — instead receive `memory` and `table_rank`
- All files use tabs for indentation, `class_name` for all reusable scripts
- Signals for cross-scene communication (never direct node references between scenes)

## Game Mechanics Implemented

### Core Game Loop
1. **Deal**: All 35 cards dealt evenly to 4 players (9, 9, 9, 8)
2. **Called Rank**: Unknown at round start. First player to discard sets the table rank for the entire round.
3. **Discard**: Player selects 1-3 cards (any ranks), declare they match table rank → cards go face-down to LastDeck
4. **Challenge**: Any player can challenge the most recent discard → LastDeck revealed → if bluff (cards ≠ table rank), discarder draws all cards from both decks; if correct, challenger draws
5. **Forced 4-of-a-kind**: Loser of challenge must discard all possible sets of 4 matching cards
6. **Final Play Check**: If player reaches 0 cards, next player is forced to challenge
7. **Win**: First player to 0 cards (after forced final check)
8. **Next Round**: Player left of challenge loser starts; table rank starts Unknown again

### Called Rank Rules
- At round start: no table rank (Unknown)
- First discard: player declares/chooses a rank → becomes table rank
- All subsequent discards: must declare cards match the table rank
- Called rank is constant for the entire round
- Cards don't need to be the same rank — only the *claim* matters
- Challenge reveals cards and checks against the table rank

### AI Strategies
- **L1**: Weighted random (30% prefer matching table rank), 10% challenge rate
- **L2**: Prefers 2-3 of table rank if available; bluffs with 1-2 random cards; 25% challenge rate
- **L3**: Heuristic — safe discards (2+ matching get bonus), bluffs prefer singletons (less risky if revealed); 35% challenge rate
- **L4**: Delegates to L3

### Memory System
- `Memory.max_card_count[player][rank]` — player's best guess about max cards of each rank every player holds
- `set_guess(player, rank, count)` — tightens estimate (never increases the bound)
- `get_guess(player, rank)` — returns -1 for unknown
- Used by AI levels to estimate bluff probability (L2+): if memory says opponent can't have the table rank, they're likely bluffing
- Currently not populated during gameplay — placeholder for future tracking

### Discard Flow
```
Turn start → _state_discard() (AI calls ai_discard(table_rank))
            OR _state_force_challenge() (if previous player has 0 cards)
            ↓
Human: select 1-3 cards → press Discard → _on_discard_pressed() → _execute_discard()
AI: ai_discard() → move_chosen → _on_move_chosen() → _execute_discard_move()
    OR ai_challenge() → move_chosen → _on_move_chosen() → _execute_challenge()
    ↓
_on_cards_discarded() or _execute_challenge() → resolve → next turn
```

## Technology
- Godot 4.7, GL Compatibility mode
- Viewport: 672×384, stretch mode `viewport`, scale 8× (pixel-perfect 84×48 logical resolution)
- Pixel font: Gamebuino.ttf
- Audio: ogg Vorbis files for card slides, round/game fanfares, retro jingles
- Packed scene architecture with autoload (Animator)
- Config persistence: `user://options.cfg` (AI levels, speed, totals_and_wins)
- Speed run mode: instant animations, muted audio

## Open Risks / Future Work
- **Memory not populated** — `Memory` class exists but `set_guess()` is never called during gameplay. Future: track discards and update memory based on observed card claims and revealed cards
- **Config file format** not versioned — schema changes could break old saves
- **Game balance** — AI levels need empirical testing to tune challenge rates and bluff frequency
- **Help screen** — scene exists but content not yet designed
- **Challenge button always enabled** — human can click challenge even when it's their turn to discard (not yet opponent's turn). Should be disabled unless opponent just discarded
- **Android/iOS** — fullscreen mode detected but no platform-specific builds tested
- **No rank groupings** — players can discard any 1-3 cards regardless of rank, making bluffing more unpredictable
