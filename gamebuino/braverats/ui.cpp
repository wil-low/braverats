#include "ui.h"
#include "ai.h"
#include "config.h"
#include <EEPROM.h>
#include <Gamebuino.h>

#define EEPROM_MAGIC_NUMBER 171

// uncomment this line to show debug prints instead of scores
// #define DEBUG_PRINTS

extern Gamebuino gb;
extern GameState gameState;

void UI::drawBoard() {

    gb.display.setColor(BLACK);

#ifdef DEBUG_PRINTS
    // Debug prints
    drawNumberRight(gameState._cur_player, 72, 2);
    drawNumberRight(gameState._valid_moves._flags, 72, 10);

    drawNumberRight(gameState._valid_moves._count, 83, 17);
    // drawNumberRight(gameState._moumou_counter, 83, 17);
    // drawNumberRight(gameState._pending_cmd, 83, 17);
    drawNumberRight(gameState._input_cmd, 83, 25);

    debug(CardValue(gameState._last_card), CardSuit(gameState._last_card));
    // drawNumberRight(gameState._fvm_calls, 83, 33);
    // drawNumberRight(_mode, 83, 41);
#else
    // Scores
    drawNumberRight(gameState._players[1]._score, 83, 17);
    drawNumberRight(gameState._players[0]._score, 83, 25);

    // Player 1 card count
    if (gameState._players[1]._hand._count)
        drawNumberRight(gameState._players[1]._hand._count, 72, 8);
#endif
    /*
        // Stock
        drawDeck(&gameState._deck, false);

        if (gameState._players[1]._hand._count != 0) {
            drawCard(gameState._players[1]._hand.x,
       gameState._players[1]._hand.y, Card(Undefined, Spades, true));
        }

        Player &p = gameState._players[0];

        drawDeck(&p._hand, false);
        if (p._hand.scrollOffset > 0)
            drawLeftArrow(0, 38);
        if (p._hand._count - p._hand.scrollOffset > p._hand.maxVisibleCards)
            drawRightArrow(81, 38);

        drawDeck(&gameState._table, false);

        if (_mode == MODE_SELECT_SUIT) {
            drawSuitSelector();
        } else {
            drawDeck(&gameState._played, false);
        }
            */
}

static const char round_complete[] = "ROUND COMPLETE:";
static const char empty_hand[] = "EMPTY HAND";
static const char moumou[] = "MOUMOU";

void UI::drawRoundOver(bool is_moumou) {
    gb.display.setColor(BLACK);
    gb.display.fontSize = 1;

    gb.display.cursorX = 8;
    gb.display.cursorY = 17;
    gb.display.print(round_complete);

    gb.display.cursorY = 25;
    if (is_moumou) {
        gb.display.cursorX = 25;
        gb.display.print(moumou);
    } else {
        gb.display.cursorX = 17;
        gb.display.print(empty_hand);
    }
    /*
        // P1 deck
        drawDeck(&gameState._players[1]._hand, false);
        drawNumberRight(gameState._players[1]._hand_score, 83, 5);
        drawNumberRight(gameState._players[1]._score, 83, 17);
        if (gameState._players[1]._hand._count >
            gameState._players[1]._hand.maxVisibleCards) {
            gb.display.drawPixel(70, 14);
            gb.display.drawPixel(72, 14);
            gb.display.drawPixel(74, 14);
        }
        // P0 deck
        drawDeck(&gameState._players[0]._hand, false);
        drawNumberRight(gameState._players[0]._score, 83, 25);
        drawNumberRight(gameState._players[0]._hand_score, 83, 38);
        if (gameState._players[1]._hand._count >
            gameState._players[1]._hand.maxVisibleCards) {
            gb.display.drawPixel(70, 46);
            gb.display.drawPixel(72, 46);
            gb.display.drawPixel(74, 46);
        }
        if (gameState._players[0]._level != Human && _drawRoundOverTimer == 0)
            update_score(&gameState, this);
        else
            _drawRoundOverTimer--;
            */
}

