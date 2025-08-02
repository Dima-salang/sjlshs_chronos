import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:sjlshs_chronos/features/student_management/student_manager.dart';
import 'package:sjlshs_chronos/features/logging/chronos_logger.dart';
import 'package:logger/logger.dart';

class ExcelUploadWidget extends StatefulWidget {
  final Isar isar;
  final VoidCallback? onStudentsImported;
  
  const ExcelUploadWidget({
    Key? key, 
    required this.isar,
    this.onStudentsImported,
  }) : super(key: key);

  @override
  _ExcelUploadWidgetState createState() => _ExcelUploadWidgetState();
}

class _ExcelUploadWidgetState extends State<ExcelUploadWidget> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  final Logger logger = getLogger();

  Future<void> _pickAndProcessExcel() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting file...';
      _hasError = false;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      final excelFilePath = result?.files.single.path;
      logger.d(excelFilePath);

      if (excelFilePath != null) {
        setState(() {
          _statusMessage = 'Processing file...';
        });


        final studentManager = StudentManagementExcelStrategy(excelFilePath, widget.isar);
        final students = studentManager.getStudentData();
        int successCount = 0;

        // Skip header row (index 0) and process each row
        for (var student in students) {
          try {
            await studentManager.addStudent(student);
            successCount++;
          } catch (e) {
            logger.e('Error processing row: $e');
          }
        }

        setState(() {
          _statusMessage = 'Successfully imported $successCount students';
          _hasError = false;
          
          // Notify parent that students were imported
          if (widget.onStudentsImported != null) {
            widget.onStudentsImported!();
          }
        });
      } else {
        setState(() {
          _statusMessage = 'No file selected';
          _hasError = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Import Students from Excel',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload an Excel file (.xlsx or .xls) with student information. Expected columns:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'LRN | Last Name | First Name | Year Level | Section | Adviser Name',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndProcessExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Excel File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _hasError ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
