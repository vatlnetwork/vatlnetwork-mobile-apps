import 'package:flutter/foundation.dart';
import '../models/planner_item.dart';
import '../services/data_service.dart';

class PlannerProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  List<PlannerItem> _plannerItems = [];
  bool _isLoading = false;
  String? _currentSubjectId; // Track the current subject ID being viewed

  List<PlannerItem> get plannerItems => _plannerItems;
  bool get isLoading => _isLoading;
  String? get currentSubjectId => _currentSubjectId;

  // Load all planner items
  Future<void> loadPlannerItems() async {
    _isLoading = true;
    _currentSubjectId = null; // Clear subject filter
    notifyListeners();

    try {
      _plannerItems = await _dataService.getPlannerItems();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading planner items: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load planner items for a specific subject
  Future<void> loadPlannerItemsForSubject(String subjectId) async {
    _isLoading = true;
    _currentSubjectId = subjectId; // Set current subject ID
    notifyListeners();

    try {
      _plannerItems = await _dataService.getPlannerItemsForSubject(subjectId);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading planner items for subject: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new planner item
  Future<void> addPlannerItem(
    String subjectId,
    String title,
    String description,
    DateTime dueDate,
    PlannerItemType type,
  ) async {
    final plannerItem = PlannerItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: subjectId,
      title: title,
      description: description,
      dueDate: dueDate,
      type: type,
    );

    try {
      await _dataService.addPlannerItem(plannerItem);
      
      // Only add to the current list if we're viewing the same subject or all items
      if (_currentSubjectId == null || _currentSubjectId == subjectId) {
        _plannerItems.add(plannerItem);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding planner item: $e');
      }
    }
  }

  // Update an existing planner item
  Future<void> updatePlannerItem(
    String plannerItemId,
    String title,
    String description,
    DateTime dueDate,
    PlannerItemType type,
  ) async {
    final index = _plannerItems.indexWhere((item) => item.id == plannerItemId);

    if (index != -1) {
      final updatedItem = _plannerItems[index].copyWith(
        title: title,
        description: description,
        dueDate: dueDate,
        type: type,
      );

      try {
        await _dataService.updatePlannerItem(updatedItem);
        _plannerItems[index] = updatedItem;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error updating planner item: $e');
        }
      }
    }
  }

  // Toggle the completion status of a planner item
  Future<void> togglePlannerItemCompletion(String plannerItemId) async {
    final index = _plannerItems.indexWhere((item) => item.id == plannerItemId);

    if (index != -1) {
      _plannerItems[index].toggleCompletion();

      try {
        await _dataService.updatePlannerItem(_plannerItems[index]);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error toggling planner item completion: $e');
        }
      }
    }
  }

  // Delete a planner item
  Future<void> deletePlannerItem(String plannerItemId) async {
    try {
      await _dataService.deletePlannerItem(plannerItemId);
      _plannerItems.removeWhere((item) => item.id == plannerItemId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting planner item: $e');
      }
    }
  }

  // Refresh planner items in the background without changing the current view
  Future<void> refreshAllPlannerItems({bool silent = true}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // If we have a current subject filter, refresh only that subject's items
      if (_currentSubjectId != null) {
        // Silently update the data store
        await _dataService.getPlannerItems();
        
        // Reload the filtered view for the current subject
        final subjectItems = await _dataService.getPlannerItemsForSubject(_currentSubjectId!);
        _plannerItems = subjectItems;
      } else {
        // No subject filter, so refresh all items
        _plannerItems = await _dataService.getPlannerItems();
      }
      
      // Notify listeners only if changes should be visible
      if (!silent) {
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing planner items: $e');
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Get the count of tasks due today for a specific subject
  Future<int> getDueTasksCountForToday(String subjectId) async {
    try {
      final items = await _dataService.getPlannerItemsForSubject(subjectId);
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      return items.where((item) {
        final dueDate = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
        
        return dueDate.isAtSameMomentAs(today) && !item.isCompleted;
      }).length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting due tasks for today: $e');
      }
      return 0;
    }
  }
}
