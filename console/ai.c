#include "ai.h"
#include "core.h"
#include "ui.h"
#include <stdlib.h>

Card ai_move(GameState *state, uint8_t my_idx, Card opponent_move) {
    uint8_t hand_size = state->_players[my_idx]._hand._count;
    uint8_t my_level = state->_players[my_idx]._level;
    switch (my_level) {
    case Level_2:
    case Level_3: {
        if (state->_round_count == 0) {
            // first card is random
            return state->_players[my_idx]._hand._items[rand() % hand_size];
        }
        bool is_spy = opponent_move != UnknownCard;
        uint8_t opp_idx = PLAYER_COUNT - 1 - my_idx;
        int8_t outcome[CardCount][RR_Result_Count];
        for (uint8_t me = 0; me < hand_size; ++me) {
            for (uint8_t i = 0; i < RR_Result_Count; ++i)
                outcome[me][i] = 0;
            Card p0_card = UnknownCard;
            Card p1_card = UnknownCard;
            *(my_idx == 0 ? &p0_card : &p1_card) =
                state->_players[my_idx]._hand._items[me];
            for (uint8_t opp = 0; opp < state->_players[opp_idx]._hand._count;
                 ++opp) {
                Card opp_card = state->_players[opp_idx]._hand._items[opp];
                if (is_spy && opponent_move != opp_card)
                    continue;
                *(my_idx == 0 ? &p1_card : &p0_card) = opp_card;
                GameState new_state = resolve_round(state, p0_card, p1_card);
                move_cards(&new_state, p0_card, p1_card,
                           new_state._last_result);
                RoundResult winner = check_winner(&new_state);
                // render_outcome(p0_card, p1_card, &new_state, winner);
                if (winner == (uint8_t)(opp_idx + RR_Player0_GameWon))
                    outcome[me][winner]++;
                else
                    outcome[me][new_state._last_result]++;
            }
        }
        if (my_level == Level_3) {
            int8_t min_eval = INT8_MAX;
            int8_t max_eval = INT8_MIN;
            int8_t evals[CardCount];
            for (uint8_t i = 0; i < hand_size; ++i) {
                evals[i] = 0;
            }
            for (uint8_t me = 0; me < hand_size; ++me) {
                int8_t eval = outcome[me][RR_Player0 + my_idx];
                eval += outcome[me][RR_Player0_GameWon + my_idx];
                eval -= outcome[me][RR_Player0 + opp_idx];
                eval -= outcome[me][RR_Player0_GameWon + opp_idx] * 8;

                Card my_card = state->_players[my_idx]._hand._items[me];
                if (my_card == Spy)
                    eval++;
                evals[me] = eval;
                // render_eval("eval1", my_card, eval);
                if (eval > max_eval)
                    max_eval = eval;
                if (eval < min_eval)
                    min_eval = eval;
            }
            uint8_t sum = 0;
            for (uint8_t i = 0; i < hand_size; ++i) {
                if (evals[i] > 0)
                    evals[i] = (evals[i] - min_eval) * 4 + 1;
                else
                    evals[i] = is_spy ? 0 : evals[i] - min_eval + 1;
                sum += evals[i];
            }
            if (sum == 0)
                sum = 1;
            for (uint8_t i = 0; i < hand_size; ++i) {
                evals[i] = evals[i] * 127 / sum;
                // Card my_card = state->_players[my_idx]._hand._items[i];
                // render_eval("eval2", my_card, evals[i]);
            }
            uint8_t rmove = rand() % 127;
            sum = 0;
            for (uint8_t i = 0; i < hand_size; ++i) {
                sum += evals[i];
                if (sum >= rmove)
                    return state->_players[my_idx]._hand._items[i];
            }
            Card result = state->_players[my_idx]._hand._items[hand_size - 1];
            return result;
        }
        // Level_2
        uint8_t best_move = 0;
        int8_t best_eval = INT8_MIN;
        for (uint8_t me = 0; me < hand_size; ++me) {
            int8_t eval = outcome[me][RR_Player0 + my_idx];
            eval += outcome[me][RR_Player0_GameWon + my_idx];
            eval -= outcome[me][RR_Player0 + opp_idx];
            eval -= outcome[me][RR_Player0_GameWon + opp_idx] * 8;

            Card my_card = state->_players[my_idx]._hand._items[me];
            if (my_card == Spy)
                eval++;

            // render_eval(my_card, eval);
            if (eval > best_eval) {
                best_eval = eval;
                best_move = me;
            }
        }
        Card result = state->_players[my_idx]._hand._items[best_move];
        return result;
    }
    default: // Level_1
        return state->_players[my_idx]._hand._items[rand() % hand_size];
    }
    return UnknownCard; // never reach here
}
