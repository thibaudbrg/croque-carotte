class Rabbit {
  static int _nextId = 0;
  final int id;
  int position; // 0 for start, 1-24 for steps, 24 for goal
  bool isAlive;
  final bool isBotControlled; // To distinguish if needed, though Player.isBot might be enough

  Rabbit({
    this.position = 0, 
    this.isAlive = true, 
    this.isBotControlled = false,
  }) : id = _nextId++;

  // Reset ID counter if needed, e.g., for new games or tests
  static void resetIdCounter() {
    _nextId = 0;
  }
}
