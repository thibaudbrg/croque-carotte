import 'package:flutter/material.dart';

enum SupportedLanguage { english, french }

class AppLocalizations {
  final SupportedLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Game titles and buttons
  String get gameTitle => language == SupportedLanguage.french 
      ? 'Croque Carotte' 
      : 'Croque Carotte';

  String get startGame => language == SupportedLanguage.french 
      ? 'Commencer' 
      : 'Start Game';

  String get resumeGame => language == SupportedLanguage.french 
      ? 'Reprendre' 
      : 'Resume Game';

  String get changeLanguage => language == SupportedLanguage.french 
      ? 'Changer de langue' 
      : 'Change Language';

  String get quit => language == SupportedLanguage.french 
      ? 'Quitter' 
      : 'Quit';

  String get boardCalibration => language == SupportedLanguage.french 
      ? 'Calibrage du plateau' 
      : 'Board Calibration';

  // Game UI
  String get yourTurn => language == SupportedLanguage.french 
      ? 'Votre tour' 
      : 'Your Turn';

  String get botTurn => language == SupportedLanguage.french 
      ? 'Tour du Bot' 
      : 'Bot Turn';

  String get you => language == SupportedLanguage.french 
      ? 'Vous' 
      : 'You';

  String get bot => language == SupportedLanguage.french 
      ? 'Bot' 
      : 'Bot';

  String get lives => language == SupportedLanguage.french 
      ? 'Vies' 
      : 'Lives';

  String get rabbits => language == SupportedLanguage.french 
      ? 'Lapins' 
      : 'Rabbits';

  String get cardsLeft => language == SupportedLanguage.french 
      ? 'Cartes restantes' 
      : 'Cards left';

  String get yourCards => language == SupportedLanguage.french 
      ? 'Vos cartes' 
      : 'Your Cards';

  String get botCards => language == SupportedLanguage.french 
      ? 'Cartes du Bot' 
      : 'Bot Cards';

  String get discardPile => language == SupportedLanguage.french 
      ? 'Défausse' 
      : 'Discard\nPile';

  // Game actions
  String get moveWhichRabbit => language == SupportedLanguage.french 
      ? 'Déplacer quel lapin ?' 
      : 'Move which rabbit?';

  String get card => language == SupportedLanguage.french 
      ? 'Carte' 
      : 'Card';

  String get rabbit => language == SupportedLanguage.french 
      ? 'Lapin' 
      : 'Rabbit';

  String get position => language == SupportedLanguage.french 
      ? 'Position' 
      : 'Position';

  String get color => language == SupportedLanguage.french 
      ? 'Couleur' 
      : 'Color';

  String get blue => language == SupportedLanguage.french 
      ? 'Bleu' 
      : 'Blue';

  String get grey => language == SupportedLanguage.french 
      ? 'Gris' 
      : 'Grey';

  String get red => language == SupportedLanguage.french 
      ? 'Rouge' 
      : 'Red';

  String get green => language == SupportedLanguage.french 
      ? 'Vert' 
      : 'Green';

  String get yellow => language == SupportedLanguage.french 
      ? 'Jaune' 
      : 'Yellow';

  String get orange => language == SupportedLanguage.french 
      ? 'Orange' 
      : 'Orange';

  String get teal => language == SupportedLanguage.french 
      ? 'Sarcelle' 
      : 'Teal';

  String get unknown => language == SupportedLanguage.french 
      ? 'Inconnu' 
      : 'Unknown';

  String get pauseReturnToMenu => language == SupportedLanguage.french 
      ? 'Pause et retour au menu' 
      : 'Pause & Return to Menu';

  String rabbitPosition(int id, int position) => language == SupportedLanguage.french 
      ? 'Lapin $id (Position $position)' 
      : 'Rabbit $id (Position $position)';

  String rabbitColor(int id) {
    String colorName;
    switch (id) {
      case 1: colorName = language == SupportedLanguage.french ? 'Bleu' : 'Blue'; break;
      case 2: colorName = language == SupportedLanguage.french ? 'Vert' : 'Green'; break;
      case 3: colorName = language == SupportedLanguage.french ? 'Jaune' : 'Yellow'; break;
      default: colorName = language == SupportedLanguage.french ? 'Inconnu' : 'Unknown';
    }
    return language == SupportedLanguage.french ? 'Couleur: $colorName' : 'Color: $colorName';
  }

  // Dialog messages
  String get pauseGame => language == SupportedLanguage.french 
      ? 'Mettre en pause' 
      : 'Pause Game';

  String get whatWouldYouLikeToDo => language == SupportedLanguage.french 
      ? 'Que voulez-vous faire ?' 
      : 'What would you like to do?';

  String get pauseAndReturnToMenu => language == SupportedLanguage.french 
      ? 'Pause et retour au menu' 
      : 'Pause & Return to Menu';

  String get continuePlaying => language == SupportedLanguage.french 
      ? 'Continuer à jouer' 
      : 'Continue Playing';

  String get quitGame => language == SupportedLanguage.french 
      ? 'Quitter la partie' 
      : 'Quit Game';

  String get confirmQuit => language == SupportedLanguage.french 
      ? 'Êtes-vous sûr de vouloir quitter ?' 
      : 'Are you sure you want to quit?';

  String get yes => language == SupportedLanguage.french 
      ? 'Oui' 
      : 'Yes';

  String get no => language == SupportedLanguage.french 
      ? 'Non' 
      : 'No';

  String get cancel => language == SupportedLanguage.french 
      ? 'Annuler' 
      : 'Cancel';

  String get newGameWarning => language == SupportedLanguage.french 
      ? 'Attention ! Cela va supprimer la partie en cours et en commencer une nouvelle. Continuer ?' 
      : 'Warning! This will delete the current game and start a new one. Continue?';

  // Game over
  String get gameOver => language == SupportedLanguage.french 
      ? 'Partie terminée !' 
      : 'Game Over!';

  String gameWinner(String winner) => language == SupportedLanguage.french 
      ? 'Gagnant: $winner' 
      : 'Winner: $winner';

  String get returnToMenu => language == SupportedLanguage.french 
      ? 'Retour au menu' 
      : 'Return to Menu';

  String get noRabbitsAvailable => language == SupportedLanguage.french 
      ? 'Aucun lapin disponible' 
      : 'No rabbits available';

  String get cannotMove => language == SupportedLanguage.french 
      ? 'Ne peut pas bouger' 
      : 'Cannot move';

  String get skipTurn => language == SupportedLanguage.french 
      ? 'Passer le tour' 
      : 'Skip Turn';

  String get noValidMoves => language == SupportedLanguage.french 
      ? 'Aucun mouvement valide possible' 
      : 'No valid moves available';

  String get selectRabbit => language == SupportedLanguage.french 
      ? 'Sélectionner un lapin' 
      : 'Select Rabbit';

  String get drawMovementCard => language == SupportedLanguage.french 
      ? 'Tirez une carte de mouvement' 
      : 'Draw a movement card';

  // Language selection
  String get selectLanguage => language == SupportedLanguage.french 
      ? 'Choisir la langue' 
      : 'Select Language';

  String get english => 'English';
  String get french => 'Français';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final SupportedLanguage language;

  const AppLocalizationsDelegate(this.language);

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(language);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => old.language != language;
}
