
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  @override
  void initState() {
    super.initState();
    // Load teachers from Firestore so they are visible after app reloads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadTeachersFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final teachers = auth.teacherEmails;
          if (teachers.isEmpty) {
            return const Center(
              child: Text('No teachers added yet.'),
            );
          }
          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final email = teachers[index];
              // Class per teacher is stored in AuthProvider but not yet exposed per email;
              // for now we keep the original placeholder subtitle.
              final className = auth.currentUser?.className ?? '';
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(email),
                subtitle: Text('Teacher account $className'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete Teacher'),
                          content: Text(
                              'Are you sure you want to delete teacher "$email"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await context.read<AuthProvider>().deleteTeacher(email);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teacher deleted'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTeacherDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTeacherDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int? selectedClass;
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Teacher'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher email / username',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email / username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Math',
                      child: Text('Math'),
                    ),
                    DropdownMenuItem(
                      value: 'Science',
                      child: Text('Science'),
                    ),
                    DropdownMenuItem(
                      value: 'English',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'Social Studies',
                      child: Text('Social Studies'),
                    ),
                    DropdownMenuItem(
                      value: 'Computer',
                      child: Text('Computer'),
                    ),
                  ],
                  onChanged: (value) {
                    selectedSubject = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class (1-10)',
                  ),
                  items: List.generate(
                    10,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('Class ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    selectedClass = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a class';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final auth = context.read<AuthProvider>();
                auth.addTeacher(
                  emailController.text.trim(),
                  passwordController.text,
                  selectedClass!,
                  selectedSubject!,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teacher added successfully')), 
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