void UI::drawDealing() {
    if (_cardAnimationCount < _dealingCount && gb.frameCount % 4 == 0) {
        _cardAnimationCount++;
        playSoundA();
    }
    bool doneDealing = _cardAnimationCount == _dealingCount;
    for (int i = 0; i < _cardAnimationCount; i++) {
        auto ca = &_cardAnimations[i];
        if (ca->x != ca->destX || ca->y != ca->destY) {
            doneDealing = false;
            drawCard(ca->x, ca->y, ca->card);
            ca->x = updatePosition(ca->x, ca->destX);
            ca->y = updatePosition(ca->y, ca->destY);
            if (ca->x == ca->destX && ca->y == ca->destY)
                ca->destination->addCard(ca->card);
        }
    }
    if (doneDealing) {
        _dealingCount = 0;
        _mode = MODE_PLAYER_MOVE;
    }
}

const char option0[] PROGMEM = "You vs L1";
const char option1[] PROGMEM = "You vs L2";
const char option2[] PROGMEM = "L2  vs L1";
const char statisticsOption[] PROGMEM = "Game statistics";
const char *const newGameMenu[] PROGMEM = {option0, option1, option2,
                                           statisticsOption};

const char quitOption[] PROGMEM = "Quit game";
const char resumeOption[] PROGMEM = "Resume game";
const char saveOption[] PROGMEM = "Save for later";
const char *const pauseMenu[] PROGMEM = {resumeOption, quitOption,
                                         statisticsOption, saveOption};

bool continueGame;

const byte title[] PROGMEM = {
    64,   36,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x80, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x06, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x78, 0x04, 0x20, 0x1e,
    0x00, 0x00, 0x00, 0x00, 0x48, 0x08, 0x10, 0x12, 0x00, 0x00, 0x00, 0x00,
    0x84, 0x10, 0x10, 0x21, 0x00, 0x00, 0x00, 0x00, 0x48, 0x10, 0x00, 0x12,
    0x00, 0x00, 0x00, 0x00, 0x78, 0x20, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x02, 0x00,
    0x00, 0x00, 0x00, 0xe0, 0x00, 0x40, 0x02, 0x00, 0x07, 0x00, 0x01, 0x30,
    0x00, 0x8c, 0x31, 0x00, 0x0c, 0x80, 0x01, 0x10, 0x7f, 0x9f, 0xf9, 0xfe,
    0x08, 0x80, 0x01, 0x91, 0x83, 0x91, 0x89, 0x81, 0x09, 0x80, 0x00, 0xe1,
    0x01, 0x10, 0x08, 0x80, 0x87, 0x00, 0x00, 0x02, 0x01, 0x10, 0x18, 0x80,
    0x40, 0x00, 0x00, 0x02, 0x01, 0x08, 0x10, 0x80, 0x40, 0x00, 0x00, 0x06,
    0x01, 0x04, 0x20, 0x80, 0x60, 0x00, 0x00, 0x3e, 0x01, 0x03, 0xc0, 0x80,
    0x7c, 0x00, 0x00, 0x42, 0x01, 0x01, 0x80, 0x80, 0xc2, 0x00, 0x00, 0x81,
    0x01, 0x00, 0x00, 0x80, 0x81, 0x00, 0x00, 0x81, 0x81, 0x00, 0x00, 0x81,
    0x01, 0x00, 0x00, 0x80, 0xc3, 0xff, 0xff, 0xc3, 0x01, 0x00, 0x00, 0x80,
    0xfc, 0x00, 0x00, 0x3f, 0x01, 0x00, 0x00, 0x47, 0x00, 0x00, 0x00, 0x00,
    0xe2, 0x00, 0x00, 0x78, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0xe0,
    0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x01, 0x80, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x80, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x02, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x20, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x08, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00};

UI::UI() {
    memset(_versusCount, 0, sizeof(_versusCount));
    memset(_versusWon, 0, sizeof(_versusWon));
}

