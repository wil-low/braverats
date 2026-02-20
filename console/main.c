#include "config.h"
#include "core.h"
#include "ui.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

GameState game_state;

void setup() {
    printf("Braverats\n");

    srand(RANDOM_SEED ? RANDOM_SEED : (unsigned int)time(NULL));

    GameState *state = &game_state;
    state->_id = 0;

    for (uint8_t i = 0; i < PLAYER_COUNT; ++i) {
        state->_players[i]._effect = EffectNone;
        state->_players[i]._victory_count = 0;
    }
    state->_players[0]._level = PLAYER0_LEVEL;
    state->_players[1]._level = PLAYER1_LEVEL;

    new_game(state);
}

void loop() {
    GameState *state = &game_state;
    render_game(state);

    RoundResult winner = check_winner(state);
    switch (winner) {
    case RR_Hold:
    case RR_Player0:
    case RR_Player1:
        if (winner != RR_Hold)
            state->_players[winner]._victory_count++;
        render_winner(state, winner);
        state->_id++;
        if (state->_id > MAX_GAMES) {
            input_wait("MAX_GAMES reached. Press Enter...");
            state->_id = 0;
        }
        if (state->_players[0]._level == Human)
            input_wait("Press Enter...");
        new_game(state);
        return;
    default:
        break;
    }

    uint8_t p0_move;
    uint8_t p1_move;
    if (state->_players[0]._effect == EffectOpponentReveals) {
        p1_move = input_move(state, 1, UnknownCard);
        p0_move =
            input_move(state, 0, state->_players[1]._hand._items[p1_move]);
    } else if (state->_players[1]._effect == EffectOpponentReveals) {
        p0_move = input_move(state, 0, UnknownCard);
        p1_move =
            input_move(state, 1, state->_players[0]._hand._items[p0_move]);
    } else {
        p0_move = input_move(state, 0, UnknownCard);
        p1_move = input_move(state, 1, UnknownCard);
    }

    RoundResult result = resolve_round(state, p0_move, p1_move);
    move_cards(state, p0_move, p1_move, result);

    if (state->_players[0]._score >= 4 || state->_players[1]._score >= 4 ||
        state->_round_count == 8) {
    }
}

int main(/*int argc, char **argv*/) {
#ifdef CSV_OUTPUT
    char buf[1000];
    FILE *csv = fopen(CSV_OUTPUT, "a");
    if (ftell(csv) == 0) {
        serialize_header(buf);
        fwrite(buf, strlen(buf), 1, csv);
    }
#endif
    setup();

    while (true) {
        loop();
#ifdef CSV_OUTPUT
        serialize_state(&game_state, buf);
        fwrite(buf, strlen(buf), 1, csv);
        fflush(csv);
#endif
    }
#ifdef CSV_OUTPUT
    fclose(csv);
#endif

    return 0;
}
