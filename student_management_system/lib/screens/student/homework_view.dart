import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class HomeworkViewScreen extends StatefulWidget {
  final String? initialSubject;

  const HomeworkViewScreen({super.key, this.initialSubject});

  @override
  State<HomeworkViewScreen> createState() => _HomeworkViewScreenState();
}

class _HomeworkViewScreenState extends State<HomeworkViewScreen> {
  int? _classNumber;

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
        });
        await auth.loadLessonsForClass(classNumber);
        await auth.loadHomeworksForClass(classNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final classNumber = _classNumber;

    if (classNumber == null) {
      return const Scaffold(
        body: Center(
          child: Text('No class assigned'),
        ),
      );
    }

    final lessons = auth.getLessonsForClass(classNumber);
    final homeworks = auth.getHomeworksForClass(classNumber);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lessons & Homework'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await auth.loadLessonsForClass(classNumber);
          await auth.loadHomeworksForClass(classNumber);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class $classNumber',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh, size: 16),
                      SizedBox(width: 6),
                      Text('Pull to refresh'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Lessons',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (lessons.isEmpty)
                      Text(
                        'No lessons have been posted yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      ...lessons.map(
                        (l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: const Icon(Icons.circle, size: 12),
                            title: Text(
                              l['title'] ?? '',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: (l['desc'] ?? '').isEmpty
                                ? null
                                : Text(l['desc'] ?? ''),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Homework',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (homeworks.isEmpty)
                      Text(
                        'No homework has been assigned yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      ...homeworks.map(
                        (h) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading:
                                const Icon(Icons.check_box_outline_blank, size: 18),
                            title: Text(
                              h['title'] ?? '',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: (h['desc'] ?? '').isEmpty
                                ? null
                                : Text(h['desc'] ?? ''),
                            trailing: TextButton(
                              onPressed: () async {
                                final homeworkId = h['id'] as String?;
                                if (homeworkId == null) return;

                                final controller = TextEditingController();
                                final submitted = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Submit Homework'),
                                      content: TextField(
                                        controller: controller,
                                        maxLines: 4,
                                        decoration: const InputDecoration(
                                          labelText: 'Your answer',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final text =
                                                controller.text.trim();
                                            if (text.isEmpty) return;
                                            await context
                                                .read<AuthProvider>()
                                                .submitHomework(
                                                  classNumber: classNumber,
                                                  homeworkId: homeworkId,
                                                  answerText: text,
                                                );
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text('Submit'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (submitted == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Homework submitted successfully'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          ),
                        ),
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

