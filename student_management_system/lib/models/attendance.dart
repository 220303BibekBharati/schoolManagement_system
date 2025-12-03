class Attendance {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final DateTime date;
  final String status; // 'present', 'absent', 'late'
  final String subject;
  final String markedBy; // Teacher ID

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.status,
    required this.subject,
    required this.markedBy,
  });

  factory Attendance.fromMap(Map<String, dynamic> data) {
    return Attendance(
      id: data['id'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      className: data['className'] ?? '',
      date: DateTime.parse(data['date']),
      status: data['status'] ?? 'absent',
      subject: data['subject'] ?? '',
      markedBy: data['markedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'date': date.toIso8601String(),
      'status': status,
      'subject': subject,
      'markedBy': markedBy,
    };
  }
}