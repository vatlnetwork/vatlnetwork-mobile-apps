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

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme colors for proper dark mode support
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dividerColor = theme.dividerColor;

    // Define alternative colors for the deprecated ones
    final surfaceVariantColor =
        isDarkMode
            ? Color.alphaBlend(
              Colors.white.withAlpha(20),
              theme.colorScheme.surface,
            )
            : Color.alphaBlend(
              Colors.black.withAlpha(10),
              theme.colorScheme.surface,
            );

    final primaryLightColor =
        isDarkMode
            ? Color.alphaBlend(
              Colors.white.withAlpha(20),
              theme.colorScheme.primary,
            )
            : Color.alphaBlend(
              theme.colorScheme.primary.withAlpha(30),
              Colors.white,
            );

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
      ),
      body: Consumer<SubjectProvider>(
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
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
                            child: Text(
                              subject.gradeSnapshots.length.toString(),
                            ),
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
      ),
    );
  }

  Widget _buildGradeDistribution(
    List<Subject> subjects,
    BuildContext context,
    Color surfaceVariantColor,
    Color primaryLightColor,
  ) {
    // Get theme colors for proper dark mode support
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? surfaceVariantColor : primaryLightColor;

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

  // Extract common PDF generation functionality
  Future<File> _generatePDF(BuildContext context) async {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
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
                            color:
                                isDarkMode
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
                            color:
                                isDarkMode
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
                            color:
                                isDarkMode
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
        pageTheme:
            isDarkMode
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
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
          throw Exception('Storage permission denied');
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
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
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
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Grade Report',
        subject: 'Academic Grade Report',
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
