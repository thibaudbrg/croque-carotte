# croque-carotte

This repository contains a simple cross-platform implementation of the classic
"Croque Carotte" board game. The game is written in **React Native** with
**TypeScript** so it can be easily executed on both iOS and Android devices
(using [Expo](https://expo.dev)). This project targets **Expo SDK&nbsp;53**, so
make sure your Expo CLI and Expo Go app are up to date.

## Running the app

1. Install dependencies:
   ```bash
   npm install
   ```
2. Ensure you have the Expo CLI installed (or run it with `npx`):
   ```bash
   npm install -g expo-cli # optional
   ```
3. Start the Expo development server:
   ```bash
   npx expo start
   ```
4. Use the Expo Go app on your iOS or Android device (or a simulator) to run
   the game.

### Troubleshooting

If you see a `TypeScript: A tsconfig.json has been auto-generated` message the
first time you run `expo start`, it's because the repository did not include a
`tsconfig.json`. One has now been added. If the message persists you can safely
delete the generated file and use the one provided in this repository.

On some systems the Metro bundler may fail with an `EMFILE: too many open
files` error. This usually means your OS is watching too many files. Installing
[watchman](https://facebook.github.io/watchman/) and restarting the command
generally resolves the issue. Alternatively, you can increase the allowed file
watch limit (e.g. `ulimit -n 10000` on macOS/Linux) before running `npx expo start`.

This implementation focuses on demonstrating the game logic and UI in a simple
way. The main code lives in `App.tsx` and the files under `src/`.
