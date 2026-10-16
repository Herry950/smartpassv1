import 'package:flutter/material.dart';

import 'package:myprojectflut/core/services/auth_service.dart';//pour jwt
import '../widgets/access_validation_card.dart';
import '../widgets/assistant_header.dart';
import '../widgets/assistant_search_card.dart';
import '../widgets/payment_validation_card.dart';
import '../widgets/student_result_card.dart';

class AssistantDashboardPage extends StatelessWidget {
  const AssistantDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    debugPrint(//about jwt
  'Session Supabase active : ${AuthService.hasActiveSession()}',
);//about jwt

    final bool isDesktop = width >= 1100;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Assistant"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1300,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const AssistantHeader(
                  assistantName: "Jean Assistant",
                ),
                //about jwt
const SizedBox(height: 16),

ElevatedButton.icon(
  onPressed: () async {
    await AuthService.testReceiptVerification();
  },
  icon: const Icon(Icons.verified_outlined),
  label: const Text('Tester le reçu SP-2026-000003'),
),//jwt

                const SizedBox(height: 24),

                if (isDesktop)
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 2,
                        child: AssistantSearchCard(),
                      ),

                      const SizedBox(width: 24),

                      Expanded(
                        flex: 3,
                        child: Column(
                          children: const [
                            StudentResultCard(),

                            SizedBox(height: 24),

                            PaymentValidationCard(),

                            SizedBox(height: 24),

                            AccessValidationCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Column(
                    children: [
                      AssistantSearchCard(),

                      SizedBox(height: 24),

                      StudentResultCard(),

                      SizedBox(height: 24),

                      PaymentValidationCard(),

                      SizedBox(height: 24),

                      AccessValidationCard(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}