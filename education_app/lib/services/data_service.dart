import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/note.dart';
import '../models/planner_item.dart';

class DataService {
  static const String _subjectsKey = 'subjects';
  static const String _notesKey = 'notes';
  static const String _plannerItemsKey = 'plannerItems';

  // Subjects
  Future<List<Subject>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsJson = prefs.getStringList(_subjectsKey) ?? [];
    
    return subjectsJson
        .map((json) => Subject.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveSubjects(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsJson = subjects
        .map((subject) => jsonEncode(subject.toJson()))
        .toList();
    
    await prefs.setStringList(_subjectsKey, subjectsJson);
  }

  Future<void> addSubject(Subject subject) async {
    final subjects = await getSubjects();
    subjects.add(subject);
    await saveSubjects(subjects);
  }

  Future<void> updateSubject(Subject subject) async {
    final subjects = await getSubjects();
    final index = subjects.indexWhere((s) => s.id == subject.id);
    
    if (index != -1) {
      subjects[index] = subject;
      await saveSubjects(subjects);
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    final subjects = await getSubjects();
    subjects.removeWhere((subject) => subject.id == subjectId);
    await saveSubjects(subjects);

    // Also delete related notes and planner items
    final notes = await getNotes();
    notes.removeWhere((note) => note.subjectId == subjectId);
    await saveNotes(notes);

    final plannerItems = await getPlannerItems();
    plannerItems.removeWhere((item) => item.subjectId == subjectId);
    await savePlannerItems(plannerItems);
  }

  // Notes
  Future<List<Note>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<Note>> getNotesForSubject(String subjectId) async {
    final notes = await getNotes();
    return notes.where((note) => note.subjectId == subjectId).toList();
  }

  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    
    await prefs.setStringList(_notesKey, notesJson);
  }

  Future<void> addNote(Note note) async {
    final notes = await getNotes();
    notes.add(note);
    await saveNotes(notes);
  }

  Future<void> updateNote(Note note) async {
    final notes = await getNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    
    if (index != -1) {
      notes[index] = note;
      await saveNotes(notes);
    }
  }

  Future<void> deleteNote(String noteId) async {
    final notes = await getNotes();
    notes.removeWhere((note) => note.id == noteId);
    await saveNotes(notes);
  }

  // Planner Items
  Future<List<PlannerItem>> getPlannerItems() async {
    final prefs = await SharedPreferences.getInstance();
    final plannerItemsJson = prefs.getStringList(_plannerItemsKey) ?? [];
    
    return plannerItemsJson
        .map((json) => PlannerItem.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<PlannerItem>> getPlannerItemsForSubject(String subjectId) async {
    final plannerItems = await getPlannerItems();
    return plannerItems.where((item) => item.subjectId == subjectId).toList();
  }

  Future<void> savePlannerItems(List<PlannerItem> plannerItems) async {
    final prefs = await SharedPreferences.getInstance();
    final plannerItemsJson = plannerItems
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_plannerItemsKey, plannerItemsJson);
  }

  Future<void> addPlannerItem(PlannerItem plannerItem) async {
    final plannerItems = await getPlannerItems();
    plannerItems.add(plannerItem);
    await savePlannerItems(plannerItems);
  }

  Future<void> updatePlannerItem(PlannerItem plannerItem) async {
    final plannerItems = await getPlannerItems();
    final index = plannerItems.indexWhere((item) => item.id == plannerItem.id);
    
    if (index != -1) {
      plannerItems[index] = plannerItem;
      await savePlannerItems(plannerItems);
    }
  }

  Future<void> deletePlannerItem(String plannerItemId) async {
    final plannerItems = await getPlannerItems();
    plannerItems.removeWhere((item) => item.id == plannerItemId);
    await savePlannerItems(plannerItems);
  }
} 