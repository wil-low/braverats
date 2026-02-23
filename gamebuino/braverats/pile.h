
#ifndef PILE_H
#define PILE_H

#include <Gamebuino.h>

enum Card {
    Jester = 0,
    Lady,
    Spy,
    Assassin,
    Chancellor,
    Magician,
    General,
    Prince,
    CardCount,
    UnknownCard = CardCount
};

class Pile {
  public:
    Pile();
    ~Pile();
    void addCard(Card card);
    void addPile(Pile *pile);
    Card getCard(int indexFromTop) const;
    Card removeCardAt(byte idx);
    void removeCards(int count, Pile *destination);
    void empty();
    void shuffle();
    void newDeck();
    byte getMaxCards() const;
    byte getCardPosition(int indexFromTop) const;

    byte x, y;
    byte scrollOffset;
    bool faceUp;
    byte maxVisibleCards;
    byte _count;
    bool scrollToLast;

    static const byte _maxCards = 8;
    Card _items[_maxCards];
};
#endif
