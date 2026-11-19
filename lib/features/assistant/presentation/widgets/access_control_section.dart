import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/services/student_search_service.dart';

/// Contrôle d'accès aux examens pour l'étudiant vérifié.
///
/// Pour chaque session à laquelle l'assistant est affecté, le résultat
/// découle du paiement : accès autorisé uniquement si un paiement validé
/// existe pour cette session. Le contrôle est enregistré dans access_logs ;
/// la politique RLS (can_assistant_record_access) vérifie l'affectation,
/// la faculté, l'année académique et la promotion ciblée.
class AccessControlSection extends StatefulWidget {
  const AccessControlSection({
    super.key,
    required this.studentId,
    required this.payments,
    required this.searchService,
  });

  final String studentId;
  final List<dynamic> payments;
  final StudentSearchService searchService;

  @override
  State<AccessControlSection> createState() => _AccessControlSectionState();
}

class _AccessControlSectionState extends State<AccessControlSection> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sessions = [];
  final Set<String> _saving = {};
  final Map<String, bool> _recorded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AccessControlSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      _recorded.clear();
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessions = await widget.searchService.getAssignedSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Paiement validé de la session, ou d'une session archivée remplacée
  /// par celle-ci (même obligation, historique conservé).
  bool _hasValidatedPayment(String sessionId) {
    return widget.payments.any((p) {
      if (p is! Map || p['status'] != 'validated') return false;
      if (p['exam_session_id'] == sessionId) return true;
      final session = p['exam_sessions'];
      return session is Map &&
          session['replaced_by_session_id'] == sessionId;
    });
  }

  Future<void> _record(Map<String, dynamic> session) async {
    final sessionId = session['id'] as String;
    final granted = _hasValidatedPayment(sessionId);

    setState(() => _saving.add(sessionId));

    try {
      await widget.searchService.logAccessAttempt(
        studentId: widget.studentId,
        examSessionId: sessionId,
        accessGranted: granted,
        reason: granted
            ? 'Paiement validé pour la session'
            : 'Paiement non validé pour la session',
      );

      if (!mounted) return;

      setState(() => _recorded[sessionId] = granted);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: granted ? AppColors.success : AppColors.error,
          content: Text(
            granted
                ? 'Contrôle enregistré : accès autorisé.'
                : 'Contrôle enregistré : accès refusé (paiement non validé).',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      final rlsDenied = e.code == '42501' ||
          e.message.toLowerCase().contains('row-level security');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            rlsDenied
                ? 'Cet étudiant n’est pas concerné par cette session '
                    '(faculté, année académique ou promotion non ciblée).'
                : 'Enregistrement impossible : ${e.message}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving.remove(sessionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contrôle d’accès aux examens',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sessions auxquelles vous êtes affecté. Le résultat dépend '
            'uniquement du paiement validé de la session.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error))
          else if (_sessions.isEmpty)
            Text(
              'Vous n’êtes affecté à aucune session. '
              'Contactez l’administration de votre faculté.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ..._sessions.map(_buildSessionTile),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final sessionId = session['id'] as String;
    final paid = _hasValidatedPayment(sessionId);
    final recorded = _recorded[sessionId];
    final saving = _saving.contains(sessionId);

    final year = session['academic_years'];
    final label = [
      session['session_name']?.toString(),
      session['semester']?.toString(),
      year is Map ? year['name']?.toString() : null,
    ].whereType<String>().join(' • ');

    final color = paid ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 420),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  paid ? Icons.check_circle_rounded : Icons.block_rounded,
                  color: color,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        paid
                            ? 'ACCÈS AUTORISÉ — paiement validé'
                            : 'ACCÈS REFUSÉ — paiement non validé',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (recorded != null)
            Text(
              'Contrôle enregistré',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: saving ? null : () => _record(session),
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Enregistrer le contrôle'),
            ),
        ],
      ),
    );
  }
}
