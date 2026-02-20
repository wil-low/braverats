#include "ai.h"
#include "core.h"
#include <stdlib.h>

uint8_t ai_move(GameState *state, uint8_t player_idx, Card opponent_move) {
    switch (state->_players[player_idx]._level) {
    default: // Level_1
        (void)opponent_move;
        return rand() % state->_players[player_idx]._hand._count;
    }
    return UINT8_MAX; // never reach here
}
