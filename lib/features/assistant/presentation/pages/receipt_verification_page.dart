import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class ReceiptVerificationPage extends StatefulWidget {
  /// Numéro de reçu à vérifier immédiatement (ex. issu d'un scan QR).
  final String? initialReceiptNumber;

  const ReceiptVerificationPage({
    super.key,
    this.initialReceiptNumber,
  });

  @override
  State<ReceiptVerificationPage> createState() =>
      _ReceiptVerificationPageState();
}

class _ReceiptVerificationPageState
    extends State<ReceiptVerificationPage> {
  final _receiptController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialReceiptNumber?.trim();

    if (initial != null && initial.isNotEmpty) {
      _receiptController.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _verifyReceipt(initial);
      });
    }
  }

  Map<String, dynamic>? _verificationResult;
  String? _errorMessage;

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  /// Recherche récursive du véritable message d'erreur.
  String? _extractMessageFromValue(
    dynamic value, {
    int depth = 0,
  }) {
    if (value == null || depth > 5) {
      return null;
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return null;
      }

      try {
        final decoded = jsonDecode(text);

        if (decoded is Map || decoded is List) {
          return _extractMessageFromValue(
            decoded,
            depth: depth + 1,
          );
        }
      } catch (_) {
        // Le contenu n'est pas nécessairement du JSON.
      }

      return text;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      const messageKeys = [
        'message',
        'error_description',
        'error',
        'details',
        'hint',
        'reason',
        'description',
      ];

      for (final key in messageKeys) {
        if (!map.containsKey(key)) {
          continue;
        }

        final extracted = _extractMessageFromValue(
          map[key],
          depth: depth + 1,
        );

        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }

      const nestedKeys = [
        'data',
        'response',
        'body',
      ];

      for (final key in nestedKeys) {
        if (!map.containsKey(key)) {
          continue;
        }

        final extracted = _extractMessageFromValue(
          map[key],
          depth: depth + 1,
        );

        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return null;
  }

  /// Détermine si le code reçu correspond à un refus d'accès.
  bool _isAccessDeniedResult(String resultCode) {
    const accessDeniedCodes = {
      'unauthorized',
      'forbidden',
      'access_denied',
      'assistant_inactive',
      'inactive_assistant',
      'assistant_not_active',
      'assistant_disabled',
      'account_inactive',
      'permission_denied',
    };

    return accessDeniedCodes.contains(
      resultCode.trim().toLowerCase(),
    );
  }

  /// Message affiché lorsque le serveur refuse l'accès.
  String get _assistantAccessDeniedMessage {
    return "Accès refusé : votre compte assistant est "
        "actuellement désactivé ou ne dispose pas des "
        "autorisations nécessaires. Veuillez contacter "
        "l’administration de votre faculté.";
  }

  /// Extraction du message renvoyé par la fonction Supabase.
  String _extractFunctionError(FunctionException error) {
    debugPrint('========== ERREUR GET-RECEIPT ==========');
    debugPrint('HTTP STATUS : ${error.status}');
    debugPrint('DETAILS : ${error.details}');
    debugPrint('REASON : ${error.reasonPhrase}');
    debugPrint('========================================');

    final detailsMessage = _extractMessageFromValue(
      error.details,
    );

    if (detailsMessage != null &&
        detailsMessage.trim().isNotEmpty) {
      return detailsMessage;
    }

    final reason = error.reasonPhrase?.trim();

    if (reason != null &&
        reason.isNotEmpty &&
        reason.toLowerCase() != 'forbidden' &&
        reason.toLowerCase() != 'unauthorized') {
      return reason;
    }

    switch (error.status) {
      case 401:
        return "Votre session a expiré. Veuillez vous reconnecter.";

      case 403:
        return _assistantAccessDeniedMessage;

      case 404:
        return "Aucun reçu correspondant à ce numéro n'a été trouvé.";

      case 500:
        return "Le serveur n'a pas pu vérifier le reçu. "
            "Veuillez réessayer ultérieurement.";

      default:
        return "La vérification a échoué "
            "(HTTP ${error.status}). "
            "Veuillez réessayer.";
    }
  }

  /// Actualise la vérification du reçu actuellement saisi.
  Future<void> _refreshVerification() async {
    if (_isLoading) return;

    final code = _receiptController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = "Saisissez un numéro de reçu avant l'actualisation.";
        _verificationResult = null;
      });
      return;
    }

    await _verifyReceipt(code);
  }

  Future<void> _verifyReceipt(String input) async {
    final code = input.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez saisir un numéro de reçu.";
        _verificationResult = null;
      });
      return;
    }

    if (!RegExp(r'^SP-\d{4}-\d{6}$').hasMatch(code)) {
      setState(() {
        _errorMessage =
            "Format invalide. Exemple : SP-2026-000006.";
        _verificationResult = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationResult = null;
    });

    try {
      final response =
          await Supabase.instance.client.functions.invoke(
        'get-receipt',
        body: {
          'receipt_number': code,
        },
      );

      final data = _asMap(response.data);

      if (data == null) {
        debugPrint(
          'GET-RECEIPT : réponse reçue : ${response.data}',
        );

        throw const FormatException(
          "Le serveur a renvoyé une réponse inexploitable.",
        );
      }

      debugPrint('========== RÉPONSE GET-RECEIPT ==========');
      debugPrint('DONNÉES : $data');
      debugPrint('========================================');

      final resultCode =
          data['result']?.toString().trim() ?? '';

      final message = _extractMessageFromValue(data) ??
          "Aucun message d'erreur fourni par le serveur.";

      final normalizedResultCode =
          resultCode.toLowerCase();

      if (_isAccessDeniedResult(normalizedResultCode)) {
        if (!mounted) return;

        setState(() {
          _errorMessage = message !=
                  "Aucun message d'erreur fourni par le serveur."
              ? message
              : _assistantAccessDeniedMessage;

          _verificationResult = null;
        });

        return;
      }

      final responseStatus = data['status'] ??
          data['statusCode'] ??
          data['http_status'];

      final statusCode = int.tryParse(
        responseStatus?.toString() ?? '',
      );

      if (data['success'] == false &&
          (statusCode == 401 || statusCode == 403)) {
        if (!mounted) return;

        setState(() {
          _errorMessage = message !=
                  "Aucun message d'erreur fourni par le serveur."
              ? message
              : statusCode == 403
                  ? _assistantAccessDeniedMessage
                  : "Votre session a expiré. Veuillez vous reconnecter.";

          _verificationResult = null;
        });

        return;
      }

      final isAuthentic =
          data['success'] == true &&
          resultCode == 'authentic';

      final receipt = _asMap(data['receipt']);
      final student = _asMap(data['student']);
      final examSession = _asMap(data['exam_session']);

      if (!mounted) return;

      setState(() {
        if (resultCode == 'not_found') {
          _errorMessage = message;
          _verificationResult = null;
          return;
        }

        _verificationResult = {
          'valid': isAuthentic,
          'signature_verified': isAuthentic,
          'result': resultCode,
          'message': message,
          'status': receipt?['status'] ??
              data['payment_status'] ??
              resultCode,
          'receipt_number': receipt?['receipt_number'] ??
              data['receipt_number'] ??
              code,
          'amount': receipt?['amount'],
          'currency': receipt?['currency'],
          'paid_at': receipt?['paid_at'],
          'student': student,
          'exam_session': examSession,
        };
      });
    } on FunctionException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _extractFunctionError(error);
        _verificationResult = null;
      });
    } on FormatException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _verificationResult = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Erreur de vérification du reçu : $error');
      debugPrint('StackTrace : $stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage =
            "Impossible de contacter le service de vérification. "
            "Vérifiez votre connexion et réessayez.";
        _verificationResult = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _receiptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _verificationResult;
    final isValid = result?['valid'] == true;
    final isSignatureVerified =
        result?['signature_verified'] == true;

    final student = _asMap(result?['student']);
    final examSession = _asMap(result?['exam_session']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Vérification de reçu"),
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Retour à la page précédente',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
              )
            : null,
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser la vérification',
            onPressed:
                _isLoading ? null : _refreshVerification,
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
                // FORMULAIRE DE RECHERCHE
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 42,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Authenticité d'un reçu",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Saisissez le numéro figurant sur le reçu "
                        "de l'étudiant pour vérifier son authenticité "
                        "auprès du système officiel.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _receiptController,
                        enabled: !_isLoading,
                        textCapitalization:
                            TextCapitalization.characters,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: "Numéro de reçu",
                          hintText: "SP-2026-000006",
                          prefixIcon: Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                          ),
                          suffixIcon: IconButton(
                            tooltip: "Effacer",
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _receiptController.clear();
                                    setState(() {
                                      _errorMessage = null;
                                      _verificationResult = null;
                                    });
                                  },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted:
                            _isLoading ? null : _verifyReceipt,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _verifyReceipt(
                                    _receiptController.text,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.fact_check_rounded),
                          label: Text(
                            _isLoading
                                ? "Vérification en cours..."
                                : "Vérifier le reçu",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: .08),

                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                if (result != null)
                  _buildResultCard(
                    result: result,
                    student: student,
                    examSession: examSession,
                    isValid: isValid,
                    isSignatureVerified: isSignatureVerified,
                  ).animate().fadeIn().slideY(begin: .08),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required Map<String, dynamic> result,
    required Map<String, dynamic>? student,
    required Map<String, dynamic>? examSession,
    required bool isValid,
    required bool isSignatureVerified,
  }) {
    final statusColor =
        isValid ? AppColors.success : AppColors.error;

    final resultCode = result['result']?.toString() ?? '';

    final title = isValid
        ? "REÇU AUTHENTIQUE"
        : resultCode == 'not_validated'
            ? "PAIEMENT NON VALIDÉ"
            : resultCode == 'invalid_signature'
                ? "SIGNATURE INVALIDE"
                : resultCode == 'student_not_found'
                    ? "ÉTUDIANT INTROUVABLE"
                    : "AUTHENTICITÉ NON CONFIRMÉE";

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATUT GLOBAL
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isValid
                    ? Icons.verified_rounded
                    : Icons.gpp_bad_rounded,
                color: statusColor,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result['message']?.toString() ??
                          "Résultat de la vérification.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignatureVerified
                          ? "Signature HMAC-SHA256 vérifiée par le serveur."
                          : "L'authenticité cryptographique n'est pas confirmée.",
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // ÉTUDIANT
          Text(
            "Étudiant propriétaire du reçu",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          if (student != null)
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _initials(student['full_name']),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['full_name']?.toString() ??
                            "Nom inconnu",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Matricule : ${student['matricule'] ?? 'N/A'}",
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          student['faculty'],
                          student['department'],
                          student['promotion'],
                        ]
                            .where((value) =>
                                value != null &&
                                value.toString().isNotEmpty)
                            .join(' • '),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Text(
              "Les informations de l'étudiant ne sont pas disponibles.",
              style: TextStyle(color: AppColors.textSecondary),
            ),

          const Divider(height: 32),

          // SESSION D'EXAMEN
          Row(
            children: [
              Icon(
                Icons.event_note_rounded,
                color: AppColors.primary,
                size: 23,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  "Session d'examen associée",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (examSession != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "LIÉE AU REÇU",
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (examSession != null) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayValue(examSession['session_name']),
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile(
                    "Semestre",
                    _displayValue(examSession['semester']),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      "Aucune session d'examen n'a été renvoyée "
                      "pour ce paiement. Vérifiez que le paiement "
                      "possède un exam_session_id dans Supabase "
                      "et que la fonction get-receipt est déployée "
                      "avec la nouvelle version.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 32),

          // DÉTAILS DU REÇU
          Text(
            "Détails du paiement",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          _buildDetailTile(
            "Numéro du reçu",
            result['receipt_number']?.toString() ?? "N/A",
          ),
          _buildDetailTile(
            "Montant",
            result['amount'] != null
                ? "${result['amount']} ${result['currency'] ?? ''}"
                : "Non disponible",
          ),
          _buildDetailTile(
            "Statut du paiement",
            result['status']?.toString().toUpperCase() ?? "INCONNU",
          ),
          _buildDetailTile(
            "Date du paiement",
            _formatDate(result['paid_at']),
          ),

          if (isValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "La vérification cryptographique a été "
                      "confirmée par le serveur officiel.",
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _displayValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return "Non renseigné";
    }

    return value.toString();
  }

  String _initials(dynamic value) {
    final name = value?.toString().trim() ?? '';

    if (name.isEmpty) return 'U';

    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "Non disponible";
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    final local = parsed.toLocal();

    String twoDigits(int number) =>
        number.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/'
        '${twoDigits(local.month)}/'
        '${local.year} à '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }

  Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}