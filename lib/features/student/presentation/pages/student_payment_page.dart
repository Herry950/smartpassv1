import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
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

/// Paiement des frais d'examen.
///
/// L'étudiant choisit parmi les sessions OUVERTES aux paiements qui le
/// concernent (filtrage RLS : faculté, année académique, promotion).
/// Les sessions déjà payées et validées ne sont pas proposées. Le serveur
/// (create-payment) reste seul juge : session ouverte, éligibilité,
/// unicité du paiement et du paiement en attente.
class StudentPaymentPage extends StatefulWidget {
  const StudentPaymentPage({super.key});

  @override
  State<StudentPaymentPage> createState() => _StudentPaymentPageState();
}

class _StudentPaymentPageState extends State<StudentPaymentPage> {
  String selectedMethod = PaymentMethodCard.visaMethod;

  bool isLoading = false;
  bool loadingPage = true;
  String? loadError;

  List<Map<String, dynamic>> _openSessions = [];
  Map<String, Set<String>> _statuses = {};
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    loadExamSessions();
  }

  Future<void> loadExamSessions() async {
    setState(() {
      loadingPage = true;
      loadError = null;
    });

    try {
      final studentId = await AuthService.getStudentId();

      if (studentId == null) {
        throw const PaymentRemoteException(
          message: 'Profil étudiant introuvable.',
        );
      }

      final results = await Future.wait<dynamic>([
        ExamSessionRepository.getOpenExamSessions(),
        ExamSessionRepository.getPaymentStatusesBySession(studentId),
      ]);

      if (!mounted) return;

      final sessions = results[0] as List<Map<String, dynamic>>;
      final statuses = results[1] as Map<String, Set<String>>;

      final payable = sessions
          .where((s) => !(statuses[s['id'].toString()] ?? const <String>{})
              .contains('validated'))
          .toList();

      setState(() {
        _openSessions = sessions;
        _statuses = statuses;
        _selectedSessionId = payable.any(
          (s) => s['id'].toString() == _selectedSessionId,
        )
            ? _selectedSessionId
            : (payable.isEmpty ? null : payable.first['id'].toString());
        loadingPage = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingPage = false;
        loadError = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _payableSessions => _openSessions
      .where((s) => !_isPaid(s['id'].toString()))
      .toList();

  bool _isPaid(String sessionId) =>
      (_statuses[sessionId] ?? const <String>{}).contains('validated');

  bool _isPending(String sessionId) =>
      (_statuses[sessionId] ?? const <String>{}).contains('pending');

  Map<String, dynamic>? get _selectedSession {
    for (final session in _payableSessions) {
      if (session['id'].toString() == _selectedSessionId) return session;
    }
    return null;
  }

  String _sessionLabel(Map<String, dynamic> session) {
    final year = session['academic_years'];
    return [
      session['session_name']?.toString(),
      session['semester']?.toString(),
      year is Map ? year['name']?.toString() : null,
    ].whereType<String>().join(' — ');
  }

  Future<void> _startPayment() async {
    final examSession = _selectedSession;

    if (isLoading || examSession == null) return;

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
        examSessionId: examSession['id'].toString(),
        email: email,
        paymentMethod: selectedMethod,
        redirectUrl: Uri.base.resolve('/student/payment-result').toString(),
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

      // Sur le web, la page de paiement Flutterwave s'ouvre dans le même
      // onglet : après le paiement, Flutterwave redirige l'étudiant vers
      // /student/payment-result dans SmartPass.
      final opened = await launchUrl(
        uri,
        webOnlyWindowName: '_self',
        mode: LaunchMode.platformDefault,
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

      // Les statuts ont pu changer côté serveur.
      await loadExamSessions();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: loadingPage ? null : loadExamSessions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (loadingPage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return _buildMessage(
        icon: Icons.error_outline_rounded,
        title: 'Chargement impossible',
        message: loadError!,
      );
    }

    if (_openSessions.isEmpty) {
      return _buildMessage(
        icon: Icons.event_busy_rounded,
        title: "Aucune session d'examen disponible.",
        message: 'Aucune session ouverte aux paiements ne concerne '
            'actuellement votre faculté, votre année et votre promotion.',
      );
    }

    final examSession = _selectedSession;

    if (examSession == null) {
      return _buildMessage(
        icon: Icons.verified_rounded,
        title: 'Toutes vos sessions sont payées',
        message: 'Les paiements des sessions actuellement ouvertes sont '
            'déjà validés. Vos reçus sont disponibles dans « Mes reçus ».',
      );
    }

    final sessionId = examSession['id'].toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              const PaymentHeader(),
              const SizedBox(height: 22),
              _buildSessionSelector(),
              const SizedBox(height: 22),
              PaymentAmountCard(
                amount: examSession['fee_amount'].toString(),
                currency: examSession['currency'] ?? 'USD',
              ),
              const SizedBox(height: 22),
              PaymentReasonCard(
                reason: 'Accès aux examens',
                session: examSession['session_name'] ?? '--',
                semester: examSession['semester'] ?? '--',
                academicYear:
                    examSession['academic_years']?['name'] ?? '--',
              ),
              if (_isPending(sessionId)) ...[
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: .3),
                    ),
                  ),
                  child: Text(
                    'Une tentative de paiement est en attente de '
                    'confirmation pour cette session. Si vous avez été '
                    'débité, attendez la confirmation ; sinon, elle '
                    'expirera automatiquement après 15 minutes.',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
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
                paymentOpen: examSession['payment_open'] ?? false,
                isLoading: isLoading,
                onPressed: _startPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSelector() {
    final payable = _payableSessions;
    final paidCount = _openSessions.length - payable.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session à payer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedSessionId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.event_note_rounded),
            ),
            items: payable
                .map(
                  (s) => DropdownMenuItem<String>(
                    value: s['id'].toString(),
                    child: Text(
                      _sessionLabel(s),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: isLoading
                ? null
                : (value) => setState(() => _selectedSessionId = value),
          ),
          if (paidCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              '$paidCount session(s) ouverte(s) déjà payée(s) : '
              'non proposée(s).',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppColors.primary),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: loadExamSessions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
