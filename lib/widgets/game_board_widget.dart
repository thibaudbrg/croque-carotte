import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:croque_carotte/models/game_state.dart';
import 'package:croque_carotte/models/player.dart';
import 'package:croque_carotte/models/rabbit.dart';
import 'package:croque_carotte/models/game_card.dart';

class GameBoardWidget extends StatefulWidget {
  final GameState gameState;
  final Size boardSize;
  final bool showDebugInfo;
  final Function(GameCard, Player, Rabbit?)? onCardPlayed; // Callback for card play

  const GameBoardWidget({
    super.key,
    required this.gameState,
    required this.boardSize,
    this.showDebugInfo = false,
    this.onCardPlayed,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget>
    with TickerProviderStateMixin {
  late AnimationController _pawnAnimationController;
  late AnimationController _cardAnimationController;
  
  // Animation states
  Map<String, Animation<Offset>> _pawnAnimations = {};
  GameCard? _currentlyDrawnCard;
  Animation<double>? _cardScaleAnimation;
  Animation<Offset>? _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _pawnAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Smooth pawn movement
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Card draw/discard animation
      vsync: this,
    );
    
    // Set up card animations
    _cardScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _cardSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 0.0), // Slide to discard pile
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pawnAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  static final List<Offset> _stepCoordinates = [
    // Position 0: Start (TODO: You may want to calibrate this too)
    const Offset(0.054, 0.037), // Start position - adjust if needed
    
    // Positions 1-24: The main spiral path (outer ring)
    const Offset(0.244, 0.153), // Step 1
    const Offset(0.397, 0.133), // Step 2
    const Offset(0.535, 0.193), // Step 3
    const Offset(0.660, 0.206), // Step 4
    const Offset(0.787, 0.259), // Step 5
    const Offset(0.827, 0.381), // Step 6
    const Offset(0.855, 0.509), // Step 7
    const Offset(0.860, 0.647), // Step 8
    const Offset(0.736, 0.702), // Step 9
    const Offset(0.621, 0.758), // Step 10
    const Offset(0.509, 0.769), // Step 11
    const Offset(0.389, 0.740), // Step 12
    const Offset(0.165, 0.546), // Step 13
    const Offset(0.206, 0.421), // Step 14
    const Offset(0.262, 0.303), // Step 15
    const Offset(0.380, 0.349), // Step 16
    const Offset(0.333, 0.475), // Step 17
    const Offset(0.366, 0.590), // Step 18
    const Offset(0.480, 0.643), // Step 19
    const Offset(0.633, 0.598), // Step 20
    const Offset(0.712, 0.497), // Step 21
    const Offset(0.679, 0.383), // Step 22
    const Offset(0.547, 0.329), // Step 23
    const Offset(0.511, 0.469), // Step 24 - FINISH! 🥕 (The Carrot!)
  ];

  // Method to animate pawn movement step by step
  void animatePawnMove(Rabbit rabbit, Player player, int newPosition) {
    if (newPosition < 0 || newPosition >= _stepCoordinates.length) return;
    
    final String rabbitKey = '${player.name}_${rabbit.id}';
    final int currentPos = rabbit.position;
    final int totalSteps = (newPosition - currentPos).abs();
    
    if (totalSteps == 0) return; // No movement needed
    
    print('Animating rabbit ${rabbit.id} from $currentPos to $newPosition ($totalSteps steps)');
    
    // Start the step-by-step animation
    _animateStepByStep(rabbit, player, currentPos, newPosition, 0, totalSteps);
  }
  
  // Helper method to animate step by step
  void _animateStepByStep(Rabbit rabbit, Player player, int startPos, int finalPos, int currentStep, int totalSteps) {
    if (currentStep >= totalSteps) {
      // Animation complete - update final position
      setState(() {
        rabbit.position = finalPos;
        _pawnAnimations.remove('${player.name}_${rabbit.id}');
      });
      _pawnAnimationController.reset();
      print('Animation complete: rabbit ${rabbit.id} reached position $finalPos');
      return;
    }
    
    final String rabbitKey = '${player.name}_${rabbit.id}';
    final int direction = finalPos > startPos ? 1 : -1;
    final int nextPos = startPos + (direction * (currentStep + 1));
    
    // Make sure we don't go beyond the target
    final int targetPos = direction > 0 ? 
        (nextPos > finalPos ? finalPos : nextPos) : 
        (nextPos < finalPos ? finalPos : nextPos);
    
    print('Step ${currentStep + 1}/$totalSteps: moving to position $targetPos');
    
    final Offset currentOffset = currentStep == 0 ? 
        _stepCoordinates[startPos] : 
        _stepCoordinates[startPos + (direction * currentStep)];
    final Offset nextOffset = _stepCoordinates[targetPos];
    
    setState(() {
      _pawnAnimations[rabbitKey] = Tween<Offset>(
        begin: currentOffset,
        end: nextOffset,
      ).animate(CurvedAnimation(
        parent: _pawnAnimationController,
        curve: Curves.easeInOutBack, // Bouncy movement for each hop
      ));
    });
    
    // Animate to next position
    _pawnAnimationController.forward(from: 0.0).then((_) {
      _pawnAnimationController.reset();
      
      // Continue to next step after a brief pause
      Future.delayed(const Duration(milliseconds: 200), () {
        _animateStepByStep(rabbit, player, startPos, finalPos, currentStep + 1, totalSteps);
      });
    });
  }
  
  // Method to handle card drawing animation
  void animateCardDraw(GameCard card) {
    setState(() {
      _currentlyDrawnCard = card;
    });
    
    _cardAnimationController.forward(from: 0.0).then((_) {
      // After card animation, reset
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _currentlyDrawnCard = null;
        });
        _cardAnimationController.reset();
      });
    });
  }

  // Method to execute card effects with animation
  void executeCardWithAnimation(GameCard card, Player player, Rabbit? selectedRabbit) {
    animateCardDraw(card);
    
    Future.delayed(const Duration(milliseconds: 400), () {
      switch (card.type) {
        case GameCardType.move1:
        case GameCardType.move2:
        case GameCardType.move3:
          if (selectedRabbit != null && selectedRabbit.isAlive) {
            int steps = card.type == GameCardType.move1 ? 1 : 
                      card.type == GameCardType.move2 ? 2 : 3;
            int newPosition = selectedRabbit.position + steps;
            if (newPosition > 24) newPosition = 24; // Cap at finish
            
            animatePawnMove(selectedRabbit, player, newPosition);
          }
          break;
        case GameCardType.turnCarrot:
          // Handle carrot rotation
          widget.gameState.rotateCarrot();
          break;
      }
      
      // Notify parent about card play
      widget.onCardPlayed?.call(card, player, selectedRabbit);
    });
  }

  Widget _buildPawn(BuildContext context, Rabbit rabbit, Player player) {
    if (!rabbit.isAlive || rabbit.position < 0 || rabbit.position >= _stepCoordinates.length) {
      return const SizedBox.shrink();
    }

    final String rabbitKey = '${player.name}_${rabbit.id}';
    final double pawnSize = 20.0;
    
    // Use animated position if available, otherwise use static position
    Offset relativePos = _stepCoordinates[rabbit.position];
    if (_pawnAnimations.containsKey(rabbitKey)) {
      relativePos = _pawnAnimations[rabbitKey]!.value;
    }

    // Determine pawn color based on player and rabbit
    Color pawnColor;
    if (player.isBot) {
      // All bot rabbits are purple
      pawnColor = Colors.purple;
    } else {
      // Human player rabbits: grey, blue, green, red, yellow (rabbits 0-4 mapped to display 1-5)
      switch (rabbit.id) {
        case 0: pawnColor = Colors.grey; break;   // Display as Rabbit 1
        case 1: pawnColor = Colors.blue; break;   // Display as Rabbit 2
        case 2: pawnColor = Colors.green; break;  // Display as Rabbit 3
        case 3: pawnColor = Colors.red; break;    // Display as Rabbit 4
        case 4: pawnColor = Colors.yellow; break; // Display as Rabbit 5
        default: pawnColor = Colors.grey; break;
      }
    }

    Widget pawnVisual = Container(
      width: pawnSize,
      height: pawnSize,
      decoration: BoxDecoration(
        color: pawnColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.shade900, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: widget.showDebugInfo ? Center(
        child: Text(
          '${rabbit.id}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ) : null,
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400), // Smooth sliding animation
      curve: Curves.easeInOut,
      left: relativePos.dx * widget.boardSize.width - pawnSize / 2,
      top: relativePos.dy * widget.boardSize.height - pawnSize / 2,
      child: pawnVisual,
    );
  }

  Widget _buildDebugMarkers() {
    if (!widget.showDebugInfo) return const SizedBox.shrink();
    
    return Stack(
      children: _stepCoordinates.asMap().entries.map((entry) {
        int index = entry.key;
        Offset position = entry.value;
        
        return Positioned(
          left: position.dx * widget.boardSize.width - 15,
          top: position.dy * widget.boardSize.height - 15,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Build the drawn card overlay
  Widget _buildDrawnCard() {
    if (_currentlyDrawnCard == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Positioned(
          top: widget.boardSize.height * 0.1,
          left: widget.boardSize.width * 0.1,
          child: Transform.scale(
            scale: _cardScaleAnimation?.value ?? 1.0,
            child: Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentlyDrawnCard!.type == GameCardType.turnCarrot 
                        ? Icons.refresh 
                        : Icons.directions_run,
                    size: 30,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentlyDrawnCard!.title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.showDebugInfo ? (TapDownDetails details) {
        // Debug feature: print tap coordinates
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final relativeX = localPosition.dx / widget.boardSize.width;
        final relativeY = localPosition.dy / widget.boardSize.height;
        
        print('Tapped at: (${relativeX.toStringAsFixed(3)}, ${relativeY.toStringAsFixed(3)})');
        print('Add to _stepCoordinates: const Offset(${relativeX.toStringAsFixed(3)}, ${relativeY.toStringAsFixed(3)}),');
      } : null,
      child: Stack(
        children: <Widget>[
          // 1. The Board - Use PNG since it works reliably
          Image.asset(
            'assets/images/board.png',
            width: widget.boardSize.width,
            height: widget.boardSize.height,
            fit: BoxFit.contain,
          ),

          // 2. Debug markers (if enabled)
          _buildDebugMarkers(),

          // 3. Player Pawns
          ...widget.gameState.humanPlayer.rabbits.map((rabbit) => _buildPawn(context, rabbit, widget.gameState.humanPlayer)),
          
          // 4. Bot Pawns
          ...widget.gameState.botPlayer.rabbits.map((rabbit) => _buildPawn(context, rabbit, widget.gameState.botPlayer)),
          
          // 5. Drawn card overlay
          _buildDrawnCard(),
        ],
      ),
    );
  }
}
