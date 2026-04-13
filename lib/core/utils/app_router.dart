// app_router.dart
import 'package:coexist_app_portal/features/dashboard/presentation/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coexist_app_portal/di/injection_container.dart' as di;

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';

import '../../features/dashboard/presentation/widgets/dashboard_section.dart';
import '../../features/dashboard/presentation/widgets/events_section.dart';
import '../../features/dashboard/presentation/widgets/users_section.dart';

import '../../features/events/presentation/pages/event_details_page.dart';
import '../../features/events/presentation/widgets/web_form_section.dart';
import '../../features/events/presentation/bloc/event_bloc.dart';

import '../../features/pickups/presentation/bloc/pickup_bloc.dart';
import '../../features/pickups/presentation/widgets/pickups_section.dart';

/// Navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const setNewPassword = '/set-new-password';
  static const emailVerification = '/email-verification';

  static const dashboard = '/dashboard';
  static const dashboardEvents = '/dashboard/events';
  static const dashboardPickups = '/dashboard/pickups';
  static const dashboardUsers = '/dashboard/users';

  static const createEvent = '/create-event';

  static String eventDetails(String id) => '/event-details/$id';
  static String editEvent(String id) => '/edit-event/$id';
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.login,

  /// AUTH GUARD
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    final currentPath = state.uri.path;

    final isAuthRoute =
        currentPath == AppRoutes.login ||
        currentPath == AppRoutes.register ||
        currentPath == AppRoutes.forgotPassword ||
        currentPath == AppRoutes.setNewPassword ||
        currentPath == AppRoutes.emailVerification;

    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
    if (isLoggedIn && isAuthRoute) return AppRoutes.dashboard;

    return null;
  },

  routes: [
    /// ================= AUTH =================
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
    GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, __) => ForgotPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.setNewPassword,
      builder: (_, __) => const SetNewPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.emailVerification,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return EmailVerificationPage(email: email);
      },
    ),

    /// ================= DASHBOARD SHELL =================
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<EventBloc>(create: (_) => di.sl<EventBloc>()),
            BlocProvider<PickupBloc>(create: (_) => di.sl<PickupBloc>()),
          ],
          child: DashboardPage(child: child), // ✅ IMPORTANT FIX
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final name = extra?['name'] ?? 'User';
            return DashboardSection(
              isWide: true,
              name: name ?? 'User',
              headingSize: 24,
              subHeadingSize: 14,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.dashboardEvents,
          builder: (context, state) => const EventsSection(),
        ),
        GoRoute(
          path: AppRoutes.dashboardPickups,
          builder: (context, state) => const PickupsSection(),
        ),
        GoRoute(
          path: AppRoutes.dashboardUsers,
          builder: (context, state) => const UsersSection(),
        ),
      ],
    ),

    /// ================= FULLSCREEN PAGES =================
    GoRoute(
      path: '/event-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final eventId = state.pathParameters['id']!;
        return EventDetailsPage(eventId: eventId);
      },
    ),

    GoRoute(
      path: AppRoutes.createEvent,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateEventForm(),
    ),

    GoRoute(
      path: '/edit-event/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final eventId = state.pathParameters['id']!;
        return CreateEventForm(eventId: eventId);
      },
    ),
  ],
);
