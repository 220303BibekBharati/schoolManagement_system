import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _isLoading = false;

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
          _isLoading = true;
        });
        await auth.loadTimetableForClass(classNumber);
        if (mounted) {
          setState(() {
            _isLoading = false;
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

    if (classNumber == null) {
      return const Scaffold(
        body: Center(
          child: Text('No class assigned'),
        ),
      );
    }

    final fullTimetable = auth.getTimetableForClass(classNumber);
    final timetable = fullTimetable
        .where((t) => (t['subject'] as String? ?? '').isNotEmpty)
        .where((t) => t['subject'] == user?.subject)
        .toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : timetable.isEmpty
              ? const Center(
                  child: Text('No timetable defined for your subject.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: timetable.length,
                  itemBuilder: (context, index) {
                    final t = timetable[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(t['subject'] ?? ''),
                        subtitle: Text('${t['dayOfWeek']} • ${t['time']}'),
                      ),
                    );
                  },
                ),
    );
  }
}

