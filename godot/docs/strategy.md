# AI Strategies

AI decision-making is centralized in the static `AI` class, which dispatches to per-level strategies. Each level receives `memory` and `table_rank` as context.

---

## AI Architecture

### `AI` Class (Static)

- **`select_discard(memory, my_hand, ai_level, table_rank)`** → `Move` — dispatches to level-specific strategy
- **`should_challenge(memory, ai_level)`** → `bool` — dispatches to level-specific strategy
- **`_random_discard()`** — fallback for invalid selections
- **`_argmax_score()`** — utility to pick highest-scored move

Player delegates via:
- `ai_discard(table_rank)` — called by Main when it's the player's turn to discard
- `ai_challenge(last_discard_rank)` — called when challenge decision is needed

### Move Data

- `Move.Action` enum: `Discard_1`, `Discard_2`, `Discard_3`, `Challenge`
- `Move._score` (float) — populated by each level's strategy to rank options
- Strategy returns the chosen move directly (no `argmax` over valid_moves)

---

## Level Strategies

### L1 — Random

| Action | Behavior |
|--------|----------|
| Discard | Weighted random: 30% prefer matching table rank, 70% random |
| Challenge | 10% flat rate |

**Philosophy:** Simple noise. No pattern recognition. Good for testing basic game flow.

### L2 — Probabilistic

| Action | Behavior |
|--------|----------|
| Discard | Prefers 2-3 of table rank if available; bluffs with 1-2 random cards |
| Challenge | 25% flat rate |

**Philosophy:** Mild pattern. Will sometimes match the table rank but also bluffs. Uses memory system (if available) to estimate if opponent could plausibly hold the table rank.

### L3 — Heuristic

| Action | Behavior |
|--------|----------|
| Discard | Safe discards (2+ matching cards get bonus score); bluffs prefer singletons over pairs (less risky if revealed) |
| Challenge | 35% flat rate |

**Philosophy:** Risk-aware. Prefers discarding cards that are actually matching the table rank, and when bluffing, uses singletons (only 1 copy of that rank in hand) to minimize loss if challenged. Uses memory to estimate bluff probability.

### L4 — Heuristic Delegate

- Delegates to L3 strategy (MCTS deemed too complex for bluffing game mechanics)
- No separate algorithm — L4 is L3 in practice

---

## Challenge Rate Tuning

| Level | Challenge Rate |
|-------|---------------|
| L1 | 10% |
| L2 | 25% |
| L3 | 35% |
| L4 | 35% (delegates to L3) |

These are currently flat rates. Future: memory-based challenge probability (if memory says opponent can't hold the table rank, increase challenge likelihood).

---

## Memory System (Future)

`Memory` is a 2D array: `max_card_count[player_idx][rank]`

- Stores each player's guessed maximum card count per rank
- `set_guess(player, rank, count)` — tightens estimate (never increases the bound)
- `get_guess(player, rank)` — returns -1 for unknown
- **Currently unused** — API exists but no AI level calls `set_guess()` during gameplay
- Passed to `AI.select_discard()` and `AI.should_challenge()` as a hook for future memory-based decisions

---

## Key Differences from Cheaters

| Aspect | Cheaters AI | Braverats AI |
|--------|-------------|--------------|
| Actions | Discard cards + Challenge | Single card selection |
| Levels | L1-L4 (4 levels) | L1-L2 (2 levels at launch) |
| Context | `memory` + `table_rank` | Opponent's known cards + hand |
| Output | `Move` (discard/challenge) | `Card` selection |
