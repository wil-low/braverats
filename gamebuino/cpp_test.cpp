// cpp_test.cpp
// Braverats round-history tester: fixes P0 hand, iterates all 8! permutations
// of P1 hand, prints round history in the Godot GameOver format.
//
// Build:  g++ -O2 -o cpp_test cpp_test.cpp
// Output: 40320 game results

#include <cstdint>
#include <cstdio>
#include <cstring>

// ── Replicate core data structures (from core.h, pile.h, config.h) ──────────

#define PLAYER_COUNT 2

enum Card {
    Jester = 0,
    Lady,
    Spy,
    Assassin,
    Chancellor,
    Magician,
    General,
    Prince,
    CardCount,
    UnknownCard = CardCount,
};

enum RoundResult {
    RR_Player0 = 0,
    RR_Player1,
    RR_Hold,
    RR_Player0_GameWon,
    RR_Player1_GameWon,
    RR_NoResult,
};

typedef struct {
    Card _items[8];
    uint8_t _count;
} Pile;

typedef struct {
    uint8_t _level; // 0=Human, 1=L1, 2=L2
    Pile _hand;
    Card _effect;
    uint8_t _score;
    uint16_t _victory_count;
    uint8_t _unrealized_points;
} Player;

typedef struct {
    Card _cards[PLAYER_COUNT];
    RoundResult _result;       // result for THIS round (passed to move_cards)
    RoundResult _final_result; // final resolved result (after holds cascade)
    uint8_t _points;
} Round;

typedef struct {
    Player _players[PLAYER_COUNT];
    Round _rounds[CardCount];
    uint8_t _round_count;
    RoundResult _last_result;
} GameState;

// Card display letters — matches Godot POWER_NAMES single char
static const char CARD_LETTERS[] = "JLSACMGP";

// Forward declarations
static void simulate_game(const Card p0_hand[], const Card p1_hand[]);
static int64_t g_count = 0;
static const Card *g_p0_hand = nullptr;

// ── Core game logic (from core.cpp) ─────────────────────────────────────────

void new_game(GameState *state) {
    for (uint8_t i = 0; i < PLAYER_COUNT; ++i) {
        Player *p = &state->_players[i];
        p->_score = 0;
        p->_effect = (Card)UnknownCard;
        p->_unrealized_points = 0;
        p->_victory_count = 0;
        p->_hand._count = 0;
        for (uint8_t n = 0; n < CardCount; ++n) {
            p->_hand._items[p->_hand._count++] = (Card)n;
        }
    }
    state->_last_result = RR_NoResult;
    state->_round_count = 0;
}

GameState resolve_round(GameState *state, Card p0_card, Card p1_card) {
    GameState new_state = *state;
    state = &new_state;
    uint8_t p0_value =
        p0_card + (state->_players[0]._effect == General ? 2 : 0);
    uint8_t p1_value =
        p1_card + (state->_players[1]._effect == General ? 2 : 0);

    state->_players[0]._effect = (Card)UnknownCard;
    state->_players[1]._effect = (Card)UnknownCard;

    state->_last_result = p0_value > p1_value ? RR_Player0 : RR_Player1;
    if (p0_value == p1_value)
        state->_last_result = RR_Hold;

    if (p0_card != Magician && p1_card != Magician) {
        if (p0_value == p1_value || p0_card == Jester || p1_card == Jester) {
            state->_last_result = RR_Hold;
            return *state;
        }

        if (p0_card != p1_card) {
            if (p0_card == Assassin || p1_card == Assassin)
                state->_last_result =
                    p0_value < p1_value ? RR_Player0 : RR_Player1;

            if (p0_card == Spy)
                state->_players[0]._effect = Spy;
            if (p1_card == Spy)
                state->_players[1]._effect = Spy;

            if (p0_card == General)
                state->_players[0]._effect = General;
            if (p1_card == General)
                state->_players[1]._effect = General;

            if (p0_card == Prince)
                state->_last_result =
                    (p1_card == Lady) ? RR_Player1_GameWon : RR_Player0;
            if (p1_card == Prince)
                state->_last_result =
                    (p0_card == Lady) ? RR_Player0_GameWon : RR_Player1;
        }
    }
    return *state;
}

