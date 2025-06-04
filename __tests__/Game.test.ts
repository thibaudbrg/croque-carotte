import { Game } from '../src/game/Game';
import { CardType } from '../src/game/types';

describe('Game logic', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('advances the player based on drawn card', () => {
    const game = new Game(10);
    const deck = (game as any).deck;
    jest.spyOn(deck, 'draw').mockReturnValue(CardType.Move2);

    const result = game.takeTurn();

    expect(result.card).toBe(CardType.Move2);
    expect(game.state.players[0].position).toBe(2);
    expect(game.state.currentPlayer).toBe(1);
  });

  it('rotates holes and penalizes players on new holes', () => {
    const game = new Game(10);
    // Place the current player on position 2 so they fall after rotation
    game.state.players[0].position = 2;
    game.state.players[0].lives = 2;

    jest.spyOn(game as any, 'generateHoles').mockReturnValue([2, 5, 6, 7]);
    const deck = (game as any).deck;
    jest.spyOn(deck, 'draw').mockReturnValue(CardType.Carrot);

    game.takeTurn();

    expect(game.state.players[0].position).toBe(0);
    expect(game.state.players[0].lives).toBe(1);
  });

  it('declares the player as winner when reaching the carrot', () => {
    const game = new Game(5);
    game.state.players[0].position = 3;
    const deck = (game as any).deck;
    jest.spyOn(deck, 'draw').mockReturnValue(CardType.Move1);

    const result = game.takeTurn();

    expect(result.winner?.id).toBe(0);
  });
});
