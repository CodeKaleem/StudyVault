import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/registered_students_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/server/chat_screen.dart';
import '../screens/content/past_papers_screen.dart';
import '../screens/gpa/gpa_calculator_screen.dart';
import '../screens/server/server_content_screen.dart'; 
import '../screens/server/server_settings_screen.dart';
import '../screens/server/announcements_screen.dart'; // Added
import '../screens/profile/profile_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider, 
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.uri.toString() == '/login';
        final isSplashing = state.uri.toString() == '/splash';
        final role = authProvider.role;

        if (authProvider.isLoading) return null;

        if (isSplashing) return null;

        if (!isLoggedIn && !isLoggingIn) return '/login';

        if (isLoggedIn && isLoggingIn) {
          if (role == AppRole.teacher) {
            return '/teacher';
          } else {
            return '/student';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/teacher',
          builder: (context, state) => const TeacherDashboard(),
        ),
        GoRoute(
          path: '/student',
          builder: (context, state) => const StudentDashboard(),
        ),
        GoRoute(
          path: '/server/:id',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             final extra = state.extra as Map<String, dynamic>?; 
             final name = extra?['name'] ?? 'Chat';
             return ChatScreen(serverId: id, serverName: name);
          },
        ),
        GoRoute(
          path: '/server/:id/settings',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             final extra = state.extra as Map<String, dynamic>?; 
             final name = extra?['name'] ?? 'Server';
             return ServerSettingsScreen(serverId: id, serverName: name);
          },
        ),
        // Server Content Library
        GoRoute(
          path: '/server/:id/content',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>?; 
             final name = extra?['name'] ?? 'Server';
             return ServerContentScreen(serverId: id, serverName: name);
          },
        ),
        GoRoute(
          path: '/server/:id/announcements',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             final extra = state.extra as Map<String, dynamic>?;
             final name = extra?['name'] ?? 'Server';
             final isTeacher = extra?['isTeacher'] ?? false;
             return AnnouncementsScreen(serverId: id, serverName: name, isTeacher: isTeacher);
          },
        ),
        GoRoute(
          path: '/past-papers',
          builder: (context, state) => const PastPapersScreen(),
        ),
        GoRoute(
          path: '/gpa-calculator',
          builder: (context, state) => const GpaCalculatorScreen(),
        ),
        GoRoute(
          path: '/registered-students',
          builder: (context, state) => const RegisteredStudentsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}