void remove_from_hand(GameState *state, uint8_t player_idx, Card card) {
    Player *p = &state->_players[player_idx];
    for (uint8_t n = 0; n < p->_hand._count; ++n) {
        if (card == p->_hand._items[n]) {
            for (uint8_t i = n; i < p->_hand._count - 1; ++i) {
                p->_hand._items[i] = p->_hand._items[i + 1];
            }
            break;
        }
    }
    p->_hand._count--;
}

void move_cards(GameState *state, Card p0_card, Card p1_card,
                RoundResult result) {
    Round *round = &state->_rounds[state->_round_count++];
    round->_cards[0] = p0_card;
    round->_cards[1] = p1_card;
    round->_result = result;

    remove_from_hand(state, 0, p0_card);
    remove_from_hand(state, 1, p1_card);

    state->_players[0]._score = 0;
    state->_players[1]._score = 0;
    if (result == RR_Player0_GameWon)
        state->_players[0]._score = 100;
    else if (result == RR_Player1_GameWon)
        state->_players[1]._score = 100;
    else {
        state->_players[0]._unrealized_points = 0;
        state->_players[1]._unrealized_points = 0;
        for (uint8_t i = 0; i < state->_round_count; ++i) {
            RoundResult *rr = &state->_rounds[i]._result;
            if (*rr == RR_Hold)
                *rr = result;
            state->_rounds[i]._points = 1;
            switch (*rr) {
            case RR_Player0:
                if (state->_rounds[i]._cards[0] == Chancellor &&
                    state->_rounds[i]._cards[1] != Magician) {
                    state->_rounds[i]._points = 2;
                    state->_players[0]._score += 2;
                } else
                    state->_players[0]._score++;
                break;
            case RR_Player1:
                if (state->_rounds[i]._cards[1] == Chancellor &&
                    state->_rounds[i]._cards[0] != Magician) {
                    state->_rounds[i]._points = 2;
                    state->_players[1]._score += 2;
                } else
                    state->_players[1]._score++;
                break;
            case RR_Hold:
                state->_players[0]._unrealized_points +=
                    (state->_rounds[i]._cards[0] == Chancellor ? 2 : 1);
                state->_players[1]._unrealized_points +=
                    (state->_rounds[i]._cards[1] == Chancellor ? 2 : 1);
                break;
            default:
                break;
            }
        }
    }
}

RoundResult check_winner(GameState *state) {
    if (state->_last_result == RR_Player0_GameWon ||
        state->_last_result == RR_Player1_GameWon)
        return state->_last_result;
    if (state->_players[0]._score >= 4 || state->_players[1]._score >= 4) {
        if (state->_players[0]._score == state->_players[1]._score)
            return RR_Hold;
        return state->_players[0]._score > state->_players[1]._score
                   ? RR_Player0_GameWon
                   : RR_Player1_GameWon;
    }
    return state->_round_count == 8 ? RR_Hold : RR_NoResult;
}

// ── Simulate one game: prints round history to stdout ──────────────────────

