import 'dart:math';

import 'package:croque_carotte/models/deck.dart';
import 'package:croque_carotte/models/player.dart';
import 'package:croque_carotte/models/rabbit.dart'; // Import Rabbit class
import 'package:croque_carotte/models/tile.dart';

// Enum to represent the current player
enum CurrentPlayer { human, bot }

class GameState {
  final Player humanPlayer;
  final Player botPlayer;
  final Deck deck;
  final List<Tile> board; // Represents the game board, 24 steps + start/finish if needed
  CurrentPlayer currentPlayerTurn;
  bool isGameOver;
  String? winner; // To store the name of the winner or 'bot'/'human'
  final Random _random; // For deterministic randomness, can be seeded
  
  // Callback for when game ends (for UI notifications)
  Function(String)? onGameEnd;
  
  // Callback for when deck needs reshuffle (for UI animations)
  Function()? onReshuffleNeeded;

  // Carrot rotation state (0-5, cycles through hole patterns)
  int _carrotRotationState = 0;

  // Constants for the board
  static const int numberOfSteps = 24;

  // Predefined hole patterns for each carrot rotation state
  static const Map<int, List<int>> _holePatterns = {
    0: [], // No holes visible
    1: [6, 14], // Holes at positions 6, 14
    2: [3, 17], // Holes at positions 3, 17
    3: [10, 19], // Holes at positions 10, 19
    4: [6, 21], // Holes at positions 6, 21
    5: [10, 17], // Holes at positions 10, 17
  };

  GameState({Player? human, Player? bot, Deck? gameDeck, Random? random, this.onGameEnd, this.onReshuffleNeeded})
      : humanPlayer = human ?? Player(name: 'Player 1'), // Remove lives parameter - it's set by default
        botPlayer = bot ?? Player(name: 'Bot', isBot: true), // Remove lives parameter
        deck = gameDeck ?? Deck(onReshuffleNeeded: onReshuffleNeeded),
        board = List.generate(numberOfSteps + 1, (index) => Tile(id: index)), // Now works with optional type
        currentPlayerTurn = CurrentPlayer.human, // Human player starts
        isGameOver = false,
        _random = random ?? Random();

  void startGame() {
    deck.shuffle();
    // Potentially reset player positions, lives, etc., if this can be called mid-game
    isGameOver = false;
    winner = null;
    currentPlayerTurn = CurrentPlayer.human; // Or randomize starting player
    // Initialize rabbit positions to the start
    for (var rabbit in humanPlayer.rabbits) {
      rabbit.position = 0; // Assuming 0 is the starting position before step 1
      rabbit.isAlive = true;
    }
    for (var rabbit in botPlayer.rabbits) {
      rabbit.position = 0;
      rabbit.isAlive = true;
    }
    // Players already have 5 rabbits from Player constructor, no need to reassign
    print("Game started. Deck shuffled. Player turn: $currentPlayerTurn");
    
    // Print initial deck composition for debugging
    deck.printDeckStatus();
  }

  // Method to handle drawing a card and its effect
  void drawCardAndPlay() {
    if (isGameOver) return;

    final drawnCard = deck.draw();
    if (drawnCard == null) {
      // Handle empty deck scenario if necessary, though rules don't specify
      print("Deck is empty!");
      // Potentially end game or reshuffle discard pile if that was a rule
      return;
    }

    print("${currentPlayerTurn == CurrentPlayer.human ? humanPlayer.name : botPlayer.name} drew ${drawnCard.title}");

    // TODO: Implement card effect logic (move rabbit or rotate carrot)
    // This will involve selecting a rabbit for movement cards

    // Switch turn
    switchTurn();
  }

  void switchTurn() {
    currentPlayerTurn = (currentPlayerTurn == CurrentPlayer.human) ? CurrentPlayer.bot : CurrentPlayer.human;
    print("Turn switched. Current player: $currentPlayerTurn");
    // Remove automatic bot triggering - let the GameScreen handle this
  }

  // Enhanced carrot rotation logic with predefined hole patterns
  void rotateCarrot() {
    if (isGameOver) return;
    
    // Clear all existing holes first
    _clearAllHoles();
    
    // Advance to next rotation state (0-5 cycle)
    _carrotRotationState = (_carrotRotationState + 1) % 6;
    
    print("🥕 Carrot rotated to state $_carrotRotationState");
    
    // Get the hole positions for this state
    List<int> holePositions = _holePatterns[_carrotRotationState] ?? [];
    
    if (holePositions.isEmpty) {
      print("🕳️ No holes appear in this state");
    } else {
      print("🕳️ Creating holes at positions: $holePositions");
      
      // Create holes at the specified positions
      for (int position in holePositions) {
        if (position > 0 && position < board.length) {
          board[position].type = TileType.hole;
          board[position].isTrapOpen = true;
          print("  💥 Hole opened at position $position");
        }
      }
      
      // Check for rabbits that fall into the new holes
      for (int holePosition in holePositions) {
        _checkTrap(humanPlayer, holePosition);
        _checkTrap(botPlayer, holePosition);
      }
    }
    
    checkForWinOrLoss();
  }

