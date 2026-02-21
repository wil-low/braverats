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
        state->_players[i]._effect = UnknownCard;
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
    case RR_Player0_GameWon:
    case RR_Player1_GameWon:
        if (winner != RR_Hold)
            state->_players[winner - RR_Player0_GameWon]._victory_count++;
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

    Card p0_card;
    Card p1_card;
    if (state->_players[0]._effect == Spy) {
        p1_card = input_move(state, 1, UnknownCard);
        p0_card = input_move(state, 0, p1_card);
    } else if (state->_players[1]._effect == Spy) {
        p0_card = input_move(state, 0, UnknownCard);
        p1_card = input_move(state, 1, p0_card);
    } else {
        p0_card = input_move(state, 0, UnknownCard);
        p1_card = input_move(state, 1, UnknownCard);
    }

    *state = resolve_round(state, p0_card, p1_card);
    move_cards(state, p0_card, p1_card, state->_last_result);

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
