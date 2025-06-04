// Visual representation of a single board cell.
import React from 'react';
import { View, StyleSheet } from 'react-native';

interface Props {
  hasHole: boolean;
  children?: React.ReactNode;
}

/**
 * Single cell on the board.
 */
export function Cell({ hasHole, children }: Props) {
  return (
    <View style={[styles.cell, hasHole && styles.hole]}> {children} </View>
  );
}

const styles = StyleSheet.create({
  cell: {
    width: 50,
    height: 50,
    borderWidth: 1,
    borderColor: '#333',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#a1d99b',
  },
  hole: {
    backgroundColor: '#654321',
  },
});
