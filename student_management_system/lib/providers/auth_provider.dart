import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_management_system/services/auth_service.dart';
import 'package:student_management_system/models/user.dart';
import 'package:student_management_system/models/attendance.dart';
import 'package:student_management_system/utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  // email -> { 'password': String, 'classNumber': int }
  final Map<String, Map<String, dynamic>> _teachers = {};
  bool _teacherCredsLoaded = false;
  // classNumber -> list of students { 'name': String, 'rollNo': int }
  final Map<int, List<Map<String, dynamic>>> _classStudents = {};
  // classNumber -> list of lessons { 'title': String, 'desc': String }
  final Map<int, List<Map<String, String>>> _classLessons = {};
  // classNumber -> list of homeworks
  final Map<int, List<Map<String, String>>> _classHomeworks = {};
  // classNumber -> list of timetable entries { 'dayOfWeek': String, 'time': String, 'subject': String }
  final Map<int, List<Map<String, String>>> _classTimetables = {};
  // studentId -> list of attendance records
  final Map<String, List<Attendance>> _studentAttendance = {};

  static const String _teacherCredsKey = 'teacher_credentials';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get teacherEmails => _teachers.keys.toList(growable: false);
  List<Map<String, dynamic>> getStudentsForClass(int classNumber) =>
      _classStudents[classNumber] ?? const [];
  List<Map<String, String>> getLessonsForClass(int classNumber) =>
      _classLessons[classNumber] ?? const [];
  List<Map<String, String>> getHomeworksForClass(int classNumber) =>
      _classHomeworks[classNumber] ?? const [];
  List<Map<String, String>> getTimetableForClass(int classNumber) =>
      _classTimetables[classNumber] ?? const [];
  List<Attendance> getAttendanceForStudent(String studentId) =>
      _studentAttendance[studentId] ?? const [];

  Future<void> _loadTeacherCredentialsIfNeeded() async {
    if (_teacherCredsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_teacherCredsKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonString);
        _teachers
          ..clear()
          ..addAll(data.map((key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map))));
      } catch (_) {
        // ignore corrupt data and start fresh
        _teachers.clear();
      }
    }

    _teacherCredsLoaded = true;
  }

  Future<void> _saveTeacherCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_teachers);

    await prefs.setString(_teacherCredsKey, jsonString);
  }

  Future<void> loadTeachersFromFirestore() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: AppConstants.teacherRole)
        .get();

    _teachers
      ..clear()
      ..addEntries(
        snap.docs.map((d) {
          final data = d.data();
          final email = data['email'] as String? ?? '';
          final classNumber = data['classNumber'] as int? ?? 0;
          final subject = data['subject'] as String? ?? '';
          final password = data['password'] as String? ?? '';
          return MapEntry(email, {
            'password': password,
            'classNumber': classNumber,
            'subject': subject,
          });
        }),
      );
    _teacherCredsLoaded = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadTeacherCredentialsIfNeeded();

      // Look up user in Firestore
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw Exception('Invalid credentials');
      }

      final doc = snap.docs.first;
      final data = doc.data();

      if (data['password'] != password) {
        throw Exception('Invalid credentials');
      }

      final role = data['role'] as String?;
      if (role == null) {
        throw Exception('User role not set');
      }

      // Map Firestore user to local User model
      _currentUser = _userFromFirestore(doc.id, data);

      // Subscribe to FCM topics for native platforms only (not supported on web)
      if (!kIsWeb) {
        try {
          final messaging = FirebaseMessaging.instance;
          if (role == AppConstants.teacherRole) {
            await messaging.subscribeToTopic('teachers');
          } else if (role == AppConstants.studentRole) {
            await messaging.subscribeToTopic('students');
          }
        } catch (_) {
          // Ignore notification subscription errors so login still succeeds
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _classNameFromData(Map<String, dynamic> data) {
    final classNumber = data['classNumber'];
    if (classNumber is int) {
      return 'Class $classNumber';
    }
    return data['className'] as String?;
  }

  User _userFromFirestore(String id, Map<String, dynamic> data) {
    final createdAtString = data['createdAt'] as String?;
    DateTime createdAt;
    try {
      createdAt = createdAtString != null
          ? DateTime.parse(createdAtString)
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    return User(
      id: id,
      name: (data['name'] as String?) ?? 'User',
      email: (data['email'] as String?) ?? '',
      role: (data['role'] as String?) ?? '',
      className: _classNameFromData(data),
      subject: data['subject'] as String?,
      parentId: data['parentId'] as String?,
      studentIds: data['studentIds'] != null
          ? List<String>.from(data['studentIds'] as List)
          : null,
      createdAt: createdAt,
    );
  }

  Future<void> addTeacher(
    String email,
    String password,
    int classNumber,
    String subject,
  ) async {
    _teachers[email] = {
      'password': password,
      'classNumber': classNumber,
      'subject': subject,
    };
    _saveTeacherCredentials();
    notifyListeners();

    // Persist teacher user in Firestore so the account survives restarts
    final users = FirebaseFirestore.instance.collection('users');
    await users.doc(email).set({
      'email': email,
      'password': password,
      'role': AppConstants.teacherRole, // 'teacher'
      'classNumber': classNumber,
      'subject': subject,
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteTeacher(String email) async {
    // Remove from in-memory cache
    _teachers.remove(email);
    notifyListeners();

    // Remove from Firestore users collection
    final users = FirebaseFirestore.instance.collection('users');
    await users.doc(email).delete();
  }

  Future<void> addStudent({
    required int classNumber,
    required String name,
    required int rollNo,
    required String loginId,
    required String password,
  }) async {
    final list = _classStudents[classNumber] ?? <Map<String, dynamic>>[];
    // Simple rule: don't allow duplicate roll numbers in same class
    final exists = list.any((s) => s['rollNo'] == rollNo);
    if (!exists) {
      list.add({
        'name': name,
        'rollNo': rollNo,
        'loginId': loginId,
      });

      _classStudents[classNumber] = list;
      notifyListeners();

      // Persist student basic record in a separate 'students' collection
      final students = FirebaseFirestore.instance.collection('students');
      await students.add({
        'name': name,
        'rollNo': rollNo,
        'classNumber': classNumber,
        'loginId': loginId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Also create a user document so the student can log in
      final users = FirebaseFirestore.instance.collection('users');
      await users.doc(loginId).set({
        'email': loginId,
        'password': password,
        'role': AppConstants.studentRole,
        'classNumber': classNumber,
        'rollNo': rollNo,
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteStudent({
    required int classNumber,
    required int rollNo,
  }) async {
    // Update in-memory list
    final list = _classStudents[classNumber] ?? <Map<String, dynamic>>[];
    list.removeWhere((s) => s['rollNo'] == rollNo);
    _classStudents[classNumber] = list;
    notifyListeners();

    // Delete from students collection (match by classNumber + rollNo)
    final studentsCol = FirebaseFirestore.instance.collection('students');
    final snap = await studentsCol
        .where('classNumber', isEqualTo: classNumber)
        .where('rollNo', isEqualTo: rollNo)
        .get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }

    // Delete from users collection (student accounts for this class/roll)
    final usersCol = FirebaseFirestore.instance.collection('users');
    final userSnap = await usersCol
        .where('role', isEqualTo: AppConstants.studentRole)
        .where('classNumber', isEqualTo: classNumber)
        .where('rollNo', isEqualTo: rollNo)
        .get();
    for (final d in userSnap.docs) {
      await d.reference.delete();
    }
  }

  Future<void> loadStudentsForClass(int classNumber) async {
    final studentsCol = FirebaseFirestore.instance.collection('students');

    // Query where classNumber is stored as an int
    final numericSnap = await studentsCol
        .where('classNumber', isEqualTo: classNumber)
        .get();

    // Query where classNumber might have been stored as a string
    final stringSnap = await studentsCol
        .where('classNumber', isEqualTo: classNumber.toString())
        .get();

    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...numericSnap.docs,
      ...stringSnap.docs,
    ];

    _classStudents[classNumber] = allDocs
        .map((d) => {
              'name': d['name'] as String? ?? '',
              'rollNo': d['rollNo'] is int
                  ? d['rollNo'] as int
                  : int.tryParse(d['rollNo']?.toString() ?? '0') ?? 0,
            })
        .toList();
    notifyListeners();
  }

  Future<void> saveAttendanceForDate({
    required int classNumber,
    required DateTime date,
    required Map<int, bool> attendanceByRoll,
  }) async {
    final teacher = _currentUser;
    if (teacher == null) return;

    final dateKey = date.toIso8601String().split('T').first;
    final attendanceCol = FirebaseFirestore.instance.collection('attendance');

    final students = _classStudents[classNumber] ?? <Map<String, dynamic>>[];

    for (final s in students) {
      final roll = s['rollNo'] as int?;
      if (roll == null) continue;

      final present = attendanceByRoll[roll] ?? false;

      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: AppConstants.studentRole)
          .where('classNumber', isEqualTo: classNumber)
          .where('rollNo', isEqualTo: roll)
          .limit(1)
          .get();

      if (usersSnap.docs.isEmpty) {
        continue;
      }

      final userDoc = usersSnap.docs.first;
      final userData = userDoc.data();
      final studentId = userDoc.id;
      final studentName = userData['name'] as String? ?? '';
      final className = 'Class $classNumber';

      final docId = '$studentId-$dateKey';

      final record = Attendance(
        id: docId,
        studentId: studentId,
        studentName: studentName,
        className: className,
        date: DateTime.parse(dateKey),
        status: present ? 'present' : 'absent',
        subject: teacher.subject ?? '',
        markedBy: teacher.id,
      );

      await attendanceCol.doc(docId).set(record.toMap());

      final list = _studentAttendance[studentId] ?? <Attendance>[];
      list.removeWhere((a) => a.date.toIso8601String().split('T').first == dateKey);
      list.add(record);
      _studentAttendance[studentId] = list;
    }

    notifyListeners();
  }

  Future<void> loadAttendanceForCurrentStudent() async {
    final user = _currentUser;
    if (user == null) return;
    final col = FirebaseFirestore.instance.collection('attendance');

    // New-style records: match by studentId (current user id)
    final byIdSnap = await col.where('studentId', isEqualTo: user.id).get();

    // Legacy records: match by studentName + className (e.g. "Class 10")
    QuerySnapshot<Map<String, dynamic>>? byNameSnap;
    try {
      if (user.name.isNotEmpty && (user.className ?? '').isNotEmpty) {
        byNameSnap = await col
            .where('studentName', isEqualTo: user.name)
            .where('className', isEqualTo: user.className)
            .get();
      }
    } catch (_) {
      // If composite index is missing, just skip legacy name-based query
      byNameSnap = null;
    }

    final seenIds = <String>{};
    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final d in byIdSnap.docs) {
      if (seenIds.add(d.id)) allDocs.add(d);
    }
    if (byNameSnap != null) {
      for (final d in byNameSnap.docs) {
        if (seenIds.add(d.id)) allDocs.add(d);
      }
    }

    final list = allDocs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return Attendance.fromMap(data);
    }).toList();

    list.sort((a, b) => a.date.compareTo(b.date));
    _studentAttendance[user.id] = list;

    notifyListeners();
  }

  Future<String?> uploadLessonImage(Uint8List data, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = await ref.putData(data);
    return await task.ref.getDownloadURL();
  }

  Future<void> addLesson({
    required int classNumber,
    required String title,
    required String desc,
    String? imageUrl,
  }) async {
    // Persist to Firestore; subject will be set by caller via currentUser.subject
    final classes = FirebaseFirestore.instance.collection('classes');
    await classes.doc(classNumber.toString()).collection('lessons').add({
      'title': title,
      'desc': desc,
      'imageUrl': imageUrl ?? '',
      'subject': _currentUser?.subject ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await loadLessonsForClass(classNumber);
  }

  Future<void> deleteLesson({
    required int classNumber,
    required String lessonId,
  }) async {
    final classes = FirebaseFirestore.instance.collection('classes');

    // New path
    await classes
        .doc(classNumber.toString())
        .collection('lessons')
        .doc(lessonId)
        .delete()
        .catchError((_) {});

    // Legacy path (ignore errors)
    await classes
        .doc('Class $classNumber')
        .collection('lessons')
        .doc(lessonId)
        .delete()
        .catchError((_) {});

    await loadLessonsForClass(classNumber);
  }

  Future<void> loadLessonsForClass(int classNumber) async {
    final classesCol = FirebaseFirestore.instance.collection('classes');

    // New structure: classes/{classNumber}/lessons
    final numericSnap = await classesCol
        .doc(classNumber.toString())
        .collection('lessons')
        .get();

    // Old structure (if any): classes/Class {classNumber}/lessons
    final legacySnap = await classesCol
        .doc('Class $classNumber')
        .collection('lessons')
        .get();

    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...numericSnap.docs,
      ...legacySnap.docs,
    ];

    _classLessons[classNumber] = allDocs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'title': data['title'] as String? ?? '',
        'desc': data['desc'] as String? ?? '',
        'imageUrl': data['imageUrl'] as String? ?? '',
        'subject': data['subject'] as String? ?? '',
      };
    }).toList();
    notifyListeners();
  }

  Future<void> addHomework({
    required int classNumber,
    required String title,
    required String desc,
  }) async {
    final classes = FirebaseFirestore.instance.collection('classes');
    await classes.doc(classNumber.toString()).collection('homeworks').add({
      'title': title,
      'desc': desc,
      'subject': _currentUser?.subject ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Reload from Firestore so we always have the correct homework IDs
    await loadHomeworksForClass(classNumber);
  }

  Future<void> loadHomeworksForClass(int classNumber) async {
    final classesCol = FirebaseFirestore.instance.collection('classes');

    // New structure: classes/{classNumber}/homeworks
    final numericSnap = await classesCol
        .doc(classNumber.toString())
        .collection('homeworks')
        .get();

    // Old structure (if any): classes/Class {classNumber}/homeworks
    final legacySnap = await classesCol
        .doc('Class $classNumber')
        .collection('homeworks')
        .get();

    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...numericSnap.docs,
      ...legacySnap.docs,
    ];

    _classHomeworks[classNumber] = allDocs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'title': data['title'] as String? ?? '',
        'desc': data['desc'] as String? ?? '',
        'subject': data['subject'] as String? ?? '',
      };
    }).toList();
    notifyListeners();
  }

  Future<void> loadTimetableForClass(int classNumber) async {
    final snap = await FirebaseFirestore.instance
        .collection('timetables')
        .where('classNumber', isEqualTo: classNumber)
        .get();

    _classTimetables[classNumber] = snap.docs.map((d) {
      final data = d.data();
      return {
        'dayOfWeek': data['dayOfWeek'] as String? ?? '',
        'time': data['time'] as String? ?? '',
        'subject': data['subject'] as String? ?? '',
      };
    }).toList();
    notifyListeners();
  }

  Future<void> addTimetableEntry({
    required int classNumber,
    required String dayOfWeek,
    required String time,
    required String subject,
  }) async {
    final col = FirebaseFirestore.instance.collection('timetables');
    await col.add({
      'classNumber': classNumber,
      'dayOfWeek': dayOfWeek,
      'time': time,
      'subject': subject,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await loadTimetableForClass(classNumber);
  }

  Future<List<String>> loadSubjectsForClass(int classNumber) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: AppConstants.teacherRole)
        .where('classNumber', isEqualTo: classNumber)
        .get();

    final subjects = <String>{};
    for (final d in snap.docs) {
      final data = d.data();
      final subject = data['subject'] as String? ?? '';
      if (subject.isNotEmpty) {
        subjects.add(subject);
      }
    }
    return subjects.toList()..sort();
  }

  Future<void> submitHomework({
    required int classNumber,
    required String homeworkId,
    required String answerText,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final submissionRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(classNumber.toString())
        .collection('homeworks')
        .doc(homeworkId)
        .collection('submissions')
        .doc(user.id);

    await submissionRef.set({
      'studentId': user.id,
      'studentName': user.name,
      'submittedAt': DateTime.now().toIso8601String(),
      'answerText': answerText,
    });
  }

  Future<List<Map<String, dynamic>>> loadHomeworkSubmissions(
    int classNumber,
    String homeworkId,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classNumber.toString())
        .collection('homeworks')
        .doc(homeworkId)
        .collection('submissions')
        .orderBy('submittedAt')
        .get();

    return snap.docs
        .map((d) => {
              'id': d.id,
              'studentId': d['studentId'] as String? ?? '',
              'studentName': d['studentName'] as String? ?? '',
              'submittedAt': d['submittedAt'] as String? ?? '',
              'answerText': d['answerText'] as String? ?? '',
            })
        .toList();
  }

  Future<void> logout() async {
    final user = _currentUser;
    if (user != null && !kIsWeb) {
      try {
        final messaging = FirebaseMessaging.instance;
        if (user.role == AppConstants.teacherRole) {
          await messaging.unsubscribeFromTopic('teachers');
        } else if (user.role == AppConstants.studentRole) {
          await messaging.unsubscribeFromTopic('students');
        }
      } catch (_) {
        // Ignore unsubscribe errors
      }
    }

    _currentUser = null;
    notifyListeners();
  }

  bool isLoggedIn() => _currentUser != null;
}