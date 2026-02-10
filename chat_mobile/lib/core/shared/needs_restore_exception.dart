// lib/core/exceptions/needs_restore_exception.dart

class NeedsRestoreException implements Exception {
  final String message;
  
  NeedsRestoreException(this.message);
  
  @override
  String toString() => message;
}