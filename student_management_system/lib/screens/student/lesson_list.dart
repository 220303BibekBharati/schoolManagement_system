import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class LessonListScreen extends StatefulWidget {
  final int classNumber;
  final String subject;

  const LessonListScreen({
    super.key,
    required this.classNumber,
    required this.subject,
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      setState(() {
        _isLoading = true;
      });
      await auth.loadLessonsForClass(widget.classNumber);
      await auth.loadHomeworksForClass(widget.classNumber);
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
    final allHomeworks = auth.getHomeworksForClass(widget.classNumber);

    List<Map<String, dynamic>> _filterHomeworksBySubject(
        List<Map<String, dynamic>> items) {
      return items.where((item) {
        final s = (item['subject'] as String? ?? '').trim();
        if (s.isEmpty) return false;
        return s.toLowerCase() == widget.subject.toLowerCase();
      }).toList();
    }

    final homeworks = _filterHomeworksBySubject(allHomeworks);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lessons',
                        style: theme.textTheme.titleLarge,
                      ),
                      Chip(
                        label: Text('Class ${widget.classNumber}'),
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.08),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('classes')
                        .doc(widget.classNumber.toString())
                        .collection('lessons')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                              'No lessons available for this subject yet.'),
                        );
                      }

                      // Filter by subject on client side to avoid index issues
                      final docs = snapshot.data!.docs.where((d) {
                        final data = d.data();
                        final s = (data['subject'] as String? ?? '').trim();
                        if (s.isEmpty) return false;
                        return s.toLowerCase() ==
                            widget.subject.toLowerCase();
                      }).toList();

                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                              'No lessons available for this subject yet.'),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final title = (data['title'] as String?)?.trim();
                          final desc = (data['desc'] as String?)?.trim() ?? '';
                          final imageUrl =
                              (data['imageUrl'] as String?)?.trim() ?? '';
                          final displayTitle = title != null && title.isNotEmpty
                              ? title
                              : 'Lesson ${index + 1}';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Colors.orange.shade50,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LessonDetailScreen(
                                      title: displayTitle,
                                      description: desc,
                                      imageUrl: imageUrl,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.9),
                                      child: const Icon(Icons.menu_book,
                                          color: Colors.deepOrange),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayTitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          if (desc.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                  right: 4.0,
                                                  bottom: 4.0),
                                              child: Text(
                                                desc,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          if (imageUrl.isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                imageUrl,
                                                height: 80,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const SizedBox(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ],
                                ),
                              ),
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
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (homeworks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child:
                          Text('No homework assigned for this subject yet.'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: homeworks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final h = homeworks[index];
                        final title = (h['title'] as String?)?.trim();
                        final desc = (h['desc'] as String?)?.trim() ?? '';
                        final displayTitle = title != null && title.isNotEmpty
                            ? title
                            : 'Homework ${index + 1}';
                        final homeworkId = h['id'] as String? ?? '';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.lightBlue.shade50,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.white.withOpacity(0.9),
                              child: const Icon(Icons.assignment,
                                  color: Colors.blueAccent),
                            ),
                            title: Text(displayTitle),
                            subtitle: desc.isNotEmpty
                                ? Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16),
                            onTap: () {
                              if (homeworkId.isEmpty) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HomeworkDetailScreen(
                                    classNumber: widget.classNumber,
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
  final String imageUrl;

  const LessonDetailScreen({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl = '',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description.isNotEmpty
                    ? description
                    : 'No details provided for this lesson.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (imageUrl.isNotEmpty) const SizedBox(height: 16),
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
