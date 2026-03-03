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
    ui.showTitle();

    if (RANDOM_SEED)
        srand(RANDOM_SEED);
    else
        srand(gb.frameCount);
}

void loop() {
    // Main loop.
    if (gb.update()) {
        if (ui._mode != MODE_ANIMATE && ui._mode != MODE_PAUSE &&
            gameState._pending_cmd != CMD_NONE) {
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
        case MODE_GAME_OVER:
            handleGameOver();
            break;
        }

        // Draw the board.
        if (ui._mode == MODE_GAME_OVER)
            ui.drawGameOver();
        else
            ui.drawBoard();

        // Draw other things based on the current state of the game.
        switch (ui._mode) {
        case MODE_PAUSE:
            if (ui._pauseTimer == 0)
                ui._mode = MODE_PLAYER_MOVE;
            else
                ui._pauseTimer--;
            break;
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
}
*/
    else if (gb.buttons.pressed(BTN_A)) {
        Pile &p = gameState._players[0]._hand;
        gameState._pending_cmd = (Command)p._items[ui._cardIndex];
        if (ui._cardIndex > 0 && ui._cardIndex == p._count - 1)
            ui._cardIndex--;
    }

    // if (originalLocation != ui._activeLocation)
    //     ui._cardIndex = 0;
}

void handleGameOver() {
    if (gb.buttons.pressed(BTN_A)) {
        gameState._pending_cmd = CMD_NEW_GAME;
    }
}
