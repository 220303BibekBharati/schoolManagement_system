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

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final title = data['title'] as String? ?? 'Notification';
              final body = data['body'] as String? ?? '';
              final createdAtStr = data['createdAt'] as String?;

              DateTime? createdAt;
              if (createdAtStr != null) {
                try {
                  createdAt = DateTime.parse(createdAtStr);
                } catch (_) {}
              }

              final timeLabel = createdAt != null
                  ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}  '
                      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                  : createdAtStr ?? '';

              final iconColor = role == 'teacher'
                  ? Colors.deepPurple
                  : Colors.blueAccent;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(
                      Icons.notifications,
                      color: iconColor,
                    ),
                  ),
                  title: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (body.isNotEmpty)
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        timeLabel,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
