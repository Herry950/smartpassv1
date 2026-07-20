import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:myprojectflut/shared/components/feature_card.dart';
import 'package:myprojectflut/shared/widgets/smart_app_bar.dart';
import 'package:myprojectflut/shared/widgets/smart_hero_image.dart';
import 'package:myprojectflut/shared/widgets/smart_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SmartAppBar(),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    isDesktop
                        ? Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SmartLogo(
                                      size: 90,
                                    )
                                        .animate()
                                        .fadeIn()
                                        .scale(),

                                    const SizedBox(height: 30),

                                    Text(
                                      "SmartPass",
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium,
                                    )
                                        .animate()
                                        .fadeIn(delay: 200.ms)
                                        .slideX(),

                                    const SizedBox(height: 16),

                                    Text(
                                      "La plateforme intelligente de gestion "
                                      "des accès aux examens universitaires.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ).animate().fadeIn(delay: 400.ms),

                                    const SizedBox(height: 30),

                                    SizedBox(
                                      width: 250,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.go('/login');
                                        },
                                        child: const Text(
                                          "Commencer",
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 600.ms),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 60),

                              const Expanded(
                                child: Center(
                                  child: SmartHeroImage(),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .slideX(begin: 0.3),
                            ],
                          )
                        : Column(
                            children: [
                              const SmartLogo(size: 90),

                              const SizedBox(height: 24),

                              Text(
                                "SmartPass",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium,
                              ),

                              const SizedBox(height: 16),

                              Text(
                                "La plateforme intelligente de gestion "
                                "des accès aux examens universitaires.",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge,
                              ),

                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.go('/login');
                                  },
                                  child: const Text(
                                    "Commencer",
                                  ),
                                ),
                              ),
                            ],
                          ),

                    const SizedBox(height: 70),

                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: const [
                        FeatureCard(
                          icon: Icons.security_rounded,
                          title: "Sécurité",
                          description:
                              "Validation fiable des accès aux examens.",
                        ),
                        FeatureCard(
                          icon: Icons.qr_code_rounded,
                          title: "Carte numérique",
                          description:
                              "Une carte étudiante avec QR Code sécurisé.",
                        ),
                        FeatureCard(
                          icon: Icons.verified_rounded,
                          title: "Contrôle rapide",
                          description:
                              "Scan QR ou recherche par matricule.",
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .slideY(begin: 0.2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}