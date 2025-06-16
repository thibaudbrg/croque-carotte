import 'package:flutter_test/flutter_test.dart';
import 'package:croque_carotte/models/deck.dart';
import 'package:croque_carotte/models/game_card.dart';

void main() {
  test('deck reshuffles when empty and discard pile exists', () {
    var reshuffleCalled = false;
    final deck = Deck(onReshuffleNeeded: () {
      reshuffleCalled = true;
    });

    // Draw all cards and immediately discard them
    while (deck.cardsRemaining > 0) {
      final card = deck.draw();
      expect(card, isNotNull);
      deck.discard(card!);
    }

    expect(deck.cardsRemaining, equals(0));
    expect(deck.discardedCardsCount, greaterThan(0));

    // Drawing once more should trigger reshuffle
    final reshuffledCard = deck.draw();
    expect(reshuffledCard, isNotNull);
    expect(reshuffleCalled, isTrue);
    expect(deck.discardedCardsCount, equals(0));
    expect(deck.cardsRemaining, greaterThan(0));
  });
}
