import React from 'react';
import { TouchableOpacity, Text, StyleSheet } from 'react-native';

interface Props {
  onDraw: () => void;
}

export function Deck({ onDraw }: Props) {
  return (
    <TouchableOpacity style={styles.deck} onPress={onDraw}>
      <Text style={styles.emoji}>🎴</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  deck: {
    width: 60,
    height: 80,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 3,
  },
  emoji: { fontSize: 40 },
});

