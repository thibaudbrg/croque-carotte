import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:croque_carotte/features/menu/main_menu_screen.dart';
import 'package:croque_carotte/core/language_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();
  
  runApp(
    ProviderScope(
      child: provider.ChangeNotifierProvider.value(
        value: languageManager,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return MaterialApp(
          title: 'Croque Carotte',
          locale: languageManager.currentLocale,
          localizationsDelegates: [
            languageManager.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('fr', 'FR'),
          ],
          theme: ThemeData(
            primarySwatch: Colors.orange,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const MainMenuScreen(),
        );
      },
    );
  }
}
