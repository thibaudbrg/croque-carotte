import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:croque_carotte/models/game_card.dart';

class DeckWidget extends StatefulWidget {
  final int cardsRemaining;
  final VoidCallback? onCardDrawn; // Changed to VoidCallback
  final double width;
  final double height;
  final GameCard? drawnCard; // Currently drawn card
  final List<GameCard> humanDiscardPile; // Human player's discard pile
  final List<GameCard> botDiscardPile; // Bot player's discard pile

  const DeckWidget({
    super.key,
    required this.cardsRemaining,
    this.onCardDrawn,
    this.width = 100.0,
    this.height = 150.0,
    this.drawnCard,
    this.humanDiscardPile = const [],
    this.botDiscardPile = const [],
  });

  @override
  State<DeckWidget> createState() => _DeckWidgetState();
}

class _DeckWidgetState extends State<DeckWidget> with TickerProviderStateMixin {
  late AnimationController _drawAnimationController;
  late AnimationController _discardAnimationController;
  late AnimationController _shuffleAnimationController;
  
  Animation<double>? _cardScaleAnimation;
  Animation<Offset>? _cardSlideAnimation;
  Animation<double>? _shuffleRotationAnimation;
  Animation<double>? _shuffleScaleAnimation;
  
  bool _isShuffling = false;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    
    // Card draw animation (grow then slide)
    _drawAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Card discard animation (slide to pile)
    _discardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Shuffle animation
    _shuffleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Enhanced card scale animation (bigger growth)
    _cardScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.2, // Make card much bigger
    ).animate(CurvedAnimation(
      parent: _drawAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    ));
    
    // Card slide animation to discard pile
    _cardSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.0, 0.0), // Slide left to discard pile
    ).animate(CurvedAnimation(
      parent: _drawAnimationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));
    
    // Shuffle rotation animation
    _shuffleRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0, // Multiple rotations
    ).animate(CurvedAnimation(
      parent: _shuffleAnimationController,
      curve: Curves.elasticInOut,
    ));
    
    // Shuffle scale animation
    _shuffleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _shuffleAnimationController,
      curve: Curves.elasticInOut,
    ));
  }

  @override
  void dispose() {
    _drawAnimationController.dispose();
    _discardAnimationController.dispose();
    _shuffleAnimationController.dispose();
    super.dispose();
  }

  void _drawCard() {
    print('DeckWidget: _drawCard called, cardsRemaining: ${widget.cardsRemaining}');
    print('DeckWidget: Current drawn card: ${widget.drawnCard?.title}');
    
    if (_isDrawing) return; // Don't allow multiple draws at once
    
    // Don't allow drawing if there's already a card drawn but not yet played
    if (widget.drawnCard != null) {
      print('DeckWidget: Cannot draw card - already have a card drawn (${widget.drawnCard!.title}) waiting for action');
      return;
    }
    
    // Drawing from empty deck will automatically trigger reshuffle
    setState(() {
      _isDrawing = true;
    });
    
    // Special handling for empty deck - show immediate reshuffle feedback
    if (widget.cardsRemaining == 0) {
      print('DeckWidget: Drawing from empty deck - auto-reshuffle will happen');
      // Trigger shuffle animation immediately since we know reshuffle will happen
      _triggerShuffleAnimation();
    }
    
    // Notify parent that a card should be drawn (this will handle auto-reshuffle if needed)
    print('DeckWidget: Calling onCardDrawn callback');
    widget.onCardDrawn?.call();
    
    // Enhanced draw animation: grow big, hold, then slide and shrink
    _drawAnimationController.forward().then((_) {
      // Wait a moment for player to see the card
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isDrawing = false;
        });
        // Reset animation for next draw
        _drawAnimationController.reset();
      });
    });
  }
  
  // Method to trigger shuffle animation
  void _triggerShuffleAnimation() {
    if (_isShuffling) return;
    
    setState(() {
      _isShuffling = true;
    });
    
    print('DeckWidget: Starting EPIC reshuffle animation!');
    print('🔄 Collecting cards: Human=${widget.humanDiscardPile.length}, Bot=${widget.botDiscardPile.length}');
    
    // Enhanced shuffle animation with multiple phases
    _shuffleAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isShuffling = false;
          });
          _shuffleAnimationController.reset();
          print('✅ DeckWidget: EPIC reshuffle complete - deck is recharged!');
        }
      });
    });
  }

  // Public method to trigger shuffle animation from parent
  void triggerShuffle() {
    _triggerShuffleAnimation();
  }

  Widget _buildCard(GameCard card, {double scale = 1.0, Offset offset = Offset.zero, double rotation = 0.0}) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: widget.width * 0.8,
            height: widget.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: card.type == GameCardType.turnCarrot 
                  ? _buildCarrotCard()
                  : _buildRabbitCard(card),
            ),
          ),
        ),
      ),
    );
  }

  // Build the full SVG rabbit card
  Widget _buildRabbitCard(GameCard card) {
    return SvgPicture.asset(
      _getRabbitSvgPath(card.type),
      width: widget.width * 0.8,
      height: widget.height * 0.8,
      fit: BoxFit.cover,
      placeholderBuilder: (context) => Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Text(
            card.type == GameCardType.move1 ? '+1' :
            card.type == GameCardType.move2 ? '+2' : '+3',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  // Build the carrot card using SVG
  Widget _buildCarrotCard() {
    return SvgPicture.asset(
      'assets/svg/carrot.svg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildDiscardPile(List<GameCard> discardPile, {required bool isBot}) {
    if (discardPile.isEmpty) {
      return Container(
        width: widget.width * 0.8,
        height: widget.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: const Center(
          child: Text(
            'Discard\nPile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return Stack(
      children: discardPile.asMap().entries.map((entry) {
        int index = entry.key;
        GameCard card = entry.value;
        
        // Create messy stacking effect
        double offsetX = (index % 3 - 1) * 5.0;
        double offsetY = (index % 2) * 3.0;
        double rotation = (index % 5 - 2) * 0.1; // Small rotation
        
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: _buildCard(card, rotation: rotation),
        );
      }).toList(),
    );
  }

  // Helper method to get the correct rabbit SVG path based on card type
  String _getRabbitSvgPath(GameCardType cardType) {
    switch (cardType) {
      case GameCardType.move1:
        return 'assets/svg/rabbit1.svg';
      case GameCardType.move2:
        return 'assets/svg/rabbit2.svg';
      case GameCardType.move3:
        return 'assets/svg/rabbit3.svg';
      default:
        return 'assets/svg/rabbit1.svg'; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Human player discard pile
        Column(
          children: [
            const Text('Your Cards', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildDiscardPile(widget.humanDiscardPile, isBot: false),
          ],
        ),
        
        // Main deck
        Column(
          children: [
            GestureDetector(
              onTap: _drawCard, // Draws card; auto-reshuffles if deck is empty
              child: SizedBox(
                width: widget.width,
                height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Deck pile with shuffle animation
                if (widget.cardsRemaining > 0)
                  AnimatedBuilder(
                    animation: _shuffleAnimationController,
                    builder: (context, child) {
                      // Check if deck is disabled (already has a drawn card)
                      bool isDeckDisabled = widget.drawnCard != null;
                      
                      return Transform.rotate(
                        angle: (_shuffleRotationAnimation?.value ?? 0.0) * 3.14159 / 2,
                        child: Transform.scale(
                          scale: _shuffleScaleAnimation?.value ?? 1.0,
                          child: Container(
                            width: widget.width,
                            height: widget.height,
                            decoration: BoxDecoration(
                              color: isDeckDisabled 
                                  ? Colors.grey.shade400  // Disabled color
                                  : (_isShuffling ? Colors.orange.shade600 : Colors.blueGrey.shade600),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isDeckDisabled 
                                    ? Colors.grey.shade600  // Disabled border
                                    : (_isShuffling ? Colors.orange.shade800 : Colors.blueGrey.shade800), 
                                width: 2
                              ),
                              boxShadow: isDeckDisabled ? [] : [  // No shadow when disabled
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: _isShuffling ? 3 : 1,
                                  blurRadius: _isShuffling ? 8 : 3,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isDeckDisabled 
                                  ? Icon(
                                      Icons.block,  // Show blocked icon when disabled
                                      color: Colors.white,
                                      size: 30,
                                    )
                                  : Icon(
                                      _isShuffling ? Icons.shuffle : Icons.filter_none,
                                      color: Colors.white,
                                      size: _isShuffling ? 35 : 30,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                // Empty deck - show automatic reshuffle status
                if (widget.cardsRemaining == 0)
                  AnimatedBuilder(
                    animation: _shuffleAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: (_shuffleRotationAnimation?.value ?? 0.0) * 3.14159 / 4,
                        child: Container(
                          width: widget.width,
                          height: widget.height,
                          decoration: BoxDecoration(
                            color: _isShuffling ? Colors.orange.shade400 : Colors.purple.shade300,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: _isShuffling ? Colors.orange.shade600 : Colors.purple.shade500, 
                              width: _isShuffling ? 3 : 2
                            ),
                            boxShadow: _isShuffling ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.6),
                                spreadRadius: 4,
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                            ] : [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.4),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isShuffling ? Icons.autorenew : Icons.shuffle,
                                  color: _isShuffling ? Colors.white : Colors.white,
                                  size: _isShuffling ? 28 : 22,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isShuffling ? 'Shuffling...' : 'Draw to\nAuto-Shuffle',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: _isShuffling ? FontWeight.bold : FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                // Enhanced drawn card animation
                if (widget.drawnCard != null && _isDrawing)
                  AnimatedBuilder(
                    animation: _drawAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          (_cardSlideAnimation?.value.dx ?? 0.0) * 100,
                          (_cardSlideAnimation?.value.dy ?? 0.0) * 100,
                        ),
                        child: Transform.scale(
                          scale: _cardScaleAnimation?.value ?? 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.6),
                                  spreadRadius: 4,
                                  blurRadius: 12,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: _buildCard(widget.drawnCard!),
                          ),
                        ),
                      );
                    },
                  ),
                
                // Card count
                if (widget.cardsRemaining > 0)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.cardsRemaining}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
            // Status text below deck
            const SizedBox(height: 4),
            Text(
              widget.drawnCard != null 
                  ? 'Select Rabbit'
                  : 'Draw Card',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: widget.drawnCard != null ? Colors.orange : Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
        
        // Bot player discard pile
        Column(
          children: [
            const Text('Bot Cards', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildDiscardPile(widget.botDiscardPile, isBot: true),
          ],
        ),
      ],
    );
  }
}
