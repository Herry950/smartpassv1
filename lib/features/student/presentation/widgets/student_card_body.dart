import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/models/student.dart';
import 'package:myprojectflut/core/services/student_card_qr.dart';

import 'student_card_hologram.dart';

class StudentCardBody extends StatelessWidget {
  final Student student;

  const StudentCardBody({
    super.key,
    required this.student,
  });

  /// Numéro de carte affiché : année de fin + matricule.
  static String cardNumber(Student student) {
    final parts = student.academicYear.split(RegExp(r'[-/]'));
    final endYear = parts.isNotEmpty ? parts.last.trim() : '';
    return endYear.isEmpty
        ? 'SP-${student.matricule}'
        : 'SP-$endYear-${student.matricule}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sur petit écran, le QR code passe sous l'identité
        // pour éviter tout débordement.
        if (constraints.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoColumn(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfo(compact: true)),
                ],
              ),
              const SizedBox(height: 18),
              Center(child: _buildQrColumn()),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoColumn(),
            const SizedBox(width: 24),
            Expanded(child: _buildInfo(compact: false)),
            const SizedBox(width: 12),
            _buildQrColumn(),
          ],
        );
      },
    );
  }

  Widget _buildPhotoColumn() {
    final hasPhoto =
        student.photoUrl != null && student.photoUrl!.isNotEmpty;

    return Column(
      children: [
        Container(
          width: 90,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            image: hasPhoto
                ? DecorationImage(
                    image: NetworkImage(student.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasPhoto
              ? const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.brandNavy,
                )
              : null,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            student.promotion,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo({required bool compact}) {
    const infoStyle = TextStyle(color: Colors.white70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          _buildChip(),
          const SizedBox(height: 18),
        ],
        Text(
          student.fullName,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'N° ${cardNumber(student)}',
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 14),
        Text('Matricule : ${student.matricule}', style: infoStyle),
        Text('Faculté : ${student.faculty}', style: infoStyle),
        if (student.department.trim().isNotEmpty)
          Text('Département : ${student.department}', style: infoStyle),
        Text('Année : ${student.academicYear}', style: infoStyle),
      ],
    );
  }

  Widget _buildQrColumn() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: StudentCardQrData.encode(
              studentId: student.id,
              matricule: student.matricule,
              academicYear: student.academicYear,
            ),
            version: QrVersions.auto,
            size: 110,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const StudentCardHologram(),
        const SizedBox(height: 8),
        const Text(
          'SECURE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  /// Puce décorative de la carte.
  Widget _buildChip() {
    Widget line({double? width, double? height, double alpha = .45}) {
      return Container(
        width: width,
        height: height,
        color: Colors.brown.withValues(alpha: alpha),
      );
    }

    return Container(
      width: 56,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF7E08A),
            Color(0xFFD4AF37),
            Color(0xFFB8860B),
          ],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        children: [
          Center(child: line(width: 40, height: 2)),
          Center(child: line(width: 2, height: 28)),
          Positioned(
            left: 13,
            top: 7,
            child: line(width: 30, height: 1.5, alpha: .35),
          ),
          Positioned(
            left: 13,
            bottom: 7,
            child: line(width: 30, height: 1.5, alpha: .35),
          ),
        ],
      ),
    );
  }
}
