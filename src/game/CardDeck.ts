// Utility class representing the deck of cards used in the game.
import { CardType } from './types';

/** Simple deck with 4 copies of each card type. */
export class CardDeck {
  /** Current list of cards remaining in the deck. */
  private cards: CardType[] = [];

  constructor() {
    this.reset();
  }

  /** Reshuffle the deck to its initial state. */
  reset() {
    this.cards = [];
    // Add four copies of each card to the deck.
    for (let i = 0; i < 4; i++) {
      this.cards.push(CardType.Move1, CardType.Move2, CardType.Move3, CardType.Carrot);
    }
    this.shuffle();
  }

  /** Draw one card. Automatically reshuffles if empty. */
  draw(): CardType {
    if (this.cards.length === 0) {
      this.reset();
    }
    return this.cards.pop() as CardType;
  }

  /** Fisher-Yates shuffle. */
  private shuffle() {
    for (let i = this.cards.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [this.cards[i], this.cards[j]] = [this.cards[j], this.cards[i]];
    }
  }
}
