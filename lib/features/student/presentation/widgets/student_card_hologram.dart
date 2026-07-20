import 'package:flutter/material.dart';

class StudentCardHologram extends StatelessWidget {
  const StudentCardHologram({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6EF3FF),
            Color(0xFF7E7BFF),
            Color(0xFFFF7BC9),
            Color(0xFFFFE27A),
            Color(0xFF6EF3FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: .25),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            /// Halo
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .18),
                ),
              ),
            ),

            /// Reflet diagonal
            Positioned(
              left: -10,
              top: -6,
              child: Transform.rotate(
                angle: -.55,
                child: Container(
                  width: 22,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: .55),
                        Colors.white.withValues(alpha: .02),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// Anneau
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .55),
                    width: 1.4,
                  ),
                ),
              ),
            ),

            /// Logo
            const Center(
              child: Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),

            /// Signature
            Positioned(
              bottom: 4,
              right: 6,
              child: Text(
                "SP",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}