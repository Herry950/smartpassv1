import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/services/student_search_service.dart';

import '../widgets/access_control_section.dart';

class MatriculeSearchPage extends StatefulWidget {
  /// Matricule à rechercher immédiatement (ex. issu du QR de la carte).
  final String? initialMatricule;

  /// Identifiant attendu (QR de la carte) : l'étudiant trouvé doit
  /// correspondre exactement à la carte scannée.
  final String? expectedStudentId;

  const MatriculeSearchPage({
    super.key,
    this.initialMatricule,
    this.expectedStudentId,
  });

  @override
  State<MatriculeSearchPage> createState() => _MatriculeSearchPageState();
}

class _MatriculeSearchPageState extends State<MatriculeSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final StudentSearchService _searchService = StudentSearchService();

  bool _isLoading = false;
  Map<String, dynamic>? _searchResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialMatricule?.trim();

    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extrait et prépare le message d'erreur pour l'affichage.
  ///
  /// Le service StudentSearchService est responsable des erreurs
  /// liées au compte assistant. Cette page ne refait pas ces contrôles.
  String _extractErrorMessage(Object error) {
    String? message;

    // Récupération du message original des exceptions Supabase.
    try {
      final dynamic exception = error;
      final dynamic rawMessage = exception.message;

      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage.trim();
      }
    } catch (_) {
      // Certaines exceptions ne possèdent pas de propriété message.
    }

    message ??= error.toString().trim();

    final normalized = message.toLowerCase();

    // Erreurs générales d'autorisation.
    if (normalized.contains('permission denied') ||
        normalized.contains('not authorized') ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden')) {
      return 'Accès refusé : vous ne disposez pas des autorisations '
          'nécessaires pour effectuer cette opération.';
    }

    // Erreurs de connexion.
    if (normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('connection refused') ||
        normalized.contains('clientexception')) {
      return 'Impossible de contacter le serveur. '
          'Vérifiez votre connexion Internet et réessayez.';
    }

    // Suppression des préfixes habituels des exceptions Dart.
    message = message
        .replaceFirst(
          RegExp(r'^Exception:\s*', caseSensitive: false),
          '',
        )
        .replaceFirst(
          RegExp(r'^Error:\s*', caseSensitive: false),
          '',
        )
        .trim();

    if (message.isEmpty ||
        message == 'Exception' ||
        message == 'Error') {
      return 'Une erreur inattendue est survenue pendant la recherche. '
          'Veuillez réessayer.';
    }

    // Les messages métier du service sont conservés tels quels.
    return message;
  }

  /// Relance la dernière recherche avec le matricule déjà saisi.
  Future<void> _refreshSearch() async {
    await _performSearch();
  }

  Future<void> _performSearch() async {
    final matricule = _controller.text.trim();

    if (matricule.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir le matricule de l’étudiant.';
        _searchResult = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      final result =
          await _searchService.searchStudentByMatricule(matricule);

      if (!mounted) return;

      final expectedId = widget.expectedStudentId;
      final foundStudent = result?['student'];

      if (result == null) {
        setState(() {
          _errorMessage =
              'Aucun étudiant trouvé avec le matricule : $matricule';
        });
      } else if (expectedId != null &&
          matricule == widget.initialMatricule?.trim() &&
          (foundStudent is! Map || foundStudent['id'] != expectedId)) {
        // Le QR code ne correspond pas à l'étudiant enregistré :
        // carte falsifiée ou obsolète.
        setState(() {
          _errorMessage =
              'QR code non conforme : la carte scannée ne correspond pas '
              'à l’étudiant enregistré sous ce matricule. Accès refusé.';
        });
      } else {
        setState(() {
          _searchResult = result;
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      final extractedMessage = _extractErrorMessage(e);

      debugPrint('========== ERREUR RECHERCHE MATRICULE ==========');
      debugPrint('Erreur originale : $e');
      debugPrint('Message affiché : $extractedMessage');
      debugPrintStack(stackTrace: stackTrace);

      setState(() {
        _errorMessage = extractedMessage;
        _searchResult = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _searchResult?['student'];

    final payments =
        _searchResult?['payments'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Retour à la page précédente',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
              )
            : null,
        title: const Text('Recherche par Matricule'),
        centerTitle: true,
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser la recherche',
            onPressed: _isLoading ? null : _refreshSearch,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchCard(),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  _buildErrorMessage(_errorMessage!),
                  const SizedBox(height: 16),
                ],

                if (student is Map<String, dynamic>) ...[
                  _buildStudentCard(student, payments),
                  const SizedBox(height: 20),
                  AccessControlSection(
                    studentId: student['id'].toString(),
                    payments: payments,
                    searchService: _searchService,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              labelText: 'Matricule de l’étudiant (ULPGL)',
              hintText: 'Ex. : 21007',
              prefixIcon: Icon(
                Icons.badge_outlined,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _performSearch,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(
              _isLoading ? 'Recherche en cours...' : 'Vérifier l’étudiant',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: .1);
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    Map<String, dynamic> student,
    List<dynamic> payments,
  ) {
    final fullName = (student['full_name'] ?? 'Nom non spécifié').toString();
    final photoUrl = student['photo_url']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identité de l'étudiant
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildAvatarFallback(fullName),
                        )
                      : _buildAvatarFallback(fullName),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Matricule : ${student['matricule'] ?? 'N/A'}',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Année académique : '
                      '${student['academic_year'] ?? 'N/A'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          Text(
            'Informations académiques ULPGL',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.school_outlined,
                  label: 'Faculté',
                  value: (student['faculty'] ?? 'N/A').toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.account_tree_outlined,
                  label: 'Département',
                  value: (student['department'] ?? 'N/A').toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildInfoTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Promotion',
            value: (student['promotion'] ?? 'N/A').toString(),
          ),

          const Divider(height: 32),

          Text(
            'Paiements et sessions d’examen',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (payments.isEmpty)
            _buildNoPaymentsMessage()
          else
            ...payments.map((payment) {
              if (payment is! Map) {
                return const SizedBox.shrink();
              }

              return _buildPaymentItem(
                Map<String, dynamic>.from(payment),
              );
            }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: .1);
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final rawSession = payment['exam_sessions'];

    final Map<String, dynamic>? session = rawSession is Map
        ? Map<String, dynamic>.from(rawSession)
        : null;

    final status =
        (payment['status'] ?? '').toString().trim().toLowerCase();

    final isPaid = status == 'validated' || status == 'completed';

    final paymentLabel = switch (status) {
      'validated' => 'Paiement validé',
      'completed' => 'Paiement confirmé',
      'pending' => 'En attente',
      'failed' => 'Échec du paiement',
      'cancelled' => 'Paiement annulé',
      _ => 'Non confirmé',
    };

    final amount = payment['amount'] ?? 0;
    final currency = payment['currency'] ?? 'USD';
    final sessionName =
        (session?['session_name'] ?? 'Session inconnue').toString();

    final Color statusColor =
        isPaid ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPaid ? Icons.receipt_long_outlined : Icons.pending_outlined,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Montant : $amount $currency',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  paymentLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPaymentsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucun paiement enregistré pour cet étudiant.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String? fullName) {
    final name = fullName?.trim() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sans photo',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}