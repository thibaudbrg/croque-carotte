// Small component representing a rabbit token.
import React from 'react';
import { Text, StyleSheet } from 'react-native';

interface Props {
  color: string;
}

export function Rabbit({ color }: Props) {
  return <Text style={[styles.rabbit, { color }]}>{'\uD83D\uDC30'}</Text>;
}

const styles = StyleSheet.create({
  rabbit: {
    fontSize: 20,
  },
});
