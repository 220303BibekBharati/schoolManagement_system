import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

import 'package:student_management_system/screens/teacher/attendance_screen.dart';
import 'package:student_management_system/screens/teacher/timetable_screen.dart';
import 'package:student_management_system/screens/teacher/homework_screen.dart';
import 'package:student_management_system/screens/common/profile_screen.dart';
import 'package:student_management_system/screens/common/notification_history.dart';
import 'package:student_management_system/widgets/drawer.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  String? _lastNotificationId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;

  final List<String> _titles = [
    'Teacher Dashboard',
    'My Timetable',
    'Take Attendance',
    'Assign Homework',
  ];

  @override
  Widget build(BuildContext context) {
    _notifSub ??= _listenForNotifications();

    Widget body;
    switch (_selectedIndex) {
      case 1:
        body = const TimetableScreen();
        break;
      case 2:
        body = const AttendanceScreen();
        break;
      case 3:
        body = const HomeworkScreen();
        break;
      case 0:
      default:
        body = TeacherHome(
          onTakeAttendanceTap: () {
            setState(() {
              _selectedIndex = 2; // Attendance tab
            });
          },
        );
        break;
    }

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
                    role: 'teacher',
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
      drawer: AppDrawer(role: 'teacher'),
      body: body,
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
            icon: Icon(Icons.schedule),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle),
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
      if (target != 'all' && target != 'teachers') return;

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

class TeacherHome extends StatelessWidget {
  final VoidCallback onTakeAttendanceTap;

  const TeacherHome({super.key, required this.onTakeAttendanceTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final name = user?.name ?? 'Teacher';
    final subject = user?.subject ?? 'Subject';
    final className = user?.className ?? 'No class assigned';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade500,
                    Colors.indigo.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        subject,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.class_, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        className,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ActionCard(
                  title: 'Take Attendance',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  onTap: onTakeAttendanceTap,
                ),
                _ActionCard(
                  title: 'Assign Homework',
                  icon: Icons.assignment,
                  color: Colors.blue,
                  onTap: () {},
                ),
                _ActionCard(
                  title: 'Upload Lesson',
                  icon: Icons.upload_file,
                  color: Colors.orange,
                  onTap: () {},
                ),
                _ActionCard(
                  title: 'View Reports',
                  icon: Icons.analytics,
                  color: Colors.purple,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Classes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _ClassCard(
                      subject: 'Mathematics',
                      className: 'Class 10-A',
                      time: '10:00 - 11:00',
                      room: 'Room 101',
                    ),
                    _ClassCard(
                      subject: 'Physics',
                      className: 'Class 10-B',
                      time: '11:00 - 12:00',
                      room: 'Room 102',
                    ),
                    _ClassCard(
                      subject: 'Chemistry',
                      className: 'Class 10-C',
                      time: '14:00 - 15:00',
                      room: 'Room 103',
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

class _ActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: _hovering ? 4 : 1,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: widget.color.withOpacity(0.1),
                    child: Icon(widget.icon, color: widget.color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String subject;
  final String className;
  final String time;
  final String room;

  const _ClassCard({
    required this.subject,
    required this.className,
    required this.time,
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
            Icons.class_,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(subject),
        subtitle: Text('$className • $room'),
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