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
    'Classes',
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
        body = const TeacherClassesScreen();
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
            icon: Icon(Icons.menu_book),
            label: 'Classes',
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeworkScreen(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Upload Lesson',
                  icon: Icons.upload_file,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeworkScreen(),
                      ),
                    );
                  },
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

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String yearLabelForClass(int c) {
      switch (c) {
        case 1:
          return 'Year One';
        case 2:
          return 'Year Two';
        case 3:
          return 'Year Three';
        case 4:
          return 'Year Four';
        case 5:
          return 'Year Five';
        default:
          return 'Year $c';
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classes',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose a class to manage modules',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final classNumber = index + 1;
                  final yearLabel = yearLabelForClass(classNumber);

                  return _TeacherClassTile(
                    classNumber: classNumber,
                    yearLabel: yearLabel,
                  );
                },
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

class _TeacherClassTile extends StatefulWidget {
  final int classNumber;
  final String yearLabel;

  const _TeacherClassTile({
    required this.classNumber,
    required this.yearLabel,
  });

  @override
  State<_TeacherClassTile> createState() => _TeacherClassTileState();
}

class _TeacherClassTileState extends State<_TeacherClassTile> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final warmGradients = [
      [Colors.deepOrange.shade400, Colors.amber.shade500],
      [Colors.pink.shade400, Colors.deepPurple.shade400],
      [Colors.red.shade400, Colors.orange.shade500],
      [Colors.orange.shade400, Colors.lime.shade500],
    ];

    final index = (widget.classNumber - 1) % warmGradients.length;
    final colors = warmGradients[index];

    final scale = _pressed
        ? 0.97
        : _hovering
            ? 1.03
            : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeworkScreen(
                initialClassNumber: widget.classNumber,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors[0].withOpacity(0.95),
                  colors[1].withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[1].withOpacity(_hovering ? 0.35 : 0.22),
                  blurRadius: _hovering ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class ${widget.classNumber}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.yearLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeworkScreen(
                            initialClassNumber: widget.classNumber,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                    label: const Text('Go To Module'),
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