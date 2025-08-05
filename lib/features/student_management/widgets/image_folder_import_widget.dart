import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

final logger = Logger();

class ImageFolderImportWidget extends StatefulWidget {
  const ImageFolderImportWidget({Key? key}) : super(key: key);

  @override
  _ImageFolderImportWidgetState createState() => _ImageFolderImportWidgetState();
}

class _ImageFolderImportWidgetState extends State<ImageFolderImportWidget> {
  String? _folderPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFolderPath();
  }

  Future<void> _loadFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _folderPath = prefs.getString('student_images_path');
    });
  }

  Future<void> _pickFolder() async {
    setState(() => _isLoading = true);
    try {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

        if (selectedDirectory != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_images_path', selectedDirectory);
          setState(() {
            _folderPath = selectedDirectory;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image folder path saved: $selectedDirectory')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required to select a folder.')),
          );
        }
      }
    } catch (e) {
      logger.e('Error picking folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick folder: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Images Folder',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Make sure the images are named using the student\'s LRN (e.g., 123456789012.jpg).',
                ),
                const Text('2. Click the button below to select the folder containing the images.'),
                const SizedBox(height: 16),
                if (_folderPath != null)
                  Text(
                    'Current Path: $_folderPath',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  )
                else
                  const Text(
                    'No folder selected.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _pickFolder,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_open),
          label: const Text('Select Image Folder'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      ],
    );
  }
}
