import React, { useState } from 'react';
import { SafeAreaView, View, Text, Button, StyleSheet } from 'react-native';
import { Game } from './src/game/Game';
import { CardType } from './src/game/types';
import { Board } from './src/components/Board';

const game = new Game();

export default function App() {
  const [state, setState] = useState(game.state);
  const [lastCard, setLastCard] = useState<CardType | null>(null);
  const [winner, setWinner] = useState<string | null>(null);

  const handleTurn = () => {
    const result = game.takeTurn();
    setState({ ...game.state });
    setLastCard(result.card);
    if (result.winner) {
      setWinner(result.winner.name);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Croque Carotte</Text>
      <Board state={state} />
      {state.players.map(p => (
        <Text key={p.id} style={styles.text}>
          {p.name}: {p.lives} lives {p.eliminated ? '(eliminated)' : ''}
        </Text>
      ))}
      {lastCard && <Text style={styles.text}>Last card: {lastCard}</Text>}
      {winner ? (
        <Text style={styles.text}>Winner: {winner}</Text>
      ) : (
        <Button title="Next turn" onPress={handleTurn} />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 24,
    marginBottom: 20,
  },
  text: {
    marginTop: 10,
  },
});
