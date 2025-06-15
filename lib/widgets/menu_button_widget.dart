import 'package:flutter/material.dart';

class MenuButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const MenuButtonWidget({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        textStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 5,
      ),
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: textColor ?? Colors.white)),
    );
  }
}
