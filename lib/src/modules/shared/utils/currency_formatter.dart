import 'package:intl/intl.dart';

/// Utilitário COMPLETO para formatação de valores monetários
/// Baseado na versão JavaScript com todas as funcionalidades
/// Arquivo: lib/shared/utils/currency_formatter.dart
class CurrencyFormatter {
  // Formatadores principais
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 1,
  );

  static final NumberFormat _numberFormatter = NumberFormat('#,##0.00', 'pt_BR');
  static final NumberFormat _percentFormatter = NumberFormat.percentPattern('pt_BR');

  CurrencyFormatter(double d);

  // ===== FORMATAÇÃO PRINCIPAL =====

  /// Formata um valor double para moeda brasileira
  /// Exemplo: 1234.56 -> "R\$ 1.234,56"
  static String format(double value, {
    bool showSymbol = true,
    int? precision,
    String? locale,
  }) {
    try {
      if (!isValidNumber(value)) {
        return showSymbol ? 'R\$ 0,00' : '0,00';
      }

      if (precision != null) {
        final customFormatter = NumberFormat.currency(
          locale: locale ?? 'pt_BR',
          symbol: showSymbol ? 'R\$' : '',
          decimalDigits: precision,
        );
        return customFormatter.format(value);
      }

      return showSymbol ? _formatter.format(value) : _numberFormatter.format(value);
    } catch (e) {
      return _formatCurrencyFallback(value, showSymbol);
    }
  }

  /// Formata um valor com sinal (+ ou -)
  /// Exemplo: 1234.56 -> "+R\$ 1.234,56"
  static String formatWithSign(double value) {
    final formatted = _formatter.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }

  /// Formata valor compacto para cards
  /// Exemplo: 12345.67 -> "R\$ 12,3K"
  static String formatCompact(double value) {
    try {
      if (!isValidNumber(value)) {
        return 'R\$ 0,00';
      }

      final absValue = value.abs();
      final signal = value < 0 ? '-' : '';

      if (absValue >= 1000000000) {
        return '${signal}R\$ ${(absValue / 1000000000).toStringAsFixed(1)}B';
      } else if (absValue >= 1000000) {
        return '${signal}R\$ ${(absValue / 1000000).toStringAsFixed(1)}M';
      } else if (absValue >= 1000) {
        return '${signal}R\$ ${(absValue / 1000).toStringAsFixed(1)}K';
      } else {
        return format(value);
      }
    } catch (e) {
      return 'R\$ 0,00';
    }
  }

  /// Formata apenas o valor numérico sem símbolo
  /// Exemplo: 1234.56 -> "1.234,56"
  static String formatValue(double value) {
    return format(value, showSymbol: false);
  }

  /// Formata um valor para exibição com precisão customizada
  static String formatWithPrecision(double value, int precision) {
    return format(value, precision: precision);
  }

  // ===== PARSING INTELIGENTE =====

  /// Converte string monetária para double com detecção inteligente de formato
  /// Suporta: "R\$ 1.234,56", "1234,56", "1,234.56", "1234" (centavos)
  static double parseFromString(String value) {
    if (value.isEmpty) return 0.0;

    try {
      String cleanStr = value.trim();
      if (cleanStr.isEmpty) return 0.0;

      // Remove símbolo de moeda e espaços
      cleanStr = cleanStr
          .replaceAll(RegExp(r'R\$\s?'), '')
          .replaceAll(RegExp(r'\s'), '')
          .trim();
      
      // Se ainda tem R$, remove qualquer variação
      if (cleanStr.toLowerCase().contains('r\$')) {
        cleanStr = cleanStr.replaceAll(RegExp(r'[rR]\$\s?'), '');
      }

      // ✅ DETECÇÃO INTELIGENTE DE FORMATO

      // Formato brasileiro com vírgula decimal: 1.234,56 ou 1234,56
      if (RegExp(r'^-?\d{1,3}(?:\.\d{3})*,\d{2}$').hasMatch(cleanStr)) {
        final parts = cleanStr.split(',');
        final integerPart = parts[0].replaceAll('.', ''); // Remove pontos de milhares
        final decimalPart = parts[1];
        return double.parse('$integerPart.$decimalPart');
      }

      // Formato americano com ponto decimal: 1,234.56 ou apenas 16800.00
      if (RegExp(r'^-?\d{1,3}(?:,\d{3})*\.\d{1,2}$').hasMatch(cleanStr) || 
          RegExp(r'^-?\d+\.\d{1,2}$').hasMatch(cleanStr)) {
        final cleanAmerican = cleanStr.replaceAll(',', ''); // Remove vírgulas de milhares
        return double.parse(cleanAmerican);
      }

      // Número simples com vírgula decimal: 1234,56
      if (RegExp(r'^-?\d+,\d{1,2}$').hasMatch(cleanStr)) {
        return double.parse(cleanStr.replaceAll(',', '.'));
      }


      // ✅ FORMATO CENTAVOS: apenas números (ex: 1000 = R\$ 10,00)
      if (RegExp(r'^-?\d+$').hasMatch(cleanStr)) {
        final centavos = int.parse(cleanStr);
        return centavos / 100;
      }

      // ✅ ÚLTIMAS TENTATIVAS: remove tudo que não é número, vírgula ou ponto
      final numbersOnly = cleanStr.replaceAll(RegExp(r'[^\d,.-]'), '');

      if (numbersOnly.contains(',')) {
        // Assumir formato brasileiro
        final parts = numbersOnly.split(',');
        if (parts.length == 2) {
          final integerPart = parts[0].replaceAll('.', '');
          final decimalPart = parts[1].substring(0, parts[1].length > 2 ? 2 : parts[1].length);
          final result = double.tryParse('$integerPart.$decimalPart');
          return result ?? 0.0;
        }
      }

      if (numbersOnly.contains('.')) {
        // Tentar parse direto - funciona para casos como "16800.00"
        final result = double.tryParse(numbersOnly);
        if (result != null) return result;
        
        // Se falhou, pode ser formato americano com vírgulas
        final cleanDots = numbersOnly.replaceAll(',', '');
        final result2 = double.tryParse(cleanDots);
        return result2 ?? 0.0;
      }

      // Último recurso: apenas números como centavos
      final onlyDigits = numbersOnly.replaceAll(RegExp(r'[^\d]'), '');
      if (onlyDigits.isNotEmpty) {
        return int.parse(onlyDigits) / 100;
      }

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Alias para compatibilidade
  static double parseCurrency(String currencyString) {
    return parseFromString(currencyString);
  }

  // ===== MÁSCARAS E INPUTS =====

  /// Mascara input em tempo real para campos monetários
  /// Uso: onChanged: (value) => setState(() => _valor = CurrencyFormatter.maskCurrencyInput(value))
  static String maskCurrencyInput(String inputValue, [String previousValue = '']) {
    if (inputValue.isEmpty) return '';

    // Remove tudo que não é dígito
    final digitsOnly = inputValue.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty || digitsOnly == '0') return '';

    // Converte para centavos e formata
    final valueInCents = int.tryParse(digitsOnly) ?? 0;
    final valueInReais = valueInCents / 100;

    // Formatar com vírgula brasileira (sem símbolo R\$)
    return NumberFormat('#,##0.00', 'pt_BR').format(valueInReais);
  }

  /// Mascara input com símbolo R\$
  static String maskCurrencyInputWithSymbol(String inputValue) {
    final masked = maskCurrencyInput(inputValue);
    return masked.isEmpty ? '' : 'R\$ $masked';
  }

  // ===== VALIDAÇÕES =====

  /// Valida se um número é válido para formatação monetária
  static bool isValidNumber(double num) {
    return !num.isNaN && 
           num.isFinite && 
           num >= -999999999999 && 
           num <= 999999999999;
  }

  /// Valida se uma string é um valor monetário válido
  static bool isCurrencyValid(String value) {
    if (value.isEmpty) return false;
    
    try {
      final numericValue = parseFromString(value);
      return isValidNumber(numericValue);
    } catch (e) {
      return false;
    }
  }

  /// Valida se um valor está dentro de um range
  static bool isValueInRange(double value, double min, double max) {
    return isValidNumber(value) && value >= min && value <= max;
  }

  // ===== COMPARAÇÕES =====

  /// Compara valores monetários com tolerância
  static bool compareCurrencyValues(dynamic value1, dynamic value2, [double tolerance = 0.01]) {
    final num1 = value1 is double ? value1 : parseFromString(value1.toString());
    final num2 = value2 is double ? value2 : parseFromString(value2.toString());
    
    return (num1 - num2).abs() <= tolerance;
  }

  // ===== FORMATAÇÕES ESPECIAIS =====

  /// Formata um valor como porcentagem
  static String formatPercent(double value, [int precision = 1]) {
    try {
      if (!isValidNumber(value)) {
        return '0%';
      }

      final formatter = NumberFormat.percentPattern('pt_BR');
      formatter.minimumFractionDigits = precision;
      formatter.maximumFractionDigits = precision;
      
      return formatter.format(value);
    } catch (e) {
      return '0%';
    }
  }

  /// Formata um número simples com separadores brasileiros
  static String formatNumber(double value, [int precision = 0]) {
    try {
      if (!isValidNumber(value)) {
        return '0';
      }

      final formatter = NumberFormat('#,##0.${'0' * precision}', 'pt_BR');
      return formatter.format(value);
    } catch (e) {
      return '0';
    }
  }

  // ===== UTILITÁRIOS DE CORES =====

  /// Retorna cor baseada no valor (verde para positivo, vermelho para negativo)
  static String getValueColorClass(double value) {
    if (value > 0) return 'positive';
    if (value < 0) return 'negative';
    return 'neutral';
  }

  /// Verifica se valor é positivo, negativo ou neutro
  static ValueType getValueType(double value) {
    if (value > 0) return ValueType.positive;
    if (value < 0) return ValueType.negative;
    return ValueType.neutral;
  }

  // ===== CÁLCULOS FINANCEIROS =====

  /// Calcula porcentagem de um valor sobre outro
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// Calcula variação percentual entre dois valores
  static double calculateVariation(double oldValue, double newValue) {
    if (oldValue == 0) return newValue == 0 ? 0 : 100;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  /// Formata variação com sinal e cor
  static String formatVariation(double oldValue, double newValue) {
    final variation = calculateVariation(oldValue, newValue);
    final signal = variation >= 0 ? '+' : '';
    return '$signal${formatPercent(variation / 100)}';
  }

  // ===== HELPERS INTERNOS =====

  /// Fallback manual para formatação em caso de erro
  static String _formatCurrencyFallback(double value, bool showSymbol) {
    try {
      final absValue = value.abs();
      final signal = value < 0 ? '-' : '';
      
      final formatted = absValue.toStringAsFixed(2);
      final parts = formatted.split('.');
      final integer = parts[0];
      final decimal = parts[1];
      
      // Adicionar separadores de milhares
      final integerFormatted = integer.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
      
      return showSymbol 
        ? '${signal}R\$ $integerFormatted,$decimal'
        : '$signal$integerFormatted,$decimal';
    } catch (e) {
      return showSymbol ? 'R\$ 0,00' : '0,00';
    }
  }
}

// ===== ENUMS E CLASSES AUXILIARES =====

enum ValueType {
  positive,
  negative,
  neutral,
}

/// Extensão para facilitar o uso em widgets
extension CurrencyFormatterExtension on double {
  /// Formata o valor como moeda
  String get currency => CurrencyFormatter.format(this);
  
  /// Formata o valor como moeda compacta
  String get currencyCompact => CurrencyFormatter.formatCompact(this);
  
  /// Formata o valor como porcentagem
  String get percent => CurrencyFormatter.formatPercent(this);
  
  /// Verifica se é um valor válido
  bool get isValidCurrency => CurrencyFormatter.isValidNumber(this);
  
  /// Retorna o tipo do valor
  ValueType get valueType => CurrencyFormatter.getValueType(this);
}

/// Extensão para strings
extension CurrencyStringExtension on String {
  /// Converte string para valor monetário
  double get toCurrency => CurrencyFormatter.parseFromString(this);
  
  /// Verifica se é uma string monetária válida
  bool get isValidCurrency => CurrencyFormatter.isCurrencyValid(this);
  
  /// Aplica máscara monetária
  String get currencyMask => CurrencyFormatter.maskCurrencyInput(this);
}