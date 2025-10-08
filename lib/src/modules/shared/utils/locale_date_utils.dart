/// Utilitários para formatação de datas com suporte a localização
/// Arquivo: lib/shared/utils/locale_date_utils.dart

import 'app_locale.dart';

class LocaleDateUtils {
  /// Formatar data baseado na localização atual
  static String formatDate(DateTime date) {
    final settings = LocaleConfig.dateSettings;
    
    switch (LocaleConfig.currentLocale) {
      case AppLocale.ptBR:
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case AppLocale.enUS:
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Formatar data e hora para logs/banco
  static String formatDateTime(DateTime dateTime) {
    switch (LocaleConfig.currentLocale) {
      case AppLocale.ptBR:
        return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
      case AppLocale.enUS:
        return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    }
  }

  /// Formatar data e hora simplificada
  static String formatDateTimeShort(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formatar mês/ano baseado na localização
  static String formatMonthYear(DateTime date) {
    switch (LocaleConfig.currentLocale) {
      case AppLocale.ptBR:
        return '${date.month.toString().padLeft(2, '0')}/${date.year}';
      case AppLocale.enUS:
        return '${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Formatar nome do mês na linguagem atual
  static String formatMonthName(DateTime date) {
    final settings = LocaleConfig.dateSettings;
    return settings.monthNames[date.month - 1];
  }

  /// Formatar mês abreviado na linguagem atual
  static String formatMonthShort(DateTime date) {
    final settings = LocaleConfig.dateSettings;
    return settings.monthNamesShort[date.month - 1];
  }

  /// Formatar dia da semana na linguagem atual
  static String formatWeekday(DateTime date) {
    final settings = LocaleConfig.dateSettings;
    return settings.weekdayNames[date.weekday - 1];
  }

  /// Formatar dia da semana abreviado
  static String formatWeekdayShort(DateTime date) {
    final settings = LocaleConfig.dateSettings;
    return settings.weekdayNamesShort[date.weekday - 1];
  }

  /// Parse data baseado na localização
  static DateTime? parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      
      switch (LocaleConfig.currentLocale) {
        case AppLocale.ptBR:
          // dd/mm/yyyy
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
          
        case AppLocale.enUS:
          // mm/dd/yyyy
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
  }

  /// Parse data e hora
  static DateTime? parseDateTime(String dateTimeStr) {
    try {
      final parts = dateTimeStr.split(' ');
      if (parts.length != 2) return null;
      
      final date = parseDate(parts[0]);
      if (date == null) return null;
      
      final timeParts = parts[1].split(':');
      if (timeParts.length < 2 || timeParts.length > 3) return null;
      
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length == 3 ? int.parse(timeParts[2]) : 0;
      
      return DateTime(date.year, date.month, date.day, hour, minute, second);
    } catch (e) {
      return null;
    }
  }

  /// Verificar se é hoje
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
  }

  /// Verificar se é ontem
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Verificar se é amanhã
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  /// Formatar data relativa na linguagem atual
  static String formatRelative(DateTime date) {
    final settings = LocaleConfig.dateSettings;
    
    if (isToday(date)) return settings.todayLabel;
    if (isYesterday(date)) return settings.yesterdayLabel;
    if (isTomorrow(date)) return settings.tomorrowLabel;
    
    return formatDate(date);
  }

  /// Formatar período entre duas datas
  static String formatPeriod(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return formatDate(start);
    }
    
    switch (LocaleConfig.currentLocale) {
      case AppLocale.ptBR:
        if (start.year == end.year && start.month == end.month) {
          return '${start.day} a ${end.day}/${end.month}/${end.year}';
        }
        return '${formatDate(start)} a ${formatDate(end)}';
        
      case AppLocale.enUS:
        if (start.year == end.year && start.month == end.month) {
          return '${start.month}/${start.day} to ${end.day}/${end.year}';
        }
        return '${formatDate(start)} to ${formatDate(end)}';
    }
  }

  /// Calcular idade em anos
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Obter primeiro dia do mês
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Obter último dia do mês
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Obter lista de dias do mês
  static List<DateTime> getDaysInMonth(DateTime date) {
    final firstDay = firstDayOfMonth(date);
    final lastDay = lastDayOfMonth(date);
    
    final days = <DateTime>[];
    for (int i = 0; i < lastDay.day; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    
    return days;
  }

  /// Formatar duração na linguagem atual
  static String formatDuration(Duration duration) {
    switch (LocaleConfig.currentLocale) {
      case AppLocale.ptBR:
        if (duration.inDays > 0) {
          return '${duration.inDays} dia${duration.inDays == 1 ? '' : 's'}';
        } else if (duration.inHours > 0) {
          return '${duration.inHours} hora${duration.inHours == 1 ? '' : 's'}';
        } else if (duration.inMinutes > 0) {
          return '${duration.inMinutes} minuto${duration.inMinutes == 1 ? '' : 's'}';
        } else {
          return 'Agora mesmo';
        }
        
      case AppLocale.enUS:
        if (duration.inDays > 0) {
          return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
        } else if (duration.inHours > 0) {
          return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
        } else if (duration.inMinutes > 0) {
          return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
        } else {
          return 'Just now';
        }
    }
  }

  /// Formatar tempo decorrido na linguagem atual
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    switch (LocaleConfig.currentLocale) {
      case AppLocale.ptBR:
        if (difference.inDays > 0) {
          return 'há ${difference.inDays} dia${difference.inDays == 1 ? '' : 's'}';
        } else if (difference.inHours > 0) {
          return 'há ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
        } else if (difference.inMinutes > 0) {
          return 'há ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
        } else {
          return 'Agora mesmo';
        }
        
      case AppLocale.enUS:
        if (difference.inDays > 0) {
          return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
        } else {
          return 'Just now';
        }
    }
  }

  // Métodos de compatibilidade para não quebrar código existente
  /// @deprecated Use formatDate() instead - mantido para compatibilidade
  static String formatDateBR(DateTime date) => formatDate(date);
  
  /// @deprecated Use formatDateTime() instead - mantido para compatibilidade  
  static String formatDateTimeBR(DateTime dateTime) => formatDateTime(dateTime);
  
  /// @deprecated Use parseDate() instead - mantido para compatibilidade
  static DateTime? parseBRDate(String dateStr) => parseDate(dateStr);
  
  /// @deprecated Use parseDateTime() instead - mantido para compatibilidade
  static DateTime? parseBRDateTime(String dateTimeStr) => parseDateTime(dateTimeStr);
}