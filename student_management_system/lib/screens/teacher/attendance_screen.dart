import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, Map<int, bool>> _attendanceByDate = {}; // date -> { rollNo -> present }
  DateTime _selectedDate = DateTime.now();

  int? _extractClassNumber(String? className) {
    if (className == null) return null;
    // Expect format like 'Class 5'
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
        await auth.loadStudentsForClass(classNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final classNumber = _extractClassNumber(user?.className);

    if (user == null || classNumber == null) {
      return const Scaffold(
        body: Center(
          child: Text('No class assigned. Please contact admin.'),
        ),
      );
    }

    final students = auth.getStudentsForClass(classNumber);

    if (students.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attendance - Class $classNumber'),
        ),
        body: const Center(
          child: Text('No students added for this class yet.'),
        ),
      );
    }

    final dateKey = _selectedDate.toIso8601String().split('T').first;
    final attendanceForDate =
        _attendanceByDate.putIfAbsent(dateKey, () => <int, bool>{});

    // Initialize attendance map for existing students if not yet set
    for (final s in students) {
      final roll = s['rollNo'] as int;
      attendanceForDate.putIfAbsent(roll, () => true); // default present
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - Class $classNumber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final date = _selectedDate;
              await context.read<AuthProvider>().saveAttendanceForDate(
                    classNumber: classNumber,
                    date: date,
                    attendanceByRoll: attendanceForDate,
                  );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance saved')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class $classNumber',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              label: Text(dateKey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Mark students present / absent',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Swipe toggles',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  final roll = s['rollNo'] as int;
                  final name = s['name'] as String;
                  final present = attendanceForDate[roll] ?? true;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            present ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        child: Text(
                          roll.toString(),
                          style: TextStyle(
                            color: present ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        present ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: present ? Colors.green : Colors.red,
                        ),
                      ),
                      trailing: Switch(
                        value: present,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        onChanged: (value) {
                          setState(() {
                            attendanceForDate[roll] = value;
                          });
                        },
                      ),
                    ),
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

