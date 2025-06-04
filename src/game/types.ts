export enum CardType {
  Move1 = 'MOVE_1',
  Move2 = 'MOVE_2',
  Move3 = 'MOVE_3',
  Carrot = 'CARROT',
}

export interface Player {
  id: number;
  name: string;
  /** Current position on the board (0 is start). */
  position: number;
  /** Remaining lives. */
  lives: number;
}

export interface GameState {
  boardSize: number;
  holes: number[];
  players: Player[];
  currentPlayer: number; // index in players array
}
