# Braverats → Godot Porting Plan

---

## What the Game Actually Is

**Braverats** — a 2-player strategy card battle game with 8 unique cards, each with special abilities. Players each have 8 cards, play one per round for up to 8 rounds. First to 4 points wins (or most points after all rounds).

---

## Game Summary

| Aspect | Details |
|--------|---------|
| **Original platform** | Gamebuino (84×48 monochrome LCD, D-pad + A/B/C buttons, Arduino) |
| **Godot viewport** | 672×384 at 8× scale (84×48 logical) — matches existing Cheaters project |
| **Players** | Player 0: Human or AI (L1/L2). Player 1: always AI (L1/L2). Single-player vs AI only. |
| **Cards** | 8 cards: Jester, Lady, Spy, Assassin, Chancellor, Magician, General, Prince |
| **Special mechanics** | Spy (see opponent's card next round), Magician (nullify effects), General (+2 strength next turn), Prince (instant win vs Lady), Assassin (lowest wins), Chancellor (2 pts on win), Jester (hold/nullify), Lady (instant win vs Prince) |
| **AI** | Level 1: random. Level 2: evaluation-based (simulates all opponent card possibilities, probabilistic selection) |
| **Persistence** | ConfigFile — career stats (games played/won per vs. mode) |

---

## Decisions from Grill Session

### Resolved Decisions

| # | Topic | Decision |
|---|-------|----------|
| 1 | Existing `godot/` directory (Cheaters) | **Re-use the existing Cheaters project structure** — adapt its pattern (Application→Title→Game→GameOver→Pause) since the infrastructure is clean and already in place |
| 2, 3, 32 | Display resolution & scale | **84×48 logical at 672×384 viewport, 8× scale**, GL Compatibility mode, `stretch_mode=2d`. Pixel font: Gamebuino.ttf. Preserves original aesthetic |
| 36, 38 | Game modes / player config | **Player 0 can be Human or any AI level (L1, L2). Player 1 is always AI.** Single-player vs AI only — no hot-seat multiplayer |
| 4, 37, 39 | Input method | **Mouse only (left-click).** Card selection via clicking cards in hand. Menu navigation, help, pause — all mouse-driven. No keyboard, no gamepad |
| 5, 40 | Card artwork | **User provides custom pixel sprites.** Working on `godot/card/card.tscn`. Will supply original-style art rather than upscaled Gamebuino bitmaps |
| 6, 41 | Card effects resolution | **Replicate exact C++ evaluation order** for faithful behavior. Document order clearly in comments |
| 7, 42 | Round reveal flow | **Confirmed recommended flow:** both players select simultaneously → cards face-down → brief pause → flip/reveal simultaneously → animate effects & result → move to round history → auto-advance. Skip animation option |
| 8, 43 | Stats persistence | **Yes — use Godot's `ConfigFile`** to persist career stats per vs. mode. Write to `user://braverats_stats.cfg` |
| 9, 44, 45 | Scene architecture | **Exact same pattern as Cheaters project:** Application root → Title → Game → GameOver → Help → Pause sub-scenes. Signals for inter-scene communication |
| 20, 46 | Card name at power 4 | **'Chancellor'** — per `godot/docs/rules.md` which is source of truth for this port |
| 47, 49 | AI levels | **Two levels at launch: L1 (random) and L2 (evaluation-based).** L3+ can be added later |
| 50, 51 | Board layout | **Matches original Gamebuino layout exactly** — user handles scene layout/positioning themselves |
| 52, 53 | End-of-game screen | **Full replication of original:** winner announcement, final scores, round-by-round history with both cards and result indicators, career victories per mode, Play Again button |

### Open / To-Be-Decided

| # | Topic | Current State |
|---|-------|---------------|
| 12 | On-hold mechanic & pending effects visuals | Needs design: held-round indicators, Spy/General persistent effect icons |
| 13 | Help/tutorial system | Three-tier recommended: per-card help (press B/mouse), how-to-play screen, card encyclopedia |
| 14 | Sound design | Recreate original 2 square-wave patterns + add reveal sound & game-over fanfare. No background music |
| 15 | AI vs AI spectator mode | Fixed pace with pause. Speed slider (slow/normal/fast/instant) |
| 17 | Card selection detail | Click-to-select in hand (mouse). Selected card visually highlighted. Selection = confirmation |
| 18 | Project file structure | See Architecture section below |
| 19 | Game state management | **Single `GameState` autoload singleton** — centralized state, mirroring original's approach |
| 21 | Round auto-advance | Auto-advance (1-2s pause) with button press to skip. Faster for AI mode |
| 22 | Card ID in history | Full card names + small icon/color swatch (not single letters like original) |
| 23 | End conditions | End early when someone reaches 4 points (unrealized points counted). If 8 rounds and tied → draw |
| 25 | Color palette | Gamebuino 3-color (black/white/grey) for UI. Each card gets a distinct muted color background for recognition |
| 26 | Pause menu | 3 options: Resume, Quit (to title), Statistics. No "Save for later" (not needed with ConfigFile) |
| 27 | Title screen | Replicate original title bitmap + menu. Subtle idle animation. Card icons as decoration |
| 28 | Card back design | Distinctive but simple geometric pattern (diamond/crosshatch) in grey/black. Identical for all cards |
| 29 | Verification approach | Unit tests for `resolve_round()` covering all 64 card matchups + automated comparison harness between C++ and Godot outputs |
| 30 | Cancelling interactions (both Spies, both Chancellors) | Replicate C++ implicit approach: both Spies → both get effect; both Chancellors → each gets 2 pts if resolved later |
| 31 | Unrealized points display | Show as small "+" followed by number next to each player's score (e.g., "3 +2") |
| 33 | Replay last game | Not implemented now. Round history on game-over screen is sufficient |

---

## Migration Strategy

### Current State (from Cheaters project reuse)

The `godot/` directory is the Cheaters project adapted as the Braverats base. Much infrastructure is already in place:

**✅ Completed infrastructure:**
| Component | File(s) | Status |
|-----------|---------|--------|
| Project config | `project.godot` | ✅ Named "Braverats", 672×384, 8× scale, GL Compat, Animator autoload |
| Application root | `application/application.gd+tscn` | ✅ Scene tree controller (Start↔Main↔Pause↔LevelSelector↔Stats) |
| Title screen | `start/start.gd+tscn` | ✅ Title with PLAY/SETTINGS/STATS/HELP buttons + signals |
| Pause overlay | `pause/pause.gd+tscn` | ✅ Resume/STATS/HELP/EXIT buttons |
| Level selector | `level_selector/*.gd+tscn` | ✅ PlayerLevel, SpeedLevel, DigitButton (for AI level selection) |
| Stats screen | `stats/stats.gd+tscn` | ✅ Win/loss tracking, reset button |
| Animation | `animator/animator.gd+tscn` | ✅ Singleton: delay, move_card, flip, flash (speed-controlled) |
| Card scene | `card/card.tscn` | ✅ Area2D with Back (frame.png), Character (characters.png), Value Label |
| Card art | `card/characters.png` | ✅ 8-frame spritesheet: Jester, Lady, Spy, Assassin, Chancellor, Magician, General, Prince |
| Card border | `card/frame.png` | ✅ 2-frame spritesheet: face-up border / face-down |
| Digit display | `digit_sprite/*.gd+tscn` | ✅ DigitSprite for labels/buttons |
| Pixel font | `Gamebuino.ttf` | ✅ Imported, used via `tres/label_settings.tres` |
| Main scene layout | `main/main.tscn` | ✅ Adapted for Braverats: P0/P1 scores, Unrealized+Plus labels, Effect0/Effect1 Sprite2Ds for pending effect icons |

**⚠️ Needs adaptation (Cheaters → Braverats):**
| Component | Current (Cheaters) | Needed (Braverats) |
|-----------|--------------------|--------------------|
| `card/card.gd` | Cheaters `Rank` enum (Ace, 6-10, J, Q, K, Unknown) | Braverats card types (Jester=0, Lady=1, Spy=2, Assassin=3, Chancellor=4, Magician=5, General=6, Prince=7) |
| `deck/deck.gd` | `prepare_cheaters()`: 9 ranks × 4 minus 1 = 35 cards | `prepare_braverats()`: 8 unique cards per player (16 total, 8 per player) |
| `player/player.gd` | Cheaters: `AI_Level` H/L1-L4, discard/challenge states, Memory, MultiDeck support | Braverats: Human vs AI selection, hand management (8 cards), round play flow, effect tracking |
| `player/ai.gd` | Cheaters AI: select_discard(), should_challenge(), L1-L4 strategies | Braverats AI: L1 (random card), L2 (evaluation-based card selection) |
| `main/main.gd` | Cheaters game loop: deal, discard, challenge, table_rank, win check | Braverats game loop: deal, simultaneous play, resolve_round, move_cards, check_winner, round history |

**❌ Missing — needs creation:**
| Component | Purpose |
|-----------|--------|
| `audio_manager.gd` (autoload) | Sound effects: card selection, reveal, round end, game over |
| `stats_manager.gd` (autoload) | ConfigFile persistence for career stats |

---

### Phase 1: Core Logic (Pure Game Rules) — ✅ COMPLETE

> All files in `main/` directory.

### ✅ `card/card.gd` — Braverats enum, display, face control
- Power enum (Jester=0–7), `power` setter + `set_power()` ✅
- `power_name` computed property ✅
- `face_up` — toggles Facedown node visibility ✅
- `_update_display()` sets `Character` sprite frame + label text ✅

### ✅ `main/round_result.gd` — Round result enum
- `PLAYER0_WINS`, `PLAYER1_WINS`, `HOLD` + helpers (`is_player_win`, `is_hold`, `winner_idx`) ✅

### ✅ `main/game_logic.gd` — Pure game rules
- `resolve_round()` — corrected eval order (Bugs 1, 2 fixed) ✅
- `move_cards()`, `check_winner()`, `new_game()` ✅

### ✅ `main/game_state.gd` — Centralized state + AI config
- Scores, held_rounds, effects, round_history, `resolve_current_round()` ✅
- `ai_levels`, `AI_Level` enum, `AI_LEVEL_NAMES` ✅

### ✅ `player/` — Deleted (all Cheaters concepts)
### ✅ `level_selector/` — Updated to `GameState.AI_Level` ✅
### ✅ `application/` — Updated to use `GameState.ai_levels` ✅
### ✅ `deck/deck.gd` — `prepare_braverats()` (8 unique cards × 2) ✅

### Phase 2: UI Layer (Adapt Cheaters Scenes)
- **`card.gd`** — ✅ Already done: uses `characters.png` frame index (0-7) for character display, Facedown node for face-back.
- **`main/main.tscn`** — Already adapted: Effect0/Effect1 for pending effects, Score0/Score1, Plus0/Plus1, Unrealized0/Unrealized1. Wire up labels to GameState.
- **`player/`** — Deleted (all Cheaters concepts). Braverats player is just a card hand layout: display cards, handle clicks, emit `card_played(card)` signal.
- **`level_selector/`** — Updated: uses `GameState.AI_Level` now. Player 0 selects Human/L1/L2, Player 1 selects L1/L2 only.
- **`game_over/game_over.tscn`** — ✅ Exists (Cheaters layout): Message, GameScore, Rounds1/2, TotalScore, Button. Needs Braverats content (card names, Braverats round history).
- **`help/help.tscn`** — ✅ Exists (Cheaters card types): Guard/Priest/Baron etc. Needs Braverats cards (Jester/Lady/Spy/Assassin/Chancellor/Magician/General/Prince).
- **`help/card_help_page.tscn`** — ✅ Exists (tool node): card icon, name, description. Needs `Card.Power` instead of `Deck.CardType`.

### Phase 3: Game Loop Integration — ✅ COMPLETE (with bugs to fix)
> Verified 2026-07-19

#### ✅ `main/main.gd` — FULLY REWRITTEN (was marked ❌ but is actually done)
- `init_players()` — deals 8 cards each, calls `GameState.new_game()`, starts round 0 ✅
- `_prepare_deck()` — calls `deck.prepare_braverats()` ✅
- `_deal_cards()` — animated deal to both player hands ✅
- `_start_selection_phase()` — manages human vs AI selection flow ✅
- `_on_card_hand_clicked()` — human click → move card to front, store in GameState ✅
- `_ai_select()` — L1 random / L2 evaluation-based selection ✅
- `_start_reveal()` — face-down → move to table → flip/reveal simultaneously ✅
- `_resolve_round()` — resolve, update scores, play sound, move to discard ✅
- `_handle_game_over()` — transition to `game_over.tscn` ✅
- `_advance_to_next_round()` — auto-advance with speed-controlled delay ✅
- `_update_display()` — syncs score labels, plus/unrealized, effect indicators ✅
- `_update_effect()` — shows Spy (frame 2) or General (frame 6) sprite ✅
- **⚠️ Needs:** Connect pause overlay signals in `application.gd`, add `round_won` signal wiring for stats

#### ⚠️ `animator/animator.gd` — PARTIALLY COMPLETE (reveal/resolve inline in main.gd)
- ✅ Has: `delay()`, `flip()`, `move_card()`, `flash()`, `kill_tweens()`
- ❌ Missing from plan: `reveal_cards(card0, card1)`, `show_effect(player_idx, effect_type)`, `show_result(result_text, duration)`
- ⚡ **Design note:** Reveal logic implemented inline in `main.gd._start_reveal()` rather than as animator methods — acceptable tradeoff
- ❌ **Bug:** `reveal_hand(p: Player, ...)` references deleted `Player` type — should be removed or refactored

#### ✅ Pause overlay — EXISTS and connected (with bugs)
- `pause/pause.gd` has signals: `resume_pressed`, `stats_pressed`, `help_pressed`, `exit_pressed` ✅
- `application.gd` has handler methods for all signals ✅
- ❌ **Bug:** `_on_pause_exit_pressed()` references `_main.interrupted = true` but `Main` has no such property
- ❌ **Bug:** `_on_pause_exit_pressed()` doesn't properly clean up GameState/animation state on quit

---

#### Phase 3 Bugs to Fix (before marking ✅)
| # | File | Issue | Priority |
|---|------|-------|----------|
| 1 | `application.gd:32` | References `_main.round_won.disconnect()` — no `round_won` signal in `Main` | High |
| 2 | `application.gd:100` | References `_main.interrupted = true` — no such property in `Main` | High |
| 3 | `application.gd:139-148` | `_on_round_won()` handler exists but signal never emitted — dead code | Medium |
| 4 | `animator.gd` | `reveal_hand(p: Player)` references deleted `Player` type | High |
| 5 | `game_over.gd:8` | `@onready var rounds_2: Label = $Rounds2` — scene has `Rounds0`, not `Rounds2` | High |

### Phase 4: Polish
- **Auto-advance** — 1-2s pause between rounds, button press to skip. Shorter for AI vs AI mode.
- **Unrealized points** — `Plus0`/`Plus1` labels + `Unrealized0`/`Unrealized1` count labels already in main.tscn. Update when held rounds resolve.
- **Effect indicators** — `Effect0`/`Effect1` Sprite2Ds (characters.png offset 3.5, 6) already in main.tscn. Show Spy icon (frame 2) when Spy effect active, General icon (frame 6) with "+2" when General effect active.

### Phase 5: Verification
- Unit tests for `game_logic.resolve_round()` covering all 64 card-vs-card matchups
- Automated comparison harness: same card pairs through C++ and GDScript, compare `RoundResult` output
- Manual playtesting for feel and UX

---

### Implementation Order (Refined)

1. **Pure logic** — `card.gd` (Braverats enum), `round_result.gd`, `game_logic.gd`, `game_state.gd` (with AI_Level enum) + autoloads
2. **Deck & card UI** — `deck.gd` (prepare_braverats), `card.tscn` wiring (character frames), `card.gd` display logic
3. **Player system** — Deleted Cheaters `player.gd`/`ai.gd`. New: simple hand scene with click-to-play, no state logic
4. **AI integration** — `ai.gd` (L1 random, L2 evaluation) — new implementation only
5. **Game loop** — `main.gd` rewrite: deal → select → resolve → animate → advance → check winner
6. **Scene wiring** — `application.gd` (Start→Game→GameOver→Pause flow), connect signals
7. **Game over** — `game_over.tscn` (winner, history, stats)
8. **Menu/selector** — `start.tscn`, `level_selector` (P0: Human/L1/L2, P1: L1/L2 only)
9. **Help** — `help.tscn` (per-card descriptions, how-to-play)
10. **Animations** — `animator.gd` additions (reveal, effect display, result overlay)
11. **Sound** — `audio_manager.gd` (PatternA, PatternB, reveal, fanfare)
12. **Stats** — ConfigFile persistence, `stats.tscn` wiring
14. **Verification** — Unit tests, C++ comparison harness, manual playtesting

---

## Key Differences (Gamebuino → Godot)

| Gamebuino | Godot |
|-----------|-------|
| 84×48 monochrome display | 672×384 at 8× scale, colored display |
| D-pad + A/B/C buttons | Mouse only (left-click) |
| PROGMEM bitmaps | PNG textures / user-supplied pixel art |
| `srand()` / `rand()` | Godot `randi()` |
| EEPROM persistence | `ConfigFile` (`user://braverats_stats.cfg`) |
| 16MHz, minimal RAM | Full CPU, no optimization needed |
| `goto` statements | Standard GDScript control flow |

---

## Architecture

```
godot/                          ← Cheaters project adapted for Braverats
├── project.godot               ✅ Named "Braverats", 672×384, 8× scale, GL Compat
├── application/                ✅ Scene tree controller (Start↔Main↔Pause↔LevelSelector↔Stats)
│   ├── application.gd
│   └── application.tscn
├── start/                      ✅ Title screen + menu (needs menu text update)
│   ├── start.gd
│   └── start.tscn
├── pause/                      ✅ Pause overlay (needs option text update)
│   ├── pause.gd
│   └── pause.tscn
├── level_selector/             ✅ AI level selection (needs P1-only-AI constraint)
│   ├── level_selector.gd+tscn
│   ├── player_level.gd+tscn
│   ├── speed_level.gd+tscn
│   └── digit_button.gd+tscn
├── stats/                      ✅ Win/loss stats (needs config path update)
│   ├── stats.gd
│   └── stats.tscn
├── main/                       ⚠️ Core logic + layout
│   ├── game_logic.gd           ✅ Pure game rules (resolve_round, check_winner, etc.)
│   ├── game_state.gd           ✅ Centralized state + AI_Level enum (needs autoload)
│   ├── round_result.gd         ✅ RoundResult enum
│   ├── main.gd                 ✅ Game loop fully rewritten (see Phase 3)
│   ├── main.tscn               ✅ P0/P1 scores, Unrealized/Plus, Effect0/Effect1
│   └── menu.png
├── card/                       ⚠️ Scene done, script needs adaptation
│   ├── card.gd                 ✅ Braverats enum + display logic
│   ├── card.tscn               ✅ Back(frame.png) + Character(characters.png) + Value
│   ├── frame.png               ✅ 2 frames: face-up border / face-down
│   └── characters.png          ✅ 8 frames: Jester/Lady/Spy/Assassin/Chancellor/Magician/General/Prince
├── player/                     ✅ Deleted (all Cheaters concepts)
│   └── (empty)                 All player logic moved to GameState
├── deck/                       ⚠️ Infrastructure exists, needs new method
│   ├── deck.gd                 ✅ Has prepare_braverats() + prepare_cheaters() (cleanup needed)
│   └── deck.tscn               ✅ Sprite2D + card_scene export
├── animator/                   ⚠️ Singleton: delay, flip, move_card, flash (reveal_hand references deleted Player)
│   ├── animator.gd
│   └── animator.tscn
├── digit_sprite/               ✅ Digit display for labels/buttons
│   ├── digit_sprite.gd+tscn
│   └── digits.png
├── tres/                       ✅ Pixel font settings
│   └── label_settings.tres
├── Gamebuino.ttf               ✅ Pixel font
├── docs/                       ✅ rules.md, conventions.md, invariants.md
│   ├── rules.md
│   ├── conventions.md
│   └── invariants.md
├── game_over.tscn              ⚠️ End-of-game scene (needs bug fix: $Rounds2 → $Rounds0)
├── help.tscn                   ⚠️ Exists but has Cheaters card data (needs Braverats update)
├── audio_manager.gd (autoload) ❌ NEW: sound effects
└── stats_manager.gd (autoload) ❌ NEW: ConfigFile persistence
```

### Legend
| Symbol | Meaning |
|--------|--------|
| ✅ | Ready to reuse as-is (infrastructure) |
| ⚠️ | Exists but needs adaptation for Braverats |
| ❌ | Needs to be created new |

---

## Evaluation Order (Faithful to C++)

Documented in `main/game_logic.gd`. Critical order:
1. General +2 (persistent flag for NEXT round, NOT current comparison)
2. Magician nullify (nullifies opponent's effect, but NOT General's +2)
3. Jester nullify (nullifies everything including Prince — Jester beats Magician)
4. Lady-vs-Prince instant win (not nullifiable)
5. Prince instant win (beats all except Lady and Assassin)
6. Value comparison (after nullification)
7. Assassin invert (lowest wins, doesn't override Lady/Prince)
8. Spy/General effect flags (carried to next round)
9. Counsellor (2 pts if won)
10. Same-card handling (Jester→hold, General→both get +2, others→tie P0 wins)

**Key interactions to test:**
- Jester vs all 8 cards (16 cases including mirror)
- Lady vs Prince (instant win)
- Prince vs Assassin (Prince wins)
- Magician nullifies effects but NOT General's +2
- Both Spies → both get effect (implicit, not cancelled)
- Both Counsellors → each gets 2 pts if resolved later
- General +2 persists and is not nullifiable by subsequent Magician

### ✅ Known Bugs — FIXED

**Bug 1 (FIXED):** Evaluation order — Jester now checked BEFORE Lady-vs-Prince. Jester nullifies everything including Prince, so Jester+Lady vs Prince→HOLD, not PLAYER0_WINS.

**Bug 2 (FIXED):** Magician no longer nullifies General's +2. General only flags for next round. Magician nullifies opponent's card EFFECT but General's persistent +2 bypasses nullification.

**Bug 7 (FIXED):** `deck.gd` now has `prepare_braverats()` that creates 8 unique cards per player (16 total), shuffled together.

---

### Bug 8: Phase 3 Verification — NEED FIX

| # | File | Line | Issue | Fix |
|---|------|------|-------|-----|
| 8 | `game_over.gd` | 8 | `@onready var rounds_2: Label = $Rounds2` — scene has `Rounds0`, not `Rounds2` | Change `$Rounds2` to `$Rounds0` |
| 9 | `game_logic.gd` | ~130-131 | `GameState.held_cards0.clear()` and `GameState.held_cards1.clear()` — `held_cards` are `Card`, not Arrays | Change `.clear()` to `= null` |
| 10 | `animator.gd` | ~38 | `reveal_hand(p: Player)` references deleted `Player` type | Remove method or replace with `reveal_cards(card0, card1)` |
| 11 | `application.gd` | 32 | `_main.round_won.disconnect()` — no `round_won` signal exists in `Main` | Remove this line |
| 12 | `application.gd` | 100 | `_main.interrupted = true` — no such property in `Main` | Remove or replace with proper cleanup |
| 13 | `application.gd` | 139-148 | `_on_round_won()` handler exists but signal never emitted | Remove or connect signal |
| 14 | `card.gd` | - | Uses `Counsellor` but plan card reference says `Chancellor` | Consider renaming for consistency |
| 15 | `help.tscn` | - | Still has Cheaters cards (Guard/Priest/Baron) not Braverats cards | Replace with Braverats card descriptions |

---

## Card Reference

| Power | Name | Effect |
|-------|------|--------|
| 0 | Jester | Holds the round (draw), nullifies opponent's card effect |
| 1 | Lady | Instant win vs Prince |
| 2 | Spy | Reveals opponent's card next round; both Spies = both see opponent |
| 3 | Assassin | Wins if lowest value played (after other effects) |
| 4 | Chancellor | Wins 2 points if round is won |
| 5 | Magician | Nullifies opponent's card effect (except General's +2) |
| 6 | General | +2 strength applied to next round (persistent, not nullifiable) |
| 7 | Prince | Instant win vs Lady; loses to Lady; loses to Assassin |

---

*Plan last updated: 2026-07-19 (Grill session)*
