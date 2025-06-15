import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:croque_carotte/core/localization.dart';

class LanguageManager extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  SupportedLanguage _currentLanguage = SupportedLanguage.english;
  
  SupportedLanguage get currentLanguage => _currentLanguage;
  
  Locale get currentLocale {
    switch (_currentLanguage) {
      case SupportedLanguage.french:
        return const Locale('fr', 'FR');
      case SupportedLanguage.english:
        return const Locale('en', 'US');
    }
  }

  AppLocalizationsDelegate get delegate => AppLocalizationsDelegate(_currentLanguage);

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _currentLanguage = languageCode == 'fr' 
        ? SupportedLanguage.french 
        : SupportedLanguage.english;
    notifyListeners();
  }

  Future<void> changeLanguage(SupportedLanguage language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language == SupportedLanguage.french ? 'fr' : 'en');
      notifyListeners();
    }
  }

  Future<void> showLanguageDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.selectLanguage),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(localizations.english),
                    leading: Radio<SupportedLanguage>(
                      value: SupportedLanguage.english,
                      groupValue: _currentLanguage,
                      onChanged: (SupportedLanguage? value) {
                        if (value != null) {
                          changeLanguage(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    onTap: () {
                      changeLanguage(SupportedLanguage.english);
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: Text(localizations.french),
                    leading: Radio<SupportedLanguage>(
                      value: SupportedLanguage.french,
                      groupValue: _currentLanguage,
                      onChanged: (SupportedLanguage? value) {
                        if (value != null) {
                          changeLanguage(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    onTap: () {
                      changeLanguage(SupportedLanguage.french);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(localizations.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
