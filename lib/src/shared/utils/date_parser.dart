class DateParser {
  /// Safely parses a date string from the API (which might be SQLite format or ISO-8601).
  /// SQLite returns: '2026-10-06 19:30:54'
  /// JS ISO returns: '2026-10-06T19:30:54.123Z'
  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      // If it doesn't have a 'Z' or offset, and lacks a 'T', we might need to fix it.
      // DateTime.tryParse handles most things gracefully if we just normalize it.
      String normalized = dateStr;
      
      // If it's the standard SQLite output like '2026-10-06 19:30:54'
      if (!normalized.contains('T') && normalized.length >= 19) {
        normalized = normalized.replaceFirst(' ', 'T');
      }
      
      // If it's already UTC but missing the 'Z' (often true for SQLite timestamps)
      if (!normalized.endsWith('Z') && !normalized.contains(RegExp(r'[+-]\d{2}:\d{2}$'))) {
        normalized = '${normalized}Z';
      }
      
      return DateTime.tryParse(normalized)?.toLocal() ?? DateTime.tryParse(dateStr)?.toLocal();
    } catch (e) {
      return null;
    }
  }
}
