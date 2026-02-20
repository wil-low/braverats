#ifndef _UI_H_
#define _UI_H_

#include "core.h"

void render_player(GameState *state, uint8_t idx);
void render_table(GameState *state);
void render_game(GameState *state);
void render_winner(GameState *state, RoundResult result);

#ifdef CSV_OUTPUT
void serialize_header(char *buf);
void serialize_state(GameState *state, char *buf);
#endif

uint8_t human_move(GameState *state, uint8_t player_idx, Card opponent_move);

#endif
