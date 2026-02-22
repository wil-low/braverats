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
        p->_effect = UnknownCard;
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

    state->_players[0]._effect = state->_players[1]._effect = UnknownCard;

    state->_last_result = p0_value > p1_value ? RR_Player0 : RR_Player1;
    if (p0_value == p1_value)
        state->_last_result = RR_Hold;

    if (p0_card != Magician && p1_card != Magician) {
        // apply card effects
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
                    (p1_card == Princess) ? RR_Player1_GameWon : RR_Player0;
            if (p1_card == Prince)
                state->_last_result =
                    (p0_card == Princess) ? RR_Player0_GameWon : RR_Player1;
        }
    }
    return *state;
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
    state->_players[0]._unrealized_points = 0;
    state->_players[1]._unrealized_points = 0;
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
                state->_players[0]._unrealized_points +=
                    (state->_rounds[i]._cards[0] == Minister ? 2 : 1);
                state->_players[1]._unrealized_points +=
                    (state->_rounds[i]._cards[1] == Minister ? 2 : 1);
                break;
            default:
                break;
            }
        }
    }
}

void remove_from_hand(GameState *state, uint8_t player_idx, Card card) {
    Player *p = &state->_players[player_idx];
#ifdef CSV_OUTPUT
    p->_remaining[p->_hand._items[card_idx]]--;
#endif
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
/*
Card input_move(GameState *state, uint8_t player_idx, Card opponent_move) {
    if (state->_players[player_idx]._level == Human)
        return human_move(state, player_idx, opponent_move);
    return ai_move(state, player_idx, opponent_move);
}
*/

void process_command(GameState *state, UI *ui) {
    /*
    state->_input_cmd = state->_pending_cmd;
    state->_pending_cmd = CMD_NONE;
    switch (state->_input_cmd) {
    case CMD_PASS:
        if (state->_players[state->_cur_player]._hand._count == 0 ||
            (state->_valid_moves._flags & FLAG_MOUMOU)) {
            state->_pending_cmd = CMD_ROUND_OVER;
        } else {
            state->_pending_cmd = CMD_NEXT_PLAYER;
            if (state->_played._count && CardValue(state->_last_card) == Jack) {
                state->_pending_cmd = ai_demand_suit(state);
            }
            state->_valid_moves._flags &= ~FLAG_PASS;
            state->_valid_moves._flags &= ~FLAG_RESTRICT_VALUE;
        }
        ui->startPass();
        break;
    case CMD_DRAW:
        state->_pending_cmd = CMD_SELECT_MOVE;
        state->_valid_moves._flags &= ~FLAG_DRAW;
        ui->startDraw();
        break;
    case CMD_NEXT_PLAYER:
        state->_cur_player = (state->_cur_player + 1) % PLAYER_COUNT;
        state->_pending_cmd = CMD_SELECT_MOVE;
        state->_valid_moves._flags |= FLAG_DRAW;
        break;
    case CMD_SELECT_MOVE:
        find_valid_moves(state, state->_cur_player);
        state->_pending_cmd = ai_move(state);
        break;
    case CMD_SELECT_SUIT:
        break;
    case CMD_ROUND_OVER:
        state->_players[0]._hand.x = 4;
        state->_players[0]._hand.y = 33;
        state->_players[0]._hand.maxVisibleCards = 6;
        state->_players[0]._hand.setFace(true);
        state->_players[0]._hand_score = hand_score(state, 0);

        state->_players[1]._hand.x = 4;
        state->_players[1]._hand.y = 1;
        state->_players[1]._hand.maxVisibleCards = 6;
        state->_players[1]._hand.setFace(true);
        state->_players[1]._hand_score = hand_score(state, 1);

        if (state->_players[0]._hand_score < state->_players[1]._hand_score) {
            ui->_versusWon[ui->_versusMode]++;
            ui->writeEeprom(false);
        }
        ui->_mode = MODE_ROUND_OVER;
        ui->_drawRoundOverTimer = ROUND_OVER_TIMER;
        break;
    case CMD_NEW_ROUND:
        new_round(state, ui);
        initial_deal(state, ui);
        break;
    case CMD_DEMAND_SPADES:
    case CMD_DEMAND_HEARTS:
    case CMD_DEMAND_DIAMOND:
    case CMD_DEMAND_CLUBS:
        state->_demanded =
            static_cast<uint8_t>(state->_input_cmd) - CMD_DEMAND_SPADES;
        state->_pending_cmd = CMD_NEXT_PLAYER;
        break;
    default: {
        Player *p = &state->_players[state->_cur_player];
        Card p_card = p->_hand._items[state->_input_cmd];
        ui->startPlayCard(state->_input_cmd);
        // apply effects
        state->_valid_moves._flags &= ~FLAG_OPPONENT_SKIPS;
        if (CardValue(p_card) == Eight) {
            state->_valid_moves._flags |= FLAG_OPPONENT_SKIPS;
        }
        if (CardValue(p_card) == Ace) {
            state->_valid_moves._flags |= FLAG_OPPONENT_SKIPS;
        }
        if (CardSuit(p_card) == Clubs && CardValue(p_card) == King) {
            state->_valid_moves._flags |= FLAG_OPPONENT_SKIPS;
        }
        // check moumou
        if (CardValue(p_card) == CardValue(state->_last_card)) {
            ++state->_moumou_counter;
            if (state->_moumou_counter == SuitCount)
                state->_valid_moves._flags |= FLAG_MOUMOU;
        } else
            state->_moumou_counter = 1;

        if (CardValue(p_card) == Six ||
            (state->_valid_moves._flags & FLAG_OPPONENT_SKIPS))
            state->_valid_moves._flags |= FLAG_DRAW;
        else
            state->_valid_moves._flags &= ~FLAG_DRAW;
        if (CardValue(p_card) != Six)
            state->_valid_moves._flags |= FLAG_PASS;
        else
            state->_valid_moves._flags &= ~FLAG_PASS;

        state->_last_card = p_card;

        state->_demanded = Undefined;

        if (!(state->_valid_moves._flags & FLAG_OPPONENT_SKIPS) &&
            CardValue(state->_last_card) != Six)
            state->_valid_moves._flags |= FLAG_RESTRICT_VALUE;
        else
            state->_valid_moves._flags &= ~FLAG_RESTRICT_VALUE;

        if (CardValue(state->_last_card) != Six)
            state->_valid_moves._flags |= FLAG_PASS;
        else
            state->_valid_moves._flags &= ~FLAG_PASS;

        state->_pending_cmd = CMD_SELECT_MOVE;
    } break;
    }
    */
}
