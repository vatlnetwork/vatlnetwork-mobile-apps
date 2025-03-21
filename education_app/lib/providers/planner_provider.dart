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
}
