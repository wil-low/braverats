#include "core.h"
#include "ai.h"
#include "ui.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void new_game(GameState *state) {
    for (uint8_t i = 0; i < PLAYER_COUNT; ++i) {
        Player *p = &state->_players[i];
        p->_hand._count = 0;
        for (uint8_t n = 0; n < CardCount; ++n) {
            p->_score = 0;
            p->_hand._items[p->_hand._count++] = n;
#ifdef CSV_OUTPUT
            p->_remaining[n] = 1;
#endif
        }
        p->_effect = EffectNone;
    }
    state->_round_count = 0;
}

RoundResult resolve_round(GameState *state, uint8_t p0_move, uint8_t p1_move) {
    Card p0_card = state->_players[0]._hand._items[p0_move];
    Card p1_card = state->_players[1]._hand._items[p1_move];
    uint8_t p0_value =
        p0_card + (state->_players[0]._effect == EffectStrength ? 2 : 0);
    uint8_t p1_value =
        p1_card + (state->_players[1]._effect == EffectStrength ? 2 : 0);

    state->_players[0]._effect = state->_players[1]._effect = EffectNone;

    RoundResult result = p0_value > p1_value ? RR_Player0 : RR_Player1;
    if (p0_value == p1_value)
        result = RR_Hold;

    if (p0_card != Magician && p1_card != Magician) {
        // apply card effects
        if (p0_value == p1_value || p0_card == Jester || p1_card == Jester)
            return RR_Hold;

        if (p0_card != p1_card) {
            if (p0_card == Princess && p1_card == Prince)
                result = RR_Player0_GameWon;
            if (p1_card == Princess && p0_card == Prince)
                result = RR_Player1_GameWon;

            if (p0_card == Assassin || p1_card == Assassin)
                result = p0_value < p1_value ? RR_Player0 : RR_Player1;

            if (p0_card == Spy)
                state->_players[0]._effect = EffectOpponentReveals;
            if (p1_card == Spy)
                state->_players[1]._effect = EffectOpponentReveals;

            if (p0_card == General)
                state->_players[0]._effect = EffectStrength;
            if (p1_card == General)
                state->_players[1]._effect = EffectStrength;

            if (p0_card == Prince)
                result = RR_Player0;
            if (p1_card == Prince)
                result = RR_Player1;
        }
    }

    return result;
}

void move_cards(GameState *state, uint8_t p0_move, uint8_t p1_move,
                RoundResult result) {
    Card p0_card = state->_players[0]._hand._items[p0_move];
    Card p1_card = state->_players[1]._hand._items[p1_move];
    Round *round = &state->_rounds[state->_round_count++];
    round->_cards[0] = p0_card;
    round->_cards[1] = p1_card;
    round->_result = result;

    remove_from_hand(state, 0, p0_move);
    remove_from_hand(state, 1, p1_move);

    state->_players[0]._score = 0;
    state->_players[1]._score = 0;
#ifdef CSV_OUTPUT
    state->_players[0]._unrealized_points = 0;
    state->_players[1]._unrealized_points = 0;
#endif
    if (result != RR_Player0_GameWon && result != RR_Player1_GameWon) {
        for (uint8_t i = 0; i < state->_round_count; ++i) {
            RoundResult *rr = &state->_rounds[i]._result;
            if (*rr == RR_Hold)
                *rr = result;
            switch (*rr) {
            case RR_Player0:
                if (state->_rounds[i]._cards[0] == Minister &&
                    state->_rounds[i]._cards[1] != Magician)
                    state->_players[0]._score += 2;
                else
                    state->_players[0]._score++;
                break;
            case RR_Player1:
                if (state->_rounds[i]._cards[1] == Minister &&
                    state->_rounds[i]._cards[0] != Magician)
                    state->_players[1]._score += 2;
                else
                    state->_players[1]._score++;
                break;
            case RR_Player0_GameWon:
                state->_players[0]._score = UINT8_MAX;
                return;
            case RR_Player1_GameWon:
                state->_players[1]._score = UINT8_MAX;
                return;
            case RR_Hold:
#ifdef CSV_OUTPUT
                state->_players[0]._unrealized_points +=
                    (state->_rounds[i]._cards[0] == Minister ? 2 : 1);
                state->_players[1]._unrealized_points +=
                    (state->_rounds[i]._cards[1] == Minister ? 2 : 1);
#endif
                break;
            default:
                break;
            }
        }
    }
}

void remove_from_hand(GameState *state, uint8_t player_idx, uint8_t card_idx) {
    Player *p = &state->_players[player_idx];
#ifdef CSV_OUTPUT
    p->_remaining[p->_hand._items[card_idx]]--;
#endif
    for (uint8_t n = card_idx; n < p->_hand._count; ++n)
        p->_hand._items[n] = p->_hand._items[n + 1];
    p->_hand._count--;
}

RoundResult check_winner(GameState *state) {
    if (state->_players[0]._score >= 4 || state->_players[1]._score >= 4) {
        if (state->_players[0]._score == state->_players[1]._score)
            return RR_Hold;
        return state->_players[0]._score > state->_players[1]._score
                   ? RR_Player0
                   : RR_Player1;
    }
    return state->_round_count == 8 ? RR_Hold : RR_NoResult;
}

uint8_t input_move(GameState *state, uint8_t player_idx, Card opponent_move) {
    if (state->_players[player_idx]._level == Human)
        return human_move(state, player_idx, opponent_move);
    return ai_move(state, player_idx, opponent_move);
}

void input_wait(const char *message) {
    printf("%s", message);
    /* flush pending input */
    int c;
    while ((c = getchar()) != '\n' && c != EOF)
        ;
    /* wait for Enter */
    getchar();
}