void UI::showTitle() {
start:
    gb.display.persistence = true;
    gb.titleScreen(F(""), title);
    if (RANDOM_SEED)
        randomSeed(RANDOM_SEED);
    else
        gb.pickRandomSeed();
    gb.battery.show = false;
    // new_round(&gameState, this);
    readEeprom();

    // If there is a saved game in EEPROM, just skip right to the game.
    /*if (continueGame) {
        writeEeprom(false);
        mode = MODE_PLAYER_MOVE;
        return;
    }*/

    char menuOption;
askAgain:
    menuOption = gb.menu(newGameMenu, 3);
    switch (menuOption) {
    case -1:
        goto start;
    case VersusMode::VersusCount:
        displayStatistics();
        goto askAgain;
    default:
        _versusMode = menuOption;
        break;
    }
    switch (_versusMode) {
    case Human_L2:
        gameState._players[0]._level = Human;
        gameState._players[1]._level = Level_2;
        break;
    case L2_L1:
        gameState._players[0]._level = Level_2;
        gameState._players[1]._level = Level_1;
        break;
    default:
        gameState._players[0]._level = Human;
        gameState._players[1]._level = Level_1;
        break;
    }
    // initial_deal(&gameState, this);
}

void UI::pause() {
askAgain:
    switch (gb.menu(pauseMenu, _mode == MODE_PLAYER_MOVE ? 4 : 3)) {
    case 2:
        // statistics
        displayStatistics();
        goto askAgain;
    case 1:
        // Quit the game
        showTitle();
        break;
    case 3:
        // Save for later
        writeEeprom(true);
        showTitle();
        break;
    case 0:
    default:
        // Resume the game
        break;
    }
}

void UI::animateMove(Pile *src, byte srcIdx, Pile *dst, byte dstIdx) {
    Card card = src->removeCardAt(srcIdx);
    CardAnimation ca;
    ca.x = src->x + dst->getCardPosition(srcIdx) * 11;
    ca.y = src->y;
    ca.destX = dst->x + dst->getCardPosition(dstIdx) * 11;
    ca.destY = dst->y;
    ca.destination = dst;
    ca.card = card;
    _cardAnimations[_cardAnimationCount++] = ca;
}

const uint16_t patternA[] PROGMEM = {0x0045, 0x0118, 0x0000};
const uint16_t patternB[] PROGMEM = {0x0045, 0x0108, 0x0000};

void UI::drawDeck(Pile *deck, bool showCount) { /*
     for (int i = 0; i < deck->maxVisibleCards; ++i) {
         if (i + deck->scrollOffset >= deck->_count)
             break;
         if (deck->faceUp) {
             drawCard(
                 deck->x + i * 11, deck->y,
                 deck->getCard(deck->_count - (i + deck->scrollOffset) - 1));
         } else {
             drawCard(deck->x, deck->y, Card(Undefined, Spades, true));
         }
     }

     if (showCount && deck->_count && !deck->faceUp) {
         gb.display.setColor(WHITE);
         drawNumberRight(deck->_count, deck->x + 8, deck->y + 2);
     }*/
}

void UI::drawCard(byte x, byte y, Card card) {
    // Fill
    byte fill = WHITE;

    gb.display.setColor(fill);
    gb.display.fillRect(x + 1, y + 1, 8, 12);

    // Draw border
    gb.display.setColor(BLACK);
    gb.display.drawFastHLine(x + 1, y, 8);
    gb.display.drawFastHLine(x + 1, y + 13, 8);
    gb.display.drawFastVLine(x, y + 1, 12);
    gb.display.drawFastVLine(x + 9, y + 1, 12);

    drawValue(x + 5, y + 7, card);
}

void UI::drawLeftArrow(byte x, byte y) {
    gb.display.drawPixel(x, y + 2);
    gb.display.drawPixel(x + 1, y + 1);
    gb.display.drawPixel(x + 1, y + 3);
    gb.display.drawPixel(x + 2, y);
    gb.display.drawPixel(x + 2, y + 4);
}

