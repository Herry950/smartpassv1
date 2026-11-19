import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/student_card_qr.dart';
import 'matricule_search_page.dart';
import 'receipt_verification_page.dart';

/// Scan du QR code d'une carte étudiante ou d'un reçu.
///
/// - QR de carte : l'étudiant est retrouvé par la vérification par
///   matricule existante (mêmes règles RLS), puis l'identifiant de la
///   carte est comparé à l'étudiant trouvé. Le QR seul ne prouve rien.
/// - QR de reçu : vérification signée par l'Edge Function get-receipt.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  final TextEditingController _manualController = TextEditingController();

  bool _handling = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String? raw) async {
    if (_handling || raw == null) return;

    final value = raw.trim();
    if (value.isEmpty) return;

    final upper = value.toUpperCase();
    Widget? target;

    if (receiptNumberPattern.hasMatch(upper)) {
      target = ReceiptVerificationPage(initialReceiptNumber: upper);
    } else {
      final card = StudentCardQrData.tryParse(value);

      if (card != null) {
        target = MatriculeSearchPage(
          initialMatricule: card.matricule,
          expectedStudentId: card.studentId,
        );
      }
    }

    if (target == null) {
      setState(() {
        _message = 'QR code non reconnu : ce n’est ni une carte étudiante '
            'SmartPass ni un reçu SmartPass.';
      });
      return;
    }

    setState(() {
      _handling = true;
      _message = null;
    });

    await _controller.stop();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => target!),
    );

    if (!mounted) return;

    setState(() => _handling = false);

    try {
      await _controller.start();
    } catch (_) {
      // La caméra peut être indisponible (permissions, appareil).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Scanner QR Code'),
        centerTitle: true,
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Changer de caméra',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Placez le QR code de la carte étudiante ou du reçu '
                  'dans le cadre.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final raw = barcode.rawValue;
                              if (raw != null && raw.isNotEmpty) {
                                _handleCode(raw);
                                break;
                              }
                            }
                          },
                          errorBuilder: (context, error) =>
                              _buildCameraError(error),
                        ),
                        IgnorePointer(
                          child: Center(
                            child: FractionallySizedBox(
                              widthFactor: .7,
                              heightFactor: .7,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_handling)
                          const ColoredBox(
                            color: Colors.black45,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Saisie manuelle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Si la caméra est indisponible : collez le contenu lu '
                  'par un lecteur externe, ou un numéro de reçu.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _manualController,
                  decoration: const InputDecoration(
                    labelText: 'Contenu du QR code',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                  onSubmitted: _handleCode,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _handling
                      ? null
                      : () => _handleCode(_manualController.text),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Vérifier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Accès à la caméra refusé. Autorisez la caméra dans le navigateur.',
      MobileScannerErrorCode.unsupported =>
        'Le scan par caméra n’est pas pris en charge sur cet appareil.',
      _ => 'Caméra indisponible. Utilisez la saisie manuelle ci-dessous.',
    };

    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: 44,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
