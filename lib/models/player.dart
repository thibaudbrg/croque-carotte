import 'package:croque_carotte/models/rabbit.dart'; // Import the Rabbit class

// Represents a player in the game
class Player {
  final String id; // Keep id if you plan to use it, otherwise name can be id
  final String name;
  List<Rabbit> rabbits;
  int lives;
  final bool isBot;

  Player({
    String? id, // Make id optional if name is primary identifier
    required this.name,
    this.lives = 5, // Default to 5 lives as per rules
    this.isBot = false,
    List<Rabbit>? initialRabbits,
  }) : id = id ?? name, // Use name as id if id is not provided
       rabbits = initialRabbits ?? List.generate(5, (_) => Rabbit(isBotControlled: isBot)) {
    // Ensure Rabbit ID counter is reset for a new set of players if starting a fresh game context
    // This might be better handled at a higher level, e.g., when GameState is created
    if (name == 'Player 1') { // Crude way to reset only once per game setup
      Rabbit.resetIdCounter(); 
    }
    // Re-initialize rabbits here to ensure they get the correct isBotControlled status
    this.rabbits = initialRabbits ?? List.generate(lives, (_) => Rabbit(isBotControlled: isBot));
  }
}
