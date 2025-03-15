import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../services/data_service.dart';

class SubjectProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  List<Subject> _subjects = [];
  bool _isLoading = false;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;

  Future<void> loadSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await _dataService.getSubjects();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading subjects: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubject(String name) async {
    final subject = Subject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );

    try {
      await _dataService.addSubject(subject);
      _subjects.add(subject);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding subject: $e');
      }
    }
  }

  Future<void> updateSubjectGrade(String subjectId, double newGrade) async {
    final index = _subjects.indexWhere((subject) => subject.id == subjectId);
    
    if (index != -1) {
      _subjects[index].updateGrade(newGrade);
      await _dataService.updateSubject(_subjects[index]);
      notifyListeners();
    }
  }

  Future<void> addGradeSnapshot(String subjectId, String label) async {
    final index = _subjects.indexWhere((subject) => subject.id == subjectId);
    
    if (index != -1) {
      _subjects[index].addGradeSnapshot(label);
      await _dataService.updateSubject(_subjects[index]);
      notifyListeners();
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _dataService.deleteSubject(subjectId);
      _subjects.removeWhere((subject) => subject.id == subjectId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting subject: $e');
      }
    }
  }
} 