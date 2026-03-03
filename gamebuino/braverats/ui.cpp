#include "ui.h"
#include "ai.h"
#include "config.h"
#include "sprite.h"
#include <EEPROM.h>

#define EEPROM_MAGIC_NUMBER 171

// uncomment this line to show debug prints instead of scores
// #define DEBUG_PRINTS

extern Gamebuino gb;
extern GameState gameState;

const char LETTERS[] PROGMEM = "JLSACMGP";

// gb.display.print(F("\x1\x2\x3\x4\x5\x6\x7\x8\x9\xa\xb\xc\xd\xe\xf"
//                    "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b"
//                    "\x1c\x1d\x1e\x1f\x20"));

void UI::drawBoard() {
    byte x;
    byte y;
    gb.display.setColor(BLACK);

    Player *p = &gameState._players[0];
#ifdef DEBUG_PRINTS
    // Debug prints
    drawNumberRight(p->_hand._count, 72, 2);
    // drawNumberRight(gameState._valid_moves._flags, 72, 10);

    // drawNumberRight(gameState._valid_moves._count, 83, 17);
    //  drawNumberRight(gameState._moumou_counter, 83, 17);
    drawNumberRight(gameState._pending_cmd, 83, 17);
    // drawNumberRight(gameState._input_cmd, 83, 25);

    // debug(CardValue(gameState._last_card), CardSuit(gameState._last_card));
    //  drawNumberRight(_mode, 83, 41);
#else
    // Score
    drawValue(70, 13, gameState._players[1]._score, false);
    drawValue(70, 23, gameState._players[0]._score, false);

    // Unrealized points
    if (gameState._players[1]._unrealized_points >= 0) {
        drawValue(81, 13, gameState._players[1]._unrealized_points, false);
        drawPlus(77, 14);
    }
    if (gameState._players[0]._unrealized_points >= 0) {
        drawValue(81, 23, gameState._players[0]._unrealized_points, false);
        drawPlus(77, 24);
    }

    gb.display.setColor(BLACK);

    // Effects
    if (gameState._players[1]._effect == Spy)
        gb.display.drawBitmap(75, 2, spr_sp);
    else if (gameState._players[1]._effect == General)
        gb.display.drawBitmap(75, 2, spr_ge);

    if (gameState._players[0]._effect == Spy)
        gb.display.drawBitmap(75, 33, spr_sp);
    else if (gameState._players[0]._effect == General)
        gb.display.drawBitmap(75, 30, spr_ge);

#endif
    // Played cards
    UI::getCoords(played1, 0, x, y);
    drawCard(x, y, _played_cards[1],
             _played_face_up[1] ? DM_NORMAL : DM_FACE_DOWN);
    UI::getCoords(played0, 0, x, y);
    drawCard(x, y, _played_cards[0],
             _played_face_up[0] ? DM_NORMAL : DM_FACE_DOWN);

    // Human hand
    bool cursorEnabled = p->_level == Human && _mode != MODE_PAUSE;
    for (uint8_t i = 0; i < p->_hand._count; ++i) {
        UI::getCoords(hand0, p->_hand._items[i], x, y);
        drawCard(x, y, p->_hand._items[i],
                 (cursorEnabled && i == _cardIndex) ? DM_SELECTED : DM_NORMAL);
    }

    // Bot hand
    p = &gameState._players[1];
    for (uint8_t i = 0; i < p->_hand._count; ++i) {
        UI::getCoords(hand1, p->_hand._items[i], x, y);
        drawValue(x, y, p->_hand._items[i], false);
    }

    gb.display.cursorX = 64;
    gb.display.cursorY = 42;
    gb.display.print(F("\26help"));
}

