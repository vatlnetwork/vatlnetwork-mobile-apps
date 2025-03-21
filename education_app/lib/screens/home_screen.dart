import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../providers/planner_provider.dart';
import '../models/subject.dart';
import 'subject_detail_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).loadSubjects();
    });
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Class'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _subjectNameController,
            decoration: const InputDecoration(
              labelText: 'Class Name',
              hintText: 'Enter class name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a class name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Provider.of<SubjectProvider>(context, listen: false)
                    .addSubject(_subjectNameController.text.trim());
                _subjectNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhoneSize = screenWidth < 600; // Common breakpoint for phone vs tablet

    return Scaffold(
      appBar: AppBar(
        title: const Text('Education App'),
        centerTitle: !isPhoneSize, // Center title only on larger screens
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'Grade Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportScreen(),
                ),
              );
            },
          ),
          Consumer<SubjectProvider>(
            builder: (context, subjectProvider, child) {
              if (subjectProvider.subjects.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final gpa = subjectProvider.calculateOverallGPA();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _getGPAColor(gpa),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GPA: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      gpa.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          if (subjectProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (subjectProvider.subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No classes yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddSubjectDialog,
                    child: const Text('Add Class'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjectProvider.subjects.length,
            itemBuilder: (context, index) {
              final subject = subjectProvider.subjects[index];
              return SubjectCard(subject: subject);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SubjectCard extends StatefulWidget {
  final Subject subject;

  const SubjectCard({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  int _dueTasks = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDueTasks();
    // Initialize the planner provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlannerProvider>(context, listen: false).refreshAllPlannerItems(silent: true);
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need to actively call _loadDueTasks() here, as we'll use Consumer pattern instead
  }

  Future<void> _loadDueTasks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await Provider.of<PlannerProvider>(context, listen: false)
          .getDueTasksCountForToday(widget.subject.id);
      
      if (!mounted) return;
      
      setState(() {
        _dueTasks = count;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(subject: widget.subject),
            ),
          ).then((_) {
            // Refresh due tasks when returning from subject detail screen
            _loadDueTasks();
            // Also refresh the underlying planner data
            // ignore: use_build_context_synchronously
            Provider.of<PlannerProvider>(context, listen: false).refreshAllPlannerItems();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Consumer<PlannerProvider>(
          builder: (context, plannerProvider, child) {
            // Listen for changes in the planner provider and reload tasks only when needed
            // This approach prevents excessive reloading
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.subject.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor(widget.subject.currentGrade),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.subject.currentGrade.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Snapshots: ${widget.subject.gradeSnapshots.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _isLoading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_late,
                                      size: 16,
                                      color: _dueTasks > 0 ? Colors.orange : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Due today: $_dueTasks',
                                      style: TextStyle(
                                        color: _dueTasks > 0 ? Colors.orange : Colors.grey[600],
                                        fontWeight: _dueTasks > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.green;
    if (grade >= 80) return Colors.lightGreen;
    if (grade >= 70) return Colors.amber;
    if (grade >= 60) return Colors.orange;
    return Colors.red;
  }
}

Color _getGPAColor(double gpa) {
  if (gpa >= 3.7) return Colors.green;
  if (gpa >= 3.0) return Colors.lightGreen;
  if (gpa >= 2.0) return Colors.amber;
  if (gpa >= 1.0) return Colors.orange;
  return Colors.red;
} 