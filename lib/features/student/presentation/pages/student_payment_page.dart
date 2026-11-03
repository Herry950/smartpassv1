import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/feedback/smartpass_feedback.dart';
import '../../../../core/feedback/smartpass_messages.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/datasource/payment_remote_datasource.dart';
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

class _StudentPaymentPageState extends State<StudentPaymentPage> {
  String selectedMethod = 'Orange';

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

  Future<void> _startPayment() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = AuthService.currentUser;

      if (user == null) {
        throw const PaymentRemoteException(
          message: 'Utilisateur non connecté.',
        );
      }

      final email = user.email;

      if (email == null || email.isEmpty) {
        throw const PaymentRemoteException(
          message:
              'Aucune adresse e-mail trouvée pour cet utilisateur.',
        );
      }

      final checkoutUrl = await PaymentRepository.createPayment(
        examSessionId: examSession!['id'].toString(),
        email: email,
        paymentMethod: selectedMethod,
      );

      if (!mounted) return;

      final uri = Uri.tryParse(checkoutUrl);

      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        throw const PaymentRemoteException(
          message: 'Le lien de paiement reçu est invalide.',
        );
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw const PaymentRemoteException(
          message:
              'Impossible d’ouvrir le lien de paiement. '
              'Veuillez réessayer.',
        );
      }
    } on PaymentRemoteException catch (e) {
      if (!mounted) return;

      switch (e.code) {
        case 'PAYMENT_ALREADY_EXISTS':
          await SmartPassFeedback.showDialogMessage(
            context,
            code: SmartPassMessageCode.paymentAlreadyValidated,
            role: SmartPassRole.student,
          );
          break;

        case 'PAYMENT_PENDING':
          await SmartPassFeedback.showDialogMessage(
            context,
            code: SmartPassMessageCode.paymentPending,
            role: SmartPassRole.student,
          );
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de démarrer le paiement. '
            'Veuillez réessayer. Détail : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
        title: const Text('Paiement'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const PaymentHeader(),
              const SizedBox(height: 22),

              PaymentAmountCard(
                amount: examSession!['fee_amount'].toString(),
                currency: examSession!['currency'] ?? 'USD',
              ),

              const SizedBox(height: 22),

              PaymentReasonCard(
                reason: 'Accès aux examens',
                session: examSession!['session_name'] ?? '--',
                semester: examSession!['semester'] ?? '--',
                academicYear:
                    examSession!['academic_years']?['name'] ?? '--',
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
                    examSession!['payment_open'] ?? false,
                isLoading: isLoading,
                onPressed: _startPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}