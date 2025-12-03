import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _lessonTitleController = TextEditingController();
  final _lessonDescController = TextEditingController();
  final _hwTitleController = TextEditingController();
  final _hwDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing lessons and homework for this teacher's class from Firestore
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
        await auth.loadLessonsForClass(classNumber);
        await auth.loadHomeworksForClass(classNumber);
      }
    });
  }

  @override
  void dispose() {
    _lessonTitleController.dispose();
    _lessonDescController.dispose();
    _hwTitleController.dispose();
    _hwDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    int? classNumber;
    if (user?.className != null) {
      final parts = user!.className!.split(' ');
      if (parts.length == 2) {
        classNumber = int.tryParse(parts[1]);
      }
    }

    final lessons = classNumber != null
        ? auth.getLessonsForClass(classNumber)
        : const <Map<String, String>>[];
    final homeworks = classNumber != null
        ? auth.getHomeworksForClass(classNumber)
        : const <Map<String, String>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons & Homework'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Lesson',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lessonTitleController,
                decoration: const InputDecoration(
                  labelText: 'Lesson Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lessonDescController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    if (classNumber == null) return;
                    final title = _lessonTitleController.text.trim();
                    final desc = _lessonDescController.text.trim();
                    if (title.isEmpty) return;
                    await context.read<AuthProvider>().addLesson(
                          classNumber: classNumber,
                          title: title,
                          desc: desc,
                        );
                    _lessonTitleController.clear();
                    _lessonDescController.clear();
                  },
                  child: const Text('Add Lesson'),
                ),
              ),
              const SizedBox(height: 16),
              if (lessons.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lessons',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...lessons.map(
                      (l) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: Text(l['title'] ?? ''),
                          subtitle: Text(l['desc'] ?? ''),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                'Add Homework',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hwTitleController,
                decoration: const InputDecoration(
                  labelText: 'Homework Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hwDescController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    if (classNumber == null) return;
                    final title = _hwTitleController.text.trim();
                    final desc = _hwDescController.text.trim();
                    if (title.isEmpty) return;
                    await context.read<AuthProvider>().addHomework(
                          classNumber: classNumber,
                          title: title,
                          desc: desc,
                        );
                    _hwTitleController.clear();
                    _hwDescController.clear();
                  },
                  child: const Text('Add Homework'),
                ),
              ),
              const SizedBox(height: 16),
              if (homeworks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Homework',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...homeworks.map(
                      (h) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.assignment),
                          title: Text(h['title'] ?? ''),
                          subtitle: Text(h['desc'] ?? ''),
                          onTap: () async {
                            if (classNumber == null) return;
                            final homeworkId = h['id'] as String?;
                            if (homeworkId == null) return;

                            final submissions = await context
                                .read<AuthProvider>()
                                .loadHomeworkSubmissions(
                                  classNumber,
                                  homeworkId,
                                );

                            // Show submissions in a simple dialog
                            // (read-only for now)
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Submissions'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: submissions.isEmpty
                                        ? const Text(
                                            'No submissions yet for this homework.',
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: submissions.length,
                                            itemBuilder: (context, index) {
                                              final s = submissions[index];
                                              return ListTile(
                                                title: Text(
                                                  s['studentName'] as String? ??
                                                      'Student',
                                                ),
                                                subtitle: Text(
                                                  s['answerText'] as String? ??
                                                      '',
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

