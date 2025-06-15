import 'package:flutter/material.dart';
import 'package:croque_carotte/models/game_state.dart';
import 'package:croque_carotte/models/game_card.dart';
import 'package:croque_carotte/models/player.dart';
import 'package:croque_carotte/models/rabbit.dart';
import 'package:croque_carotte/widgets/deck_widget.dart';
import 'package:croque_carotte/widgets/game_board_widget.dart';
import 'package:croque_carotte/widgets/rabbit_selection_widget.dart';
import 'package:croque_carotte/core/game_state_manager.dart';
import 'package:croque_carotte/core/localization.dart';

class GameScreen extends StatefulWidget {
  final GameState? existingGameState;

  const GameScreen({super.key, this.existingGameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState gameState;
  
  // Track discard piles for animation
  List<GameCard> humanDiscardPile = [];
  List<GameCard> botDiscardPile = [];
  GameCard? currentDrawnCard;
  Rabbit? selectedRabbit; // For movement card selection
  
  // Animation state tracking
  bool _isAnimationInProgress = false;
  
  // Keys to access widgets for animations
  final GlobalKey<State<DeckWidget>> _deckKey = GlobalKey<State<DeckWidget>>();

  @override
  void initState() {
    super.initState();
    // Use existing game state if provided, otherwise create new one
    if (widget.existingGameState != null) {
      gameState = widget.existingGameState!;
      // Set the callback for the resumed game
      gameState.onGameEnd = _handleGameEnd;
      gameState.onReshuffleNeeded = _handleDeckReshuffle;
      print("Resuming existing game...");
    } else {
      gameState = GameState(onGameEnd: _handleGameEnd, onReshuffleNeeded: _handleDeckReshuffle);
      gameState.startGame();
    }
  }

  void _handleDeckReshuffle() {
    print('GameScreen: Deck reshuffle triggered!');
    print('Cards to reshuffle: ${humanDiscardPile.length} from human, ${botDiscardPile.length} from bot');
    
    // Show visual animation of cards sliding from discard piles to deck
    setState(() {
      // Mark that reshuffling is in progress
    });
    
    // First trigger the deck shuffle animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deckState = _deckKey.currentState;
      if (deckState != null && deckState.mounted) {
        try {
          (deckState as dynamic).triggerShuffle();
          print('Shuffle animation started on deck');
        } catch (e) {
          print('Could not trigger shuffle animation: $e');
        }
      }
      
      // Animate cards sliding from discard piles back to deck
      // Create a visual effect showing cards moving from piles to deck
      _animateCardsReturnToDeck();
      
      // Clear discard piles after animation delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            print('Clearing discard piles: ${humanDiscardPile.length} + ${botDiscardPile.length} cards');
            humanDiscardPile.clear();
            botDiscardPile.clear();
          });
          print('Reshuffle complete - all cards back in deck!');
        }
      });
    });
  }
  
  void _animateCardsReturnToDeck() {
    // This method creates a visual effect showing cards sliding from discard piles to deck
    // In a future enhancement, we could add actual AnimatedPositioned widgets
    // For now, we'll show the effect through the existing animations
    print('Animating ${humanDiscardPile.length + botDiscardPile.length} cards returning to deck...');
    
    // Simulate cards sliding back with a slight delay between each card
    int totalCards = humanDiscardPile.length + botDiscardPile.length;
    for (int i = 0; i < totalCards; i++) {
      Future.delayed(Duration(milliseconds: 50 * i), () {
        // This creates a staggered effect
        if (mounted) {
          setState(() {
            // Trigger UI updates for smooth animation
          });
        }
      });
    }
  }

  void _handleGameEnd(String winnerName) {
    // Show win dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWinDialog(winnerName);
    });
  }

  void _showWinDialog(String winnerName) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.gameOver),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                size: 50,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.gameWinner(winnerName),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(localizations.returnToMenu),
              onPressed: () {
                // Clear any paused game and return to menu
                GameStateManager.clearPausedGame();
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to menu
              },
            ),
          ],
        );
      },
    );
  }

  void _handleCardDraw() {
    print('=== HUMAN TURN START ===');
    print('GameScreen: _handleCardDraw called');
    print('GameScreen: Current player turn: ${gameState.currentPlayerTurn}');
    print('GameScreen: Is game over: ${gameState.isGameOver}');
    print('GameScreen: Cards remaining before draw: ${gameState.deck.cardsRemaining}');
    
    if (gameState.currentPlayerTurn != CurrentPlayer.human || gameState.isGameOver) {
      print('GameScreen: Cannot draw card - not human turn or game over');
      return;
    }

    // If deck is empty, it will automatically reshuffle
    if (gameState.deck.cardsRemaining == 0) {
      print('Human drawing from empty deck - auto-reshuffle will trigger');
    }

    final drawnCard = gameState.deck.draw();
    print('GameScreen: Drew card: ${drawnCard?.title}');
    print('GameScreen: Cards remaining after draw: ${gameState.deck.cardsRemaining}');
    if (drawnCard == null) {
      print('ERROR: Human could not draw card - this should not happen!');
      return;
    }

    setState(() {
      currentDrawnCard = drawnCard;
      // Force UI refresh to update card counter
    });

    // Handle carrot rotation immediately, movement cards require rabbit selection
    if (drawnCard.type == GameCardType.turnCarrot) {
      print('Human playing carrot card');
      _executeCard(drawnCard, gameState.humanPlayer, null);
      print('=== HUMAN TURN END (auto carrot) ===');
    } else {
      // Movement card - user must select rabbit using the permanent widget
      print('Human drew movement card: ${drawnCard.title} - waiting for rabbit selection');
    }
  }

  void _handleRabbitSelection(Rabbit rabbit) {
    if (currentDrawnCard == null || currentDrawnCard!.type == GameCardType.turnCarrot) {
      print('Invalid rabbit selection - no movement card drawn');
      return;
    }
    
    print('Human selected rabbit ${rabbit.id} for ${currentDrawnCard!.title}');
    _executeCard(currentDrawnCard!, gameState.humanPlayer, rabbit);
    print('=== HUMAN TURN END ===');
  }

  void _handleSkipTurn() {
    final localizations = AppLocalizations.of(context);
    _skipTurn(localizations.noValidMoves);
  }
  
  bool _canRabbitMove(Rabbit rabbit, int steps) {
    // Check if rabbit can move the specified steps without overshooting
    int targetPosition = rabbit.position;
    int stepsToMove = steps;
    
    while (stepsToMove > 0) {
      targetPosition++;
      
      if (targetPosition > GameState.numberOfSteps) {
        print("_canRabbitMove: Rabbit ${rabbit.id} cannot move $steps steps - would overshoot (${targetPosition} > ${GameState.numberOfSteps})");
        return false; // Would overshoot
      }
      
      // Check if position is occupied
      bool occupied = gameState.humanPlayer.rabbits.any((r) => r.isAlive && r.id != rabbit.id && r.position == targetPosition) ||
                      gameState.botPlayer.rabbits.any((r) => r.isAlive && r.position == targetPosition);
      
      if (!occupied) {
        stepsToMove--; // Count this as a valid step
      }
      // If occupied, we just continue to the next position (jumping over)
    }
    
    print("_canRabbitMove: Rabbit ${rabbit.id} can move $steps steps from ${rabbit.position} to $targetPosition");
    return true; // Can complete the movement
  }
  
  void _skipTurn(String reason) {
    print('Skipping turn: $reason');
    
    // Create a dummy skip card and add to discard pile
    final skipCard = GameCard(
      type: GameCardType.move1, 
      title: 'Skipped Turn',
      description: 'Turn was skipped due to no valid moves'
    );
    
    setState(() {
      currentDrawnCard = null;
    });
    
    // Add card to discard pile
    humanDiscardPile.add(skipCard);
    
    // Add to deck's discard pile too
    gameState.deck.discard(skipCard);
    
    // Switch to next player
    // Switch turn
    gameState.currentPlayerTurn = (gameState.currentPlayerTurn == CurrentPlayer.human) 
        ? CurrentPlayer.bot 
        : CurrentPlayer.human;
    
    print("Turn switched to: ${gameState.currentPlayerTurn}");
    
    // Trigger bot turn if necessary
    if (gameState.currentPlayerTurn == CurrentPlayer.bot) {
      _handleBotTurn();
    }
  }

  void _executeCard(GameCard card, Player player, Rabbit? rabbit) {    
    // Add to appropriate discard pile for UI display
    setState(() {
      if (player.isBot) {
        botDiscardPile.add(card);
      } else {
        humanDiscardPile.add(card);
      }
      currentDrawnCard = null;
    });
    
    // Add card to deck's discard pile for reshuffling
    gameState.deck.discard(card);
    
    // Update game state - execute the card action
    if (card.type != GameCardType.turnCarrot && rabbit != null) {
      // Calculate the final position using GameState logic but don't update yet
      int steps = _getCardSteps(card);
      int finalPosition = _calculateFinalPosition(rabbit, steps);
      
      if (finalPosition != rabbit.position) {
        // DON'T switch turn yet - wait for animation to complete
        // Trigger animation in GameBoardWidget - this will update the rabbit position during animation
        _triggerRabbitMovementAnimation(player, rabbit, finalPosition, steps);
      } else {
        // Rabbit couldn't move, switch turn immediately
        _switchTurn();
      }
    } else if (card.type == GameCardType.turnCarrot) {
      gameState.rotateCarrot();
      _switchTurn(); // Switch turn immediately for carrot cards
    }
  }
  
  int _calculateFinalPosition(Rabbit rabbit, int steps) {
    int currentPos = rabbit.position;
    int stepsRemaining = steps;
    
    print("Calculating final position for rabbit ${rabbit.id}: $steps steps from $currentPos");
    
    // Use the same logic as in the animation path calculation
    while (stepsRemaining > 0 && currentPos < GameState.numberOfSteps) {
      int nextPos = currentPos + 1; // Always moving forward
      
      if (nextPos > GameState.numberOfSteps) {
        // Can't overshoot the carrot
        print("Cannot move $steps steps - would overshoot carrot");
        return rabbit.position; // Return original position if can't move
      }
      
      // Check if position is occupied (jumping logic)
      bool positionOccupied = _isPositionOccupiedByOtherRabbit(nextPos, rabbit);
      
      if (positionOccupied) {
        // Skip this occupied cell, don't count it as a step
        print("Position $nextPos is occupied, will jump over");
        currentPos = nextPos; // Move through the occupied position
        // Don't decrement stepsRemaining - this doesn't count as a step
      } else {
        // This position is free, count it as a step
        currentPos = nextPos;
        stepsRemaining--;
        print("Valid step to position $currentPos (${steps - stepsRemaining}/$steps)");
      }
    }
    
    print("Final calculated position: $currentPos");
    return currentPos;
  }
  
  void _triggerRabbitMovementAnimation(Player player, Rabbit rabbit, int finalPosition, int cardSteps) {
    print("Triggering animation: ${player.name}'s rabbit ${rabbit.id} from ${rabbit.position} to $finalPosition");
    
    // Set animation flag to prevent bot from playing during human animation
    setState(() {
      _isAnimationInProgress = true;
    });
    
    // Start the movement animation by directly updating the rabbit position with a delay
    // This simulates step-by-step movement
    _animateRabbitStepByStep(rabbit, rabbit.position, finalPosition, player, cardSteps);
  }
  
  void _animateRabbitStepByStep(Rabbit rabbit, int startPos, int finalPos, Player player, int cardSteps) {
    print("Starting step-by-step SLIDING animation: rabbit ${rabbit.id} from $startPos to $finalPos");
    
    if (startPos == finalPos) {
      // No movement needed, switch turn immediately
      setState(() {
        _isAnimationInProgress = false;
      });
      _switchTurn();
      return;
    }

    // Calculate the actual path the rabbit will take, properly handling occupied cells
    List<int> movementPath = _calculateRabbitMovementPath(rabbit, startPos, cardSteps);
    
    print("Rabbit ${rabbit.id} movement path: $movementPath");
    
    if (movementPath.isEmpty) {
      // No valid path found
      print("No valid movement path found for rabbit ${rabbit.id}");
      setState(() {
        _isAnimationInProgress = false;
      });
      _switchTurn();
      return;
    }
    
    // Animate through each position in the path with sliding
    int pathIndex = 0;
    
    void animateToNextPosition() {
      if (pathIndex >= movementPath.length || !mounted || gameState.isGameOver) {
        // Animation complete or interrupted
        if (mounted && !gameState.isGameOver) {
          print("Sliding animation complete, switching turn");
          _switchTurn();
        } else {
          // Game over or widget unmounted, just clear the flag
          if (mounted) {
            setState(() {
              _isAnimationInProgress = false;
            });
          }
        }
        return;
      }
      
      int nextPosition = movementPath[pathIndex];
      pathIndex++;
      
      print("Sliding rabbit ${rabbit.id} to position $nextPosition");
      
      // Update the rabbit position with smooth transition
      setState(() {
        rabbit.position = nextPosition;
      });
      
      // Check for win condition immediately when reaching position 24
      if (nextPosition == GameState.numberOfSteps) {
        print("🎉 Rabbit ${rabbit.id} reached position 24 - WINNER!");
        // Trigger win immediately
        _handleGameEnd(player.name);
        setState(() {
          _isAnimationInProgress = false;
        });
        return;
      }
      
      // Schedule next slide animation (faster for smoother sliding)
      Future.delayed(const Duration(milliseconds: 400), () {
        animateToNextPosition();
      });
    }
    
    // Start the sliding animation
    Future.delayed(const Duration(milliseconds: 100), () {
      animateToNextPosition();
    });
  }
  
  // Calculate the exact path a rabbit will take, handling occupied cells correctly
  List<int> _calculateRabbitMovementPath(Rabbit rabbit, int startPos, int cardSteps) {
    List<int> path = [];
    int currentPos = startPos;
    int stepsRemaining = cardSteps; // Use the original card steps, not distance
    
    print("Calculating path for rabbit ${rabbit.id}: $cardSteps card steps from $startPos");
    
    while (stepsRemaining > 0 && currentPos < GameState.numberOfSteps) {
      int nextPos = currentPos + 1; // Always moving forward
      
      // Check if we've gone beyond the board
      if (nextPos > GameState.numberOfSteps) {
        print("Would overshoot board at position $nextPos");
        break;
      }
      
      // Check if this position is occupied by another rabbit
      bool positionOccupied = _isPositionOccupiedByOtherRabbit(nextPos, rabbit);
      
      if (positionOccupied) {
        // Skip this occupied cell, don't count it as a step, but move through it
        print("Position $nextPos is occupied, jumping over (not counting as step)");
        currentPos = nextPos; // Move through the occupied position
        // Don't decrement stepsRemaining - this doesn't count as a step
        // Don't add to path - we jump over occupied cells
      } else {
        // This position is free, count it as a step and add to path
        currentPos = nextPos;
        stepsRemaining--;
        path.add(currentPos);
        print("Step to position $currentPos (${cardSteps - stepsRemaining}/$cardSteps)");
      }
    }
    
    return path;
  }
  
  // Helper method to check if a position is occupied by another rabbit
  bool _isPositionOccupiedByOtherRabbit(int position, Rabbit movingRabbit) {
    // Check all human rabbits
    for (var r in gameState.humanPlayer.rabbits) {
      if (r.isAlive && r.id != movingRabbit.id && r.position == position) {
        return true;
      }
    }
    
    // Check all bot rabbits
    for (var r in gameState.botPlayer.rabbits) {
      if (r.isAlive && r.id != movingRabbit.id && r.position == position) {
        return true;
      }
    }
    
    return false;
  }
  
  void _switchTurn() {
    // Switch turn manually with setState to trigger UI update
    setState(() {
      gameState.currentPlayerTurn = (gameState.currentPlayerTurn == CurrentPlayer.human) 
          ? CurrentPlayer.bot 
          : CurrentPlayer.human;
      
      _isAnimationInProgress = false; // Clear animation flag when turn switches
    });
    
    print("Turn switched to: ${gameState.currentPlayerTurn}");
    
    // Only trigger bot turn if it's now bot's turn and the game isn't over
    if (gameState.currentPlayerTurn == CurrentPlayer.bot && !gameState.isGameOver) {
      _handleBotTurn();
    }
  }

  int _getCardSteps(GameCard card) {
    switch (card.type) {
      case GameCardType.move1: return 1;
      case GameCardType.move2: return 2;
      case GameCardType.move3: return 3;
      default: return 0;
    }
  }

  void _handleBotTurn() {
    // Wait a bit, then check if animation is still in progress
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || gameState.isGameOver) return;
      
      // If animation is still in progress, wait longer
      if (_isAnimationInProgress) {
        print('Bot waiting for animation to complete...');
        _waitForAnimationAndPlayBot();
        return;
      }
      
      _executeBotTurn();
    });
  }
  
  void _waitForAnimationAndPlayBot() {
    // Check every 500ms if animation is complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || gameState.isGameOver) return;
      
      if (_isAnimationInProgress) {
        // Still animating, wait more
        _waitForAnimationAndPlayBot();
      } else {
        // Animation complete, execute bot turn
        _executeBotTurn();
      }
    });
  }
  
  void _executeBotTurn() {
    print('=== BOT TURN START ===');
    print('Bot turn: Drawing card. Cards remaining: ${gameState.deck.cardsRemaining}');
    
    // If deck is empty, it will automatically reshuffle
    if (gameState.deck.cardsRemaining == 0) {
      print('Bot drawing from empty deck - auto-reshuffle will trigger');
    }
    
    final drawnCard = gameState.deck.draw();
    print('Bot drew: ${drawnCard?.title}. Cards remaining after draw: ${gameState.deck.cardsRemaining}');
    if (drawnCard == null) {
      print('ERROR: Bot could not draw card - this should not happen!');
      return;
    }
    
    // Update UI state to refresh card counter
    setState(() {
      // This forces the UI to rebuild with the new card count
    });
    
    // Simple bot AI: choose first available rabbit for movement cards
    Rabbit? selectedRabbit;
    if (drawnCard.type != GameCardType.turnCarrot) {
      selectedRabbit = gameState.botPlayer.rabbits.firstWhere(
        (r) => r.isAlive,
        orElse: () => gameState.botPlayer.rabbits.first,
      );
      print('Bot selected rabbit ${selectedRabbit?.id} for ${drawnCard.title}');
    } else {
      print('Bot playing carrot card');
    }
    
    _executeCard(drawnCard, gameState.botPlayer, selectedRabbit);
    print('=== BOT TURN END ===');
  }

  Future<bool> _onWillPop() async {
    final localizations = AppLocalizations.of(context);
    // Show pause/quit confirmation dialog
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.pauseGame),
          content: Text(localizations.whatWouldYouLikeToDo),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.continuePlaying),
              onPressed: () {
                Navigator.of(context).pop(false); // Don't exit
              },
            ),
            TextButton(
              child: Text(localizations.pauseReturnToMenu),
              onPressed: () {
                // Save the current game state
                GameStateManager.pauseGame(gameState);
                Navigator.of(context).pop(true); // Exit to menu
              },
            ),
            TextButton(
              child: Text(localizations.quitGame),
              onPressed: () {
                // Clear any paused game and exit
                GameStateManager.clearPausedGame();
                Navigator.of(context).pop(true); // Exit to menu
              },
            ),
          ],
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Croque Carotte - Game On!'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                // TODO: Show game rules or info dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game info/rules not implemented yet.')),
                );
              },
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            // Top area: Game Status and Turn Info
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Human player info
                  Column(
                    children: [
                      Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Lives: ${gameState.humanPlayer.lives}'),
                      Text('Rabbits: ${gameState.humanPlayer.rabbits.where((r) => r.isAlive).length}'),
                    ],
                  ),
                  
                  // Current turn indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: gameState.currentPlayerTurn == CurrentPlayer.human 
                          ? Colors.blue.shade100 
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gameState.currentPlayerTurn == CurrentPlayer.human 
                            ? Colors.blue 
                            : Colors.red,
                      ),
                    ),
                    child: Text(
                      gameState.currentPlayerTurn == CurrentPlayer.human 
                          ? 'Your Turn' 
                          : 'Bot Turn',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  // Bot player info
                  Column(
                    children: [
                      Text('Bot', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Lives: ${gameState.botPlayer.lives}'),
                      Text('Rabbits: ${gameState.botPlayer.rabbits.where((r) => r.isAlive).length}'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Middle area: Enhanced Deck with discard piles
            Container(
              padding: const EdgeInsets.all(8.0),
              height: screenSize.height * 0.25,
              child: DeckWidget(
                key: _deckKey,
                cardsRemaining: gameState.deck.cardsRemaining,
                onCardDrawn: _handleCardDraw,
                humanDiscardPile: humanDiscardPile,
                botDiscardPile: botDiscardPile,
                drawnCard: currentDrawnCard,
                width: 120,  // Increased from 80 (1.5x bigger)
                height: 180, // Increased from 120 (1.5x bigger)
              ),
            ),
            
            // Bottom area: Game Board with rabbit selection area
            Expanded(
              child: Row(
                children: [
                  // Left side: Rabbit selection widget
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RabbitSelectionWidget(
                      humanPlayer: gameState.humanPlayer,
                      currentDrawnCard: currentDrawnCard,
                      onRabbitSelected: _handleRabbitSelection,
                      canRabbitMove: _canRabbitMove,
                      onSkipTurn: _handleSkipTurn,
                    ),
                  ),
                  
                  // Right side: Game Board
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double boardDimension = constraints.maxWidth < constraints.maxHeight
                                ? constraints.maxWidth
                                : constraints.maxHeight;
                            final Size boardSize = Size(boardDimension, boardDimension);

                            return AspectRatio(
                              aspectRatio: 1,
                              child: GameBoardWidget(
                                gameState: gameState,
                                boardSize: boardSize,
                                showDebugInfo: false,
                                onCardPlayed: (card, player, rabbit) {
                                  setState(() {
                                    // Update UI after card animation completes
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Remove duplicate win dialog - main dialog is shown via _showWinDialog()
          ],
        ),
      ),
    );
  }
}
