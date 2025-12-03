import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _target = 'all'; // all, teachers, students
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseFirestore.instance.collection('notification_requests').add({
        'title': title,
        'body': body,
        'target': _target, // 'all' | 'teachers' | 'students'
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification request sent')),
      );
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _target = 'all';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compose Notification',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Short title (e.g. Exam Tomorrow)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bodyController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Write the full notification message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.group, size: 18),
                          const SizedBox(width: 8),
                          const Text('Send to:'),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _target,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All (Teachers + Students)'),
                              ),
                              DropdownMenuItem(
                                value: 'teachers',
                                child: Text('Teachers only'),
                              ),
                              DropdownMenuItem(
                                value: 'students',
                                child: Text('Students only'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _target = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _send,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isSending ? 'Sending...' : 'Send Notification',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
