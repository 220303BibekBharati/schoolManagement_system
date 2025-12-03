import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Student Management System';
  
  // Roles
  static const String adminRole = 'admin';
  static const String teacherRole = 'teacher';
  static const String studentRole = 'student';
  static const String parentRole = 'parent';
  
  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  
  // API Endpoints (Update with your backend)
  static const baseUrl = 'http://your-backend-url.com/api';
  
  // Days of week
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  
  // Time slots
  static const List<String> timeSlots = [
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
  ];
}

class AppRoutes {
  static const login = '/';
  static const adminDashboard = '/admin';
  static const teacherDashboard = '/teacher';
  static const studentDashboard = '/student';
  static const parentDashboard = '/parent';
  static const profile = '/profile';
}