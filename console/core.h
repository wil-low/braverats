#ifndef _CORE_H_
#define _CORE_H_

#include "config.h"
#include <stdbool.h>
#include <stdint.h>

#define Undefined UINT8_MAX

#ifdef __x86_64__
#define INLINE inline
#else
#define INLINE
#endif

typedef enum {
    Jester = 0,
    Princess,
    Spy,
    Assassin,
    Minister,
    Magician,
    General,
    Prince,
    CardCount,
    UnknownCard = 255
} Card;

typedef enum {
    EffectNone = 0,
    EffectOpponentReveals,
    EffectStrength
} Effect;

typedef enum {
    RR_Player0 = 0,
    RR_Player1,
    RR_Hold,
    RR_Player0_GameWon,
    RR_Player1_GameWon,
    RR_NoResult
} RoundResult;

typedef struct {
    uint8_t _count;
    Card _items[CardCount];
} Deck;

typedef enum {
    Human = 0,
    Level_1,
    Level_2,
} AILevel;

typedef struct {
    AILevel _level;
    Deck _hand;
    Effect _effect;
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
} GameState;

void new_game(GameState *state);
GameState resolve_round(GameState *state, Card p0_card, Card p1_card);
void move_cards(GameState *state, Card p0_move, Card p1_move,
                RoundResult result);
void remove_from_hand(GameState *state, uint8_t player_idx, Card card);
RoundResult check_winner(GameState *state);

Card input_move(GameState *state, uint8_t player_idx, Card opponent_move);
void input_wait(const char *message);

#endif
