#include "core.h"
#include <stdio.h>
#include <string.h>

const char *NAMES[] = {"Jester",   "Princess", "Spy",     "Assassin",
                       "Minister", "Magician", "General", "Prince"};

const char *SHORT_NAMES[] = {"Je", "Ps", "Sp", "As", "Mi",
                             "Ma", "Ge", "PC", ""};

const char *EFFECTS[] = {
    "This round’s is nullified; and put on hold",
    "If the opponent played the Prince, you win the game",
    "Next round, your opponent reveals his card before you choose yours",
    "The lowest strength wins",
    "If you win with this card, it counts as 2 victories",
    "Nullifies the special power of the opponent’s card",
    "Your card next turn gets +2 strength",
    "You win the round"};

const char *RESULT_NAMES[] = {"Player0",         "Player1",         "Hold",
                              "Player0_GameWon", "Player1_GameWon", "NoResult"};

const char *WINNER_NAMES[] = {"", "", "Draw", "Player0", "Player1", ""};

void render_player(GameState *state, uint8_t idx) {
    Player *p = &state->_players[idx];

    if (p->_level == Human)
        printf("Player %d (Human), score %d, effect %s\n", idx, p->_score,
               SHORT_NAMES[p->_effect]);
    else
        printf("Player %d (Lev.%d), score %d, effect %s\n", idx, p->_level,
               p->_score, SHORT_NAMES[p->_effect]);

    for (uint8_t i = 0; i < p->_hand._count; ++i)
        printf("%s ", SHORT_NAMES[p->_hand._items[i]]);
    printf("\n");

    if (p->_level == Human) {
        for (uint8_t i = 0; i < p->_hand._count; ++i)
            printf("%d  ", i);
        printf("\n");
    }
    printf("\n");
}

void render_rounds(GameState *state) {
    printf("Played rounds:\n");
    for (int p = PLAYER_COUNT - 1; p >= 0; --p) {
        printf("P%d:  ", p);
        for (uint8_t i = 0; i < state->_round_count; ++i) {
            char win_mark = '.'; // RR_Hold
            switch (state->_rounds[i]._result) {
            case RR_Player0:
            case RR_Player1:
                win_mark =
                    ((RoundResult)p == state->_rounds[i]._result) ? '+' : ' ';
                break;
            case RR_Player0_GameWon:
            case RR_Player1_GameWon:
                win_mark = ((RoundResult)p ==
                            state->_rounds[i]._result - RR_Player0_GameWon)
                               ? '!'
                               : ' ';
                break;
            default:
                break;
            }
            printf("%s%c ", SHORT_NAMES[state->_rounds[i]._cards[p]], win_mark);
        }
        printf("\n");
    }
    printf("\n");
}

void render_game(GameState *state) {
    printf("\n===============\n\n");
    // cheatsheet
    for (uint8_t i = 0; i < CardCount; ++i)
        printf("%s   %-8s (%d) - %s\n", SHORT_NAMES[i], NAMES[i], i,
               EFFECTS[i]);
    printf("\n");

    render_player(state, 1);
    render_rounds(state);
    render_player(state, 0);
}

void render_winner(GameState *state, RoundResult result) {
    printf("Game complete: ");
    if (result == RR_Hold)
        printf("draw... ");
    else
        printf("Player %c wins! ", result == RR_Player0_GameWon ? '0' : '1');

    printf("Total: %d / %d\n", state->_players[0]._victory_count,
           state->_players[1]._victory_count);
}

void render_outcome(Card p0_card, Card p1_card, GameState *state,
                    RoundResult winner) {
    printf("Outcome %s %s: result %s: %s\n", SHORT_NAMES[p0_card],
           SHORT_NAMES[p1_card], RESULT_NAMES[state->_last_result],
           WINNER_NAMES[winner]);
}

void render_eval(Card card, int8_t eval) {
    printf("Eval %s: %4d\n", SHORT_NAMES[card], eval);
}

#ifdef CSV_OUTPUT
void serialize_header(char *buf) {
    sprintf(buf, "GameID;"
                 "RoundNumber;"
                 "Winner;"
                 "PreviousRoundWinner;"
                 "P0_CardType;"
                 "P0_SpyEffect;"
                 "P0_GeneralEffect;"
                 "P0_UnrealizedPoints;"
                 "P0_RemainingType0;"
                 "P0_RemainingType1;"
                 "P0_RemainingType2;"
                 "P0_RemainingType3;"
                 "P0_RemainingType4;"
                 "P0_RemainingType5;"
                 "P0_RemainingType6;"
                 "P0_RemainingType7;"
                 "P1_CardType;"
                 "P1_SpyEffect;"
                 "P1_GeneralEffect;"
                 "P1_UnrealizedPoints;"
                 "P1_RemainingType0;"
                 "P1_RemainingType1;"
                 "P1_RemainingType2;"
                 "P1_RemainingType3;"
                 "P1_RemainingType4;"
                 "P1_RemainingType5;"
                 "P1_RemainingType6;"
                 "P1_RemainingType7;"
                 "\n");
}

