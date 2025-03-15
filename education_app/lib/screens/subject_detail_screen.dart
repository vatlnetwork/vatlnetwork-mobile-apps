import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import 'notes_screen.dart';
import 'planner_screen.dart';
import 'grade_snapshots_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _gradeController = TextEditingController();
  final _snapshotLabelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _gradeController.text = widget.subject.currentGrade.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gradeController.dispose();
    _snapshotLabelController.dispose();
    super.dispose();
  }

  void _showUpdateGradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Grade'),
        content: TextField(
          controller: _gradeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Current Grade',
            hintText: 'Enter your current grade',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final grade = double.tryParse(_gradeController.text);
              if (grade != null) {
                Provider.of<SubjectProvider>(context, listen: false)
                    .updateSubjectGrade(widget.subject.id, grade);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddSnapshotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Grade Snapshot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Grade: ${widget.subject.currentGrade}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _snapshotLabelController,
              decoration: const InputDecoration(
                labelText: 'Snapshot Label',
                hintText: 'Enter a label for this snapshot',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_snapshotLabelController.text.isNotEmpty) {
                Provider.of<SubjectProvider>(context, listen: false)
                    .addGradeSnapshot(
                        widget.subject.id, _snapshotLabelController.text);
                _snapshotLabelController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Save Snapshot'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Planner'),
            Tab(text: 'Grades'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showUpdateGradeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _showAddSnapshotDialog,
          ),
        ],
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          // Find the updated subject
          final updatedSubject = subjectProvider.subjects.firstWhere(
            (s) => s.id == widget.subject.id,
            orElse: () => widget.subject,
          );

          return TabBarView(
            controller: _tabController,
            children: [
              NotesScreen(subjectId: updatedSubject.id),
              PlannerScreen(subjectId: updatedSubject.id),
              GradeSnapshotsScreen(subject: updatedSubject),
            ],
          );
        },
      ),
    );
  }
} 