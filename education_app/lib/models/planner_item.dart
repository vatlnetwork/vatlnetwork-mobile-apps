enum PlannerItemType { assignment, exam, study, other }

class PlannerItem {
  final String id;
  final String subjectId;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  PlannerItemType type;

  PlannerItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.type = PlannerItemType.assignment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'type': type.index,
    };
  }

  factory PlannerItem.fromJson(Map<String, dynamic> json) {
    return PlannerItem(
      id: json['id'],
      subjectId: json['subjectId'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'],
      type: PlannerItemType.values[json['type']],
    );
  }

  PlannerItem copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    PlannerItemType? type,
  }) {
    return PlannerItem(
      id: id,
      subjectId: subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
    );
  }

  void toggleCompletion() {
    isCompleted = !isCompleted;
  }
}
