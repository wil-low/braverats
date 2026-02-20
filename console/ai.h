#ifndef _AI_H_
#define _AI_H_

#include "core.h"
#include <stdint.h>

uint8_t ai_move(GameState *state, uint8_t player_idx, Card opponent_move);

#endif
