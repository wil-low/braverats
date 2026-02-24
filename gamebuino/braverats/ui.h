#ifndef _UI_H_
#define _UI_H_

#include "core.h"
#include <Gamebuino.h>

// Stock: where you draw cards from
// Table: table cards
// Played: cards played by human
// Human: cards in human hand
enum Location {
    played1,
    played0,
    hand0,
    hand1
};

enum DrawMode {
    DM_NORMAL,
    DM_SELECTED,
    DM_FACE_DOWN
};

struct CardAnimation {
    Card card;
    byte x, y, destX, destY;
    Pile *destination;
};

struct CardBounce {
    Card card;
    int x, y, xVelocity, yVelocity;
};

class UI {
  public:
    UI();

    // State of the game.
    GameMode _mode = MODE_GAME_OVER;

    // how many cards must be animated in dealing mode
    byte _dealingCount;

    // Stack that the cursor is currently pointed at.
    Location _activeLocation;
    // Within the human hand, card position on the screen, 0 being left card.
    byte _cardIndex;
    // Position of the cursor for animation.
    byte _cursorX, _cursorY;

    // AI level
    VersusMode _versusMode;

    Card _played_cards[2];
    bool _played_face_up[2];

    // Used to deal at the start of the game.
    CardAnimation _cardAnimations[Pile::_maxCards];
    byte _cardAnimationCount = 0;

    RoundResult _winner;

    uint8_t _drawRoundOverTimer;
    uint8_t _pauseTimer;

    uint16_t _versusCount[VersusMode::VersusCount];
    uint16_t _versusWon[VersusMode::VersusCount];

    void showTitle();
    void pause();
    void animateMove(Pile *src, byte srcIdx, Pile *dst, byte dstIdx);

    void startDraw();
    void startPlayCard(uint8_t idx);

    void drawBoard();
    void drawSuitSelector();
    void drawGameOver();
    void drawCard(byte x, byte y, Card card, DrawMode mode);
    void drawValue(byte x, byte y, Card value, bool with_bitmap);
    void drawLeftArrow(byte x, byte y);
    void drawRightArrow(byte x, byte y);
    void drawPlus(byte x, byte y);
    void drawCursor();
    void drawDealing();
    void drawCursor(byte x, byte y, bool flipped);
    void drawNumberRight(uint16_t n, byte x, byte y);

    void playSoundA();
    void playSoundB();

    void displayStatistics();
    void drawWonGame();

    void debug(uint8_t n0, uint8_t n1);

    void readEeprom();
    void writeEeprom(bool saveGame);

  private:
    void getCursorDestination(byte &x, byte &y, bool &flipped);
    byte updatePosition(byte current, byte destination);
    Pile *getActiveLocationPile();
    void getCoords(Location location, byte idx, byte &x, byte &y);

    void drawZero(byte x, byte y);
    void drawOne(byte x, byte y);
    void drawTwo(byte x, byte y);
    void drawThree(byte x, byte y);
    void drawFour(byte x, byte y);
    void drawFive(byte x, byte y);
    void drawSix(byte x, byte y);
    void drawSeven(byte x, byte y);

    void drawSegmentA(byte x, byte y);
    void drawSegmentB(byte x, byte y);
    void drawSegmentC(byte x, byte y);
    void drawSegmentD(byte x, byte y);
    void drawSegmentE(byte x, byte y);
    void drawSegmentF(byte x, byte y);
    void drawSegmentG(byte x, byte y);
};

#endif
