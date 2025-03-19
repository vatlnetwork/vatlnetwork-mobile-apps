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
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _gradeController.text = widget.subject.currentGrade.toString();
    _nameController.text = widget.subject.name;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gradeController.dispose();
    _snapshotLabelController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showUpdateClassDialog() {
    _gradeController.text = widget.subject.currentGrade.toString();
    _nameController.text = widget.subject.name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'Enter class name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Grade',
                  hintText: 'Enter your current grade',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _showDeleteConfirmationDialog();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () {
              final grade = double.tryParse(_gradeController.text);
              if (grade != null && _nameController.text.isNotEmpty) {
                final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
                
                // Update name if changed
                if (_nameController.text != widget.subject.name) {
                  subjectProvider.updateSubjectName(
                    widget.subject.id, 
                    _nameController.text.trim()
                  );
                }
                
                // Update grade if changed
                if (grade != widget.subject.currentGrade) {
                  subjectProvider.updateSubjectGrade(widget.subject.id, grade);
                }
                
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete "${widget.subject.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
              subjectProvider.deleteSubject(widget.subject.id);
              
              // Close both dialogs and navigate back to home screen
              Navigator.pop(context); // Close delete confirmation
              Navigator.pop(context); // Close update dialog
              Navigator.pop(context); // Return to home screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddSnapshotDialog() {
    // Auto-fill the label with current date in mm/dd/yyyy format
    final now = DateTime.now();
    _snapshotLabelController.text = '${now.month}/${now.day}/${now.year}';
    
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
            onPressed: _showUpdateClassDialog,
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