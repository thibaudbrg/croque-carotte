// Small component representing a rabbit token.
import React from 'react';
import { View, StyleSheet } from 'react-native';

interface Props {
  color: string;
}

export function Rabbit({ color }: Props) {
  return <View style={[styles.rabbit, { backgroundColor: color }]} />;
}

const styles = StyleSheet.create({
  rabbit: {
    width: 20,
    height: 20,
    borderRadius: 10,
  },
});
