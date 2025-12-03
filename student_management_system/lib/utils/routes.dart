import 'package:flutter/material.dart';
import 'package:student_management_system/screens/auth/login_screen.dart';
import 'package:student_management_system/screens/admin/admin_dashboard.dart';
import 'package:student_management_system/screens/teacher/teacher_dashboard.dart';
import 'package:student_management_system/screens/student/student_dashboard.dart';
import 'package:student_management_system/screens/parent/parent_dashboard.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case '/teacher':
        return MaterialPageRoute(builder: (_) => const TeacherDashboard());
      case '/student':
        return MaterialPageRoute(builder: (_) => const StudentDashboard());
      case '/parent':
        return MaterialPageRoute(builder: (_) => const ParentDashboard());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}