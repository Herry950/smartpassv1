import 'package:flutter/material.dart';

class StudentCard3D extends StatefulWidget {
  final Widget child;

  const StudentCard3D({
    super.key,
    required this.child,
  });

  @override
  State<StudentCard3D> createState() => _StudentCard3DState();
}

class _StudentCard3DState extends State<StudentCard3D> {
  double rotateX = 0;
  double rotateY = 0;

  double lightX = .5;
  double lightY = .5;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);

        final dx = (local.dx / box.size.width) - .5;
        final dy = (local.dy / box.size.height) - .5;

        setState(() {
          rotateY = dx * .18;
          rotateX = -dy * .18;

          lightX = local.dx / box.size.width;
          lightY = local.dy / box.size.height;
        });
      },
      onExit: (_) {
        setState(() {
          rotateX = 0;
          rotateY = 0;
          lightX = .5;
          lightY = .5;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..translate(
            rotateY * 10,
            rotateX * 10,
            0,
          )
          ..rotateX(rotateX)
          ..rotateY(rotateY),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              right: -6,
              top: 8,
              bottom: -8,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black.withValues(alpha: .12),
                ),
              ),
            ),

            widget.child,

            IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Align(
                  alignment: Alignment(
                    (lightX * 2) - 1,
                    (lightY * 2) - 1,
                  ),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: .22),
                          Colors.white.withValues(alpha: .05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}