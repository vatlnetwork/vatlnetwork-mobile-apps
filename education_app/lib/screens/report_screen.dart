import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../models/subject.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPDF(context),
            tooltip: 'Download Report',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _generateAndSharePDF(context),
            tooltip: 'Share Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current Grades', icon: Icon(Icons.grade)),
            Tab(text: 'Grade History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [CurrentGradesTab(), GradeHistoryTab()],
      ),
    );
  }

  // Extract common PDF generation functionality
  Future<File> _generatePDF(BuildContext context) async {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final subjects = subjectProvider.subjects;
    final gpa = subjectProvider.calculateOverallGPA();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Create PDF document
    final pdf = pw.Document();

    // Add content to PDF
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Academic Grade Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: isDarkMode ? PdfColors.grey300 : PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? PdfColors.grey300 : PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                      border: pw.Border.all(color: PdfColors.grey400),
                      color: _getGpaPdfColor(gpa),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Overall GPA',
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          gpa.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),
            pw.Text(
              'Class Summary',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: isDarkMode ? PdfColors.grey300 : PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 16),

            // Table for classes
            pw.Table(
              border: pw.TableBorder.all(
                color: isDarkMode ? PdfColors.grey500 : PdfColors.grey600,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isDarkMode ? PdfColors.grey800 : PdfColors.grey300,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Class Name',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Grade',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'GPA Value',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Snapshots',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // Data rows
                ...subjects.map((subject) {
                  final subjectGPA = Subject.toGPA(subject.currentGrade);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isDarkMode ? PdfColors.grey900 : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          subject.name,
                          style: pw.TextStyle(
                            color: isDarkMode
                                ? PdfColors.grey300
                                : PdfColors.black,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: _getGradePdfColor(subject.currentGrade),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(8),
                              ),
                            ),
                            child: pw.Text(
                              subject.currentGrade.toStringAsFixed(1),
                              style: const pw.TextStyle(color: PdfColors.white),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          subjectGPA.toStringAsFixed(1),
                          style: pw.TextStyle(
                            color: isDarkMode
                                ? PdfColors.grey300
                                : PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          subject.gradeSnapshots.length.toString(),
                          style: pw.TextStyle(
                            color: isDarkMode
                                ? PdfColors.grey300
                                : PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 32),
            pw.Text(
              'Notes:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: isDarkMode ? PdfColors.grey300 : PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '• GPA calculated using standard 4.0 scale\n'
              '• Total classes: ${subjects.length}\n'
              '• Report shows current grades as of ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 12,
                color: isDarkMode ? PdfColors.grey300 : PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generated in ${isDarkMode ? "Dark" : "Light"} Mode',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: isDarkMode ? PdfColors.grey400 : PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
        pageTheme: isDarkMode
            ? pw.PageTheme(
                pageFormat: PdfPageFormat.a4,
                theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
                buildBackground: (pw.Context context) {
                  return pw.Container(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey900,
                    ),
                  );
                },
              )
            : null,
      ),
    );

    // Save PDF to temporary file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/grade_report_$timestamp.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<void> _downloadPDF(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate the PDF
      final tempFile = await _generatePDF(context);

      // Determine the download directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Use the downloads directory on Android
        directory = Directory('/storage/emulated/0/Download');
        // Create directory if it doesn't exist
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // Use documents directory on iOS
        directory = await getApplicationDocumentsDirectory();
      }

      directory ??= await getApplicationDocumentsDirectory();

      // Create the saved file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedFilePath = '${directory.path}/GradeReport_$timestamp.pdf';
      final savedFile = File(savedFilePath);

      if (Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          final permission10plus = await Permission.manageExternalStorage
              .request();
          if (!permission10plus.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }
      // Copy the file to the downloads directory
      await tempFile.copy(savedFilePath);

      // Close loading dialog
      // ignore: use_build_context_synchronously
      Navigator.of(context, rootNavigator: true).pop();

      // Show success message with file location
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to ${savedFile.path}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Close loading dialog
      // ignore: use_build_context_synchronously
      Navigator.of(context, rootNavigator: true).pop();

      // Show error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    try {
      // Generate the PDF
      final file = await _generatePDF(context);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Grade Report',
          subject: 'Academic Grade Report',
        ),
      );
    } catch (e) {
      // Show error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  PdfColor _getGradePdfColor(double grade) {
    if (grade >= 90) return PdfColors.green;
    if (grade >= 80) return PdfColors.lightGreen;
    if (grade >= 70) return PdfColors.amber;
    if (grade >= 60) return PdfColors.orange;
    return PdfColors.red;
  }

  PdfColor _getGpaPdfColor(double gpa) {
    if (gpa >= 3.7) return PdfColors.green;
    if (gpa >= 3.0) return PdfColors.lightGreen;
    if (gpa >= 2.0) return PdfColors.amber;
    if (gpa >= 1.0) return PdfColors.orange;
    return PdfColors.red;
  }
}