void UI::drawGameOver() {
    gb.display.setColor(BLACK);
    gb.display.fontSize = 1;

    gb.display.cursorY = 6;
    switch (_winner) {
    case RR_Player0_GameWon:
        gb.display.cursorX = 17;
        gb.display.print(F("PLAYER 1 WINS!"));
        break;
    case RR_Player1_GameWon:
        gb.display.cursorX = 17;
        gb.display.print(F("PLAYER 2 WINS!"));
        break;
    case RR_Hold:
        gb.display.cursorX = 35;
        gb.display.print(F("DRAW"));
        break;
    }

    // Scores
    drawNumberRight(gameState._players[0]._score, 39, 13);
    gb.display.cursorX = 46;
    gb.display.cursorY = 13;
    gb.display.print(gameState._players[1]._score, 1);
    gb.display.drawPixel(42, 14);
    gb.display.drawPixel(42, 16);

    // Rounds
    uint8_t w = gameState._round_count * 9 - 4;
    uint8_t x = (LCDWIDTH - w) / 2;

    for (uint8_t i = 0; i < gameState._round_count; ++i) {
        Round *r = &gameState._rounds[i];
        gb.display.drawChar(x, 24, pgm_read_byte(&LETTERS[r->_cards[1]]), 1);
        gb.display.drawChar(x, 32, pgm_read_byte(&LETTERS[r->_cards[0]]), 1);
        uint8_t y =
            (r->_result == RR_Player0 || r->_result == RR_Player0_GameWon) ? 32
                                                                           : 24;
        if (r->_result == RR_Player0_GameWon ||
            r->_result == RR_Player1_GameWon) {
            gb.display.drawFastVLine(x + 5, y, 3);
            gb.display.drawPixel(x + 5, y + 4);
        } else if (r->_points == 2) {
            gb.display.drawFastVLine(x + 5, y, 5);
            gb.display.drawPixel(x + 4, y + 1);
            gb.display.drawPixel(x + 6, y + 1);
            gb.display.drawPixel(x + 4, y + 3);
            gb.display.drawPixel(x + 6, y + 3);
        } else {
            drawPlus(x + 4, y + 1);
        }
        x += 9;
    }

    // Victories
    drawNumberRight(gameState._players[0]._victory_count, 39, 41);
    gb.display.cursorX = 46;
    gb.display.cursorY = 41;
    gb.display.print(gameState._players[1]._victory_count, 1);
    gb.display.drawPixel(42, 42);
    gb.display.drawPixel(42, 44);

    if (gameState._players[0]._level != Human && _drawRoundOverTimer == 0) {
        gameState._pending_cmd = CMD_NEW_GAME;
    } else
        _drawRoundOverTimer--;
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
            drawCard(ca->x, ca->y, ca->card, DM_NORMAL);
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

UI::UI() {
    memset(_versusCount, 0, sizeof(_versusCount));
    memset(_versusWon, 0, sizeof(_versusWon));
    _cardIndex = 0;
    _helpPage = 0;
    _played_cards[0] = _played_cards[1] = UnknownCard;
}

void UI::showTitle() {
start:
    gb.display.persistence = true;
    gb.titleScreen(F(""), title);
    gb.battery.show = false;

    char menuOption;
askAgain:
    menuOption = gb.menu(newGameMenu, 4);
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
    gameState._pending_cmd = CMD_NEW_GAME;
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

void UI::drawCard(byte x, byte y, Card card, DrawMode mode) {
    if (card != UnknownCard && mode == DM_FACE_DOWN) {
        gb.display.setColor(GRAY);
        gb.display.fillRect(x + 1, y + 1, 9, 15);
        gb.display.setColor(BLACK);
        gb.display.drawFastHLine(x + 1, y, 9);
        gb.display.drawFastHLine(x + 1, y + 16, 9);
        gb.display.drawFastVLine(x, y + 1, 15);
        gb.display.drawFastVLine(x + 10, y + 1, 15);
        return;
    }
    gb.display.setColor(WHITE);
    gb.display.fillRect(x, y, 11, 17);
    if (card == UnknownCard)
        return;

    // Draw border
    gb.display.setColor(BLACK);
    switch (mode) {
    case DM_SELECTED:
        gb.display.drawFastHLine(x + 9, y, 2);
        gb.display.drawFastVLine(x + 10, y + 1, 1);
        gb.display.drawFastHLine(x + 9, y + 16, 2);
        gb.display.drawFastVLine(x + 10, y + 15, 1);
        gb.display.drawFastHLine(x, y + 16, 2);
        gb.display.drawFastVLine(x, y + 15, 1);
        /*
                gb.display.drawFastHLine(x + 8, y, 3);
                gb.display.drawFastVLine(x + 10, y + 1, 2);
                gb.display.drawFastHLine(x + 8, y + 16, 3);
                gb.display.drawFastVLine(x + 10, y + 14, 2);
                gb.display.drawFastHLine(x, y + 16, 3);
                gb.display.drawFastVLine(x, y + 14, 2);
        */
        break;
    case DM_FACE_DOWN:
    case DM_NORMAL:
        gb.display.drawFastHLine(x + 5, y, 5);
        gb.display.drawFastHLine(x + 1, y + 16, 9);
        gb.display.drawFastVLine(x, y + 6, 10);
        gb.display.drawFastVLine(x + 10, y + 1, 15);
        break;
    }
    drawValue(x, y, card, true);
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

void UI::drawValue(byte x, byte y, Card value, bool with_bitmap) {
    switch (value) {
    case Jester:
        drawZero(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 5, spr_je);
        break;
    case Lady:
        drawOne(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 6, spr_la);
        break;
    case Spy:
        drawTwo(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 7, spr_sp);
        break;
    case Assassin:
        drawThree(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 7, spr_as);
        break;
    case Chancellor:
        drawFour(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 6, spr_ch);
        break;
    case Magician:
        drawFive(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 3, spr_ma);
        break;
    case General:
        drawSix(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 6, spr_ge);
        break;
    case Prince:
        drawSeven(x, y);
        if (with_bitmap)
            gb.display.drawBitmap(x + 2, y + 4, spr_pr);
        break;
    }
}

void UI::drawZero(byte x, byte y) {
    gb.display.drawRect(x, y, 3, 5);
}

void UI::drawOne(byte x, byte y) {
    gb.display.drawPixel(x, y + 1);
    gb.display.drawFastVLine(x + 1, y, 5);
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

void UI::drawPlus(byte x, byte y) {
    gb.display.drawPixel(x + 1, y);
    gb.display.drawFastHLine(x, y + 1, 3);
    gb.display.drawPixel(x + 1, y + 2);
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

void UI::getCoords(Location location, byte idx, byte &x, byte &y) {
    switch (location) {
    case hand0:
        x = 13 * (idx % 4);
        y = 13 + 18 * (idx / 4);
        break;
    case hand1:
        x = 12 + idx * 5;
        y = 0;
        break;
    case played0:
        x = 55;
        y = 22;
        break;
    case played1:
        x = 55;
        y = 2;
        break;
    }
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

void UI::drawHelpPage() {
    drawCard(1, 0, _helpPage, DM_NORMAL);

    gb.display.textWrap = true;
    gb.display.cursorY = 0;
    switch (_helpPage) {
    case Jester:
        gb.display.cursorX = 14 + (84 - 16 - 6 * 4) / 2;
        gb.display.print(F("Jester"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(F("This round is\nnullified and put on\nhold. Wins "
                           "over all\npowers except the\nMagician's"));
        break;
    case Lady:
        gb.display.cursorX = 14 + (84 - 16 - 4 * 4) / 2;
        gb.display.print(F("Lady"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(
            F("If the opponent\nplayed the Prince,\nyou win the game\n"
              "immediately, despite of number of points"));
        break;
    case Spy:
        gb.display.cursorX = 14 + (84 - 16 - 3 * 4) / 2;
        gb.display.print(F("Spy"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(
            F("Next round, your\nopponent reveals his\ncard "
              "before you\nchoose yours. 2 Spiesnullify each other"));
        break;
    case Assassin:
        gb.display.cursorX = 14 + (84 - 16 - 8 * 4) / 2;
        gb.display.print(F("Assassin"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(F("The lowest\n    strength wins"));
        break;
    case Chancellor:
        gb.display.cursorX = 14 + (84 - 16 - 10 * 4) / 2;
        gb.display.print(F("Chancellor"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(F("If you win with\nthis card, it counts\nas 2 "
                           "points, even if the round is on hold"));
        break;
    case Magician:
        gb.display.cursorX = 14 + (84 - 16 - 8 * 4) / 2;
        gb.display.print(F("Magician"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(F("Nullifies the\nspecial power of the\nopponent's "
                           "card: the highest strength winsthe round"));
        break;
    case General:
        gb.display.cursorX = 14 + (84 - 16 - 7 * 4) / 2;
        gb.display.print(F("General"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(F("Your card next\nturn gets +2 strength"));
        break;
    case Prince:
        gb.display.cursorX = 14 + (84 - 16 - 6 * 4) / 2;
        gb.display.print(F("Prince"));
        gb.display.cursorX = 16;
        gb.display.cursorY = 14;
        gb.display.print(F("You win the round(even against the\nAssassin), yet "
                           "Jesterstill puts the round on hold"));
        break;
    }
    if (_helpPage > 0)
        gb.display.drawChar(20, 0, '\x11', 1);
    if (_helpPage < Prince)
        gb.display.drawChar(76, 0, '\x10', 1);
}
