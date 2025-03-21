import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/planner_item.dart';

class PlannerScreen extends StatefulWidget {
  final String subjectId;

  const PlannerScreen({super.key, required this.subjectId});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  PlannerItemType _selectedType = PlannerItemType.assignment;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Load planner items for this subject
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlannerProvider>(context, listen: false)
          .loadPlannerItemsForSubject(widget.subjectId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddItemDialog() {
    _showPlannerItemDialog(
      context: context,
      title: 'Add New Task',
      initialTitle: '',
      initialDescription: '',
      initialDueDate: DateTime.now(),
      initialType: PlannerItemType.assignment,
      onSave: (title, description, dueDate, type) async {
        await Provider.of<PlannerProvider>(context, listen: false).addPlannerItem(
          widget.subjectId,
          title,
          description,
          dueDate,
          type,
        );
        
        // Reload items for this subject to ensure we see the updated list
        if (mounted) {
          Provider.of<PlannerProvider>(context, listen: false)
              .loadPlannerItemsForSubject(widget.subjectId);
              
          // Also update counts for all subjects in the background
          Provider.of<PlannerProvider>(context, listen: false)
              .refreshAllPlannerItems(silent: true);
        }
      },
    );
  }

  void _showEditItemDialog(PlannerItem item) {
    _showPlannerItemDialog(
      context: context,
      title: 'Edit Task',
      initialTitle: item.title,
      initialDescription: item.description,
      initialDueDate: item.dueDate,
      initialType: item.type,
      onSave: (title, description, dueDate, type) async {
        await Provider.of<PlannerProvider>(context, listen: false).updatePlannerItem(
          item.id,
          title,
          description,
          dueDate,
          type,
        );
        
        // Ensure we reload items for this subject
        if (mounted) {
          Provider.of<PlannerProvider>(context, listen: false)
              .loadPlannerItemsForSubject(widget.subjectId);
              
          // Also update counts for all subjects in the background
          Provider.of<PlannerProvider>(context, listen: false)
              .refreshAllPlannerItems(silent: true);
        }
      },
    );
  }

  void _showPlannerItemDialog({
    required BuildContext context,
    required String title,
    required String initialTitle,
    required String initialDescription,
    required DateTime initialDueDate,
    required PlannerItemType initialType,
    required Function(String, String, DateTime, PlannerItemType) onSave
  }) {
    _titleController.text = initialTitle;
    _descriptionController.text = initialDescription;
    _selectedDate = initialDueDate;
    _selectedType = initialType;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(title),
                  content: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 5),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Enter item title',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter item description',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Due Date: '),
                              TextButton(
                                onPressed: () async {
                                  await _selectDate(context);
                                  setState(() {});
                                },
                                child: Text(
                                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<PlannerItemType>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                            items:
                                PlannerItemType.values.map((type) {
                                  return DropdownMenuItem<PlannerItemType>(
                                    value: type,
                                    child: Text(_getPlannerItemTypeText(type)),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedType = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
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
                          onSave(
                            _titleController.text.trim(),
                            _descriptionController.text.trim(),
                            _selectedDate,
                            _selectedType,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  String _getPlannerItemTypeText(PlannerItemType type) {
    switch (type) {
      case PlannerItemType.assignment:
        return 'Assignment';
      case PlannerItemType.exam:
        return 'Exam';
      case PlannerItemType.study:
        return 'Study';
      case PlannerItemType.other:
        return 'Other';
    }
  }

  Icon _getPlannerItemTypeIcon(PlannerItemType type) {
    switch (type) {
      case PlannerItemType.assignment:
        return const Icon(Icons.assignment, color: Colors.blue);
      case PlannerItemType.exam:
        return const Icon(Icons.quiz, color: Colors.red);
      case PlannerItemType.study:
        return const Icon(Icons.book, color: Colors.green);
      case PlannerItemType.other:
        return const Icon(Icons.more_horiz, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlannerProvider>(
        builder: (context, plannerProvider, child) {
          if (plannerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (plannerProvider.plannerItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No planner items yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddItemDialog,
                    child: const Text('Add Planner Item'),
                  ),
                ],
              ),
            );
          }

          // Sort items by due date
          final sortedItems = List.of(plannerProvider.plannerItems)
            ..sort((a, b) {
              // First sort by completion status (incomplete items first)
              if (a.isCompleted != b.isCompleted) {
                return a.isCompleted ? 1 : -1;
              }
              // Then sort by due date
              return a.dueDate.compareTo(b.dueDate);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final item = sortedItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _showEditItemDialog(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getPlannerItemTypeIcon(item.type),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  decoration:
                                      item.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: item.isCompleted,
                              onChanged: (value) async {
                                await Provider.of<PlannerProvider>(context, listen: false)
                                    .togglePlannerItemCompletion(item.id);
                                
                                // Ensure the correct items are loaded for this subject
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  Provider.of<PlannerProvider>(context, listen: false)
                                      .loadPlannerItemsForSubject(widget.subjectId);
                                      
                                  // Also update counts for all subjects in the background
                                  // ignore: use_build_context_synchronously
                                  Provider.of<PlannerProvider>(context, listen: false)
                                      .refreshAllPlannerItems(silent: true);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            decoration:
                                item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Due: ${_formatDate(item.dueDate)}',
                              style: TextStyle(
                                color: _getDueDateColor(item.dueDate),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await Provider.of<PlannerProvider>(context, listen: false)
                                    .deletePlannerItem(item.id);
                                
                                // Ensure the correct items are loaded for this subject
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  Provider.of<PlannerProvider>(context, listen: false)
                                      .loadPlannerItemsForSubject(widget.subjectId);
                                      
                                  // Also update counts for all subjects in the background
                                  // ignore: use_build_context_synchronously
                                  Provider.of<PlannerProvider>(context, listen: false)
                                      .refreshAllPlannerItems(silent: true);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red;
    } else if (difference <= 3) {
      return Colors.orange;
    } else if (difference <= 7) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }
}
