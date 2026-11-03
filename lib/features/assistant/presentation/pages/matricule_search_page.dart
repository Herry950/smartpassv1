import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/services/student_search_service.dart';

class MatriculeSearchPage extends StatefulWidget {
  const MatriculeSearchPage({super.key});

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
  void dispose() {
    _controller.dispose();
    super.dispose();
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

      if (result == null) {
        setState(() {
          _errorMessage =
              'Aucun étudiant trouvé avec le matricule : $matricule';
        });
      } else {
        setState(() {
          _searchResult = result;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Impossible de rechercher cet étudiant. '
            'Vérifiez la connexion et les autorisations.';
      });

      debugPrint('Erreur de recherche par matricule : $e');
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
        title: const Text('Recherche par Matricule'),
        centerTitle: true,
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

                if (student is Map<String, dynamic>)
                  _buildStudentCard(student, payments),
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
              prefixIcon: const Icon(
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
                      style: const TextStyle(
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
                        style: const TextStyle(
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
                      style: const TextStyle(
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

          const Text(
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

          const Text(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Montant : $amount $currency',
                  style: const TextStyle(
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
      child: const Row(
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
          const Text(
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
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