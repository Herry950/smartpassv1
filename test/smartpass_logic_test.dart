import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/app/theme/theme_controller.dart';
import 'package:myprojectflut/core/models/student.dart';
import 'package:myprojectflut/core/services/auth_service.dart';
import 'package:myprojectflut/core/services/faculty_report_pdf_service.dart';
import 'package:myprojectflut/core/services/student_card_pdf_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myprojectflut/core/services/student_card_qr.dart';
import 'package:myprojectflut/features/student/presentation/widgets/exam_countdown_card.dart';
import 'package:myprojectflut/features/student/presentation/widgets/student_card_body.dart';
import 'package:myprojectflut/shared/widgets/module_tile_grid.dart';

const _student = Student(
  id: '3f1c2b9a-1d2e-4c5b-8a7f-0123456789ab',
  fullName: 'Étudiant Test',
  matricule: 'MAT-001',
  faculty: 'Sciences et Technologie',
  department: 'Informatique',
  promotion: 'L1',
  academicYear: '2025-2026',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('QR de la carte étudiante', () {
    test('encode puis relit le même étudiant', () {
      final raw = StudentCardQrData.encode(
        studentId: _student.id,
        matricule: _student.matricule,
        academicYear: _student.academicYear,
      );

      final parsed = StudentCardQrData.tryParse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.studentId, _student.id);
      expect(parsed.matricule, 'MAT-001');
      expect(parsed.academicYear, '2025-2026');
    });

    test('rejette un contenu qui n’est pas une carte SmartPass', () {
      expect(StudentCardQrData.tryParse('bonjour'), isNull);
      expect(StudentCardQrData.tryParse('pas-un-uuid|MAT|2025'), isNull);
      expect(StudentCardQrData.tryParse('${_student.id}||2025'), isNull);
    });

    test('reconnaît un numéro de reçu', () {
      expect(receiptNumberPattern.hasMatch('SP-2026-000123'), isTrue);
      expect(receiptNumberPattern.hasMatch('SP-26-123'), isFalse);
    });
  });

  group('Rôles et espaces', () {
    test('chaque rôle a son espace', () {
      expect(AuthService.homeRouteForRole('student'), '/student');
      expect(AuthService.homeRouteForRole('assistant'), '/assistant');
      expect(AuthService.homeRouteForRole('admin'), '/admin');
      expect(AuthService.homeRouteForRole('central_admin'), '/central');
      expect(AuthService.homeRouteForRole('admin_inactive'), isNull);
      expect(AuthService.homeRouteForRole(null), isNull);
    });
  });

  group('Carte étudiante', () {
    test('numéro de carte sans plantage sur année courte', () {
      expect(StudentCardBody.cardNumber(_student), 'SP-2026-MAT-001');

      const shortYear = Student(
        id: 'x',
        fullName: 'A',
        matricule: 'M1',
        faculty: 'F',
        department: '',
        promotion: 'L0',
        academicYear: '2026',
      );
      expect(StudentCardBody.cardNumber(shortYear), 'SP-2026-M1');
    });

    testWidgets('corps de carte sans débordement à 360 px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: ColoredBox(
                color: AppColors.brandNavy,
                child: StudentCardBody(student: _student),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Matricule : MAT-001'), findsOneWidget);
    });
  });

  group('Compte à rebours', () {
    testWidgets('aucun examen programmé', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExamCountdownCard(examDate: null)),
        ),
      );

      expect(find.text('Aucun examen programmé'), findsOneWidget);
    });

    testWidgets('examen à venir', (tester) async {
      final date = DateTime.now().add(const Duration(days: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExamCountdownCard(examDate: date)),
        ),
      );

      expect(find.text('Début dans : 5 jours'), findsOneWidget);
    });
  });

  group('Tuiles de modules', () {
    for (final width in [360.0, 600.0, 1200.0]) {
      testWidgets('aucun débordement à ${width.toInt()} px', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ModuleTileGrid(
                  tiles: List.generate(
                    6,
                    (i) => ModuleTileData(
                      icon: Icons.school_rounded,
                      label: 'Administrateurs facultaires $i',
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ModuleTile), findsNWidgets(6));
      });
    }
  });

  group('Thème', () {
    test('le choix sombre est appliqué et conservé', () async {
      SharedPreferences.setMockInitialValues({});
      TestWidgetsFlutterBinding.ensureInitialized();

      await ThemeController.load();
      expect(ThemeController.mode.value, ThemeMode.light);
      expect(AppColors.isDark, isFalse);

      await ThemeController.setMode(ThemeMode.dark);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, AppColors.darkBackground);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('smartpass_theme_mode'), 'dark');

      // Nouvelle session : le thème enregistré est relu.
      await ThemeController.load();
      expect(ThemeController.mode.value, ThemeMode.dark);

      await ThemeController.setMode(ThemeMode.light);
      expect(AppColors.isDark, isFalse);
    });
  });

  group('PDF', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('carte étudiante imprimable générée', () async {
      final bytes = await StudentCardPdfService.generate([
        Student(
          id: _student.id,
          fullName: _student.fullName,
          matricule: _student.matricule,
          faculty: _student.faculty,
          department: _student.department,
          promotion: _student.promotion,
          academicYear: _student.academicYear,
          expiryDate: DateTime(2026, 7, 31),
        ),
      ]);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });

    final data = SessionReportData(
      facultyName: 'Sciences et Technologie',
      session: {
        'session_name': 'Session ordinaire',
        'semester': 'Semestre 1',
        'fee_amount': 50,
        'currency': 'USD',
        'academic_years': {'name': '2025-2026'},
      },
      targetedPromotions: {'L1'},
      carriedOverPayments: [
        {
          'amount': 50,
          'payment_channel': 'Flutterwave',
          'payment_method': 'Carte bancaire',
          'receipt_number': 'SP-2026-000007',
          'students': {
            'full_name': 'Étudiant C', 'matricule': 'M3', 'promotion': 'L1',
            'department': 'Génie Informatique', 'academic_year': '2025-2026',
          },
        },
      ],
      payments: [
        {
          'amount': 50,
          'payment_channel': 'Flutterwave',
          'payment_method': 'Visa',
          'receipt_number': 'SP-2026-000001',
          'paid_at': '2026-11-10T10:00:00Z',
          'students': {
            'full_name': 'Étudiant A', 'matricule': 'M1', 'promotion': 'L1',
            'department': 'Informatique', 'academic_year': '2025-2026',
          },
        },
        {
          'amount': 50,
          'payment_channel': 'manual',
          'payment_method': 'Espèces',
          'receipt_number': 'SP-2026-000002',
          'paid_at': '2026-11-11T10:00:00Z',
          'cash_remitted': true,
          'students': {
            'full_name': 'Étudiant B', 'matricule': 'M2', 'promotion': 'L2',
            'department': '', 'academic_year': '2025-2026',
          },
        },
      ],
    );

    test('règle d’autorisation du rapport', () {
      expect(data.accessStatus(data.payments[0]), 'Autorisé');
      expect(
        data.accessStatus(data.payments[1]),
        'Non concerné par les examens programmés',
      );
    });

    test('rapports facultaires PDF générés', () async {
      final service = FacultyReportPdfService(
        client: SupabaseClient('http://localhost', 'test-key'),
      );
      final payments = await service.buildPaymentsReport(data);
      final authorized = await service.buildAuthorizedStudentsReport(data);
      expect(String.fromCharCodes(payments.take(5)), '%PDF-');
      expect(String.fromCharCodes(authorized.take(5)), '%PDF-');
      // Le paiement de la session remplacée donne accès, sans être compté
      // dans les montants de la session de référence.
      expect(data.accessStatus(data.carriedOverPayments.first), 'Autorisé');
      expect(data.payments.length, 2);
    });
  });
}
