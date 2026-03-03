#include "core.h"
#include "ai.h"
#include "ui.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void new_game(GameState *state) {
    for (uint8_t i = 0; i < PLAYER_COUNT; ++i) {
        Player *p = &state->_players[i];
        p->_score = 0;
        p->_effect = UnknownCard;
        p->_hand._count = 0;
        for (uint8_t n = 0; n < CardCount; ++n) {
            p->_hand._items[p->_hand._count++] = n;
#ifdef CSV_OUTPUT
            p->_remaining[n] = 1;
#endif
        }
    }
    state->_last_result = RR_NoResult;
    state->_round_count = 0;
    state->_pending_cmd = CMD_NEW_ROUND;
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
                    (p1_card == Lady) ? RR_Player1_GameWon : RR_Player0;
            if (p1_card == Prince)
                state->_last_result =
                    (p0_card == Lady) ? RR_Player0_GameWon : RR_Player1;
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

    state->_input_cmd = state->_pending_cmd;
    state->_pending_cmd = CMD_NONE;
    switch (state->_input_cmd) {
    case CMD_NEW_GAME: {
        switch (ui->_versusMode) {
        case Human_L1:
            state->_players[0]._level = Human;
            state->_players[1]._level = Level_1;
            break;
        case Human_L2:
            state->_players[0]._level = Human;
            state->_players[1]._level = Level_2;
            break;
        case L2_L1:
            state->_players[0]._level = Level_2;
            state->_players[1]._level = Level_1;
            break;
        }
        ui->_mode = MODE_PLAYER_MOVE;
        new_game(state);
    } break;
    case CMD_NEW_ROUND: {
        ui->playSoundA();
        ui->_played_face_up[1] = false;
        ui->_played_face_up[0] = state->_players[0]._level == Human;
        Card p0_card = UnknownCard;
        Card p1_card = UnknownCard;
        if (state->_players[0]._effect == Spy) {
            p1_card = input_move(state, 1, UnknownCard);
            ui->_played_face_up[1] = true;
            p0_card = input_move(state, 0, p1_card);
        } else if (state->_players[1]._effect == Spy) {
            p0_card = input_move(state, 0, UnknownCard);
            ui->_played_face_up[0] = true;
            if (p0_card != UnknownCard)
                p1_card = input_move(state, 1, p0_card);
        } else {
            p0_card = input_move(state, 0, UnknownCard);
            p1_card = input_move(state, 1, UnknownCard);
        }

        ui->_played_cards[0] = p0_card;
        ui->_played_cards[1] = p1_card;
        state->_pending_cmd = CMD_SELECT_MOVE;
    } break;
    case CMD_SELECT_MOVE:
        ui->_mode = MODE_PLAYER_MOVE; // temporary w/o ANIMATE
        if (state->_players[1]._effect == Spy &&
            ui->_played_cards[0] != UnknownCard)
            ui->_played_cards[1] = input_move(state, 1, ui->_played_cards[0]);
        if (ui->_played_cards[0] != UnknownCard &&
            ui->_played_cards[1] != UnknownCard)
            state->_pending_cmd = CMD_RESOLVE_ROUND;
        break;
    case CMD_RESOLVE_ROUND: {
        ui->_played_face_up[0] = ui->_played_face_up[1] = true;
        *state =
            resolve_round(state, ui->_played_cards[0], ui->_played_cards[1]);
        move_cards(state, ui->_played_cards[0], ui->_played_cards[1],
                   state->_last_result);
        state->_pending_cmd = CMD_NEW_ROUND;
        ui->_winner = check_winner(state);
        switch (ui->_winner) {
        case RR_Hold:
        case RR_Player0_GameWon:
        case RR_Player1_GameWon:
            if (ui->_winner != RR_Hold)
                state->_players[ui->_winner - RR_Player0_GameWon]
                    ._victory_count++;
            state->_id++;
            state->_pending_cmd = CMD_GAME_OVER;
            ui->playSoundA();
            break;
        default:
            break;
        }
        ui->_pauseTimer = state->_players[0]._level == Human ? 32 : 8;
        ui->_mode = MODE_PAUSE;
    } break;
    case CMD_GAME_OVER:
        if (state->_players[0]._score > state->_players[1]._score) {
            ui->_versusWon[ui->_versusMode]++;
            ui->writeEeprom(false);
        }
        ui->_played_cards[0] = ui->_played_cards[1] = UnknownCard;
        ui->_versusCount[ui->_versusMode]++;
        ui->_mode = MODE_GAME_OVER;
        ui->_drawRoundOverTimer = 32;
        break;
    default: {
        ui->_played_cards[0] = (Card)state->_input_cmd;
        state->_pending_cmd = CMD_SELECT_MOVE;
    } break;
    }
}

Card input_move(GameState *state, uint8_t player_idx, Card opponent_move) {
    if (state->_players[player_idx]._level == Human)
        return UnknownCard;
    return ai_move(state, player_idx, opponent_move);
}
