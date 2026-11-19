
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';

import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/academic_year_management_page.dart';
import '../features/admin/presentation/pages/assistant_management_page.dart';
import '../features/admin/presentation/pages/room_management_page.dart';
import '../features/admin/presentation/pages/course_management_page.dart';
import '../features/admin/presentation/pages/cash_remittance_management_page.dart';
import '../features/admin/presentation/pages/exam_sessions_page.dart';
import '../features/admin/presentation/pages/exam_schedule_management_page.dart';
import '../features/admin/presentation/pages/assistant_assignment_page.dart';
import '../features/admin/presentation/pages/faculty_reports_page.dart';
import '../features/admin/presentation/pages/reconciliation_management_page.dart';

import '../features/central/presentation/pages/central_admins_page.dart';
import '../features/central/presentation/pages/central_dashboard_page.dart';
import '../features/central/presentation/pages/central_faculties_page.dart';
import '../features/central/presentation/pages/central_students_page.dart';

import '../features/assistant/presentation/pages/assistant_dashboard_page.dart';
import '../features/assistant/presentation/pages/assistant_cash_remittance_history_page.dart';

import '../features/auth/presentation/pages/assistant_invitation_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/role_selection_page.dart';
import '../features/auth/presentation/pages/student_register_page.dart';

import '../features/home/presentation/pages/home_page.dart';

import '../features/student/presentation/pages/student_dashboard_page.dart';
import '../features/student/presentation/pages/student_profile_page.dart';
import '../features/student/presentation/pages/student_card_page.dart';
import '../features/student/presentation/pages/student_payment_page.dart';
import '../features/student/presentation/pages/student_receipts_page.dart';
import '../features/student/presentation/pages/student_notifications_page.dart';
import '../features/student/presentation/pages/student_exams_page.dart';
import '../features/student/presentation/pages/student_payment_result_page.dart';
import '../features/student/presentation/pages/student_reconciliations_page.dart';

class AppRouter {
  AppRouter._();

  /// Pages accessibles sans connexion.
  static const Set<String> _publicPaths = {
    '/',
    '/login',
    '/register',
    '/roles',
    '/auth/invite',
  };

  /// Modules globaux hébergés sous /admin mais réservés
  /// à l'administrateur central (salles et années académiques).
  static const Set<String> _centralOnlyAdminPaths = {
    '/admin/rooms',
    '/admin/academic-years',
  };

  static bool _isAllowed(String path, String role) {
    switch (role) {
      case AuthService.roleStudent:
        return path.startsWith('/student');
      case AuthService.roleAssistant:
        return path.startsWith('/assistant');
      case AuthService.roleFacultyAdmin:
        return path.startsWith('/admin') &&
            !_centralOnlyAdminPaths.contains(path);
      case AuthService.roleCentralAdmin:
        return path.startsWith('/central') ||
            _centralOnlyAdminPaths.contains(path);
      default:
        return false;
    }
  }

  /// Garde de navigation : chaque rôle n'accède qu'à son espace.
  /// La sécurité des données reste assurée par les politiques RLS.
  static Future<String?> _guard(
    BuildContext context,
    GoRouterState state,
  ) async {
    final path = state.uri.path;

    if (_publicPaths.contains(path)) return null;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) return '/login';

    final String? role;

    try {
      role = await AuthService.getCachedUserRole();
    } catch (error) {
      // Erreur réseau : la page affichera elle-même l'erreur,
      // les données restant protégées par RLS.
      debugPrint('Garde de navigation : rôle indisponible ($error).');
      return null;
    }

    final home = AuthService.homeRouteForRole(role);

    if (role == null || home == null) return '/login';

