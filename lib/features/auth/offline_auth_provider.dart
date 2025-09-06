import 'package:flutter_riverpod/flutter_riverpod.dart';

final isOfflineProvider = StateProvider<bool>((ref) => false);
final isLateModeProvider = StateProvider<bool>((ref) => false);
