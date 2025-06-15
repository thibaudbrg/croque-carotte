import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import 'package:croque_carotte/features/gameboard/gameboard_screen.dart';
import 'package:croque_carotte/widgets/menu_button_widget.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[100], // A light, playful background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Croque Carotte',
              style: TextStyle(
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
                fontFamily: 'Comic Sans MS', // A playful font, consider adding a custom one later
              ),
            ),
            const SizedBox(height: 60),
            MenuButtonWidget(
              text: 'Play',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameBoardScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            MenuButtonWidget(
              text: 'Quit',
              onPressed: () {
                // This will close the app on Android.
                // On iOS, apps are usually not closed programmatically.
                SystemNavigator.pop();
              },
              backgroundColor: Colors.red[400],
            ),
          ],
        ),
      ),
    );
  }
}
