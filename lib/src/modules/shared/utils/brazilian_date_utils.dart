/// Utilitários para formatação de datas no padrão brasileiro
/// Arquivo: lib/shared/utils/brazilian_date_utils.dart

class BrazilianDateUtils {
  /// Formatar data para dd/mm/aaaa
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formatar data e hora para dd/mm/aaaa hh:mm:ss (para logs/banco)
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Formatar data e hora simplificada para dd/mm/aaaa hh:mm
  static String formatDateTimeShort(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formatar mês/ano para mm/aaaa
  static String formatMonthYear(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formatar nome do mês em português
  static String formatMonthName(DateTime date) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[date.month - 1];
  }

  /// Formatar mês abreviado em português
  static String formatMonthShort(DateTime date) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[date.month - 1];
  }

  /// Formatar dia da semana em português
  static String formatWeekday(DateTime date) {
    const weekdays = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
      'Sexta-feira', 'Sábado', 'Domingo'
    ];
    return weekdays[date.weekday - 1];
  }

  /// Formatar dia da semana abreviado
  static String formatWeekdayShort(DateTime date) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekdays[date.weekday - 1];
  }

  /// Parse data brasileira dd/mm/aaaa para DateTime
  static DateTime? parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Parse data e hora brasileira dd/mm/aaaa hh:mm:ss para DateTime
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

  /// Formatar data relativa (Hoje, Ontem, dd/mm/aaaa)
  static String formatRelative(DateTime date) {
    if (isToday(date)) return 'Hoje';
    if (isYesterday(date)) return 'Ontem';
    if (isTomorrow(date)) return 'Amanhã';
    
    return formatDate(date);
  }

  /// Formatar período entre duas datas
  static String formatPeriod(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return formatDate(start);
    }
    
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} a ${end.day}/${end.month}/${end.year}';
    }
    
    return '${formatDate(start)} a ${formatDate(end)}';
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

  /// Formatar duração em português
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} dia${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hora${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minuto${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Agora mesmo';
    }
  }

  /// Formatar tempo decorrido (ex: "há 2 dias")
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'há ${difference.inDays} dia${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'há ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'há ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Agora mesmo';
    }
  }
}