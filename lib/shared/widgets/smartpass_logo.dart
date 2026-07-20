import 'package:flutter/material.dart';

class SmartPassLogo extends StatelessWidget {
  final double size;

  const SmartPassLogo({
    super.key,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        "assets/images/smartpass_logo.png",
        fit: BoxFit.contain,
      ),
    );
  }
}