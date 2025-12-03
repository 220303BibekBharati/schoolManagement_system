import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationHistoryScreen extends StatelessWidget {
  final String role; // 'teacher' or 'student'

  const NotificationHistoryScreen({super.key, required this.role});

  bool _matchesTarget(String target) {
    final t = target.toLowerCase();
    if (t == 'all') return true;
    if (role == 'teacher' && t == 'teachers') return true;
    if (role == 'student' && t == 'students') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notification_requests')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No notifications yet.'),
            );
          }

          final docs = snapshot.data!.docs
              .where((d) => _matchesTarget(d.data()['target'] as String? ?? 'all'))
              .toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text('No notifications for you yet.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final title = data['title'] as String? ?? 'Notification';
              final body = data['body'] as String? ?? '';
              final createdAt = data['createdAt'] as String?;

              String subtitle = body;
              if (createdAt != null) {
                subtitle = '$body\n$createdAt';
              }

              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(title),
                subtitle: Text(subtitle),
              );
            },
          );
        },
      ),
    );
  }
}
