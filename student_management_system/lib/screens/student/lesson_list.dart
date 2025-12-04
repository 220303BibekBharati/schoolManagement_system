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
  int _submittedHomeworkCount = 0;

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
      await auth.loadLessonCompletionsForSubject(
        classNumber: widget.classNumber,
        subject: widget.subject,
      );
      final user = auth.currentUser;
      if (user != null) {
        final submitted = await auth.countSubmittedHomeworksForSubject(
          classNumber: widget.classNumber,
          subject: widget.subject,
          studentId: user.id,
        );
        if (mounted) {
          setState(() {
            _submittedHomeworkCount = submitted;
          });
        }
      }
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

                      final totalLessons = docs.length;
                      if (totalLessons == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                              'No lessons available for this subject yet.'),
                        );
                      }

                      // Group lessons by unit label (teacher-defined)
                      final Map<String,
                              List<QueryDocumentSnapshot<Map<String, dynamic>>>>
                          units = {};

                      for (final d in docs) {
                        final data = d.data();
                        final rawUnit = (data['unit'] as String? ?? '').trim();
                        final unitKey = rawUnit.isEmpty ? 'Other' : rawUnit;
                        units.putIfAbsent(unitKey, () => []).add(d);
                      }

                      final unitNames = units.keys.toList()
                        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                      // Lessons progress: use in-memory completions if present
                      int completedLessons = 0;
                      if (user != null) {
                        for (final d in docs) {
                          if (auth.isLessonCompleted(
                            user.id,
                            widget.classNumber,
                            widget.subject,
                            d.id,
                          )) {
                            completedLessons++;
                          }
                        }
                      }

                      final lessonsProgress = totalLessons == 0
                          ? 0
                          : ((completedLessons / totalLessons) * 100).round();

                      // Homework progress based on actual submissions
                      final totalHomeworks = homeworks.length;
                      final submittedHomeworks = totalHomeworks == 0
                          ? 0
                          : _submittedHomeworkCount.clamp(0, totalHomeworks);
                      final homeworkProgress = totalHomeworks == 0
                          ? 0
                          : ((submittedHomeworks / totalHomeworks) * 100)
                              .round();

                      String yearLabelForClass(int c) {
                        switch (c) {
                          case 1:
                            return 'Year One';
                          case 2:
                            return 'Year Two';
                          case 3:
                            return 'Year Three';
                          case 4:
                            return 'Year Four';
                          case 5:
                            return 'Year Five';
                          default:
                            return 'Year $c';
                        }
                      }

                      final yearLabel = yearLabelForClass(widget.classNumber);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium-style header
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.subject,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Chip(
                                            label: Text(yearLabel),
                                            backgroundColor: Colors.white
                                                .withOpacity(0.12),
                                            labelStyle: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Chip(
                                            label:
                                                Text('$totalLessons lessons'),
                                            backgroundColor: Colors.white
                                                .withOpacity(0.12),
                                            labelStyle: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Chip(
                                            label: Text(
                                                '$totalHomeworks homework'),
                                            backgroundColor: Colors.white
                                                .withOpacity(0.12),
                                            labelStyle: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 140,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Lessons progress circle
                                      _ProgressCircle(
                                        label: 'Lessons',
                                        percent: lessonsProgress,
                                      ),
                                      const SizedBox(height: 12),
                                      _ProgressCircle(
                                        label: 'Homework',
                                        percent: homeworkProgress,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Units & Lessons',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: unitNames.length,
                            itemBuilder: (context, unitIndex) {
                              final unitName = unitNames[unitIndex];
                              final unitDocs = units[unitName] ?? const [];

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 1.5,
                                child: ExpansionTile(
                                  title: Text(
                                    unitName,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  children: unitDocs.asMap().entries.map((e) {
                                    final index = e.key;
                                    final doc = e.value;
                                    final data = doc.data();
                                    final title =
                                        (data['title'] as String?)?.trim();
                                    final desc =
                                        (data['desc'] as String?)?.trim() ?? '';
                                    final imageUrl =
                                        (data['imageUrl'] as String?)?.trim() ?? '';
                                    final displayTitle =
                                        title != null && title.isNotEmpty
                                            ? title
                                            : 'Lesson ${index + 1}';
                                    final lessonId = doc.id;

                                    final isCompleted = user != null &&
                                        auth.isLessonCompleted(
                                          user.id,
                                          widget.classNumber,
                                          widget.subject,
                                          lessonId,
                                        );

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      leading: const Icon(Icons.play_arrow),
                                      title: Text(
                                        displayTitle,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: desc.isNotEmpty
                                          ? Text(
                                              desc,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            )
                                          : null,
                                      trailing: Icon(
                                        isCompleted
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isCompleted
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LessonDetailScreen(
                                              classNumber: widget.classNumber,
                                              subject: widget.subject,
                                              lessonId: lessonId,
                                              title: displayTitle,
                                              description: desc,
                                              imageUrl: imageUrl,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
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

class _ProgressCircle extends StatelessWidget {
  final String label;
  final int percent;

  const _ProgressCircle({
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    final value = clamped / 100.0;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 48,
          width: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor:
                    theme.colorScheme.onPrimary.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.secondary,
                ),
              ),
              Text(
                '$clamped%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
          ),
        ),
      ],
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
  final int classNumber;
  final String subject;
  final String lessonId;
  final String title;
  final String description;
  final String imageUrl;

  const LessonDetailScreen({
    super.key,
    required this.classNumber,
    required this.subject,
    required this.lessonId,
    required this.title,
    required this.description,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final completed = user != null &&
        auth.isLessonCompleted(user.id, classNumber, subject, lessonId);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (user == null || completed)
                    ? null
                    : () async {
                        await context
                            .read<AuthProvider>()
                            .markLessonComplete(
                              classNumber: classNumber,
                              subject: subject,
                              lessonId: lessonId,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                icon: Icon(
                  completed ? Icons.check_circle : Icons.check,
                ),
                label: Text(
                  completed ? 'Completed' : 'Mark as complete',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