void UI::drawRightArrow(byte x, byte y) {
    gb.display.drawPixel(x, y);
    gb.display.drawPixel(x, y + 4);
    gb.display.drawPixel(x + 1, y + 1);
    gb.display.drawPixel(x + 1, y + 3);
    gb.display.drawPixel(x + 2, y + 2);
}

void UI::drawValue(byte x, byte y, Card value) {
    switch (value) {
    case Jester:
        drawZero(x, y);
        break;
    case Princess:
        drawOne(x, y);
        break;
    case Spy:
        drawTwo(x, y);
        break;
    case Assassin:
        drawThree(x, y);
        break;
    case Minister:
        drawFour(x, y);
        break;
    case Magician:
        drawFive(x, y);
        break;
    case General:
        drawSix(x, y);
        break;
    case Prince:
        drawSeven(x, y);
        break;
    }
}

void UI::drawZero(byte x, byte y) {
    gb.display.drawPixel(x + 1, y);
    gb.display.drawFastVLine(x, y + 1, 4);
    gb.display.drawFastVLine(x + 2, y + 1, 4);
    gb.display.drawPixel(x + 1, y + 2);
}

void UI::drawOne(byte x, byte y) {
    gb.display.drawPixel(x + 1, y);
    gb.display.drawFastVLine(x, y + 1, 4);
    gb.display.drawFastVLine(x + 2, y + 1, 4);
    gb.display.drawPixel(x + 1, y + 2);
}

void UI::drawTwo(byte x, byte y) {
    drawSegmentA(x, y);
    drawSegmentB(x, y);
    drawSegmentG(x, y);
    drawSegmentE(x, y);
    drawSegmentD(x, y);
}

void UI::drawThree(byte x, byte y) {
    drawSegmentA(x, y);
    drawSegmentB(x, y);
    drawSegmentG(x, y);
    drawSegmentC(x, y);
    drawSegmentD(x, y);
}

void UI::drawFour(byte x, byte y) {
    drawSegmentF(x, y);
    drawSegmentG(x, y);
    drawSegmentB(x, y);
    drawSegmentC(x, y);
}

void UI::drawFive(byte x, byte y) {
    drawSegmentA(x, y);
    drawSegmentF(x, y);
    drawSegmentG(x, y);
    drawSegmentC(x, y);
    drawSegmentD(x, y);
}

void UI::drawSix(byte x, byte y) {
    drawFive(x, y);
    drawSegmentE(x, y);
}

void UI::drawSeven(byte x, byte y) {
    drawSegmentA(x, y);
    drawSegmentB(x, y);
    drawSegmentC(x, y);
}

void UI::drawCursor() {
    bool flipped;
    byte x, y;
    getCursorDestination(x, y, flipped);

    _cursorX = updatePosition(_cursorX, x);
    _cursorY = updatePosition(_cursorY, y);

    drawCursor(_cursorX, _cursorY, flipped);
}

void UI::getCursorDestination(byte &x, byte &y, bool &flipped) {
    Pile *pile = getActiveLocationPile();
    x = pile->x - 2;
    y = pile->y + 4;
    /*    switch (_activeLocation) {
        case stock:
            x = pile->x - 2;
            y = pile->y + 4;
            flipped = true;
            break;
        case table:
            x = pile->x + 4 * 11;
            y = pile->y + 4;
            flipped = false;
            break;
        case played:
            x = pile->x - 2;
            y = pile->y + 4;
            flipped = true;
            break;
        case hand:
            if (_cardIndex == pile->maxVisibleCards - 1) {
                x = pile->x - 7 + _cardIndex * 11;
                flipped = true;
            } else {
                x = pile->x + 10 + _cardIndex * 11;
                flipped = false;
            }
            y = pile->y + 4;
            break;
        }*/
}

void UI::startDraw() {
    /*
        _cardAnimationCount = 0;
        for (int i = 0; i < 1; i++)
            animateMove(&gameState._deck, 0,
                        &gameState._players[gameState._cur_player]._hand,
                        gameState._players[gameState._cur_player]._hand._count);
        _dealingCount = _cardAnimationCount;
        _cardAnimationCount = 0;

        _mode = MODE_ANIMATE;
        playSoundA();*/
}

