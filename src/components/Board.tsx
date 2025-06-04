// React Native component to display the game board and rabbits.
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { GameState } from '../game/types';
import { Cell } from './Cell';
import { Rabbit } from './Rabbit';

interface Props {
  state: GameState;
}

/**
 * Render the board as a grid of cells in an aerial view.
 */
export function Board({ state }: Props) {
  // 5 columns grid layout
  const cols = 5;

  const renderCell = (index: number) => {
    const playersHere = state.players.filter(p => p.position === index);
    const isHole = state.holes.includes(index);
    return (
      <Cell key={index} hasHole={isHole}>
        {playersHere.map(p => (
          <Rabbit key={p.id} color={p.id === 0 ? '#ff0000' : '#0000ff'} />
        ))}
      </Cell>
    );
  };

  // Build an array of cells to render.
  const cells: JSX.Element[] = [];
  for (let i = 0; i < state.boardSize; i++) {
    cells.push(renderCell(i));
  }

  // Container arranges cells in rows.
  return <View style={styles.container}>{cells}</View>;
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    width: 5 * 50,
  },
});