    return _isAllowed(path, role) ? null : home;
  }

  static GoRouter create(Uri initialUri) {
    return GoRouter(
      debugLogDiagnostics: kDebugMode,
      refreshListenable: _AuthRefreshListenable(),
      redirect: _guard,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const StudentRegisterPage(),
        ),
        GoRoute(
          path: '/roles',
          builder: (context, state) => const RoleSelectionPage(),
        ),

        // ESPACE ÉTUDIANT
        GoRoute(
          path: '/student',
          builder: (context, state) => const StudentDashboardPage(),
        ),
        GoRoute(
          path: '/student/profile',
          builder: (context, state) => const StudentProfilePage(),
        ),
        GoRoute(
          path: '/student/card',
          builder: (context, state) => const StudentCardPage(),
        ),
        GoRoute(
          path: '/student/payment',
          builder: (context, state) => const StudentPaymentPage(),
        ),
        GoRoute(
          path: '/student/reconciliations',
          builder: (context, state) => const StudentReconciliationsPage(),
        ),
        GoRoute(
          path: '/student/payment-result',
          builder: (context, state) => StudentPaymentResultPage(
            txRef: state.uri.queryParameters['tx_ref'],
            providerStatus: state.uri.queryParameters['status'],
          ),
        ),
        GoRoute(
          path: '/student/receipts',
          builder: (context, state) => const StudentReceiptsPage(),
        ),
        GoRoute(
          path: '/student/notifications',
          builder: (context, state) => const StudentNotificationsPage(),
        ),
        GoRoute(
          path: '/student/exams',
          builder: (context, state) => const StudentExamsPage(),
        ),

        // ESPACE ASSISTANT
        GoRoute(
          path: '/assistant',
          builder: (context, state) => const AssistantDashboardPage(),
        ),
        GoRoute(
          path: '/assistant/remittances',
          builder: (context, state) =>
              const AssistantCashRemittanceHistoryPage(),
        ),

        // ESPACE ADMINISTRATEUR FACULTAIRE
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/academic-years',
          builder: (context, state) =>
              const AcademicYearManagementPage(),
        ),
        GoRoute(
          path: '/admin/assistants',
          builder: (context, state) => const AssistantManagementPage(),
        ),
        GoRoute(
          path: '/admin/cash-remittances',
          builder: (context, state) =>
              const CashRemittanceManagementPage(),
        ),
        GoRoute(
          path: '/admin/rooms',
          builder: (context, state) => const RoomManagementPage(),
        ),
        GoRoute(
          path: '/admin/courses',
          builder: (context, state) => const CourseManagementPage(),
        ),
        GoRoute(
          path: '/admin/assignments',
          builder: (context, state) => const AssistantAssignmentPage(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const FacultyReportsPage(),
        ),
        GoRoute(
          path: '/admin/reconciliations',
          builder: (context, state) => const ReconciliationManagementPage(),
        ),
        GoRoute(
          path: '/admin/sessions',
          builder: (context, state) => const ExamSessionsPage(),
        ),
        GoRoute(
          path: '/admin/sessions/:sessionId/schedule',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;

            return ExamScheduleManagementPage(
              sessionId: sessionId,
            );
          },
        ),

        // ESPACE ADMINISTRATEUR CENTRAL
        GoRoute(
          path: '/central',
          builder: (context, state) => const CentralDashboardPage(),
        ),
        GoRoute(
          path: '/central/faculties',
          builder: (context, state) => CentralFacultiesPage(
            initialTab:
                state.uri.queryParameters['tab'] == 'promotions' ? 1 : 0,
          ),
        ),
        GoRoute(
          path: '/central/students',
          builder: (context, state) => const CentralStudentsPage(),
        ),
        GoRoute(
          path: '/central/admins',
          builder: (context, state) => const CentralAdminsPage(),
        ),

        // INVITATION ASSISTANT
        GoRoute(
          path: '/auth/invite',
          builder: (context, state) => AssistantInvitationPage(
            callbackUri: initialUri,
          ),
        ),
      ],
    );
  }
}

/// Réévalue les gardes de navigation à chaque changement d'authentification.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.signedOut ||
            data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.userUpdated) {
          AuthService.clearRoleCache();
        }
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