void UI::startPlayCard(uint8_t idx) {
    /*
    Pile &p = gameState._players[gameState._cur_player]._hand;

    _cardAnimationCount = 0;
    animateMove(&p, idx, &gameState._played, gameState._played._count);
    _dealingCount = _cardAnimationCount;
    _cardAnimationCount = 0;

    if (p._count - p.scrollOffset >= p.maxVisibleCards) {
    } else if (p.scrollOffset > 0) {
        p.scrollOffset--;
    } else if (_cardIndex == p._count && _cardIndex > 0) {
        _cardIndex--;
    }
    _mode = MODE_ANIMATE;
    playSoundA();
    */
}

void UI::drawWonGame() {
    /*
    // Bounce the cards from the hands, one at a time.
    if (!gb.display.persistence) {
        gb.display.persistence = true;
        drawBoard();
        initializeCardBounce();
    }

    // Apply gravity
    bounce.yVelocity += 0x0080;
    bounce.x += bounce.xVelocity;
    bounce.y += bounce.yVelocity;
    // If the card is at the bottom of the screen, reverse the y
    // velocity and scale by 80%.
    if (bounce.y + (14 << 8) > LCDHEIGHT << 8) {
        bounce.y = (LCDHEIGHT - 14) << 8;
        bounce.yVelocity = bounce.yVelocity * -4 / 5;
        playSoundB();
    }
    drawCard(bounce.x >> 8, bounce.y >> 8, bounce.card);
    // Check to see if the current card is off the screen.
    if (bounce.x + (10 << 8) < 0 || bounce.x > LCDWIDTH << 8) {
        if (!initializeCardBounce())
            showTitle();
    }
            */
}

void UI::displayStatistics() {
    while (true) {
        if (gb.update()) {
            gb.display.cursorX = 0;
            gb.display.cursorY = 0;
            for (uint8_t i = 0; i < VersusMode::VersusCount; i++) {
                gb.display.print((const __FlashStringHelper *)pgm_read_word(
                    newGameMenu + i));
                gb.display.print(F(": played "));
                gb.display.print(_versusCount[i]);
                gb.display.print(F("\n              won "));
                gb.display.println(_versusWon[i]);
            }
            if (gb.buttons.pressed(BTN_A) || gb.buttons.pressed(BTN_B) ||
                gb.buttons.pressed(BTN_C))
                return;
        }
    }
}

void UI::debug(uint8_t n0, uint8_t n1) {
    drawNumberRight(n0, 83, 33);
    drawNumberRight(n1, 83, 41);
}

bool initializeCardBounce() {
    /*
    // Return false if all the cards are done.
    if (hands[bounceIndex]._count == 0)
        return false;
    // Pick the next card to animate, with a random initial velocity.
    bounce.card = hands[bounceIndex].removeTopCard();
    bounce.x = hands[bounceIndex].x << 8;
    bounce.y = hands[bounceIndex].y << 8;
    bounce.xVelocity = (random(2) ? 1 : -1) * random(0x0100, 0x0200);
    bounce.yVelocity = -1 * random(0x0200);
    bounceIndex = (bounceIndex + 1) % 4;
    */
    return true;
}

Pile *UI::getActiveLocationPile() {
    /* switch (_activeLocation) {
    case stock:
        return &gameState._deck;
    case table:
        return &gameState._table;
    case hand:
        return &gameState._players[0]._hand;
    case played:
        return &gameState._played;
    }*/
    return nullptr;
}

byte UI::updatePosition(byte current, byte destination) {
    if (current == destination)
        return current;

    byte delta = (destination - current) / 3;
    if (delta == 0 && ((gb.frameCount % 3) == 0))
        delta = destination > current ? 1 : -1;
    return current + delta;
}

