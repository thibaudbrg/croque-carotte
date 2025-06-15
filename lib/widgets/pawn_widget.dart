import 'package:flutter/material.dart';

class PawnWidget extends StatelessWidget {
  final Color color;
  final double size;

  const PawnWidget({
    super.key,
    required this.color,
    this.size = 24.0, // Default size
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
    );
  }
}
