#include <Gamebuino.h>
#include <SPI.h>

#include "ai.h"
#include "core.h"
#include "ui.h"

Gamebuino gb;
GameState gameState;
UI ui;

void setup() {
    gb.begin();

    GameState *state = &gameState;
    /*
        // Initialize positions of piles.
        gameState._deck.x = 2;
        gameState._deck.y = 1;
        gameState._deck.maxVisibleCards = 1;
        gameState._deck.faceUp = false;

        gameState._table.x = 16;
        gameState._table.y = 1;
        gameState._table.maxVisibleCards = 4;
        gameState._table.scrollToLast = true;

        gameState._played.x = 2;
        gameState._played.y = 17;
        gameState._played.maxVisibleCards = 6;
        gameState._played.scrollToLast = true;
*/
    gameState._players[0]._score = 0;
    gameState._players[1]._score = 0;

    ui.showTitle();
}

void loop() {
    // Main loop.
    if (gb.update()) {
        if (ui._mode != MODE_ANIMATE && gameState._pending_cmd != CMD_NONE) {
            process_command(&gameState, &ui);
        }

        // Exit to title whenever C is pressed.
        if (gb.buttons.pressed(BTN_C)) {
            ui.pause();
            return;
        }

        // Handle key presses for various modes.
        switch (ui._mode) {
        case MODE_PLAYER_MOVE:
            handleSelectingButtons();
            break;
        case MODE_ROUND_OVER:
            handleRoundOver();
            break;
        }

        // Draw the board.
        if (ui._mode == MODE_ROUND_OVER)
            ui.drawRoundOver(false);
        else
            ui.drawBoard();

        // Draw other things based on the current state of the game.
        switch (ui._mode) {
        case MODE_ANIMATE:
            ui.drawDealing();
            break;
        case MODE_PLAYER_MOVE:
            break;
        }
    }
}

void handleSelectingButtons() {
    // Handle buttons when user is using the arrow cursor to navigate.
    Location originalLocation = ui._activeLocation;
    if (gb.buttons.pressed(BTN_RIGHT)) {
        if (ui._cardIndex < gameState._players[0]._hand._count - 1)
            ++ui._cardIndex;
    }
    if (gb.buttons.pressed(BTN_LEFT)) {
        if (ui._cardIndex > 0)
            --ui._cardIndex;
    }
    /*if (gb.buttons.pressed(BTN_DOWN)) {
        if (ui._activeLocation < played)
            ui._activeLocation = played;
        else if (ui._activeLocation = played)
            ui._activeLocation = hand;
    }
    if (gb.buttons.pressed(BTN_UP)) {
        if (ui._activeLocation > stock)
            ui._activeLocation = ui._activeLocation - 1;
    }
    if (gb.buttons.pressed(BTN_B)) {
        if (gameState._deck._count != 0) {
            ui._cardAnimationCount = 0;
            ui.animateMove(&gameState._deck, 0, &gameState._players[1]._hand,
                           gameState._players[1]._hand._count);
            ui._dealingCount = ui._cardAnimationCount;
            ui._cardAnimationCount = 0;
            ui._mode = MODE_ANIMATE;
            // playSoundA();
        }
    } else if (gb.buttons.pressed(BTN_A)) {

        switch (ui._activeLocation) {
        case stock:
            if (gameState._valid_moves._flags & FLAG_DRAW) {
                if (gameState._deck._count != 0) {
                    gameState._pending_cmd = CMD_DRAW;
                }
                }
            }
            break;
        case hand: {
            Pile &p = gameState._players[0]._hand;
            if (p._count) {
                uint8_t idx = ui._cardIndex + p.scrollOffset;
                for (uint8_t i = 0; i < gameState._valid_moves._count; ++i) {
                    if (idx == gameState._valid_moves._items[i]) {
                        gameState._pending_cmd = idx;
                        break;
                    }
                }
            }
        } break;
        case played:
            if (gameState._valid_moves._flags & FLAG_PASS)
                gameState._pending_cmd = CMD_PASS;
            break;
        }
    }
    if (originalLocation != ui._activeLocation)
        ui._cardIndex = 0;
        */
}

void handleRoundOver() {
    // if (gb.buttons.pressed(BTN_A))
    //     update_score(&gameState, &ui);
}
