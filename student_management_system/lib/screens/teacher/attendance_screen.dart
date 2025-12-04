import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_management_system/providers/auth_provider.dart';
import 'package:student_management_system/utils/constants.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, Map<int, bool>> _attendanceByDate = {}; // date -> { rollNo -> present }
  DateTime _selectedDate = DateTime.now();
  int? _currentClassNumber;
  bool _isLoadingClass = false;

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
      await _loadTeacherClassAndStudents();
    });
  }

  Future<void> _loadTeacherClassAndStudents() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingClass = true;
    });

    int? classNumber;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final raw = data['classNumber'];
        if (raw is int) {
          classNumber = raw;
        } else if (raw is String) {
          classNumber = int.tryParse(raw);
        }
      }

      _currentClassNumber = classNumber;

      if (classNumber != null) {
        await auth.loadStudentsForClass(classNumber);
        await _loadExistingAttendanceForDate(classNumber);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClass = false;
        });
      }
    }
  }

  Future<void> _showAddStudentDialog(int classNumber) async {
    final nameController = TextEditingController();
    final rollController = TextEditingController();
    final loginIdController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Student'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: rollController,
                  decoration: const InputDecoration(
                    labelText: 'Roll No',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter roll';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Invalid roll';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: loginIdController,
                  decoration: const InputDecoration(
                    labelText: 'Login ID / Email',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter login ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter password';
                    }
                    if (value.length < 6) {
                      return 'Min 6 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final rollNo = int.parse(rollController.text.trim());
                final loginId = loginIdController.text.trim();
                final password = passwordController.text.trim();

                await context.read<AuthProvider>().addStudent(
                      classNumber: classNumber,
                      name: name,
                      rollNo: rollNo,
                      loginId: loginId,
                      password: password,
                    );
                await context.read<AuthProvider>().loadStudentsForClass(classNumber);
                await _loadExistingAttendanceForDate(classNumber);

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student added')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadExistingAttendanceForDate(int classNumber) async {
    final auth = context.read<AuthProvider>();
    final students = auth.getStudentsForClass(classNumber);
    if (students.isEmpty) return;

    final dateKey = _selectedDate.toIso8601String().split('T').first;

    final snap = await FirebaseFirestore.instance
        .collection('attendance')
        .where('className', isEqualTo: 'Class $classNumber')
        .where('date', isEqualTo: dateKey)
        .get();

    final byName = <String, String>{};
    for (final d in snap.docs) {
      final data = d.data();
      final name = (data['studentName'] as String? ?? '').trim();
      final status = (data['status'] as String? ?? '').toLowerCase();
      if (name.isNotEmpty) {
        byName[name] = status;
      }
    }

    final attendanceForDate =
        _attendanceByDate.putIfAbsent(dateKey, () => <int, bool>{});
    attendanceForDate.clear();

    for (final s in students) {
      final roll = s['rollNo'] as int;
      final name = s['name'] as String? ?? '';
      final status = byName[name];
      if (status == null) {
        // If no record stored for this student on this date, default to present
        attendanceForDate[roll] = true;
      } else {
        attendanceForDate[roll] = status == 'present';
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final classNumber = _currentClassNumber;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not logged in.'),
        ),
      );
    }

    if (user.role != AppConstants.teacherRole) {
      return const Scaffold(
        body: Center(
          child: Text('Only teachers can take attendance.'),
        ),
      );
    }

    if (_isLoadingClass) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Allow only class teachers with an assigned class to take attendance
    if (classNumber == null) {
      return const Scaffold(
        body: Center(
          child: Text('Only the class teacher with an assigned class can take attendance.'),
        ),
      );
    }

    final students = auth.getStudentsForClass(classNumber);

    if (students.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attendance - Class $classNumber'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Add Student',
              onPressed: () {
                _showAddStudentDialog(classNumber);
              },
            ),
          ],
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
    if (attendanceForDate.isEmpty) {
      for (final s in students) {
        final roll = s['rollNo'] as int;
        attendanceForDate.putIfAbsent(roll, () => true); // default present
      }
    }

    final totalStudents = students.length;
    final presentCount =
        attendanceForDate.values.where((v) => v == true).length;
    final absentCount = totalStudents - presentCount;
    final presentPercent = totalStudents == 0
        ? 0
        : ((presentCount / totalStudents) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - Class $classNumber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Student',
            onPressed: () {
              _showAddStudentDialog(classNumber);
            },
          ),
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade500,
                      Colors.blue.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Class',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Class $classNumber',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  'Present: $presentCount',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor:
                                    Colors.greenAccent.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  'Absent: $absentCount',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor:
                                    Colors.redAccent.withOpacity(0.6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side:
                                      const BorderSide(color: Colors.white70),
                                ),
                                icon: const Icon(Icons.calendar_today,
                                    size: 18),
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
                                    await _loadExistingAttendanceForDate(
                                        classNumber);
                                  }
                                },
                                label: Text(dateKey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$presentPercent% present',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 52,
                            width: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: totalStudents == 0
                                      ? 0
                                      : presentCount / totalStudents,
                                  strokeWidth: 6,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.15),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.lightGreenAccent,
                                  ),
                                ),
                                Text(
                                  '$presentPercent%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    'Use the switch to toggle',
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
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Text(
                          roll.toString(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        present ? 'Present' : 'Absent',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
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

