import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';
import 'package:student_management_system/screens/student/my_classes.dart';
import 'package:student_management_system/screens/student/attendance_view.dart';
import 'package:student_management_system/screens/student/homework_view.dart';
import 'package:student_management_system/screens/common/profile_screen.dart';
import 'package:student_management_system/screens/common/notification_history.dart';
import 'package:student_management_system/widgets/drawer.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  String? _lastNotificationId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;

  final List<Widget> _screens = [
    const StudentHome(),
    const MyClassesScreen(),
    const AttendanceViewScreen(),
    const HomeworkViewScreen(),
  ];

  final List<String> _titles = [
    'Student Dashboard',
    'My Classes',
    'Attendance',
    'Homework',
  ];

  @override
  Widget build(BuildContext context) {
    _notifSub ??= _listenForNotifications();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryScreen(
                    role: 'student',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(role: 'student'),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment),
            label: 'Homework',
          ),
        ],
      ),
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenForNotifications() {
    final query = FirebaseFirestore.instance
        .collection('notification_requests')
        .orderBy('createdAt', descending: true)
        .limit(1);

    return query.snapshots().listen((snap) {
      if (!mounted) return;
      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first;
      if (doc.id == _lastNotificationId) return;

      final data = doc.data();
      final target = (data['target'] as String? ?? 'all').toLowerCase();
      if (target != 'all' && target != 'students') return;

      _lastNotificationId = doc.id;

      final title = data['title'] as String? ?? 'Notification';
      final body = data['body'] as String? ?? '';

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$title${body.isNotEmpty ? ': $body' : ''}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudentHomeContent();
  }
}

class _StudentHomeContent extends StatefulWidget {
  const _StudentHomeContent();

  @override
  State<_StudentHomeContent> createState() => _StudentHomeContentState();
}

class _StudentHomeContentState extends State<_StudentHomeContent> {
  bool _isLoadingTimetable = false;

  int? _extractClassNumber(String? className) {
    if (className == null) return null;
    final parts = className.split(' ');
    if (parts.length == 2) {
      return int.tryParse(parts[1]);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      final classNumber = _extractClassNumber(user?.className);
      if (classNumber != null) {
        setState(() {
          _isLoadingTimetable = true;
        });
        await auth.loadTimetableForClass(classNumber);
        if (mounted) {
          setState(() {
            _isLoadingTimetable = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final classNumber = _extractClassNumber(user?.className);

    final timetable = classNumber != null
        ? auth.getTimetableForClass(classNumber)
        : const <Map<String, String>>[];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Student!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('Your academic overview'),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: const [
                _StatCard(
                  title: 'Attendance %',
                  value: '95%',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Pending Homework',
                  value: '3',
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Total Classes',
                  value: '6',
                  icon: Icons.class_,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Grade',
                  value: 'A+',
                  icon: Icons.grade,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Timetable',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingTimetable)
                      const Center(child: CircularProgressIndicator())
                    else if (classNumber == null)
                      const Text('No class assigned.')
                    else if (timetable.isEmpty)
                      const Text('No timetable defined for your class.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: timetable.length,
                        itemBuilder: (context, index) {
                          final t = timetable[index];
                          return _TimeTableItem(
                            subject: t['subject'] ?? '',
                            time: t['time'] ?? '',
                            teacher: '',
                            room: '',
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeTableItem extends StatelessWidget {
  final String subject;
  final String time;
  final String teacher;
  final String room;

  const _TimeTableItem({
    required this.subject,
    required this.time,
    required this.teacher,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.book,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(subject),
        subtitle: Text('$teacher • $room'),
        trailing: Chip(
          label: Text(time),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        onTap: () {
          // Navigate to class details
        },
      ),
    );
  }
}