import 'package:flutter/material.dart';
import 'package:sjlshs_chronos/features/device_management/key_management.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';

class DeviceConfigurationScreen extends StatefulWidget {
  const DeviceConfigurationScreen({super.key});

  @override
  State<DeviceConfigurationScreen> createState() =>
      _DeviceConfigurationScreenState();
}

class _DeviceConfigurationScreenState extends State<DeviceConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _encryptionKeyController = TextEditingController();
  final _pinController = TextEditingController();
  final _secretsManager = SecretsManager();
  String? _encryptionKey;

  @override
  void dispose() {
    _encryptionKeyController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _saveEncryptionKey() {
    if (_encryptionKeyController.text.isNotEmpty) {
      _secretsManager.saveEncryptionKey(_encryptionKeyController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption key saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an encryption key')),
      );
    }
  }

  void _savePin() {
    if (_pinController.text.isNotEmpty) {
      _secretsManager.savePin(_pinController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PIN')),
      );
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

  void _getEncryptionKey() async {
    final key = await _secretsManager.getEncryptionKey();
    setState(() {
      _encryptionKey = key;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encryption key retrieved')),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _encryptionKeyController,
                decoration: const InputDecoration(
                  labelText: 'Encryption Key',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an encryption key';
                  }
                  return null;
                },
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a PIN';
                  }
                  return null;
                },
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
              if (_encryptionKey != null) ...[
                const SizedBox(height: 16),
                SelectableText('Encryption Key: $_encryptionKey'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}