  // Helper method to clear all holes on the board
  void _clearAllHoles() {
    for (int i = 0; i < board.length; i++) {
      if (board[i].type == TileType.hole) {
        board[i].type = TileType.normal;
        board[i].isTrapOpen = false;
      }
    }
  }

  void _checkTrap(Player player, int trapPosition) {
    for (var rabbit in player.rabbits) {
      if (rabbit.isAlive && rabbit.position == trapPosition) {
        rabbit.isAlive = false;
        print("💀 ${player.name}'s rabbit ${rabbit.id} at position $trapPosition fell into a hole and disappeared!");
        player.lives--; // Decrement lives
      }
    }
  }

  // Move a rabbit with proper jumping logic and exact win condition
  void moveRabbit(Player player, Rabbit rabbit, int steps) {
    if (isGameOver || !rabbit.isAlive) return;

    int currentPosition = rabbit.position;
    int targetPosition = currentPosition;
    int stepsToMove = steps;

    print("${player.name}'s rabbit ${rabbit.id} attempting to move $steps steps from position $currentPosition");

    // Calculate the final position by stepping through each cell
    while (stepsToMove > 0) {
      targetPosition++;
      
      // Check if this position has a hole - holes block movement completely
      if (targetPosition < board.length && 
          board[targetPosition].type == TileType.hole && 
          board[targetPosition].isTrapOpen) {
        print("${player.name}'s rabbit ${rabbit.id} cannot move $steps steps - hole at position $targetPosition blocks path!");
        return;
      }
      
      // Check if this position is occupied by another rabbit
      bool positionOccupied = _isPositionOccupied(targetPosition, rabbit);
      
      if (positionOccupied) {
        // Skip this occupied cell, don't count it as a step
        print("Position $targetPosition is occupied, jumping over...");
        continue;
      } else {
        // This position is free, count it as a step
        stepsToMove--;
        print("Step to position $targetPosition (${steps - stepsToMove}/$steps)");
      }
    }

    // Check if final position would overshoot before updating
    if (targetPosition > numberOfSteps) {
      print("${player.name}'s rabbit ${rabbit.id} cannot move $steps steps - would overshoot the carrot (position $targetPosition > $numberOfSteps)!");
      return;
    }

    // Update rabbit position
    rabbit.position = targetPosition;
    print("${player.name} moved rabbit ${rabbit.id} to step $targetPosition.");

    // Check for win condition immediately after movement
    if (targetPosition == numberOfSteps) {
      print("🎉 ${player.name}'s rabbit ${rabbit.id} reached the carrot! Game won!");
      _endGame(player.name);
      return;
    }

    checkForWinOrLoss();
  }

  // Helper method to check if a position is occupied by any other rabbit
  bool _isPositionOccupied(int position, Rabbit excludeRabbit) {
    // Check all human player rabbits
    for (var rabbit in humanPlayer.rabbits) {
      if (rabbit.isAlive && rabbit.id != excludeRabbit.id && rabbit.position == position) {
        return true;
      }
    }
    
    // Check all bot player rabbits
    for (var rabbit in botPlayer.rabbits) {
      if (rabbit.isAlive && rabbit.id != excludeRabbit.id && rabbit.position == position) {
        return true;
      }
    }
    
    return false;
  }

  void checkForWinOrLoss() {
    // Win condition is now handled immediately in moveRabbit when reaching numberOfSteps
    
    // Check for loss condition (all rabbits eliminated)
    if (humanPlayer.rabbits.every((r) => !r.isAlive) || humanPlayer.lives <= 0) {
      _endGame(botPlayer.name); // Bot wins if human has no rabbits left
      return;
    }
    if (botPlayer.rabbits.every((r) => !r.isAlive) || botPlayer.lives <= 0) {
      _endGame(humanPlayer.name); // Human wins if bot has no rabbits left
      return;
    }
  }

  void _endGame(String winnerName) {
    isGameOver = true;
    winner = winnerName;
    print("Game Over! Winner: $winner");
    
    // Notify UI of game end
    onGameEnd?.call(winnerName);
  }

  // Helper to get current player object
  Player get currentPlayer => currentPlayerTurn == CurrentPlayer.human ? humanPlayer : botPlayer;

  // Get all current hole positions on the board
  List<int> getHolePositions() {
    List<int> holePositions = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i].type == TileType.hole && board[i].isTrapOpen) {
        holePositions.add(i);
      }
    }
    return holePositions;
  }

  // Get current carrot rotation state for debugging
  int get carrotRotationState => _carrotRotationState;
}
