import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme provider – true for dark mode, false for light mode.
final themeProvider = StateProvider<bool>((ref) => false);
