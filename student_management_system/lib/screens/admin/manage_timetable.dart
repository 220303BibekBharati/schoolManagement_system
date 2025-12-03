import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class ManageTimetableScreen extends StatefulWidget {
  const ManageTimetableScreen({super.key});

  @override
  State<ManageTimetableScreen> createState() => _ManageTimetableScreenState();
}

class _ManageTimetableScreenState extends State<ManageTimetableScreen> {
  int _selectedClass = 1;
  String _selectedDay = 'Monday';
  final _timeController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _timeController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadTimetable(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    await context.read<AuthProvider>().loadTimetableForClass(_selectedClass);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final timetable = auth.getTimetableForClass(_selectedClass);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Timetable'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Class:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _selectedClass,
                  items: List.generate(
                    10,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('Class ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedClass = value;
                    });
                    _loadTimetable(context);
                  },
                ),
                const SizedBox(width: 24),
                const Text('Day:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedDay,
                  items: const [
                    DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                    DropdownMenuItem(value: 'Tuesday', child: Text('Tuesday')),
                    DropdownMenuItem(value: 'Wednesday', child: Text('Wednesday')),
                    DropdownMenuItem(value: 'Thursday', child: Text('Thursday')),
                    DropdownMenuItem(value: 'Friday', child: Text('Friday')),
                    DropdownMenuItem(value: 'Saturday', child: Text('Saturday')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedDay = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time (e.g. 10:00 - 11:00)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final time = _timeController.text.trim();
                    final subject = _subjectController.text.trim();
                    if (time.isEmpty || subject.isEmpty) return;
                    await context.read<AuthProvider>().addTimetableEntry(
                          classNumber: _selectedClass,
                          dayOfWeek: _selectedDay,
                          time: time,
                          subject: subject,
                        );
                    _timeController.clear();
                    _subjectController.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : timetable.isEmpty
                      ? const Center(
                          child: Text('No timetable entries for this class.'),
                        )
                      : ListView.builder(
                          itemCount: timetable.length,
                          itemBuilder: (context, index) {
                            final t = timetable[index];
                            return ListTile(
                              leading: const Icon(Icons.schedule),
                              title: Text(t['subject'] ?? ''),
                              subtitle: Text('${t['dayOfWeek']} • ${t['time']}'),
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
