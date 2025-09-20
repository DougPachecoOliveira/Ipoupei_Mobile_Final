/// 🔧 Utilitários para conversões seguras de tipos
/// Previne crashes por valores null ou tipos incorretos
class SafeConversions {
  
  /// Conversão segura para double
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Conversão segura para int
  static int toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Conversão segura para boolean (compatível com SQLite)
  static bool toBoolean(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == '1' || lower == 'true' || lower == 'yes';
    }
    return defaultValue;
  }

  /// Parse seguro de cores hexadecimais
  static int parseColor(String? colorString, {int defaultColor = 0xFF6200EA}) {
    if (colorString == null || colorString.isEmpty) return defaultColor;
    
    try {
      String cleanColor = colorString.replaceAll('#', '0xFF');
      if (cleanColor.length != 10) return defaultColor; // 0xFF + 6 chars
      return int.parse(cleanColor);
    } catch (e) {
      return defaultColor;
    }
  }

  /// Parse seguro de DateTime
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse seguro de DateTime com fallback
  static DateTime parseDateTimeWithFallback(dynamic value, DateTime fallback) {
    final result = parseDateTime(value);
    return result ?? fallback;
  }
}