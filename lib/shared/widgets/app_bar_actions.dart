import 'package:flutter/material.dart';

class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined),
        ),

        const SizedBox(width: 8),

        const CircleAvatar(
          radius: 18,
          child: Icon(Icons.person_rounded),
        ),
      ],
    );
  }
}