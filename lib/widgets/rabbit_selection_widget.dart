import 'package:flutter/material.dart';
import 'package:croque_carotte/models/rabbit.dart';
import 'package:croque_carotte/models/game_card.dart';
import 'package:croque_carotte/models/player.dart';
import 'package:croque_carotte/core/localization.dart';

class RabbitSelectionWidget extends StatelessWidget {
  final Player humanPlayer;
  final GameCard? currentDrawnCard;
  final Function(Rabbit rabbit) onRabbitSelected;
  final Function(Rabbit rabbit, int steps) canRabbitMove;
  final Function()? onSkipTurn;

  const RabbitSelectionWidget({
    super.key,
    required this.humanPlayer,
    required this.currentDrawnCard,
    required this.onRabbitSelected,
    required this.canRabbitMove,
    this.onSkipTurn,
  });

  String _getRabbitColorName(int id, AppLocalizations localizations) {
    switch (id) {
      case 0: return localizations.grey;
      case 1: return localizations.blue;
      case 2: return localizations.green;
      case 3: return localizations.red;
      case 4: return localizations.yellow;
      default: return localizations.unknown;
    }
  }

  int _getStepsFromCard(GameCard? card) {
    if (card == null) return 0;
    switch (card.type) {
      case GameCardType.move1:
        return 1;
      case GameCardType.move2:
        return 2;
      case GameCardType.move3:
        return 3;
      case GameCardType.turnCarrot:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bool canSelect = currentDrawnCard != null && currentDrawnCard!.type != GameCardType.turnCarrot;
    final int steps = _getStepsFromCard(currentDrawnCard);
    
    final List<Rabbit> availableRabbits = humanPlayer.rabbits.where((r) => r.isAlive).toList();
    final List<Rabbit> movableRabbits = canSelect 
        ? availableRabbits.where((r) => canRabbitMove(r, steps)).toList()
        : [];
    final bool noValidMoves = canSelect && availableRabbits.isNotEmpty && movableRabbits.isEmpty;

    return Container(
      width: 200, // Fixed width for the rabbit selection area
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.selectRabbit,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (canSelect && currentDrawnCard != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${localizations.card}: ${currentDrawnCard!.title}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          // Special message for carrot cards
          if (currentDrawnCard?.type == GameCardType.turnCarrot)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Carrot Card',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The carrot will rotate!\nNew holes may appear on the board.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          ...humanPlayer.rabbits.map((rabbit) {
            final bool isAlive = rabbit.isAlive;
            final bool canMove = canSelect && isAlive && canRabbitMove(rabbit, steps);
            final bool isInteractive = canSelect && canMove;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isInteractive ? () => onRabbitSelected(rabbit) : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isInteractive 
                          ? Colors.blue.shade50
                          : (canSelect ? Colors.grey.shade100 : Colors.grey.shade50),
                      border: Border.all(
                        color: isInteractive 
                            ? Colors.blue
                            : (canSelect ? Colors.grey : Colors.grey.shade300),
                        width: isInteractive ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        // Rabbit icon (using color circles)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: _buildRabbitIcon(rabbit.id, isAlive, isInteractive),
                        ),
                        const SizedBox(width: 8),
                        // Rabbit info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${localizations.rabbit} ${rabbit.id + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isAlive ? Colors.black : Colors.grey,
                                ),
                              ),
                              Text(
                                '${localizations.position} ${rabbit.position}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isAlive ? Colors.grey.shade700 : Colors.grey,
                                ),
                              ),
                              Text(
                                _getRabbitColorName(rabbit.id, localizations),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isAlive ? Colors.grey.shade600 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status indicator
                        if (!isAlive)
                          const Icon(Icons.close, size: 16, color: Colors.red)
                        else if (canSelect && !canMove)
                          const Icon(Icons.block, size: 16, color: Colors.orange)
                        else if (isInteractive)
                          const Icon(Icons.touch_app, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          if (!canSelect)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                localizations.drawMovementCard,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (noValidMoves && onSkipTurn != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: onSkipTurn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  localizations.skipTurn,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRabbitIcon(int rabbitId, bool isAlive, bool isInteractive) {
    // Use the same colors as the game board for human player pawns
    // Human player rabbits: grey, blue, green, red, yellow (rabbits 0-4 internally, displayed as 1-5)
    Color color;
    switch (rabbitId) {
      case 0: color = Colors.grey; break;
      case 1: color = Colors.blue; break;
      case 2: color = Colors.green; break;
      case 3: color = Colors.red; break;
      case 4: color = Colors.yellow; break;
      default: color = Colors.grey; break;
    }

    if (!isAlive) {
      color = Colors.grey;
    } else if (!isInteractive) {
      color = color.withOpacity(0.5);
    }

    // Simple circle with the rabbit's color and number
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Text(
          '${rabbitId + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
