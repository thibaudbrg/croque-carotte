import 'package:flutter_test/flutter_test.dart';
import 'package:croque_carotte/models/game_state.dart';

void main() {
  group('moveRabbit', () {
    test('does not overshoot the end of the board', () {
      final game = GameState();
      final rabbit = game.humanPlayer.rabbits.first;
      rabbit.position = GameState.numberOfSteps - 1;

      game.moveRabbit(game.humanPlayer, rabbit, 2);

      expect(rabbit.position, GameState.numberOfSteps - 1);
      expect(game.isGameOver, isFalse);
    });

    test('jumps over occupied spaces', () {
      final game = GameState();
      final rabbit1 = game.humanPlayer.rabbits[0];
      final rabbit2 = game.humanPlayer.rabbits[1];
      rabbit1.position = 5;
      rabbit2.position = 6;

      game.moveRabbit(game.humanPlayer, rabbit1, 2);

      expect(rabbit1.position, 8);
    });
  });
}
