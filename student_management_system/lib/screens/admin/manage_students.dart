import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/providers/auth_provider.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  int _selectedClass = 1;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing students for the initial class from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadStudentsForClass(_selectedClass);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final students = auth.getStudentsForClass(_selectedClass);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Class:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _selectedClass,
                  items: List.generate(
                    10,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('Class ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedClass = value;
                    });
                    // Load students for the newly selected class
                    context
                        .read<AuthProvider>()
                        .loadStudentsForClass(_selectedClass);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Student Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _rollController,
                          decoration: const InputDecoration(
                            labelText: 'Roll No',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter roll';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _loginIdController,
                          decoration: const InputDecoration(
                            labelText: 'Login ID / Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter login ID';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter password';
                            }
                            if (value.length < 6) {
                              return 'Min 6 chars';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          final name = _nameController.text.trim();
                          final rollNo =
                              int.parse(_rollController.text.trim());
                          final loginId = _loginIdController.text.trim();
                          final password = _passwordController.text.trim();
                          context.read<AuthProvider>().addStudent(
                                classNumber: _selectedClass,
                                name: name,
                                rollNo: rollNo,
                                loginId: loginId,
                                password: password,
                              );
                          _nameController.clear();
                          _rollController.clear();
                          _loginIdController.clear();
                          _passwordController.clear();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('No students for this class yet.'))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final rollNo = s['rollNo'] as int;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(rollNo.toString()),
                          ),
                          title: Text(s['name'] as String),
                          subtitle:
                              Text('Class $_selectedClass • Roll $rollNo'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Student'),
                                    content: Text(
                                        'Delete student "${s['name']}" (Roll $rollNo)?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                await context
                                    .read<AuthProvider>()
                                    .deleteStudent(
                                      classNumber: _selectedClass,
                                      rollNo: rollNo,
                                    );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Student deleted'),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

