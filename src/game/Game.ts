// Implementation of the game rules and player interactions.
import { CardType, GameState, Player } from './types';
import { CardDeck } from './CardDeck';

/**
 * Core game logic for Croque Carotte.
 */
export class Game {
  state: GameState;
  private deck: CardDeck; // Card deck providing random actions.

  constructor(boardSize = 20, startingLives = 3) {
    // Two players: user and bot start at position 0 with some lives.
    this.deck = new CardDeck();
    const players: Player[] = [
      { id: 0, name: 'You', position: 0, lives: startingLives, eliminated: false },
      { id: 1, name: 'Bot', position: 0, lives: startingLives, eliminated: false },
    ];
    this.state = {
      boardSize,
      holes: this.generateHoles(boardSize),
      players,
      currentPlayer: 0,
    };
  }

  /** Main game loop for a single turn. */
  takeTurn() {
    const card = this.deck.draw();
    const player = this.state.players[this.state.currentPlayer];
    switch (card) {
      case CardType.Move1:
        this.advancePlayer(player, 1);
        break;
      case CardType.Move2:
        this.advancePlayer(player, 2);
        break;
      case CardType.Move3:
        this.advancePlayer(player, 3);
        break;
      case CardType.Carrot:
        this.rotateCarrot();
        break;
    }
    // Check win condition by reaching the carrot
    if (!player.eliminated && player.position >= this.state.boardSize - 1) {
      return { card, winner: player };
    }
    // Check if only one player remains
    const remaining = this.state.players.filter(p => !p.eliminated);
    if (remaining.length === 1) {
      return { card, winner: remaining[0] };
    }
    this.nextTurn();
    return { card };
  }

  /** Move player forward and handle holes. */
  private advancePlayer(player: Player, steps: number) {
    player.position = Math.min(player.position + steps, this.state.boardSize - 1);
    // If the player lands on a hole, they fall and go back to start losing a life
    if (this.state.holes.includes(player.position)) {
      player.lives -= 1;
      player.position = 0;
      if (player.lives <= 0) {
        player.eliminated = true;
      }
    }
  }

  /** Change hole positions randomly. Any player on a new hole loses a life. */
  private rotateCarrot() {
    this.state.holes = this.generateHoles(this.state.boardSize);
    for (const p of this.state.players) {
      if (this.state.holes.includes(p.position)) {
        p.lives -= 1;
        p.position = 0;
        if (p.lives <= 0) {
          p.eliminated = true;
        }
      }
    }
  }

  /** Switch active player. */
  private nextTurn() {
    const total = this.state.players.length;
    let next = (this.state.currentPlayer + 1) % total;
    while (this.state.players[next].eliminated) {
      next = (next + 1) % total;
      if (next === this.state.currentPlayer) {
        break; // all players eliminated (should be handled elsewhere)
      }
    }
    this.state.currentPlayer = next;
  }

  /** Generate a random set of hole positions. */
  private generateHoles(size: number): number[] {
    const holes: Set<number> = new Set();
    while (holes.size < 4) {
      const idx = Math.floor(Math.random() * (size - 2)) + 1; // avoid start and carrot
      holes.add(idx);
    }
    return Array.from(holes);
  }
}
