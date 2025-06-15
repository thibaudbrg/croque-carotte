import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:croque_carotte/models/deck.dart';
import 'package:croque_carotte/models/game_card.dart';
import 'package:croque_carotte/widgets/pawn_widget.dart';

// Provider for the deck
final deckProvider = StateProvider<Deck>((ref) => Deck());

// Provider for the last drawn card (can be null)
final drawnCardProvider = StateProvider<GameCard?>((ref) => null);

class GameBoardScreen extends ConsumerWidget {
  const GameBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckProvider);
    final drawnCard = ref.watch(drawnCardProvider);

    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Croque Carotte Game'),
        backgroundColor: Colors.orange[700],
      ),
      body: Stack(
        children: <Widget>[
          // Background Image
          Image.asset(
            'assets/images/board.png', // Ensure you have this image in assets/images/
            fit: BoxFit.cover, // Cover the whole screen, might crop
            // fit: BoxFit.contain, // Ensure whole image is visible, might leave empty space
            // You might need to adjust the fit based on your board aspect ratio and desired look
            width: double.infinity,
            height: double.infinity,
          ),
          // Pawns (Example hardcoded positions)
          // These positions are percentages of screen width/height to be somewhat responsive
          // You'll need to adjust these based on your board image layout
          Positioned(
            top: screenSize.height * 0.2,
            left: screenSize.width * 0.3,
            child: const PawnWidget(color: Colors.blue, size: 30),
          ),
          Positioned(
            top: screenSize.height * 0.5,
            left: screenSize.width * 0.6,
            child: const PawnWidget(color: Colors.red, size: 30),
          ),

          // Card Deck Area & Draw Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withOpacity(0.5), // Semi-transparent background for readability
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (drawnCard != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        'Drawn: ${drawnCard.title} (${drawnCard.type.name})',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  Text(
                    'Cards in deck: ${deck.cardsRemaining}',
                     style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final currentDeck = ref.read(deckProvider.notifier).state;
                      final card = currentDeck.draw();
                      if (card != null) {
                        ref.read(drawnCardProvider.notifier).state = card;
                        print('Card Drawn: ${card.title} - ${card.description}');
                      } else {
                        ref.read(drawnCardProvider.notifier).state = null;
                        print('No cards left in deck!');
                      }
                      // Update the state of the deckProvider to reflect the change in cardsRemaining
                      // This creates a *new* Deck instance with the drawn card removed from its internal list.
                      // For more complex deck state (like reshuffling an empty deck), 
                      // Deck would ideally be a Notifier itself.
                      ref.read(deckProvider.notifier).state = Deck.copy(currentDeck);
                    },
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.amber[700],
                       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                    ),
                    child: const Text('Draw Card', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
