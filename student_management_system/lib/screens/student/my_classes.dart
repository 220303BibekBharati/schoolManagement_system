import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';
import 'package:student_management_system/screens/student/lesson_list.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  int? _classNumber;
  List<String> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;

      int? classNumber;
      if (user?.className != null) {
        final parts = user!.className!.split(' ');
        if (parts.length == 2) {
          classNumber = int.tryParse(parts[1]);
        }
      }

      if (classNumber != null) {
        setState(() {
          _classNumber = classNumber;
          _isLoading = true;
        });
        final subjects = await auth.loadSubjectsForClass(classNumber);
        if (mounted) {
          setState(() {
            _subjects = subjects;
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classNumber = _classNumber;

    if (_isLoading && classNumber == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (classNumber == null) {
      return const Scaffold(
        body: Center(
          child: Text('No class assigned'),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Subjects',
                    style: theme.textTheme.titleLarge,
                  ),
                  Chip(
                    label: Text('Class $classNumber'),
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.08),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_subjects.isEmpty)
                const Expanded(
                  child: Center(
                    child:
                        Text('No subjects have been assigned for your class.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final colors = [
                        Colors.orange.shade100,
                        Colors.lightBlue.shade100,
                        Colors.green.shade100,
                        Colors.purple.shade100,
                      ];
                      final bgColor = colors[index % colors.length];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: bgColor,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.white.withOpacity(0.9),
                            child: const Icon(Icons.menu_book,
                                color: Colors.deepOrange),
                          ),
                          title: Text(
                            subject,
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text('Class $classNumber'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonListScreen(
                                  classNumber: classNumber,
                                  subject: subject,
                                ),
                              ),
                            );
                          },
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
}

