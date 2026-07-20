import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myprojectflut/shared/widgets/app_bar_actions.dart';
import 'package:myprojectflut/shared/widgets/smart_logo.dart';

class SmartAppBar extends StatefulWidget {
  const SmartAppBar({super.key});

  @override
  State<SmartAppBar> createState() => _SmartAppBarState();
}

class _SmartAppBarState extends State<SmartAppBar> {
  bool menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: 20,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12,
                sigmaY: 12,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .80),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .55),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 25,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const SmartLogo(size: 45),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              "SmartPass",
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isDesktop) ...[
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text("Accueil"),
                      ),
                      TextButton(
                        onPressed: () => context.go('/roles'),
                        child: const Text("Connexion"),
                      ),
                      const SizedBox(width: 12),
                      const AppBarActions(),
                    ] else
                      IconButton(
                        onPressed: () {
                          setState(() {
                            menuOpen = !menuOpen;
                          });
                        },
                        icon: Icon(
                          menuOpen
                              ? Icons.close_rounded
                              : Icons.menu_rounded,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: !isDesktop && menuOpen
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.home_rounded),
                        title: const Text("Accueil"),
                        onTap: () {
                          context.go('/');
                          setState(() => menuOpen = false);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.login_rounded),
                        title: const Text("Connexion"),
                        onTap: () {
                          context.go('/roles');
                          setState(() => menuOpen = false);
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}