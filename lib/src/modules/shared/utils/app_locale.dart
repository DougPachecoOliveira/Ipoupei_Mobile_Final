/// Sistema de localização do iPoupei
/// Arquivo: lib/shared/utils/app_locale.dart

enum AppLocale {
  ptBR('pt', 'BR', 'Português (Brasil)'),
  enUS('en', 'US', 'English (United States)');

  const AppLocale(this.languageCode, this.countryCode, this.displayName);

  final String languageCode;
  final String countryCode;
  final String displayName;

  String get locale => '${languageCode}_$countryCode';
}

/// Configurações de localização
class LocaleConfig {
  static AppLocale _currentLocale = AppLocale.ptBR; // Padrão brasileiro

  static AppLocale get currentLocale => _currentLocale;

  static void setLocale(AppLocale locale) {
    _currentLocale = locale;
  }

  static bool get isPtBR => _currentLocale == AppLocale.ptBR;
  static bool get isEnUS => _currentLocale == AppLocale.enUS;

  /// Obter configurações de data baseado na localização
  static DateLocaleSettings get dateSettings {
    switch (_currentLocale) {
      case AppLocale.ptBR:
        return DateLocaleSettings.ptBR();
      case AppLocale.enUS:
        return DateLocaleSettings.enUS();
    }
  }
}

/// Configurações específicas de data por localização
class DateLocaleSettings {
  final String dateFormat;
  final String dateTimeFormat;
  final String monthYearFormat;
  final List<String> monthNames;
  final List<String> monthNamesShort;
  final List<String> weekdayNames;
  final List<String> weekdayNamesShort;
  final String todayLabel;
  final String yesterdayLabel;
  final String tomorrowLabel;

  const DateLocaleSettings({
    required this.dateFormat,
    required this.dateTimeFormat,
    required this.monthYearFormat,
    required this.monthNames,
    required this.monthNamesShort,
    required this.weekdayNames,
    required this.weekdayNamesShort,
    required this.todayLabel,
    required this.yesterdayLabel,
    required this.tomorrowLabel,
  });

  factory DateLocaleSettings.ptBR() {
    return const DateLocaleSettings(
      dateFormat: 'dd/MM/yyyy',
      dateTimeFormat: 'dd/MM/yyyy HH:mm:ss',
      monthYearFormat: 'MM/yyyy',
      monthNames: [
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
      ],
      monthNamesShort: [
        'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
        'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
      ],
      weekdayNames: [
        'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
        'Sexta-feira', 'Sábado', 'Domingo'
      ],
      weekdayNamesShort: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
      todayLabel: 'Hoje',
      yesterdayLabel: 'Ontem',
      tomorrowLabel: 'Amanhã',
    );
  }

  factory DateLocaleSettings.enUS() {
    return const DateLocaleSettings(
      dateFormat: 'MM/dd/yyyy',
      dateTimeFormat: 'MM/dd/yyyy HH:mm:ss',
      monthYearFormat: 'MM/yyyy',
      monthNames: [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ],
      monthNamesShort: [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ],
      weekdayNames: [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ],
      weekdayNamesShort: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      todayLabel: 'Today',
      yesterdayLabel: 'Yesterday',
      tomorrowLabel: 'Tomorrow',
    );
  }
}