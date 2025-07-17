import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Function(GameCard, Player, Rabbit?)? onCardAnimation; // Callback for card animation

  const GameBoardWidget({
    super.key,
    required this.gameState,
    required this.boardSize,
    this.showDebugInfo = false,
    this.onCardPlayed,
    this.onCardAnimation,
  });

  @override
  State<GameBoardWidget> createState() => GameBoardWidgetState();
}

class GameBoardWidgetState extends State<GameBoardWidget>
    with TickerProviderStateMixin {
  late AnimationController _pawnAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _carrotRotationController;
  late AnimationController _holeAnimationController;
  
  // Animation states
  Map<String, Animation<Offset>> _pawnAnimations = {};
  GameCard? _currentlyDrawnCard;
  Animation<double>? _cardScaleAnimation;
  Animation<Offset>? _cardSlideAnimation;
  Animation<double>? _carrotRotationAnimation;
  Map<int, Animation<double>> _holeAnimations = {}; // Animation for each hole position
  
  // Hole state tracking
  Set<int> _currentHolePositions = {};
  Set<int> _previousHolePositions = {};
  
  // Interactive calibration state
  int? _selectedCalibrationPosition;
  Map<int, Offset> _calibrationAdjustments = {};
  final FocusNode _focusNode = FocusNode();
  
  // Carrot center calibration state
  bool _isCarrotCalibrationMode = false;
  int _currentCarrotRotationState = 0; // 0, 1, or 2 (corresponding to 0°, 120°, 240°)
  Map<int, Offset> _carrotCenterAdjustments = {}; // Adjustments for each rotation state
  
  // Calibrated carrot center adjustments from calibration mode
  static const Map<int, Offset> _calibratedCarrotAdjustments = {
    0: Offset(0.0, 0.0),     // 0° rotation
    1: Offset(-12.0, -37.0), // 120° rotation
    2: Offset(26.0, -32.0),  // 240° rotation
  };

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
    _carrotRotationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Slightly longer for smoother rotation
      vsync: this,
    );
    _holeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Smooth hole appear/disappear
      vsync: this,
    );
    
    // Initialize hole positions
    _currentHolePositions = widget.gameState.getHolePositions().toSet();
    _previousHolePositions = Set.from(_currentHolePositions);
    
    // Set up initial hole animations (appearing from start)
    _initializeHoleAnimations();
    
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
    
    // Set up carrot rotation animation with smooth acceleration/deceleration
    _carrotRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _carrotRotationController,
      curve: Curves.easeInOutCubic, // Smoother curve with gradual acceleration/deceleration
    ));
  }

  // Public method to execute card animation from GameScreen
  void executeCardAnimation(GameCard card, Player player, Rabbit? selectedRabbit) {
    // Call the callback to notify GameScreen that animation is about to start
    if (widget.onCardAnimation != null) {
      widget.onCardAnimation!(card, player, selectedRabbit);
    }
    
    // Execute the actual animation
    executeCardWithAnimation(card, player, selectedRabbit);
  }

  @override
  void dispose() {
    _pawnAnimationController.dispose();
    _cardAnimationController.dispose();
    _carrotRotationController.dispose();
    _holeAnimationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static final List<Offset> _stepCoordinates = [
    // Position 0: Start (TODO: You may want to calibrate this too)
    const Offset(0.054, 0.037), // Start position - adjust if needed
    
    // Positions 1-24: The main spiral path (outer ring)
    const   Offset(0.241, 0.152), // Step 1
    const   Offset(0.400, 0.134), // Step 2
    const   Offset(0.537, 0.183), // Step 3
    const   Offset(0.663, 0.207), // Step 4
    const   Offset(0.786, 0.255), // Step 5
    const   Offset(0.826, 0.375), // Step 6
    const   Offset(0.852, 0.503), // Step 7
    const   Offset(0.855, 0.646), // Step 8
    const   Offset(0.736, 0.698), // Step 9
    const   Offset(0.618, 0.750),  // Step 10
    const   Offset(0.508, 0.761),  // Step 11
    const   Offset(0.389, 0.734),  // Step 12
    const   Offset(0.166, 0.543),  // Step 13
    const   Offset(0.206, 0.417),  // Step 14
    const   Offset(0.261, 0.300),  // Step 15
    const   Offset(0.377, 0.350),  // Step 16
    const   Offset(0.333, 0.469),  // Step 17
    const   Offset(0.361, 0.585),  // Step 18
    const   Offset(0.480, 0.635),  // Step 19
    const   Offset(0.630, 0.593),  // Step 20
    const   Offset(0.715, 0.497),  // Step 21
    const   Offset(0.680, 0.380),  // Step 22
    const   Offset(0.548, 0.332),  // Step 23
    const   Offset(0.506, 0.466),  // Step 24 - FINISH! 🥕 (The Carrot!)
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

  // Method to execute card effects with animation - public method for external access
  void executeCardWithAnimation(GameCard card, Player player, Rabbit? selectedRabbit) {
    // For carrot cards, skip the card display overlay and directly animate the carrot
    if (card.type == GameCardType.turnCarrot) {
      print('Executing carrot rotation animation');
      _animateCarrotRotation();
      // Notify parent about card play immediately since there's no delay for carrot cards
      widget.onCardPlayed?.call(card, player, selectedRabbit);
      return;
    }
    
    // For other cards, show the card overlay first
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
          // This case is now handled above
          break;
      }
      
      // Notify parent about card play
      widget.onCardPlayed?.call(card, player, selectedRabbit);
    });
  }

  // Method to animate carrot rotation with smooth visual feedback
  void _animateCarrotRotation() {
    print('Starting carrot rotation animation. Current state: ${widget.gameState.carrotRotationState}');
    print('Animation controller status: ${_carrotRotationController.status}');
    print('Animation controller value: ${_carrotRotationController.value}');
    
    // Start the smooth rotation animation BEFORE updating game state
    _carrotRotationController.forward(from: 0.0).then((_) {
      // After animation completes, update the game state and reset controller
      setState(() {
        widget.gameState.rotateCarrot();
        // Update hole positions and animate changes
        _animateHoleChanges();
      });
      print('Carrot rotation animation completed. New state: ${widget.gameState.carrotRotationState}');
      _carrotRotationController.reset();
    });
  }

  // Method to animate hole appearance/disappearance
  void _animateHoleChanges() {
    // Get new hole positions
    Set<int> newHolePositions = widget.gameState.getHolePositions().toSet();
    
    // Find holes that are appearing and disappearing
    Set<int> appearingHoles = newHolePositions.difference(_currentHolePositions);
    Set<int> disappearingHoles = _currentHolePositions.difference(newHolePositions);
    
    print('Hole changes: appearing=$appearingHoles, disappearing=$disappearingHoles');
    print('Current holes: $_currentHolePositions');
    print('New holes: $newHolePositions');
    
    // Clean up old animations first (from previous carrot rotations)
    List<int> toRemove = [];
    for (int hole in _holeAnimations.keys) {
      if (!newHolePositions.contains(hole) && !_currentHolePositions.contains(hole)) {
        toRemove.add(hole);
      }
    }
    for (int hole in toRemove) {
      _holeAnimations.remove(hole);
    }
    
    // Create animations for appearing holes (scale from 0 to 1)
    for (int hole in appearingHoles) {
      // Only create animation if one doesn't already exist
      if (!_holeAnimations.containsKey(hole)) {
        _holeAnimations[hole] = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _holeAnimationController,
          curve: Curves.elasticOut,
        ));
      }
    }
    
    // Create animations for disappearing holes (scale from 1 to 0)
    for (int hole in disappearingHoles) {
      _holeAnimations[hole] = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _holeAnimationController,
        curve: Curves.easeInOut,
      ));
      
      // Add listener to remove the animation when it completes
      _holeAnimations[hole]!.addListener(() {
        // When animation is complete (scale is 0), remove it from the map
        if (_holeAnimations[hole]!.value <= 0.01) {
          setState(() {
            _holeAnimations.remove(hole);
          });
        }
      });
    }
    
    // Update hole positions IMMEDIATELY so static holes will be rendered
    _previousHolePositions = Set.from(_currentHolePositions);
    _currentHolePositions = newHolePositions;
    
    // Start hole animations
    if (appearingHoles.isNotEmpty || disappearingHoles.isNotEmpty) {
      // Check if controller is in a valid state to start animation
      if (_holeAnimationController.status != AnimationStatus.forward && 
          _holeAnimationController.status != AnimationStatus.reverse) {
        _holeAnimationController.forward(from: 0.0).then((_) {
          // After animation completes, ensure holes are still rendered by forcing rebuild
          if (mounted) {
            _holeAnimationController.reset();
            setState(() {
              // Force rebuild to ensure static holes are shown
            });
          }
        });
      }
    }
  }

  // Initialize hole animations for the first time
  void _initializeHoleAnimations() {
    // Create appearing animations for all initial holes
    for (int hole in _currentHolePositions) {
      _holeAnimations[hole] = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _holeAnimationController,
        curve: Curves.elasticOut,
      ));
    }
    
  // Start initial hole animations with a small delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _currentHolePositions.isNotEmpty) {
        _holeAnimationController.forward(from: 0.0).then((_) {
          if (mounted) {
            _holeAnimationController.reset();
          }
        });
      }
    });
  }

  // Interactive calibration methods
  void _selectCalibrationPosition(int position) {
    if (!widget.showDebugInfo || _isCarrotCalibrationMode) return;
    
    setState(() {
      _selectedCalibrationPosition = position;
    });
    
    // Request focus for keyboard input
    _focusNode.requestFocus();
    
    print('Selected position $position for calibration. Use arrow keys to adjust.');
    print('Current coordinate: ${_getAdjustedCoordinate(position)}');
  }

  void _enterCarrotCalibrationMode() {
    if (!widget.showDebugInfo) return;
    
    setState(() {
      _isCarrotCalibrationMode = true;
      _currentCarrotRotationState = 0; // Start with 0° rotation
      _selectedCalibrationPosition = null; // Clear position selection
    });
    
    // Request focus for keyboard input
    _focusNode.requestFocus();
    
    print('Entered carrot calibration mode. Current rotation state: $_currentCarrotRotationState (${_currentCarrotRotationState * 120}°)');
    print('Use arrow keys to adjust carrot center position.');
    print('Press Tab to switch between rotation states (0°, 120°, 240°).');
  }

  void _exitCarrotCalibrationMode() {
    setState(() {
      _isCarrotCalibrationMode = false;
      _currentCarrotRotationState = 0;
    });
    
    print('Exited carrot calibration mode.');
  }

  void _switchCarrotRotationState() {
    if (!_isCarrotCalibrationMode) return;
    
    setState(() {
      _currentCarrotRotationState = (_currentCarrotRotationState + 1) % 3;
    });
    
    print('Switched to rotation state: $_currentCarrotRotationState (${_currentCarrotRotationState * 120}°)');
    print('Current adjustment: ${_carrotCenterAdjustments[_currentCarrotRotationState] ?? Offset.zero}');
  }

  Offset _getCarrotCenterAdjustment(int rotationState) {
    if (_isCarrotCalibrationMode) {
      // In calibration mode, use dynamic adjustments
      return _carrotCenterAdjustments[rotationState] ?? Offset.zero;
    } else {
      // In normal mode, use calibrated values
      return _calibratedCarrotAdjustments[rotationState] ?? Offset.zero;
    }
  }

  void _adjustCarrotCenterPosition(double deltaX, double deltaY) {
    if (!_isCarrotCalibrationMode) return;
    
    setState(() {
      final currentAdjustment = _carrotCenterAdjustments[_currentCarrotRotationState] ?? Offset.zero;
      _carrotCenterAdjustments[_currentCarrotRotationState] = Offset(
        currentAdjustment.dx + deltaX,
        currentAdjustment.dy + deltaY,
      );
    });
    
    print('Adjusted carrot center for rotation state $_currentCarrotRotationState (${_currentCarrotRotationState * 120}°)');
    print('New adjustment: ${_carrotCenterAdjustments[_currentCarrotRotationState]!.dx.toStringAsFixed(1)}, ${_carrotCenterAdjustments[_currentCarrotRotationState]!.dy.toStringAsFixed(1)} pixels');
    
    // Keep focus after adjustment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _printCarrotCenterAdjustments() {
    print('=== CARROT CENTER ADJUSTMENTS ===');
    for (int i = 0; i < 3; i++) {
      final adjustment = _carrotCenterAdjustments[i] ?? Offset.zero;
      print('Rotation state $i (${i * 120}°): Offset(${adjustment.dx.toStringAsFixed(1)}, ${adjustment.dy.toStringAsFixed(1)})');
    }
    print('=== Copy these values to your carrot positioning logic ===');
  }

  Offset _getAdjustedCoordinate(int position) {
    if (position < 0 || position >= _stepCoordinates.length) {
      return Offset.zero;
    }
    
    final baseCoordinate = _stepCoordinates[position];
    final adjustment = _calibrationAdjustments[position] ?? Offset.zero;
    
    return Offset(
      baseCoordinate.dx + (adjustment.dx / widget.boardSize.width),
      baseCoordinate.dy + (adjustment.dy / widget.boardSize.height),
    );
  }

  void _adjustCalibrationPosition(int position, double deltaX, double deltaY) {
    if (!widget.showDebugInfo || position < 0 || position >= _stepCoordinates.length) return;
    
    setState(() {
      final currentAdjustment = _calibrationAdjustments[position] ?? Offset.zero;
      _calibrationAdjustments[position] = Offset(
        currentAdjustment.dx + deltaX,
        currentAdjustment.dy + deltaY,
      );
    });
    
    final newCoordinate = _getAdjustedCoordinate(position);
    print('Adjusted position $position to: (${newCoordinate.dx.toStringAsFixed(3)}, ${newCoordinate.dy.toStringAsFixed(3)})');
    print('Raw adjustment: (${_calibrationAdjustments[position]!.dx.toStringAsFixed(1)}, ${_calibrationAdjustments[position]!.dy.toStringAsFixed(1)}) pixels');
    
    // Keep focus after adjustment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!widget.showDebugInfo) return;
    
    if (event is KeyDownEvent) {
      const double moveStep = 1.0; // Move 1 pixel at a time
      
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          if (_isCarrotCalibrationMode) {
            _adjustCarrotCenterPosition(-moveStep, 0);
          } else if (_selectedCalibrationPosition != null) {
            _adjustCalibrationPosition(_selectedCalibrationPosition!, -moveStep, 0);
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          if (_isCarrotCalibrationMode) {
            _adjustCarrotCenterPosition(moveStep, 0);
          } else if (_selectedCalibrationPosition != null) {
            _adjustCalibrationPosition(_selectedCalibrationPosition!, moveStep, 0);
          }
          break;
        case LogicalKeyboardKey.arrowUp:
          if (_isCarrotCalibrationMode) {
            _adjustCarrotCenterPosition(0, -moveStep);
          } else if (_selectedCalibrationPosition != null) {
            _adjustCalibrationPosition(_selectedCalibrationPosition!, 0, -moveStep);
          }
          break;
        case LogicalKeyboardKey.arrowDown:
          if (_isCarrotCalibrationMode) {
            _adjustCarrotCenterPosition(0, moveStep);
          } else if (_selectedCalibrationPosition != null) {
            _adjustCalibrationPosition(_selectedCalibrationPosition!, 0, moveStep);
          }
          break;
        case LogicalKeyboardKey.tab:
          if (_isCarrotCalibrationMode) {
            _switchCarrotRotationState();
          }
          break;
        case LogicalKeyboardKey.enter:
          if (_isCarrotCalibrationMode) {
            _printCarrotCenterAdjustments();
          } else {
            _printFinalCoordinate();
          }
          break;
        case LogicalKeyboardKey.escape:
          if (_isCarrotCalibrationMode) {
            _exitCarrotCalibrationMode();
          } else {
            setState(() {
              _selectedCalibrationPosition = null;
            });
          }
          break;
      }
    }
  }

  void _printFinalCoordinate() {
    if (_selectedCalibrationPosition == null) return;
    
    final finalCoordinate = _getAdjustedCoordinate(_selectedCalibrationPosition!);
    print('=== FINAL COORDINATE FOR POSITION $_selectedCalibrationPosition ===');
    print('const Offset(${finalCoordinate.dx.toStringAsFixed(3)}, ${finalCoordinate.dy.toStringAsFixed(3)}), // Step $_selectedCalibrationPosition');
    print('=== Copy this line to _stepCoordinates ===');
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
    if (!widget.showDebugInfo || _isCarrotCalibrationMode) return const SizedBox.shrink();
    
    return Stack(
      children: _stepCoordinates.asMap().entries.map((entry) {
        int index = entry.key;
        Offset position = _getAdjustedCoordinate(index);
        bool isSelected = _selectedCalibrationPosition == index;
        bool isHolePosition = [3, 6, 10, 14, 17, 19, 21].contains(index);
        
        // Make marker size same as holes
        final double markerSize = widget.boardSize.width * 0.07;
        
        return Positioned(
          left: position.dx * widget.boardSize.width - markerSize / 2,
          top: position.dy * widget.boardSize.height - markerSize / 2,
          child: GestureDetector(
            onTap: () => _selectCalibrationPosition(index),
            child: Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.red.withOpacity(0.9)
                    : isHolePosition 
                        ? Colors.blue.withOpacity(0.8)
                        : Colors.yellow.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.orange, 
                  width: isSelected ? 3 : 2
                ),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
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

  // Build holes as black circles with smooth animations
  Widget _buildHoles() {
    if (widget.showDebugInfo) {
      // In debug mode, don't show holes - only show calibration markers
      return const SizedBox.shrink();
    }
    
    // Build holes for all positions that might be visible (current + previous + animating)
    Set<int> allHolePositions = Set.from(_currentHolePositions);
    allHolePositions.addAll(_previousHolePositions);
    allHolePositions.addAll(_holeAnimations.keys);
    
    return Stack(
      children: allHolePositions.map((holePosition) {
        if (holePosition < 0 || holePosition >= _stepCoordinates.length) {
          return const SizedBox.shrink();
        }
        
        Offset position = _getAdjustedCoordinate(holePosition);
        final double holeSize = widget.boardSize.width * 0.08;
        
        // Check if this hole has an animation
        if (_holeAnimations.containsKey(holePosition) && _holeAnimations[holePosition] != null) {
          return AnimatedBuilder(
            animation: _holeAnimations[holePosition]!,
            builder: (context, child) {
              double rawScale = _holeAnimations[holePosition]!.value;
              double scale = rawScale.clamp(0.0, 1.0); // Clamp scale to valid range
              double opacity = scale.clamp(0.0, 1.0); // Clamp opacity to valid range
              
              // If scale is essentially 0, don't render anything
              if (scale < 0.01) {
                return const SizedBox.shrink();
              }
              
              return Positioned(
                left: position.dx * widget.boardSize.width - holeSize / 2,
                top: position.dy * widget.boardSize.height - holeSize / 2,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: holeSize,
                      height: holeSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity((0.8 * opacity).clamp(0.0, 1.0)),
                            spreadRadius: (3 * scale).clamp(0.0, 10.0),
                            blurRadius: (6 * scale).clamp(0.0, 20.0),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          // Static hole (no animation) - show if it's in current positions
          if (!_currentHolePositions.contains(holePosition)) {
            return const SizedBox.shrink();
          }
          
          return Positioned(
            left: position.dx * widget.boardSize.width - holeSize / 2,
            top: position.dy * widget.boardSize.height - holeSize / 2,
            child: Container(
              width: holeSize,
              height: holeSize,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    spreadRadius: 3,
                    blurRadius: 6,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  // Build layered board with rotating carrot center
  Widget _buildLayeredBoard() {
    return Stack(
      children: [
        // Base board layer
        Image.asset(
          'assets/images/board.png',
          width: widget.boardSize.width,
          height: widget.boardSize.height,
          fit: BoxFit.contain,
        ),
        
        // Rotating carrot center layer
        AnimatedBuilder(
          animation: _carrotRotationController,
          builder: (context, child) {
            // Calculate current rotation angle with smooth interpolation
            double baseAngle = widget.gameState.carrotRotationState * 120.0;
            double animationProgress = _carrotRotationAnimation?.value ?? 0.0;
            
            // Debug print during animation (disabled for cleaner output)
            // if (_carrotRotationController.isAnimating) {
            //   print('Animation progress: ${animationProgress.toStringAsFixed(3)}, Controller status: ${_carrotRotationController.status}');
            // }
            
            // During animation, smoothly interpolate to the next rotation state
            double rotationAngle;
            Offset adjustment;
            
            if (_isCarrotCalibrationMode) {
              // In calibration mode, use the current calibration state
              rotationAngle = _currentCarrotRotationState * 120.0;
              adjustment = _getCarrotCenterAdjustment(_currentCarrotRotationState);
            } else {
              // In normal mode, animate from current state to next state
              if (_carrotRotationController.isAnimating) {
                // During animation: interpolate rotation angle from current to next state
                int currentState = widget.gameState.carrotRotationState;
                int nextState = (currentState + 1) % 3;
                double currentAngle = currentState * 120.0;
                
                // Interpolate rotation angle from current to next (adding 120°)
                rotationAngle = currentAngle + (animationProgress * 120.0);
                
                // Interpolate adjustment from current state to next state
                Offset currentAdjustment = _getCarrotCenterAdjustment(currentState);
                Offset nextAdjustment = _getCarrotCenterAdjustment(nextState);
                adjustment = Offset.lerp(currentAdjustment, nextAdjustment, animationProgress) ?? currentAdjustment;
              } else {
                // When not animating: use the current state
                rotationAngle = baseAngle;
                adjustment = _getCarrotCenterAdjustment(widget.gameState.carrotRotationState);
              }
            }
            
            // Debug print rotation angle (disabled for cleaner output)
            // print('Rotation angle: ${rotationAngle.toStringAsFixed(1)}°, Adjustment: $adjustment');
            
            return Transform.translate(
              offset: adjustment,
              child: Transform.rotate(
                angle: rotationAngle * (pi / 180), // Convert degrees to radians
                child: Image.asset(
                  'assets/images/board_carrot_center.png',
                  width: widget.boardSize.width,
                  height: widget.boardSize.height,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTapDown: widget.showDebugInfo ? (TapDownDetails details) {
          // Debug feature: print tap coordinates
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          final relativeX = localPosition.dx / widget.boardSize.width;
          final relativeY = localPosition.dy / widget.boardSize.height;
          
          print('Tapped at: (${relativeX.toStringAsFixed(3)}, ${relativeY.toStringAsFixed(3)})');
          print('Add to _stepCoordinates: const Offset(${relativeX.toStringAsFixed(3)}, ${relativeY.toStringAsFixed(3)}),');
        } : null,
        child: Container(
          color: Colors.transparent, // Ensure the container can receive focus
          child: Stack(
            children: <Widget>[
              // 1. The Board - Layered board system
              _buildLayeredBoard(),

              // 2. Debug markers (if enabled)
              _buildDebugMarkers(),

              // 3. Holes (displayed before pawns so pawns appear on top)
              _buildHoles(),

              // 4. Player Pawns
              ...widget.gameState.humanPlayer.rabbits.map((rabbit) => _buildPawn(context, rabbit, widget.gameState.humanPlayer)),
              
              // 5. Bot Pawns
              ...widget.gameState.botPlayer.rabbits.map((rabbit) => _buildPawn(context, rabbit, widget.gameState.botPlayer)),
              
              // 6. Drawn card overlay
              _buildDrawnCard(),
              
              // 7. Calibration instructions (if in debug mode)
              if (widget.showDebugInfo) _buildCalibrationInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalibrationInstructions() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CALIBRATION MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (_isCarrotCalibrationMode) ...[
              Text(
                'CARROT CENTER CALIBRATION',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rotation: ${_currentCarrotRotationState * 120}°',
                style: const TextStyle(color: Colors.yellow, fontSize: 10),
              ),
              const SizedBox(height: 2),
              const Text(
                '• Use arrow keys to adjust carrot',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• Press Tab to switch rotation',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• Press Enter to print adjustments',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• Press Escape to exit carrot mode',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ] else ...[
              const Text(
                '• Click position to select',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• Use arrow keys to adjust',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• Press Enter to print coord',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• Press Escape to deselect',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _enterCarrotCalibrationMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CALIBRATE CARROT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            if (_selectedCalibrationPosition != null && !_isCarrotCalibrationMode) ...[
              const SizedBox(height: 4),
              Text(
                'Selected: Position $_selectedCalibrationPosition',
                style: const TextStyle(color: Colors.yellow, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