static void simulate_game(const Card p0_hand[], const Card p1_hand[]) {
    GameState state;
    new_game(&state);

    memcpy(state._players[0]._hand._items, p0_hand, 8 * sizeof(Card));
    state._players[0]._hand._count = 8;
    memcpy(state._players[1]._hand._items, p1_hand, 8 * sizeof(Card));
    state._players[1]._hand._count = 8;

    RoundResult game_winner = RR_NoResult;

    for (uint8_t round = 0; round < 8; ++round) {
        Card p0_card = state._players[0]._hand._items[0];
        Card p1_card = state._players[1]._hand._items[0];

        state = resolve_round(&state, p0_card, p1_card);
        move_cards(&state, p0_card, p1_card, state._last_result);

        game_winner = check_winner(&state);
        if (game_winner != RR_NoResult)
            break;
    }

    // Winner message from final check
    switch (game_winner) {
    case RR_Player0_GameWon:
        printf("WIN0\t");
        break;
    case RR_Player1_GameWon:
        printf("WIN1\t");
        break;
    case RR_Hold:
        printf("DRAW\t");
        break;
    default:
        printf("NO RESULT\t");
        break;
    }

    // Final accumulated scores
    printf("%d\t%d\t", state._players[0]._score, state._players[1]._score);

    // Round history: two lines (mirrors Godot rounds_1 / rounds_0 labels)
    char p1_line[20] = "";
    char p0_line[20] = "";

    for (uint8_t i = 0; i < state._round_count; ++i) {
        const Round &r = state._rounds[i];
        char c0 = CARD_LETTERS[r._cards[0]];
        char c1 = CARD_LETTERS[r._cards[1]];

        char m0 = ' ';
        char m1 = ' ';
        switch (r._result) {
        case RR_Player0:
            if (r._cards[0] == Lady && r._cards[1] == Prince)
                m0 = '!';
            else if (r._points == 2)
                m0 = '#';
            else
                m0 = '+';
            break;
        case RR_Player1:
            if (r._cards[1] == Lady && r._cards[0] == Prince)
                m1 = '!';
            else if (r._points == 2)
                m1 = '#';
            else
                m1 = '+';
            break;
        case RR_Player0_GameWon:
            m0 = '!';
            break;
        case RR_Player1_GameWon:
            m1 = '!';
            break;
        case RR_Hold:
        default:
            break;
        }

        char buf[4];
        snprintf(buf, sizeof(buf), "%c%c", c0, m0);
        strncat(p0_line, buf, sizeof(p0_line) - strlen(p0_line) - 1);

        snprintf(buf, sizeof(buf), "%c%c", c1, m1);
        strncat(p1_line, buf, sizeof(p1_line) - strlen(p1_line) - 1);
    }

    // Pad to 8 characters
    while (strlen(p0_line) < 8)
        strncat(p0_line, " ", sizeof(p0_line) - strlen(p0_line) - 1);
    while (strlen(p1_line) < 8)
        strncat(p1_line, " ", sizeof(p1_line) - strlen(p1_line) - 1);

    printf("%s\t", p0_line);
    printf("%s\n", p1_line);
}

// ── Manual permutation generator ────────────────────────────────────────────

static void permute(Card *arr, int idx, int n) {
    if (idx == n) {
        simulate_game(g_p0_hand, arr);
        g_count++;
        if (g_count % 1000 == 0) {
            fprintf(stderr, "%ld / 40320 (%.1f%%)\r", (long)g_count,
                    (double)g_count / 40320.0 * 100.0);
        }
        return;
    }
    // Avoid duplicate swaps (handles any duplicates in arr, though there aren't
    // any here)
    uint8_t used[8] = {0};
    for (int i = idx; i < n; ++i) {
        if (used[arr[i]])
            continue;
        used[arr[i]] = 1;
        Card tmp = arr[idx];
        arr[idx] = arr[i];
        arr[i] = tmp;
        permute(arr, idx + 1, n);
        tmp = arr[idx];
        arr[idx] = arr[i];
        arr[i] = tmp;
    }
}

// ── Main ────────────────────────────────────────────────────────────────────

int main() {
    fprintf(stderr, "# Braverats: 40320 permutations (P0 fixed, P1 varies)\n");
    fprintf(stderr, "# Format:\n");
    fprintf(stderr, "#   PLAYER message / DRAW\n");
    fprintf(stderr, "#   P0=N  P1=N  (final accumulated scores)\n");
    fprintf(stderr, "#   P1: C{mark} ...  (rounds_1, top line)\n");
    fprintf(stderr, "#   P0: C{mark} ...  (rounds_0, bottom line)\n");
    fprintf(stderr, "#\n");
    fprintf(stderr, "# Marks: ! = instant Lady-Prince win, # = 2pts, + = 1pt, "
                    "sp = hold\n\n");

    // P0 fixed to identity
    static const Card p0_fixed[] = {Assassin, Prince,  Chancellor, Jester,
                                    Lady,     General, Spy,        Magician};
    g_p0_hand = p0_fixed;

    // P1 starts as identity
    Card p1_perm[] = {Jester,     Lady,     Spy,     Assassin,
                      Chancellor, Magician, General, Prince};

    permute(p1_perm, 0, CardCount);

    fprintf(stderr, "\nDone: %ld games\n", (long)g_count);
    return 0;
}
