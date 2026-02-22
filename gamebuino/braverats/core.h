#ifndef _CORE_H_
#define _CORE_H_

#include "config.h"
#include "pile.h"
#include <stdint.h>

#define Undefined UINT8_MAX

typedef enum {
    RR_Player0 = 0,
    RR_Player1,
    RR_Hold,
    RR_Player0_GameWon,
    RR_Player1_GameWon,
    RR_NoResult,
    RR_Result_Count = RR_NoResult,
} RoundResult;

typedef enum {
    Human = 0,
    Level_1,
    Level_2,
    Level_3,
} AILevel;

typedef enum {
    Human_L1 = 0,
    Human_L2,
    L2_L1,
    VersusCount
} VersusMode;

typedef enum {
    MODE_PLAYER_MOVE = 0,
    MODE_ANIMATE,
    MODE_ROUND_OVER
} GameMode;

typedef enum {
    CMD_PLAY_CARD = 0,
    CMD_NEXT_PLAYER = 100,
    CMD_NEW_ROUND = 101,
    CMD_SELECT_MOVE = 102,
    CMD_ROUND_OVER = 103,
    CMD_NONE = 255
} Command;

typedef struct {
    AILevel _level;
    Pile _hand;
    Card _effect;
    uint8_t _score;
    uint16_t _victory_count;
    uint8_t _unrealized_points;
    uint8_t _remaining[CardCount];
} Player;

typedef struct {
    Card _cards[PLAYER_COUNT];
    RoundResult _result;
    uint8_t _points;
} Round;

typedef struct {
    Player _players[PLAYER_COUNT];
    Round _rounds[CardCount];
    uint8_t _round_count;
    uint32_t _id;
    RoundResult _last_result;
    Command _pending_cmd;
} GameState;

class UI;

void new_game(GameState *state);
GameState resolve_round(GameState *state, Card p0_card, Card p1_card);
void move_cards(GameState *state, Card p0_move, Card p1_move,
                RoundResult result);
void remove_from_hand(GameState *state, uint8_t player_idx, Card card);
RoundResult check_winner(GameState *state);

void process_command(GameState *state, UI *ui);

#endif
