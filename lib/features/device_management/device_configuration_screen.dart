import 'package:flutter/material.dart';
import 'package:sjlshs_chronos/features/device_management/device_management.dart';
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
  final _deviceNameController = TextEditingController();
  final _secretsManager = SecretsManager();
  String? _encryptionKey;
  String _deviceName = 'Loading...';
  String _deviceID = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDeviceID();
    _loadDeviceName();
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
