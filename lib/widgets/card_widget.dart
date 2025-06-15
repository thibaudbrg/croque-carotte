import 'package:flutter/material.dart';
import 'package:croque_carotte/models/game_card.dart';

// Placeholder for displaying a single card
class CardWidget extends StatelessWidget {
  final GameCard card;

  const CardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(card.description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('Type: ${card.type.name}', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
