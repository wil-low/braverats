#include "pile.h"

Pile::Pile() {
    _count = 0;
    maxVisibleCards = 1;
    scrollOffset = 0;
    faceUp = true;
    scrollToLast = false;
}

Pile::~Pile() {
}

void Pile::addCard(Card card) {
    if (_count < _maxCards) {
        _items[_count++] = card;
        if (scrollToLast)
            scrollOffset = max(0, _count - maxVisibleCards);
    }
}

void Pile::addPile(Pile *pile) {
    for (int i = pile->_count - 1; i >= 0; i--) {
        addCard(pile->getCard(i));
    }
}

Card Pile::getCard(int indexFromTop) const {
    if (indexFromTop < _count) {
        return _items[_count - indexFromTop - 1];
    }
    return Card();
}

Card Pile::removeCardAt(byte idx) {
    if (idx < _count) {
        Card card = _items[idx];
        --_count;
        for (byte i = idx; i < _count; i++)
            _items[i] = _items[i + 1];
        if (scrollToLast)
            scrollOffset = max(0, _count - maxVisibleCards);
        return card;
    }
    return Card();
}

void Pile::removeCards(int count, Pile *destination) {
    count = min(count, _count);
    _count -= count;
    for (int i = 0; i < count; i++)
        destination->addCard(_items[_count + i]);
    if (scrollToLast)
        scrollOffset = max(0, _count - maxVisibleCards);
}

void Pile::empty() {
    _count = 0;
    scrollOffset = 0;
}

void Pile::shuffle() {
    for (int i = 0; i < _count; i++) {
        int randomIndex = random(_count - i);
        Card tmp = _items[randomIndex];
        _items[randomIndex] = _items[_count - i - 1];
        _items[_count - i - 1] = tmp;
    }
}

void Pile::newDeck() {
    empty();
    for (uint8_t value = Jester; value <= Prince; value++)
        addCard(static_cast<Card>(value));
}

byte Pile::getMaxCards() const {
    return _maxCards;
}

byte Pile::getCardPosition(int indexFromTop) const {
    if (indexFromTop < scrollOffset)
        return 0;
    if (indexFromTop >= scrollOffset + maxVisibleCards)
        return faceUp ? maxVisibleCards - 1 : 0;
    return indexFromTop - scrollOffset;
}
