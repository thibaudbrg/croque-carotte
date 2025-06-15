import 'dart:math';
import 'package:croque_carotte/models/game_card.dart';

class Deck {
  final List<GameCard> _cards;
  final List<GameCard> _discardedCards = []; // Track all discarded cards
  
  // Callback for when deck needs to be reshuffled
  Function()? onReshuffleNeeded;

  Deck({this.onReshuffleNeeded}) : _cards = [] {
    _initializeDeck();
    shuffle();
  }

  // Named constructor to create a Deck from an existing list of cards (e.g., for copying)
  Deck._internal(this._cards, List<GameCard> discardedCards, {this.onReshuffleNeeded}) {
    _discardedCards.addAll(discardedCards);
  }

  // Factory constructor or static method to create a copy
  // This is used to update the state in Riverpod correctly when a card is drawn
  factory Deck.copy(Deck other) {
    return Deck._internal(
      List<GameCard>.from(other._cards), 
      List<GameCard>.from(other._discardedCards),
      onReshuffleNeeded: other.onReshuffleNeeded
    );
  }

  void _initializeDeck() {
    // Movement cards with new distribution:
    // 7 Move +1 cards
    for (int i = 0; i < 7; i++) {
      _cards.add(GameCard(title: 'Move 1', description: 'Move your pawn 1 space forward.', type: GameCardType.move1));
    }
    // 7 Move +2 cards  
    for (int i = 0; i < 7; i++) {
      _cards.add(GameCard(title: 'Move 2', description: 'Move your pawn 2 spaces forward.', type: GameCardType.move2));
    }
    // 6 Move +3 cards
    for (int i = 0; i < 6; i++) {
      _cards.add(GameCard(title: 'Move 3', description: 'Move your pawn 3 spaces forward.', type: GameCardType.move3));
    }
    // 10 Carrot cards
    for (int i = 0; i < 10; i++) {
      _cards.add(GameCard(title: 'Turn Carrot', description: 'Turn the carrot to open a random trapdoor!', type: GameCardType.turnCarrot));
    }
    
    // Total: 7 + 7 + 6 + 10 = 30 cards
    print('Deck initialized with ${_cards.length} cards: 7 Move+1, 7 Move+2, 6 Move+3, 10 Carrot');
  }

  void shuffle() {
    _cards.shuffle(Random());
  }

  GameCard? draw() {
    if (_cards.isEmpty) {
      // Try to reshuffle from discarded cards
      if (_discardedCards.isNotEmpty) {
        print('Deck empty! Reshuffling ${_discardedCards.length} discarded cards...');
        _cards.addAll(_discardedCards);
        _discardedCards.clear();
        shuffle();
        
        // Notify UI about reshuffle for animation
        onReshuffleNeeded?.call();
        
        print('Deck reshuffled! ${_cards.length} cards now available.');
      } else {
        print('No cards left to draw - both deck and discard pile are empty!');
        return null; // Truly no cards left
      }
    }
    
    final drawnCard = _cards.removeLast();
    print('Drew card: ${drawnCard.title} (${_cards.length} cards remaining)');
    return drawnCard;
  }
  
  // Method to add a card to the discard pile
  void discard(GameCard card) {
    _discardedCards.add(card);
    print('Card discarded: ${card.title} (${_discardedCards.length} cards in discard pile)');
  }
  
  // Get number of discarded cards
  int get discardedCardsCount => _discardedCards.length;

  int get cardsRemaining => _cards.length;
  
  // Debug method to get deck composition
  Map<GameCardType, int> getDeckComposition() {
    Map<GameCardType, int> composition = {};
    for (var card in _cards) {
      composition[card.type] = (composition[card.type] ?? 0) + 1;
    }
    return composition;
  }
  
  // Debug method to print deck status
  void printDeckStatus() {
    var composition = getDeckComposition();
    print('Deck Status: ${cardsRemaining} cards remaining');
    print('  Move +1: ${composition[GameCardType.move1] ?? 0}');
    print('  Move +2: ${composition[GameCardType.move2] ?? 0}');
    print('  Move +3: ${composition[GameCardType.move3] ?? 0}');
    print('  Carrot: ${composition[GameCardType.turnCarrot] ?? 0}');
  }
}