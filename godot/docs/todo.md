# Open Tasks / TODOs

Tasks extracted from the porting plan. Ordered by implementation priority.

---

## Phase 1: Core Logic (Priority: HIGH)

- [ ] **`card.gd`** — Redefine: Braverats enum (Jester=0 through Prince=7), POWER_NAMES array, power value property. Update `_update_display()` to use character frame index = power value.
- [ ] **`round_result.gd`** — New enum: `Player0Wins`, `Player1Wins`, `Hold` (enum values 0, 1, 2).
- [ ] **`game_logic.gd`** — Pure logic: port C++ `resolve_round()`, `move_cards()`, `check_winner()`, `new_game()`. No Godot node references. Testable with unit tests.
- [ ] **`game_state.gd`** (autoload) — Centralized state: `_players[2]`, `_rounds[8]`, `_round_count`, `_scores[2]`, `_unrealized[2]`, `_effects[2]` (Spy/General flags), `_pending_cmd`.

## Phase 2: Deck & Card UI (Priority: HIGH)

- [ ] **`deck/deck.gd`** — Add `prepare_braverats()`: 8 unique cards per player (16 total), shuffle per player's hand. Keep existing pop()/clear()/shift_to().
- [ ] **`card/card.tscn`** wiring — Update to use `characters.png` frame index (0-7) for character display. Map power value to frame. Back uses `frame.png` frame 1.
- [ ] **`card/gd`** display logic — Power value to character frame mapping.

## Phase 3: Player & AI (Priority: HIGH)

- [ ] **`player/player.gd`** — Remove Cheaters discard/challenge logic. New flow: hold 8 cards, select 1, play card → emit `card_played(card)` signal. Track effects (Spy, General).
- [ ] **`player/ai.gd`** — Adapt: `select_card(opponent_known_cards, my_hand, ai_level)` → returns Card. L1: random. L2: simulate all opponent cards, score expected outcome, probabilistic selection.
- [ ] **`level_selector/`** — Adapt: Player 0 selects Human/L1/L2, Player 1 selects L1/L2 only (Player 1 is always AI).

## Phase 4: Game Loop Integration (Priority: MEDIUM)

- [ ] **`main/main.gd`** — Rewrite game loop: deal → select → resolve → animate → advance → check winner.
- [ ] **`animator/animator.gd`** — Add: `reveal_cards(card0, card1)`, `show_effect(player_idx, effect_type)`, `show_result(result_text, duration)`.
- [ ] **`player.tscn`** layout — Update for Braverats 2-player hand display.

## Phase 5: Scenes & Polish (Priority: MEDIUM)

- [ ] **`game_over.tscn`** — New scene: winner announcement, final scores, round-by-round history, career victories, Play Again button.
- [ ] **`help.tscn`** — New scene: per-card help descriptions (from original `ui.cpp`), how-to-play rules text.
- [ ] **`application.gd`** — Connect Start→Game→GameOver→Pause flow.
- [ ] **Unrealized points display** — Show as small "+" followed by number next to each player's score (e.g., "3 +2").
- [ ] **Effect indicators** — `Effect0`/`Effect1` Sprite2Ds: show Spy icon (frame 2) when Spy effect active, General icon (frame 6) with "+2" when General effect active.
- [ ] **Auto-advance** — 1-2s pause between rounds, button press to skip. Shorter for AI mode.

## Phase 6: Sound & Persistence (Priority: LOW)

- [ ] **`audio_manager.gd`** (autoload) — Recreate original 2 square-wave patterns + reveal sound & game-over fanfare. No background music.
- [ ] **`stats_manager.gd`** (autoload) — ConfigFile persistence for career stats at `user://braverats_stats.cfg`.
- [ ] **`stats.tscn`** — Wire up to stats manager, update config path.

## Phase 7: Verification (Priority: LOW)

- [ ] **Unit tests** — `game_logic.resolve_round()` covering all 64 card-vs-card matchups.
- [ ] **C++ comparison harness** — Same card pairs through C++ and GDScript, compare `RoundResult` output.
- [ ] **Manual playtesting** — Feel and UX validation.

---

## Open Design Decisions

| # | Topic | Status |
|---|-------|--------|
| 12 | On-hold mechanic & pending effects visuals | Needs design: held-round indicators, Spy/General persistent effect icons |
| 13 | Help/tutorial system | Three-tier: per-card help, how-to-play screen, card encyclopedia |
| 14 | Sound design | 2 square-wave patterns + reveal sound & game-over fanfare (no background music) |
| 15 | AI vs AI spectator mode | Fixed pace with pause. Speed slider (slow/normal/fast/instant) |
| 17 | Card selection detail | Click-to-select in hand (mouse). Selected card visually highlighted |
| 19 | Game state management | Single `GameState` autoload singleton |
| 21 | Round auto-advance | Auto-advance (1-2s pause) with button press to skip |
| 22 | Card ID in history | Full card names + small icon/color swatch |
| 23 | End conditions | End early at 4 points (unrealized points counted). If 8 rounds tied → draw |
| 25 | Color palette | Gamebuino 3-color (black/white/grey) for UI. Each card gets distinct muted color background |
| 26 | Pause menu | 3 options: Resume, Quit (to title), Statistics |
| 27 | Title screen | Replicate original title bitmap + menu. Subtle idle animation |
| 28 | Card back design | Distinctive but simple geometric pattern (diamond/crosshatch) in grey/black |
| 31 | Unrealized points display | Show as small "+" followed by number next to score (e.g., "3 +2") |

---

## Known Issues (Inherited from Cheaters)

- **Config file format** not versioned — schema changes could break old saves
- **Challenge button always enabled** — human can click challenge even when it's their turn to discard
- **Android/iOS** — fullscreen mode detected but no platform-specific builds tested
