import 'package:flutter/foundation.dart';

/// Lightweight in-memory "admin unlocked" flag.
///
/// Not a security boundary; it only controls UI/editing capabilities.
final class AdminAccessService {
  AdminAccessService._();

  static final ValueNotifier<bool> unlocked = ValueNotifier<bool>(false);

  static bool get isUnlocked => unlocked.value;

  static void unlock() {
    unlocked.value = true;
  }

  static void lock() {
    unlocked.value = false;
  }
}
