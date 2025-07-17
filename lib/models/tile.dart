// Represents a tile on the game board
class Tile {
  final int id;
  TileType type; // Made mutable so holes can be created dynamically
  bool isTrapOpen; // New field to indicate if a trapdoor tile is currently open

  Tile({
    required this.id,
    this.type = TileType.normal, // Default to normal, can be overridden
    this.isTrapOpen = false,   // Default to false
  });
}

enum TileType {
  normal,
  carrot,
  hole,
  start,
  finish,
}
