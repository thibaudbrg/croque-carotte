import 'package:flutter/material.dart';
import 'package:croque_carotte/models/game_state.dart';
import 'package:croque_carotte/widgets/game_board_widget.dart';

class BoardCalibrationScreen extends StatefulWidget {
  const BoardCalibrationScreen({super.key});

  @override
  State<BoardCalibrationScreen> createState() => _BoardCalibrationScreenState();
}

class _BoardCalibrationScreenState extends State<BoardCalibrationScreen> {
  late GameState gameState;
  bool showDebugMarkers = true;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    gameState.startGame();
    
    // Set some test rabbit positions to visualize
    gameState.humanPlayer.rabbits[0].position = 1;
    gameState.humanPlayer.rabbits[1].position = 5;
    gameState.humanPlayer.rabbits[2].position = 10;
    
    gameState.botPlayer.rabbits[0].position = 3;
    gameState.botPlayer.rabbits[1].position = 8;
    gameState.botPlayer.rabbits[2].position = 15;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Calibration'),
        actions: [
          IconButton(
            icon: Icon(showDebugMarkers ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                showDebugMarkers = !showDebugMarkers;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.yellow.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Board Calibration Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Yellow circles show current step positions with numbers'),
                const Text('2. Blue circles = human rabbits, Red circles = bot rabbits'),
                const Text('3. Tap anywhere on the board to get coordinates'),
                const Text('4. Copy coordinates from console to _stepCoordinates in code'),
                Text('5. Debug markers: ${showDebugMarkers ? "ON" : "OFF"} (toggle with eye icon)'),
              ],
            ),
          ),
          
          // Board area
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
                        showDebugInfo: true, // Always show debug info in calibration mode
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Test controls
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Move some rabbits to test positions
                      for (int i = 0; i < gameState.humanPlayer.rabbits.length && i < 3; i++) {
                        gameState.humanPlayer.rabbits[i].position = (i * 5) % 17;
                      }
                      for (int i = 0; i < gameState.botPlayer.rabbits.length && i < 3; i++) {
                        gameState.botPlayer.rabbits[i].position = ((i * 5) + 2) % 17;
                      }
                    });
                  },
                  child: const Text('Test Positions'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Reset all rabbits to start
                      for (var rabbit in gameState.humanPlayer.rabbits) {
                        rabbit.position = 0;
                      }
                      for (var rabbit in gameState.botPlayer.rabbits) {
                        rabbit.position = 0;
                      }
                    });
                  },
                  child: const Text('Reset to Start'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