// ============================================================================
// Current Grades Tab (Original Report Content)
// ============================================================================

class CurrentGradesTab extends StatelessWidget {
  const CurrentGradesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dividerColor = theme.dividerColor;

    final surfaceVariantColor = isDarkMode
        ? Color.alphaBlend(
            Colors.white.withAlpha(20),
            theme.colorScheme.surface,
          )
        : Color.alphaBlend(
            Colors.black.withAlpha(10),
            theme.colorScheme.surface,
          );

    final primaryLightColor = isDarkMode
        ? Color.alphaBlend(
            Colors.white.withAlpha(20),
            theme.colorScheme.primary,
          )
        : Color.alphaBlend(
            theme.colorScheme.primary.withAlpha(30),
            Colors.white,
          );

    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        if (subjectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (subjectProvider.subjects.isEmpty) {
          return const Center(
            child: Text(
              'No classes to display in report',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final gpa = subjectProvider.calculateOverallGPA();
        final today = DateTime.now();
        final dateFormat = DateFormat('MMMM d, yyyy');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report header
              Center(
                child: Column(
                  children: [
                    Text(
                      'Academic Report',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generated on ${dateFormat.format(today)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _getGPAColor(gpa),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Overall GPA',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gpa.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Class summary section
              Text(
                'Class Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? surfaceVariantColor : primaryLightColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Class Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Grade',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'GPA Value',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Snapshots',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table rows for each subject
              ...subjectProvider.subjects.map((subject) {
                final subjectGPA = Subject.toGPA(subject.currentGrade);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(subject.name)),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(subject.currentGrade),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subject.currentGrade.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            subjectGPA.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getGPAColor(subjectGPA),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(subject.gradeSnapshots.length.toString()),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Grade Trend section
              Text(
                'Grade Distribution',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Grade distribution chart
              _buildGradeDistribution(
                subjectProvider.subjects,
                context,
                surfaceVariantColor,
                primaryLightColor,
              ),

              const SizedBox(height: 40),

              // Final notes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? surfaceVariantColor : primaryLightColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• GPA calculated using standard 4.0 scale\n'
                      '• Total classes: ${subjectProvider.subjects.length}\n'
                      '• Report shows current grades as of ${dateFormat.format(today)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeDistribution(
    List<Subject> subjects,
    BuildContext context,
    Color surfaceVariantColor,
    Color primaryLightColor,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? surfaceVariantColor
        : primaryLightColor;

    // Count subjects in each grade range
    int aRange = 0, bRange = 0, cRange = 0, dRange = 0, fRange = 0;

    for (final subject in subjects) {
      final grade = subject.currentGrade;
      if (grade >= 90) {
        aRange++;
      } else if (grade >= 80) {
        bRange++;
      } else if (grade >= 70) {
        cRange++;
      } else if (grade >= 60) {
        dRange++;
      } else {
        fRange++;
      }
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildGradeBar('A', aRange, subjects.length, Colors.green, context),
          _buildGradeBar(
            'B',
            bRange,
            subjects.length,
            Colors.lightGreen,
            context,
          ),
          _buildGradeBar('C', cRange, subjects.length, Colors.amber, context),
          _buildGradeBar('D', dRange, subjects.length, Colors.orange, context),
          _buildGradeBar('F', fRange, subjects.length, Colors.red, context),
        ],
      ),
    );
  }

  Widget _buildGradeBar(
    String grade,
    int count,
    int total,
    Color color,
    BuildContext context,
  ) {
    final textTheme = Theme.of(context).textTheme;

    // Calculate height percentage (minimum 10 for visibility even if count is 0)
    final percentage = total > 0 ? (count / total) * 100 : 0;
    final height = 100 * (percentage > 0 ? percentage / 100 : 0.1);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          count.toString(),
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          grade,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ============================================================================
// Grade History Tab (New Feature)
// ============================================================================

class GradeHistoryTab extends StatefulWidget {
  const GradeHistoryTab({super.key});

  @override
  State<GradeHistoryTab> createState() => _GradeHistoryTabState();
}

class _GradeHistoryTabState extends State<GradeHistoryTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  Set<String> _selectedSubjectIds = {};
  final List<Color> _subjectColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  /// Attempts to parse the snapshot label as a date.
  /// Returns the parsed date if successful, otherwise returns the snapshot's timestamp.
  DateTime _getSnapshotDate(GradeSnapshot snapshot) {
    // Try common date formats
    final formats = [
      DateFormat('yyyy-MM-dd'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('M/d/yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('d/M/yyyy'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('MMM d, yyyy'),
      DateFormat('MMMM d, yyyy'),
      DateFormat('d MMM yyyy'),
      DateFormat('d MMMM yyyy'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(snapshot.label);
      } catch (_) {
        // Continue to next format
      }
    }

    // Fallback to the timestamp
    return snapshot.date;
  }

  /// Gets all snapshots within the date range, organized by subject
  Map<String, List<MapEntry<DateTime, double>>> _getSnapshotsInRange(
    List<Subject> subjects,
  ) {
    if (_startDate == null || _endDate == null) {
      return {};
    }

    final result = <String, List<MapEntry<DateTime, double>>>{};

    for (final subject in subjects) {
      // Skip if subject is not selected (and some subjects are selected)
      if (_selectedSubjectIds.isNotEmpty &&
          !_selectedSubjectIds.contains(subject.id)) {
        continue;
      }

      final snapshots = <MapEntry<DateTime, double>>[];

      for (final snapshot in subject.gradeSnapshots) {
        final date = _getSnapshotDate(snapshot);
        // Normalize to start of day for comparison
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final normalizedStart = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        final normalizedEnd = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
        );

        if (!normalizedDate.isBefore(normalizedStart) &&
            !normalizedDate.isAfter(normalizedEnd)) {
          snapshots.add(MapEntry(normalizedDate, snapshot.grade));
        }
      }

      // Sort by date
      snapshots.sort((a, b) => a.key.compareTo(b.key));

      if (snapshots.isNotEmpty) {
        result[subject.id] = snapshots;
      }
    }

    return result;
  }

  /// Get all unique dates in the range that have data
  List<DateTime> _getAllDatesInRange() {
    if (_startDate == null || _endDate == null) {
      return [];
    }

    final dates = <DateTime>[];
    var current = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showClassFilterDialog(BuildContext context, List<Subject> subjects) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Classes'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All / Clear All buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedSubjectIds = subjects
                                  .map((s) => s.id)
                                  .toSet();
                            });
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedSubjectIds = {};
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    // List of classes
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          final isSelected = _selectedSubjectIds.contains(
                            subject.id,
                          );
                          final color =
                              _subjectColors[index % _subjectColors.length];

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  _selectedSubjectIds.add(subject.id);
                                } else {
                                  _selectedSubjectIds.remove(subject.id);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(child: Text(subject.name)),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {}); // Refresh the main widget
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getSubjectColor(List<Subject> subjects, String subjectId) {
    final index = subjects.indexWhere((s) => s.id == subjectId);
    if (index == -1) return Colors.grey;
    return _subjectColors[index % _subjectColors.length];
  }

  /// Calculates the average GPA for all snapshots in the date range
  double _calculateAverageGPA(
    Map<String, List<MapEntry<DateTime, double>>> snapshotsInRange,
  ) {
    if (snapshotsInRange.isEmpty) return 0.0;

    double totalGPA = 0.0;
    int count = 0;

    for (final snapshots in snapshotsInRange.values) {
      for (final entry in snapshots) {
        totalGPA += Subject.toGPA(entry.value);
        count++;
      }
    }

    if (count == 0) return 0.0;
    return totalGPA / count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final surfaceVariantColor = isDarkMode
        ? Color.alphaBlend(
            Colors.white.withAlpha(20),
            theme.colorScheme.surface,
          )
        : Color.alphaBlend(
            Colors.black.withAlpha(10),
            theme.colorScheme.surface,
          );

    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        if (subjectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (subjectProvider.subjects.isEmpty) {
          return const Center(
            child: Text(
              'No classes to display',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final subjects = subjectProvider.subjects;
        final snapshotsInRange = _getSnapshotsInRange(subjects);
        final allDates = _getAllDatesInRange();
        final dateFormat = DateFormat('MMM d');

        // Get visible subjects for the legend
        final visibleSubjects = subjects.where((s) {
          if (_selectedSubjectIds.isEmpty) return true;
          return _selectedSubjectIds.contains(s.id);
        }).toList();

        return Column(
          children: [
            // Controls section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date range selector
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _startDate != null && _endDate != null
                                ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
                                : 'Select Date Range',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Class filter dropdown
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showClassFilterDialog(context, subjects),
                        icon: const Icon(Icons.filter_list),
                        label: Text(
                          _selectedSubjectIds.isEmpty
                              ? 'All Classes'
                              : '${_selectedSubjectIds.length} Selected',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Legend
                  if (visibleSubjects.isNotEmpty)
                    SizedBox(
                      height: 32,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: visibleSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = visibleSubjects[index];
                          final color = _getSubjectColor(subjects, subject.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  subject.name,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: snapshotsInRange.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No grade data in selected range',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try selecting a different date range',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Average GPA for date range
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _getGPAColor(
                                  _calculateAverageGPA(snapshotsInRange),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Average GPA for Period',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _calculateAverageGPA(
                                      snapshotsInRange,
                                    ).toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Graph section
                          Text(
                            'Grade Trend',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 300,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceVariantColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildGradeChart(
                              subjects,
                              snapshotsInRange,
                              theme,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Table section
                          Text(
                            'Grade History Table',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGradeTable(
                            subjects,
                            snapshotsInRange,
                            allDates,
                            theme,
                            surfaceVariantColor,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGradeChart(
    List<Subject> subjects,
    Map<String, List<MapEntry<DateTime, double>>> snapshotsInRange,
    ThemeData theme,
  ) {
    if (snapshotsInRange.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    // Find min and max dates across all subjects
    DateTime? minDate;
    DateTime? maxDate;

    for (final snapshots in snapshotsInRange.values) {
      for (final entry in snapshots) {
        if (minDate == null || entry.key.isBefore(minDate)) {
          minDate = entry.key;
        }
        if (maxDate == null || entry.key.isAfter(maxDate)) {
          maxDate = entry.key;
        }
      }
    }

    if (minDate == null || maxDate == null) {
      return const Center(child: Text('No data to display'));
    }

    final dateRange = maxDate.difference(minDate).inDays.toDouble();
    final dateFormat = DateFormat('M/d');

    // Build line chart data
    final lineBarsData = <LineChartBarData>[];

    for (final entry in snapshotsInRange.entries) {
      final subjectId = entry.key;
      final snapshots = entry.value;
      final color = _getSubjectColor(subjects, subjectId);

      // Group snapshots into continuous segments (for discontinuous line)
      final segments = <List<FlSpot>>[];
      var currentSegment = <FlSpot>[];

      DateTime? lastDate;
      for (final snapshot in snapshots) {
        final daysSinceStart = snapshot.key
            .difference(minDate)
            .inDays
            .toDouble();

        // If there's a gap of more than 3 days, start a new segment
        if (lastDate != null && snapshot.key.difference(lastDate).inDays > 3) {
          if (currentSegment.isNotEmpty) {
            segments.add(currentSegment);
            currentSegment = [];
          }
        }

        currentSegment.add(FlSpot(daysSinceStart, snapshot.value));
        lastDate = snapshot.key;
      }

      if (currentSegment.isNotEmpty) {
        segments.add(currentSegment);
      }

      // Create a line for each segment
      for (final segment in segments) {
        if (segment.isNotEmpty) {
          lineBarsData.add(
            LineChartBarData(
              spots: segment,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: dateRange > 0 ? dateRange : 1,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor.withAlpha(100),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: theme.dividerColor.withAlpha(50),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: dateRange > 14 ? (dateRange / 7).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final date = minDate!.add(Duration(days: value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dateFormat.format(date),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.dividerColor),
        ),
        lineBarsData: lineBarsData,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}% (${_getLetterGrade(spot.y)})',
                  TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGradeTable(
    List<Subject> subjects,
    Map<String, List<MapEntry<DateTime, double>>> snapshotsInRange,
    List<DateTime> allDates,
    ThemeData theme,
    Color surfaceVariantColor,
  ) {
    // Get only dates that have at least one data point
    final datesWithData = <DateTime>{};
    for (final snapshots in snapshotsInRange.values) {
      for (final entry in snapshots) {
        datesWithData.add(entry.key);
      }
    }

    final sortedDates = datesWithData.toList()..sort();

    if (sortedDates.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    final dateFormat = DateFormat('M/d');
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get visible subjects
    final visibleSubjects = subjects.where((s) {
      if (_selectedSubjectIds.isEmpty) return true;
      return _selectedSubjectIds.contains(s.id);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(surfaceVariantColor),
          columnSpacing: 16,
          horizontalMargin: 12,
          columns: [
            const DataColumn(
              label: Text(
                'Class',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...sortedDates.map(
              (date) => DataColumn(
                label: Text(
                  dateFormat.format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          rows: visibleSubjects.map((subject) {
            final subjectSnapshots = snapshotsInRange[subject.id] ?? [];
            final snapshotMap = <DateTime, double>{};
            for (final entry in subjectSnapshots) {
              snapshotMap[entry.key] = entry.value;
            }
            final color = _getSubjectColor(subjects, subject.id);

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(subject.name),
                    ],
                  ),
                ),
                ...sortedDates.map((date) {
                  final grade = snapshotMap[date];
                  if (grade == null) {
                    return DataCell(
                      Container(
                        width: 50,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            '-',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }
                  return DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getGradeColor(grade),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${grade.toStringAsFixed(1)} (${_getLetterGrade(grade)})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

Color _getGradeColor(double grade) {
  if (grade >= 90) return Colors.green;
  if (grade >= 80) return Colors.lightGreen;
  if (grade >= 70) return Colors.amber;
  if (grade >= 60) return Colors.orange;
  return Colors.red;
}

Color _getGPAColor(double gpa) {
  if (gpa >= 3.7) return Colors.green;
  if (gpa >= 3.0) return Colors.lightGreen;
  if (gpa >= 2.0) return Colors.amber;
  if (gpa >= 1.0) return Colors.orange;
  return Colors.red;
}

/// Returns the letter grade for a given percentage
String _getLetterGrade(double grade) {
  if (grade >= 93) return 'A';
  if (grade >= 90) return 'A-';
  if (grade >= 87) return 'B+';
  if (grade >= 83) return 'B';
  if (grade >= 80) return 'B-';
  if (grade >= 77) return 'C+';
  if (grade >= 73) return 'C';
  if (grade >= 70) return 'C-';
  if (grade >= 67) return 'D+';
  if (grade >= 63) return 'D';
  if (grade >= 60) return 'D-';
  return 'F';
}
