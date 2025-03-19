class Subject {
  final String id;
  final String name;
  double currentGrade;
  List<GradeSnapshot> gradeSnapshots;

  Subject({
    required this.id,
    required this.name,
    this.currentGrade = 0.0,
    List<GradeSnapshot>? gradeSnapshots,
  }) : gradeSnapshots = gradeSnapshots ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentGrade': currentGrade,
      'gradeSnapshots': gradeSnapshots.map((snapshot) => snapshot.toJson()).toList(),
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      currentGrade: json['currentGrade'],
      gradeSnapshots: (json['gradeSnapshots'] as List?)
          ?.map((snapshot) => GradeSnapshot.fromJson(snapshot))
          .toList() ?? [],
    );
  }

  void updateGrade(double newGrade) {
    currentGrade = newGrade;
  }

  void addGradeSnapshot(String label) {
    gradeSnapshots.add(
      GradeSnapshot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        grade: currentGrade,
        date: DateTime.now(),
        label: label,
      ),
    );
  }

  void deleteGradeSnapshot(String snapshotId) {
    gradeSnapshots.removeWhere((snapshot) => snapshot.id == snapshotId);
  }
}

class GradeSnapshot {
  final String id;
  final double grade;
  final DateTime date;
  final String label;

  GradeSnapshot({
    required this.id,
    required this.grade,
    required this.date,
    required this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'date': date.toIso8601String(),
      'label': label,
    };
  }

  factory GradeSnapshot.fromJson(Map<String, dynamic> json) {
    return GradeSnapshot(
      id: json['id'],
      grade: json['grade'],
      date: DateTime.parse(json['date']),
      label: json['label'],
    );
  }
} 