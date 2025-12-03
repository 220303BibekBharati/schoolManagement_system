
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/models/attendance.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class AttendanceViewScreen extends StatefulWidget {
  const AttendanceViewScreen({super.key});

  @override
  State<AttendanceViewScreen> createState() => _AttendanceViewScreenState();
}

class _AttendanceViewScreenState extends State<AttendanceViewScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _isLoading = true;
      });
      await context.read<AuthProvider>().loadAttendanceForCurrentStudent();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }

    final records = auth.getAttendanceForStudent(user.id);

    final totalDays = records.length;
    final presentDays =
        records.where((r) => r.status.toLowerCase() == 'present').length;
    final absentDays =
        records.where((r) => r.status.toLowerCase() == 'absent').length;
    final overallPercent =
        totalDays == 0 ? 0 : ((presentDays / totalDays) * 100).round();

    final monthGroups = <String, List<Attendance>>{};
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      monthGroups.putIfAbsent(key, () => []).add(r);
    }

    final monthKeys = monthGroups.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatChip(
                                  label: 'Present',
                                  value: presentDays.toString(),
                                ),
                                _StatChip(
                                  label: 'Absent',
                                  value: absentDays.toString(),
                                ),
                                _StatChip(
                                  label: 'Overall %',
                                  value: '$overallPercent%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              width: 160,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 160,
                                    width: 160,
                                    child: CircularProgressIndicator(
                                      value: totalDays == 0
                                          ? 0
                                          : presentDays / totalDays,
                                      strokeWidth: 12,
                                      backgroundColor:
                                          Colors.red.withOpacity(0.2),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.green),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$overallPercent%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Overall Attendance'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Attendance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Row(
                          children: const [
                            _LegendDot(color: Colors.green, label: 'Present'),
                            SizedBox(width: 8),
                            _LegendDot(color: Colors.red, label: 'Absent'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (monthKeys.isEmpty)
                      const Text('No attendance records yet.')
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: monthKeys.length,
                          itemBuilder: (context, index) {
                            final key = monthKeys[index];
                            final list = monthGroups[key]!;
                            final monthTotal = list.length;
                            final monthPresent = list
                                .where((r) =>
                                    r.status.toLowerCase() == 'present')
                                .length;
                            final presentRatio = monthTotal == 0
                                ? 0.0
                                : monthPresent / monthTotal;
                            final absentRatio = 1.0 - presentRatio;

                            final year = int.parse(key.split('-')[0]);
                            final month = int.parse(key.split('-')[1]);
                            final label = '${_monthName(month)} $year';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 20,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex:
                                                  (presentRatio * 100).round(),
                                              child: Container(
                                                color: Colors.green,
                                              ),
                                            ),
                                            Expanded(
                                              flex:
                                                  (absentRatio * 100).round(),
                                              child: Container(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(presentRatio * 100).round()}% present • ${(absentRatio * 100).round()}% absent',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return month.toString();
    return names[month - 1];
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

