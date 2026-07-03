import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider that manages the active [ThemeMode].
/// Defaults to [ThemeMode.dark] to maintain the default branding.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
