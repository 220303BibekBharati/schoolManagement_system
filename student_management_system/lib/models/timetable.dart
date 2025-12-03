class TimeSlot {
  final String id;
  final String className;
  final String subject;
  final String teacherId;
  final String teacherName;
  final String dayOfWeek; // 'Monday', 'Tuesday', etc.
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String roomNumber;

  TimeSlot({
    required this.id,
    required this.className,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> data) {
    return TimeSlot(
      id: data['id'] ?? '',
      className: data['className'] ?? '',
      subject: data['subject'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? '',
      startTime: _parseTime(data['startTime']),
      endTime: _parseTime(data['endTime']),
      roomNumber: data['roomNumber'] ?? '',
    );
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'className': className,
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dayOfWeek': dayOfWeek,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'roomNumber': roomNumber,
    };
  }
}