enum GameCardType {
  move1,
  move2,
  move3,
  turnCarrot,
}

class GameCard {
  final String title;
  final String description;
  final GameCardType type;

  GameCard({
    required this.title,
    required this.description,
    required this.type,
  });

  @override
  String toString() {
    return 'GameCard(title: $title, description: $description, type: $type)';
  }
}
