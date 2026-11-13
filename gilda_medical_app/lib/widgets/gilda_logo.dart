import 'package:flutter/material.dart';

class GildaLogo extends StatelessWidget {
  final double size;
  const GildaLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF2ECC71)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_pharmacy, color: Colors.white, size: size * 0.42),
          Text('GM', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.18,
            letterSpacing: 1,
          )),
        ]),
      ),
    );
  }
}
