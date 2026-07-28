import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/assistant/presentation/pages/assistant_dashboard_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/role_selection_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/student/presentation/pages/student_dashboard_page.dart';
import '../features/student/presentation/pages/student_profile_page.dart';
import '../features/student/presentation/pages/student_card_page.dart';
import '../features/student/presentation/pages/student_payment_page.dart';
import '../features/student/presentation/pages/student_receipts_page.dart';
import '../features/student/presentation/pages/student_notifications_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
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
        path: '/roles',
        builder: (context, state) => const RoleSelectionPage(),
      ),

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
        path: '/student/receipts',
        builder: (context, state) => const StudentReceiptsPage(),
      ),

      GoRoute(
        path: '/student/notifications',
        builder: (context, state) => const StudentNotificationsPage(),
      ),

      GoRoute(
        path: '/assistant',
        builder: (context, state) => const AssistantDashboardPage(),
      ),

      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
}