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

  // Constants for the board
  static const int numberOfSteps = 24;

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

  // Placeholder for carrot rotation logic
  void rotateCarrot() {
    if (isGameOver) return;
    print("Carrot is rotating!");
    // Determine trapdoor activation based on _random or a fixed sequence if mockable
    // For now, let's say there's a 25% chance a trapdoor opens at a specific position
    // This needs to be tied to specific board positions defined as trapdoors
    int trapPosition = _random.nextInt(numberOfSteps) + 1; // Random step from 1 to 24
    bool trapActivated = _random.nextDouble() < 0.25; // 25% chance

    if (trapActivated) {
      print("Trapdoor activated at step $trapPosition!");
      _checkTrap(humanPlayer, trapPosition);
      _checkTrap(botPlayer, trapPosition);
    } else {
      print("Carrot rotated, but no trapdoor opened this time.");
    }
    checkForWinOrLoss();
  }

  void _checkTrap(Player player, int trapPosition) {
    List<Rabbit> rabbitsToRemove = [];
    for (var rabbit in player.rabbits) {
      if (rabbit.isAlive && rabbit.position == trapPosition) {
        rabbit.isAlive = false;
        rabbitsToRemove.add(rabbit); // Mark for removal from active play, not necessarily list
        print("${player.name}'s rabbit at $trapPosition fell into a trap!");
        player.lives--; // Decrement lives
      }
    }
    // Actual removal from list might not be needed if isAlive is checked
    // player.rabbits.removeWhere((rabbit) => !rabbit.isAlive);
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
      
      // Check if we've gone beyond the board
      if (targetPosition > numberOfSteps) {
        // Can't overshoot the carrot - rabbit cannot move if it would overshoot
        print("${player.name}'s rabbit ${rabbit.id} cannot move $steps steps - would overshoot the carrot (position $targetPosition > $numberOfSteps)!");
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
}
