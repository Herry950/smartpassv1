import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../widgets/payment_amount_card.dart';
import '../widgets/payment_button.dart';
import '../widgets/payment_header.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/payment_reason_card.dart';

class StudentPaymentPage extends StatefulWidget {
  const StudentPaymentPage({super.key});

  @override
  State<StudentPaymentPage> createState() =>
      _StudentPaymentPageState();
}

class _StudentPaymentPageState
    extends State<StudentPaymentPage> {
  // Option par défaut alignée sur les choix disponibles
  String selectedMethod = "Orange";

  bool isLoading = false;
  bool loadingPage = true;

  Map<String, dynamic>? examSession;

  @override
  void initState() {
    super.initState();
    loadExamSession();
  }

  Future<void> loadExamSession() async {
    try {
      final session =
          await ExamSessionRepository.getCurrentExamSession();

      if (!mounted) return;

      setState(() {
        examSession = session;
        loadingPage = false;
      });
    } catch (e) {
      if (!mounted) return; 

      setState(() {
        loadingPage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingPage) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (examSession == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Aucune session d'examen disponible.",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const PaymentHeader(),

              const SizedBox(height: 22),

              PaymentAmountCard(
                amount: examSession!["fee_amount"].toString(),
                currency: examSession!["currency"] ?? "USD",
              ),

              const SizedBox(height: 22),

              PaymentReasonCard(
                reason: "Accès aux examens",
                session: examSession!["session_name"] ?? "--",
                semester: examSession!["semester"] ?? "--",
                academicYear:
                    examSession!["academic_years"]?["name"] ?? "--",
              ),

              const SizedBox(height: 22),

              PaymentMethodCard(
                selectedMethod: selectedMethod,
                onChanged: (value) {
                  setState(() {
                    selectedMethod = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              PaymentButton(
                paymentOpen:
                    examSession!["payment_open"] ?? false,
                isLoading: isLoading,
                onPressed: () async {
                  print("1");
                  setState(() {
                    isLoading = true;
                  });
                  print("2");
                  try {
                    final user = AuthService.currentUser;
                    print("3");
                    if (user == null) {
                      throw Exception(
                        "Utilisateur non connecté.",
                      );
                    }

                    final email = user.email;
                    print("4");
                    if (email == null || email.isEmpty) {
                      throw Exception(
                        "Aucune adresse e-mail trouvée pour cet utilisateur.",
                      );
                    }

                    final checkoutUrl =
                        await PaymentRepository.createPayment(
                      examSessionId: examSession!["id"],
                      email: email,
                      paymentMethod: selectedMethod, // <-- Transmission du moyen de paiement choisi
                    );
                    print("5 : $checkoutUrl");
                    if (!mounted) return;

                    final uri = Uri.parse(checkoutUrl);

                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      throw Exception(
                        "Impossible d'ouvrir le lien de paiement : $checkoutUrl",
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}