void UI::drawCursor(byte x, byte y, bool flipped) {
    if (flipped) {
        for (int i = 0; i < 4; i++) {
            gb.display.setColor(BLACK);
            gb.display.drawPixel(x + 3 + i, y + i);
            gb.display.drawPixel(x + 3 + i, y + (6 - i));
            gb.display.setColor(WHITE);
            gb.display.drawFastHLine(x + 3, y + i, i);
            gb.display.drawFastHLine(x + 3, y + (6 - i), i);
        }
        gb.display.setColor(BLACK);
        gb.display.drawFastVLine(x + 2, y, 7);
        gb.display.drawFastHLine(x, y + 2, 2);
        gb.display.drawFastHLine(x, y + 4, 2);
        gb.display.drawPixel(x, y + 3);
        gb.display.setColor(WHITE);
        gb.display.drawFastHLine(x + 1, y + 3, 2);
    } else {
        for (int i = 0; i < 4; i++) {
            gb.display.setColor(BLACK);
            gb.display.drawPixel(x + 3 - i, y + i);
            gb.display.drawPixel(x + 3 - i, y + (6 - i));
            gb.display.setColor(WHITE);
            gb.display.drawFastHLine(x + 4 - i, y + i, i);
            gb.display.drawFastHLine(x + 4 - i, y + (6 - i), i);
        }
        gb.display.setColor(BLACK);
        gb.display.drawFastVLine(x + 4, y, 7);
        gb.display.drawFastHLine(x + 5, y + 2, 2);
        gb.display.drawFastHLine(x + 5, y + 4, 2);
        gb.display.drawPixel(x + 6, y + 3);
        gb.display.setColor(WHITE);
        gb.display.drawFastHLine(x + 4, y + 3, 2);
    }
}

void UI::drawSegmentA(byte x, byte y) {
    gb.display.drawFastHLine(x, y, 3);
}

void UI::drawSegmentB(byte x, byte y) {
    gb.display.drawFastVLine(x + 2, y, 3);
}

void UI::drawSegmentC(byte x, byte y) {
    gb.display.drawFastVLine(x + 2, y + 2, 3);
}

void UI::drawSegmentD(byte x, byte y) {
    gb.display.drawFastHLine(x, y + 4, 3);
}

void UI::drawSegmentE(byte x, byte y) {
    gb.display.drawFastVLine(x, y + 2, 3);
}

void UI::drawSegmentF(byte x, byte y) {
    gb.display.drawFastVLine(x, y, 3);
}

void UI::drawSegmentG(byte x, byte y) {
    gb.display.drawFastHLine(x, y + 2, 3);
}

void UI::playSoundA() {
    gb.sound.playPattern(patternA, 0);
}

void UI::playSoundB() {
    gb.sound.playPattern(patternB, 0);
}

void UI::drawNumberRight(uint16_t n, byte x, byte y) {
    byte cur_x = x - 3;
    if (n == 0) {
        gb.display.drawChar(cur_x, y, '0', 1);
        return;
    }
    while (n > 0) {
        gb.display.drawChar(cur_x, y, (n % 10) + '0', 1);
        n = n / 10;
        cur_x -= 4;
    }
}

void UI::readEeprom() {
    /*
    if (EEPROM.read(0) != EEPROM_MAGIC_NUMBER)
        return;
    int address = 1;
    for (uint8_t i = 0; i < VersusMode::VersusCount; i++) {
        EEPROM.get(address, _versusCount[i]);
        address += sizeof(_versusCount[i]);
        EEPROM.get(address, _versusWon[i]);
        address += sizeof(_versusWon[i]);
    }
        */
}

void UI::writeEeprom(bool saveGame) {
    /*
    EEPROM.update(0, EEPROM_MAGIC_NUMBER);
    int address = 1;
    for (uint8_t i = 0; i < VersusMode::VersusCount; i++) {
        EEPROM.put(address, _versusCount[i]);
        address += sizeof(_versusCount[i]);
        EEPROM.put(address, _versusWon[i]);
        address += sizeof(_versusWon[i]);
    }
        */
}
