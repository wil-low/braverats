#ifndef _UI_H_
#define _UI_H_

#include "core.h"

void render_player(GameState *state, uint8_t idx);
void render_table(GameState *state);
void render_game(GameState *state);
void render_winner(GameState *state, RoundResult result);

void render_outcome(Card p0_card, Card p1_card, GameState *state,
                    RoundResult winner);
void render_eval(Card card, int8_t eval);

#ifdef CSV_OUTPUT
void serialize_header(char *buf);
void serialize_state(GameState *state, char *buf);
#endif

Card human_move(GameState *state, uint8_t player_idx, Card opponent_move);

#endif
