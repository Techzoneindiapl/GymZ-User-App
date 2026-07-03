import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum TextSizeScale { medium, large }

/// Provider that manages the active font scale size.
/// Defaults to [TextSizeScale.medium].
final textSizeProvider = StateProvider<TextSizeScale>((ref) => TextSizeScale.medium);
