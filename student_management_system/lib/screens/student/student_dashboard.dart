import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';
import 'package:student_management_system/models/attendance.dart';
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
  ];

  final List<String> _titles = [
    'Student Dashboard',
    'My Classes',
    'Attendance',
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
      // Load attendance for current student so stats are available
      await auth.loadAttendanceForCurrentStudent();

      // Load timetable and homework for this class so dashboard stats are ready
      if (classNumber != null) {
        setState(() {
          _isLoadingTimetable = true;
        });
        await auth.loadTimetableForClass(classNumber);
        await auth.loadHomeworksForClass(classNumber);
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

    // Real attendance stats for this student
    final List<Attendance> attendanceRecords = user != null
        ? auth.getAttendanceForStudent(user.id)
        : const <Attendance>[];
    final totalDays = attendanceRecords.length;
    final presentDays = attendanceRecords
        .where((r) => r.status.toLowerCase() == 'present')
        .length;
    final attendancePercent =
        totalDays == 0 ? 0 : ((presentDays / totalDays) * 100).round();

    // Real homework count for this class (uses provider cache if loaded)
    final homeworkCount =
        classNumber != null ? auth.getHomeworksForClass(classNumber).length : 0;

    // Real total classes from today's timetable entries
    final totalClasses = timetable.length;

    final theme = Theme.of(context);
    final name = user?.name ?? 'Student';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.teal.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.class_, color: Colors.white.withOpacity(0.9), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      classNumber != null ? 'Class $classNumber' : 'No class assigned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your academic overview',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                title: 'Attendance %',
                value: '${attendancePercent}%',
                icon: Icons.check_circle,
                color: Colors.teal,
              ),
              _StatCard(
                title: 'Homework',
                value: homeworkCount.toString(),
                icon: Icons.assignment,
                color: Colors.lightBlue,
              ),
              _StatCard(
                title: 'Total Classes',
                value: totalClasses.toString(),
                icon: Icons.class_,
                color: Colors.blueAccent,
              ),
              const _StatCard(
                title: 'Grade',
                value: '-',
                icon: Icons.grade,
                color: Colors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Timetable',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (classNumber != null)
                        Chip(
                          label: Text('Class $classNumber'),
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.08),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
    );
  }
}

class _StatCard extends StatefulWidget {
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
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          color: widget.color.withOpacity(0.08),
          elevation: _hovering ? 4 : 1,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child:
                      Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
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