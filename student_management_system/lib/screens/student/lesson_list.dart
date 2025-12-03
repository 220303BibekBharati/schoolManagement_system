import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class LessonListScreen extends StatelessWidget {
  final int classNumber;
  final String subject;

  const LessonListScreen({
    super.key,
    required this.classNumber,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final lessonsStream = FirebaseFirestore.instance
        .collection('classes')
        .doc(classNumber.toString())
        .collection('lessons')
        .where('subject', isEqualTo: subject)
        .orderBy('createdAt')
        .snapshots();

    final homeworkStream = FirebaseFirestore.instance
        .collection('classes')
        .doc(classNumber.toString())
        .collection('homeworks')
        .where('subject', isEqualTo: subject)
        .orderBy('createdAt')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lessons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: lessonsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No lessons available for this subject yet.'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final title = (data['title'] as String?)?.trim();
                    final desc = (data['desc'] as String?)?.trim() ?? '';
                    final displayTitle = title != null && title.isNotEmpty
                        ? title
                        : 'Lesson ${index + 1}';

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: Text(displayTitle),
                        subtitle: desc.isNotEmpty
                            ? Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing:
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonDetailScreen(
                                title: displayTitle,
                                description: desc,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Homework',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: homeworkStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No homework assigned for this subject yet.'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final title = (data['title'] as String?)?.trim();
                    final desc = (data['desc'] as String?)?.trim() ?? '';
                    final displayTitle = title != null && title.isNotEmpty
                        ? title
                        : 'Homework ${index + 1}';
                    final homeworkId = docs[index].id;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment),
                        title: Text(displayTitle),
                        subtitle: desc.isNotEmpty
                            ? Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing:
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeworkDetailScreen(
                                classNumber: classNumber,
                                homeworkId: homeworkId,
                                title: displayTitle,
                                description: desc,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeworkDetailScreen extends StatelessWidget {
  final int classNumber;
  final String homeworkId;
  final String title;
  final String description;

  const HomeworkDetailScreen({
    super.key,
    required this.classNumber,
    required this.homeworkId,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description.isNotEmpty
                      ? description
                      : 'No details provided for this homework.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
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
                              final text = controller.text.trim();
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

                  if (submitted == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Homework submitted successfully'),
                      ),
                    );
                  }
                },
                child: const Text('Submit Homework'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonDetailScreen extends StatelessWidget {
  final String title;
  final String description;

  const LessonDetailScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            description.isNotEmpty ? description : 'No details provided for this lesson.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
