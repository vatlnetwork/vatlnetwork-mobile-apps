import 'package:flutter/foundation.dart';
import '../models/planner_item.dart';
import '../services/data_service.dart';

class PlannerProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  List<PlannerItem> _plannerItems = [];
  bool _isLoading = false;

  List<PlannerItem> get plannerItems => _plannerItems;
  bool get isLoading => _isLoading;

  Future<void> loadPlannerItems() async {
    _isLoading = true;
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

  Future<void> loadPlannerItemsForSubject(String subjectId) async {
    _isLoading = true;
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
      _plannerItems.add(plannerItem);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding planner item: $e');
      }
    }
  }

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

  Future<void> refreshAllPlannerItems({bool silent = true}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Get the latest data
      final freshItems = await _dataService.getPlannerItems();
      
      // Check if anything actually changed before updating and notifying
      bool hasChanges = false;
      
      if (freshItems.length != _plannerItems.length) {
        hasChanges = true;
      } else {
        // Compare items to see if any changed
        final Map<String, PlannerItem> existingItems = {
          for (var item in _plannerItems) item.id: item
        };
        
        for (final newItem in freshItems) {
          final existingItem = existingItems[newItem.id];
          if (existingItem == null || 
              existingItem.isCompleted != newItem.isCompleted ||
              existingItem.dueDate != newItem.dueDate) {
            hasChanges = true;
            break;
          }
        }
      }
      
      if (hasChanges) {
        _plannerItems = freshItems;
        notifyListeners();
      } else if (!silent) {
        // Only notify if explicitly requested
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
