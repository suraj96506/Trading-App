import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage dark mode state across the app.
/// Returns true if dark theme is enabled.
final themeProvider = StateProvider<bool>((ref) => false);
