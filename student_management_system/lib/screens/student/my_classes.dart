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

    String yearLabelForClass(int c) {
      // Simple mapping; adjust as needed
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

    final yearLabel = yearLabelForClass(classNumber);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Modules',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your enrolled subjects',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];

                      return _StudentSubjectTile(
                        index: index,
                        classNumber: classNumber,
                        subject: subject,
                        yearLabel: yearLabel,
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

class _StudentSubjectTile extends StatefulWidget {
  final int index;
  final int classNumber;
  final String subject;
  final String yearLabel;

  const _StudentSubjectTile({
    required this.index,
    required this.classNumber,
    required this.subject,
    required this.yearLabel,
  });

  @override
  State<_StudentSubjectTile> createState() => _StudentSubjectTileState();
}

class _StudentSubjectTileState extends State<_StudentSubjectTile> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final coolGradients = [
      [Colors.blue.shade500, Colors.teal.shade400],
      [Colors.indigo.shade500, Colors.cyan.shade400],
      [Colors.lightBlue.shade400, Colors.teal.shade300],
      [Colors.blueGrey.shade500, Colors.blue.shade400],
    ];

    final colors = coolGradients[widget.index % coolGradients.length];

    final scale = _pressed
        ? 0.97
        : _hovering
            ? 1.03
            : 1.0;

    void openModule() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonListScreen(
            classNumber: widget.classNumber,
            subject: widget.subject,
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: openModule,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors[0].withOpacity(0.95),
                  colors[1].withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[1].withOpacity(_hovering ? 0.35 : 0.22),
                  blurRadius: _hovering ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.yearLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                    onPressed: openModule,
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                    label: const Text('Go To Module'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