void serialize_state(GameState *state, char *buf) {
    Round *last_round = &state->_rounds[state->_round_count];
    sprintf(buf,
            "%d;" // GameID;"
            "%d;" // RoundNumber;"
            "%d;" // Winner;"
            "%d;" // PreviousRoundWinner;"
            "%d;" // P0_CardType;"
            "%d;" // P0_SpyEffect;"
            "%d;" // P0_GeneralEffect;"
            "%d;" // P0_UnrealizedPoints;"
            "%d;" // P0_RemainingType0;"
            "%d;" // P0_RemainingType1;"
            "%d;" // P0_RemainingType2;"
            "%d;" // P0_RemainingType3;"
            "%d;" // P0_RemainingType4;"
            "%d;" // P0_RemainingType5;"
            "%d;" // P0_RemainingType6;"
            "%d;" // P0_RemainingType7;"
            "%d;" // P1_CardType;"
            "%d;" // P1_SpyEffect;"
            "%d;" // P1_GeneralEffect;"
            "%d;" // P1_UnrealizedPoints;"
            "%d;" // P1_RemainingType0;"
            "%d;" // P1_RemainingType1;"
            "%d;" // P1_RemainingType2;"
            "%d;" // P1_RemainingType3;"
            "%d;" // P1_RemainingType4;"
            "%d;" // P1_RemainingType5;"
            "%d;" // P1_RemainingType6;"
            "%d;" // P1_RemainingType7;"
            "\n",
            state->_id,          // GameID;"
            state->_round_count, // RoundNumber;"
            last_round->_result, // Winner;"
            (state->_round_count == 0 ? RR_NoResult
                                      : state->_rounds[state->_round_count - 1]
                                            ._result), // PreviousRoundWinner;"
            last_round->_cards[0],                     // P0_CardType;"
            (state->_players[0]._effect == Spy),       // P0_SpyEffect;"
            (state->_players[0]._effect == General),   // P0_GeneralEffect;"
            state->_players[0]._unrealized_points,     // P0_UnrealizedPoints;"
            state->_players[0]._remaining[0],          // P0_RemainingType0;"
            state->_players[0]._remaining[1],          // P0_RemainingType1;"
            state->_players[0]._remaining[2],          // P0_RemainingType2;"
            state->_players[0]._remaining[3],          // P0_RemainingType3;"
            state->_players[0]._remaining[4],          // P0_RemainingType4;"
            state->_players[0]._remaining[5],          // P0_RemainingType5;"
            state->_players[0]._remaining[6],          // P0_RemainingType6;"
            state->_players[0]._remaining[7],          // P0_RemainingType7;"
            last_round->_cards[1],                     // P1_CardType;"
            (state->_players[1]._effect == Spy),       // P1_SpyEffect;"
            (state->_players[1]._effect == General),   // P1_GeneralEffect;"
            state->_players[1]._unrealized_points,     // P1_UnrealizedPoints;"
            state->_players[1]._remaining[0],          // P1_RemainingType0;"
            state->_players[1]._remaining[1],          // P1_RemainingType1;"
            state->_players[1]._remaining[2],          // P1_RemainingType2;"
            state->_players[1]._remaining[3],          // P1_RemainingType3;"
            state->_players[1]._remaining[4],          // P1_RemainingType4;"
            state->_players[1]._remaining[5],          // P1_RemainingType5;"
            state->_players[1]._remaining[6],          // P1_RemainingType6;"
            state->_players[1]._remaining[7]           // P1_RemainingType7;"
    );
}
#endif

Card human_move(GameState *state, uint8_t player_idx, Card opponent_move) {
    if (opponent_move != UnknownCard)
        printf("Opponent plays: %s\n", NAMES[opponent_move]);
    int result;
    while (true) {
        printf("Enter your choice: ");
        scanf("%d", &result);
        if (result < state->_players[player_idx]._hand._count)
            return state->_players[player_idx]._hand._items[result];
    }
    return UnknownCard; // never reach here
}
