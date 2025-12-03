import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sjlshs_chronos/features/device_management/device_management.dart';
import 'package:sjlshs_chronos/features/device_management/key_management.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';
import 'package:sjlshs_chronos/features/student_management/firestore_import_service.dart';
import 'package:sjlshs_chronos/features/student_management/google_drive_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sjlshs_chronos/features/auth/auth_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceConfigurationScreen extends ConsumerStatefulWidget {
  const DeviceConfigurationScreen({super.key});

  @override
  ConsumerState<DeviceConfigurationScreen> createState() =>
      _DeviceConfigurationScreenState();
}

class _DeviceConfigurationScreenState
    extends ConsumerState<DeviceConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _encryptionKeyController = TextEditingController();
  final _pinController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _secretsManager = SecretsManager();
  String? _encryptionKey;
  String _deviceName = 'Loading...';
  String _deviceID = 'Loading...';
  String? _imageFolderPath;
  bool _isLoadingFolder = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceID();
    _loadDeviceName();
    _loadImageFolderPath();
  }

  @override
  void dispose() {
    _encryptionKeyController.dispose();
    _pinController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceName() async {
    final deviceName = await getDeviceName();
    if (mounted) {
      setState(() {
        _deviceName = deviceName;
        _deviceNameController.text = deviceName;
      });
    }
  }

  Future<void> _loadDeviceID() async {
    final deviceId = await getDeviceID();
    if (mounted) {
      setState(() {
        _deviceID = deviceId;
      });
    }
  }

  void _saveDeviceName() async {
    if (_formKey.currentState?.validate() ?? false) {
      await setDeviceName(_deviceNameController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device name saved')));
      await _loadDeviceName(); // Refresh the name
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a device name')),
      );
    }
  }

  void _saveEncryptionKey() {
    if (_encryptionKeyController.text.isNotEmpty) {
      _secretsManager.saveEncryptionKey(_encryptionKeyController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Encryption key saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an encryption key')),
      );
    }
  }

  void _savePin() {
    if (_pinController.text.isNotEmpty) {
      _secretsManager.savePin(_pinController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN saved')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a PIN')));
    }
  }

  void _checkPin() async {
    if (_pinController.text.isNotEmpty) {
      final isValid = await _secretsManager.checkPin(_pinController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN is ${isValid ? 'valid' : 'invalid'}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PIN to check')),
      );
    }
  }

  Future<void> _loadImageFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _imageFolderPath = prefs.getString('student_images_path');
      });
    }
  }

  Future<void> _selectImageFolder() async {
    setState(() => _isLoadingFolder = true);
    try {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();

        if (selectedDirectory != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_images_path', selectedDirectory);
          setState(() {
            _imageFolderPath = selectedDirectory;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image folder path saved: $selectedDirectory'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is required to select a folder.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick folder: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoadingFolder = false);
    }
  }

  void _getEncryptionKey() async {
    final key = await _secretsManager.getEncryptionKey();
    setState(() {
      _encryptionKey = key;
    });
    if (key != null && key.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Encryption key retrieved')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No encryption key found')));
    }
  }

  Future<void> _importMasterList() async {
    final isar = ref.read(isarProvider).value;
    if (isar == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Database not initialized')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Importing Master List'),
              content: StreamBuilder<double>(
                stream: FirestoreImportService(isar).importMasterList(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final progress = snapshot.data ?? 0.0;

                  if (progress >= 1.0) {
                    // Close dialog after a short delay when complete
                    Future.delayed(const Duration(seconds: 1), () {
                      if (context.mounted) Navigator.of(context).pop();
                    });
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 16),
                        Text('Import Complete!'),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                      Text('${(progress * 100).toStringAsFixed(1)}%'),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Device Configuration',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Identity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // device id
                Text('Device ID: ${_deviceID}'),
                const Divider(height: 48),
                Text('Current name: $_deviceName'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'New Device Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a device name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveDeviceName,
                  child: const Text('Save Device Name'),
                ),
                const Divider(height: 48),
                Text(
                  'Security & Encryption',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _encryptionKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Encryption Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveEncryptionKey,
                  child: const Text('Save Encryption Key'),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _savePin,
                      child: const Text('Save PIN'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _checkPin,
                      child: const Text('Check PIN'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _getEncryptionKey,
                  child: const Text('Get Encryption Key'),
                ),
                if (_encryptionKey != null && _encryptionKey!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SelectableText('Retrieved Key: $_encryptionKey'),
                ],
                const Divider(height: 48),
                Text(
                  'Data Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _importMasterList,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Import Master List from Firestore'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Student Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Images Folder Path:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _imageFolderPath ?? 'No folder selected',
                          style: TextStyle(
                            fontStyle:
                                _imageFolderPath == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                            color:
                                _imageFolderPath == null ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoadingFolder ? null : _selectImageFolder,
                  icon:
                      _isLoadingFolder
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.folder_open),
                  label: const Text('Select Images Folder'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _importPhotos,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Import Photos from Google Drive'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _clearImagesFolder,
                  icon: const Icon(Icons.delete_sweep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('Clear Images Folder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importPhotos() async {
    final isar = ref.read(isarProvider).value;
    if (isar == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Database not initialized')));
      return;
    }

    _startPhotoImport(isar);
  }

  Future<void> _startPhotoImport(isar) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Importing Photos'),
              content: StreamBuilder<double>(
                stream: _photoImportStream(isar),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final progress = snapshot.data ?? 0.0;

                  if (progress >= 1.0) {
                    Future.delayed(const Duration(seconds: 1), () {
                      if (context.mounted) Navigator.of(context).pop();
                    });
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 16),
                        Text('Import Complete!'),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                      Text('${(progress * 100).toStringAsFixed(1)}%'),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Stream<double> _photoImportStream(isar) {
    final service = GoogleDriveService(isar, FirebaseFirestore.instance);
    return service.importPhotos();
  }

  Future<void> _clearImagesFolder() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 10),
                Text('Clear Images Folder'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to delete all student photos?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. All photos in the student_photos folder will be permanently deleted.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Get the application documents directory
      final prefs = await SharedPreferences.getInstance();
      final appDir = prefs.getString('student_images_path');
      final photosDir = Directory(appDir!);

      if (await photosDir.exists()) {
        // Delete all files in the directory
        final files = photosDir.listSync();
        int deletedCount = 0;

        for (final file in files) {
          if (file is File) {
            await file.delete();
            deletedCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted $deletedCount photo(s)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Images folder does not exist'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing images folder: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
