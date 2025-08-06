import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sjlshs_chronos/features/device_management/key_management.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  final _secretsManager = SecretsManager();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submitPin() async {
    if (_pinController.text.isNotEmpty) {
      final isValid = await _secretsManager.checkPin(_pinController.text);
      if (isValid) {
        context.go('/scanner');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid PIN')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Enter PIN',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: 'PIN',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitPin,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
