# Cross-Cutting Invariants

## Stats Tracking

- `_totals_and_wins[2 * level]` = total games played, `_totals_and_wins[2 * level + 1]` = wins
- `level` maps to `Player.AI_Level` enum (H=0, L1=1, …, L4=4)
- **Both players count toward totals**: When a round ends, both winner and loser increment total. Only the winner increments wins.

## Memory System

- `Memory` is a 2D array: `max_card_count[player_idx][rank]`
- Stores each player's guessed maximum card count per rank. Unknown = -1
- **API exists but is not used** by any AI level — levels use flat-probability challenge rates instead
- Passed to `AI.select_discard()` and `AI.should_challenge()` as a hook for future memory-based decisions

## Table Rank

- Starts as `Card.Rank.Unknown` at round start
- Set by the **first player to discard** (they declare a rank)
- Remains **constant for the entire round**
- Stored in `Main._table_rank`

## Challenge Rules

- Any player can challenge the **most recent discard** at any time
- Only the challenger and discarding player are involved
- If the discarding player was lying (cards ≠ table rank) → they draw the pile
- If the discarding player was truthful (cards = table rank) → challenger draws the pile
- **Forced challenge**: If a player discards their last card (0 cards remaining), the next player **must** challenge

## 4-of-a-Kind Forced Discard

After losing a challenge, the loser draws the entire pile and **must immediately discard all possible sets of 4 matching cards** from their hand.

## Next Round Starter

The player **to the left of the challenge loser** starts the next round.

## Animation System

- All card movement goes through the `Animator` class
- Reparent cards to `_animation_layer` before animating, reparent back to final container after
- Singleton autoload node

## AI Decision Flow

- `AI` is a static-only `class_name` — no members, only static methods
- Player delegates via `ai_discard(table_rank)` and `ai_challenge(last_discard_rank)`
- Each level's strategies populate `Move._score` (float), then return the chosen move directly (no `argmax` over valid_moves)

## Compact Mode (MultiCard Hand Display for Player 0)

Human players can switch to compact mode where cards of the same rank are grouped into a
single `MultiCard` node. Each rank gets one MultiCard showing 0–4 cards.

### Selection Invariants

- Each MultiCard has two sprite states: `_available` (not selected) and `_selected` (selected)
- **`_available.frame + _selected.frame = total cards of that rank in player's hand`**
- This sum is preserved at all times — selecting moves a card from available to selected,
  deselecting moves it back

### Selection Mechanics

- Clicking a MultiCard with available cards: selects one (moves from available → selected)
- Clicking a fully-selected MultiCard (`_available.frame == 0`): deselects all at once
  (resets `_selected.frame` to 0, restores to `_available.frame`)
- This provides an all-or-nothing toggle — selecting all 4 at once is a natural "bluff everything" gesture

### Visibility

- `MultiCard.visible = _available.frame > 0` — hides when all cards of a rank are selected/discarded
- `clear_selection()` transfers selected cards back to available (preserves total)
- `clear()` resets both frames to 0 and hides all MultiCards

### Validation

- The 3-card discard limit is enforced at **submit time** in `main.gd` (line 538: `count <= 3`),
  not at input time. The discard button simply stays inert — no visual error, just no action

## Signals

Signal signatures (pass actual data, not indices):
- `cards_discarded(count, table_rank, cards)`
- `challenge_declared`
- `move_chosen(move)`
