import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sjlshs_chronos/providers/theme_provider.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeNotifierProvider);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('Change the look and feel of the app.'),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            secondary: const Icon(Icons.wb_sunny),
            value: ThemeMode.light,
            groupValue: themeNotifier.themeMode,
            onChanged: (value) {
              ref.read(themeNotifierProvider.notifier).setTheme(ThemeModeOption.light);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.nightlight_round),
            value: ThemeMode.dark,
            groupValue: themeNotifier.themeMode,
            onChanged: (value) {
              ref.read(themeNotifierProvider.notifier).setTheme(ThemeModeOption.dark);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            secondary: const Icon(Icons.settings_brightness),
            value: ThemeMode.system,
            groupValue: themeNotifier.themeMode,
            onChanged: (value) {
              ref.read(themeNotifierProvider.notifier).setTheme(ThemeModeOption.system);
            },
          ),
        ],
      ),
    );
  }
}
