import 'package:croque_carotte/models/game_state.dart';

class GameStateManager {
  static GameState? _pausedGame;
  
  // Save the current game state for later resumption
  static void pauseGame(GameState gameState) {
    _pausedGame = gameState;
  }
  
  // Check if there's a paused game available
  static bool hasPausedGame() {
    return _pausedGame != null && !_pausedGame!.isGameOver;
  }
  
  // Resume the paused game
  static GameState? resumeGame() {
    final GameState? game = _pausedGame;
    _pausedGame = null; // Clear the paused game
    return game;
  }
  
  // Clear any paused game (e.g., when starting a new game)
  static void clearPausedGame() {
    _pausedGame = null;
  }
}
