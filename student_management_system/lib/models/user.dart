class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin', 'teacher', 'student', 'parent'
  final String? className;
  final String? subject;
  final String? parentId;
  final List<String>? studentIds;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.className,
    this.subject,
    this.parentId,
    this.studentIds,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      className: data['className'],
      subject: data['subject'],
      parentId: data['parentId'],
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: DateTime.parse(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'className': className,
      'subject': subject,
      'parentId': parentId,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}