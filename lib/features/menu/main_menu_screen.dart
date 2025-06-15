import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:croque_carotte/features/gameboard/game_screen.dart';
import 'package:croque_carotte/features/gameboard/board_calibration_screen.dart';
import 'package:croque_carotte/core/game_state_manager.dart';
import 'package:croque_carotte/core/language_manager.dart';
import 'package:croque_carotte/core/localization.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _hasPausedGame = false;

  @override
  void initState() {
    super.initState();
    _checkForPausedGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForPausedGame();
  }

  void _checkForPausedGame() {
    setState(() {
      _hasPausedGame = GameStateManager.hasPausedGame();
    });
  }

  Future<void> _startNewGame(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    
    // Check if there's a paused game
    if (_hasPausedGame) {
      final bool? shouldStartNew = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(localizations.confirmQuit),
            content: Text(localizations.newGameWarning),
            actions: <Widget>[
              TextButton(
                child: Text(localizations.cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(localizations.yes),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      
      if (shouldStartNew != true) return;
      
      // Clear the paused game
      GameStateManager.clearPausedGame();
      _checkForPausedGame(); // Update UI state
    }
    
    // Start new game
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.gameTitle),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade200, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Show Resume Game button if there's a paused game
              if (_hasPausedGame) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(localizations.resumeGame),
                  onPressed: () {
                    final resumedGame = GameStateManager.resumeGame();
                    if (resumedGame != null) {
                      _checkForPausedGame(); // Update UI state
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(existingGameState: resumedGame),
                        ),
                      ).then((_) {
                        // Check for paused game when returning from game screen
                        _checkForPausedGame();
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Start New Game button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: Text(localizations.startGame),
                onPressed: () => _startNewGame(context).then((_) {
                  // Check for paused game when returning from start new game
                  _checkForPausedGame();
                }),
              ),
              const SizedBox(height: 20),

              // Change Language button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: Text(localizations.changeLanguage),
                onPressed: () {
                  final languageManager = Provider.of<LanguageManager>(context, listen: false);
                  languageManager.showLanguageDialog(context);
                },
              ),

              const SizedBox(height: 20),

              // Board Calibration button (debug)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.purple,
                ),
                child: Text(localizations.boardCalibration),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BoardCalibrationScreen()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Quit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                  backgroundColor: Colors.red,
                ),
                child: Text(localizations.quit),
                onPressed: () async {
                  final bool? shouldQuit = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(localizations.confirmQuit),
                        content: Text(localizations.whatWouldYouLikeToDo),
                        actions: <Widget>[
                          TextButton(
                            child: Text(localizations.cancel),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: Text(localizations.quit),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldQuit == true) {
                    SystemNavigator.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
