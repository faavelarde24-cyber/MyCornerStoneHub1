/// Utility functions for safely handling IDs in logging and display
library;

/// Safe helper to get shortened book/page ID for logging
/// Handles both short numeric IDs (1-2 digits) and long UUIDs
String getSafeIdShort(String id, {int maxLength = 8}) {
  if (id.isEmpty) return 'EMPTY_ID';
  if (id.length <= maxLength) return id;
  return id.substring(0, maxLength);
}

/// Validates if an ID is valid (not null, empty, or "0")
bool isValidId(String? id) {
  return id != null && id.isNotEmpty && id != '0';
}