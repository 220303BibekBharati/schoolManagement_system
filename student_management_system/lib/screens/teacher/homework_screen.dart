import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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

  int? _selectedClass;
  String? _lessonImageUrl;
  String? _lessonImageName;
  bool _isUploadingLessonImage = false;

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
        setState(() {
          _selectedClass = classNumber;
        });
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
    final classNumber = _selectedClass;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Class',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  DropdownButton<int>(
                    value: _selectedClass,
                    hint: const Text('Choose class'),
                    items: List.generate(12, (i) => i + 1)
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c,
                            child: Text('Class $c'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() {
                        _selectedClass = value;
                      });
                      await auth.loadLessonsForClass(value);
                      await auth.loadHomeworksForClass(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Add Lesson',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
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
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Attach Image'),
                    onPressed: classNumber == null || _isUploadingLessonImage
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );
                            if (result == null || result.files.isEmpty) return;
                            final file = result.files.first;
                            final bytes = file.bytes;
                            if (bytes == null) return;

                            setState(() {
                              _isUploadingLessonImage = true;
                            });

                            final path =
                                'lessons/class_${classNumber}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                            final url = await context
                                .read<AuthProvider>()
                                .uploadLessonImage(bytes, path);

                            if (!mounted) return;
                            setState(() {
                              _lessonImageUrl = url;
                              _lessonImageName = file.name;
                              _isUploadingLessonImage = false;
                            });
                          },
                  ),
                  const SizedBox(width: 8),
                  if (_isUploadingLessonImage)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_lessonImageName != null)
                    Expanded(
                      child: Text(
                        _lessonImageName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
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
                          imageUrl: _lessonImageUrl,
                        );
                    _lessonTitleController.clear();
                    _lessonDescController.clear();
                    setState(() {
                      _lessonImageUrl = null;
                      _lessonImageName = null;
                    });
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
                      (l) => _HoverCard(
                        icon: Icons.menu_book,
                        iconColor: Colors.deepPurple,
                        title: l['title'] ?? '',
                        subtitle: l['desc'] ?? '',
                        onDelete: () async {
                          if (classNumber == null) return;
                          final lessonId = l['id'] as String?;
                          if (lessonId == null || lessonId.isEmpty) return;
                          await context
                              .read<AuthProvider>()
                              .deleteLesson(
                                classNumber: classNumber,
                                lessonId: lessonId,
                              );
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                'Add Homework',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
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
                      (h) => _HoverCard(
                        icon: Icons.assignment,
                        iconColor: Colors.blueAccent,
                        title: h['title'] ?? '',
                        subtitle: h['desc'] ?? '',
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
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _HoverCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.onDelete,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: _hovering ? 4 : 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.iconColor.withOpacity(0.1),
              child: Icon(widget.icon, color: widget.iconColor),
            ),
            title: Text(
              widget.title,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: widget.subtitle.isNotEmpty
                ? Text(widget.subtitle)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Delete',
                    onPressed: widget.onDelete,
                  ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

