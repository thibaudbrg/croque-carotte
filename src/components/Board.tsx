// React Native component to display the game board and rabbits.
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
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
  const cols = 5;
  const rows = Math.ceil(state.boardSize / cols);

  const generateSnail = (r: number, c: number) => {
    const order: number[] = [];
    let top = 0,
      bottom = r - 1,
      left = 0,
      right = c - 1;
    while (top <= bottom && left <= right) {
      for (let i = left; i <= right; i++) order.push(top * c + i);
      top++;
      for (let i = top; i <= bottom; i++) order.push(i * c + right);
      right--;
      if (top <= bottom) {
        for (let i = right; i >= left; i--) order.push(bottom * c + i);
        bottom--;
      }
      if (left <= right) {
        for (let i = bottom; i >= top; i--) order.push(i * c + left);
        left++;
      }
    }
    return order;
  };

  const snail = generateSnail(rows, cols).slice(0, state.boardSize);

  const last = snail[snail.length - 1];

  const renderCell = (index: number) => {
    const playersHere = state.players.filter(
      p => p.position === index && !p.eliminated,
    );
    const isHole = state.holes.includes(index);
    return (
      <Cell key={index} hasHole={isHole}>
        {playersHere.map(p => (
          <Rabbit key={p.id} color={p.id === 0 ? '#ff0000' : '#0000ff'} />
        ))}
        {index === last && <Text style={{ fontSize: 24 }}>🥕</Text>}
      </Cell>
    );
  };

  // Build an array of cells to render.
  const cells: JSX.Element[] = [];
  for (const idx of snail) {
    cells.push(renderCell(idx));
  }

  return <View style={styles.container}>{cells}</View>;
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    width: 5 * 50,
  },
});
