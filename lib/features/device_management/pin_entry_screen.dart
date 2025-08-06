import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sjlshs_chronos/features/device_management/key_management.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sjlshs_chronos/features/auth/offline_auth_provider.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
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
        ref.read(isOfflineProvider.notifier).state = true;
        if (mounted) {
          context.go('/scanner', extra: true);
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
      ),
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
