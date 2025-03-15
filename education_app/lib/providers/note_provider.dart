import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/data_service.dart';

class NoteProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _dataService.getNotes();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notes: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotesForSubject(String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _dataService.getNotesForSubject(subjectId);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notes for subject: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String subjectId, String title, String content) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: subjectId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _dataService.addNote(note);
      _notes.add(note);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding note: $e');
      }
    }
  }

  Future<void> updateNote(String noteId, String title, String content) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    
    if (index != -1) {
      final updatedNote = _notes[index].copyWith(
        title: title,
        content: content,
      );
      
      try {
        await _dataService.updateNote(updatedNote);
        _notes[index] = updatedNote;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error updating note: $e');
        }
      }
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _dataService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting note: $e');
      }
    }
  }
} 