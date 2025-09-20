// 💰 Format Currency Utilities - iPoupei Mobile
// 
// Utilitários de formatação monetária adaptados do React
// Compatível com o padrão brasileiro: R$ 1.234,56
//
// Funcionalidades:
// - formatCurrency(1234.56) → "R$ 1.234,56"
// - parseCurrency("R$ 1.234,56") → 1234.56
// - formatCurrencyCompact(1234567) → "R$ 1,2M"

import 'dart:math' as math;

/// ✅ Formata um valor numérico para moeda brasileira (BRL)
String formatCurrency(dynamic value, {bool showSymbol = true}) {
  print('🔍 formatCurrency input: $value (${value.runtimeType})');
  
  if (value == null) return showSymbol ? 'R\$ 0,00' : '0,00';
  
  double numericValue;
  
  if (value is String) {
    numericValue = parseCurrency(value);
  } else if (value is num) {
    numericValue = value.toDouble();
  } else {
    numericValue = 0.0;
  }
  
  // Validar se é um número válido
  if (!numericValue.isFinite || numericValue.isNaN) {
    numericValue = 0.0;
  }
  
  // Limitar valor máximo/mínimo
  numericValue = math.max(-999999999999.99, math.min(999999999999.99, numericValue));
  
  // Formatar manualmente para garantir padrão brasileiro correto
  final isNegative = numericValue < 0;
  final absoluteValue = numericValue.abs();
  
  // Converter para string com 2 decimais
  final formatted = absoluteValue.toStringAsFixed(2);
  final parts = formatted.split('.');
  
  String integerPart = parts[0];
  final decimalPart = parts[1];
  
  // Adicionar separadores de milhares (pontos)
  if (integerPart.length > 3) {
    String reversed = integerPart.split('').reversed.join('');
    List<String> chunks = [];
    
    for (int i = 0; i < reversed.length; i += 3) {
      int end = math.min(i + 3, reversed.length);
      chunks.add(reversed.substring(i, end));
    }
    
    integerPart = chunks.join('.').split('').reversed.join('');
  }
  
  // Montar resultado final
  final signal = isNegative ? '-' : '';
  final valueFormatted = '$integerPart,$decimalPart';
  
  final result = showSymbol 
    ? '${signal}R\$ $valueFormatted'
    : '$signal$valueFormatted';
    
  print('🔍 formatCurrency output: "$result"');
  return result;
}

/// ✅ Converte uma string de moeda brasileira para número
double parseCurrency(String currencyString) {
  if (currencyString.isEmpty) return 0.0;
  
  // Remove símbolo de moeda, espaços e caracteres especiais
  String cleaned = currencyString
      .trim()
      .replaceAll('R\$', '')
      .replaceAll(' ', '')
      .trim();
  
  if (cleaned.isEmpty || cleaned == '-') return 0.0;
  
  // Detectar se é negativo
  final isNegative = cleaned.startsWith('-');
  if (isNegative) {
    cleaned = cleaned.substring(1);
  }
  
  try {
    // Formato brasileiro: 1.234.567,89
    if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length == 2) {
        // Parte inteira: remover pontos de milhares
        final integerPart = parts[0].replaceAll('.', '');
        // Parte decimal: máximo 2 dígitos
        final decimalPart = parts[1].length > 2 
            ? parts[1].substring(0, 2)
            : parts[1].padRight(2, '0');
        
        final combined = '$integerPart.$decimalPart';
        final result = double.tryParse(combined) ?? 0.0;
        
        return isNegative ? -result : result;
      }
    }
    
    // Formato americano ou apenas números: 1234.56 ou 1234
    cleaned = cleaned.replaceAll(',', ''); // Remove vírgulas americanas
    final result = double.tryParse(cleaned) ?? 0.0;
    
    return isNegative ? -result : result;
    
  } catch (e) {
    return 0.0;
  }
}

/// ✅ Formata um valor para moeda sem o símbolo R$
String formatCurrencyWithoutSymbol(dynamic value) {
  return formatCurrency(value, showSymbol: false);
}

/// ✅ Formatar um valor para exibição compacta (K, M, B)
String formatCurrencyCompact(dynamic value) {
  final numericValue = value is num ? value.toDouble() : parseCurrency(value.toString());
  
  if (!numericValue.isFinite || numericValue.isNaN) {
    return 'R\$ 0,00';
  }
  
  final absValue = numericValue.abs();
  final signal = numericValue < 0 ? '-' : '';
  
  if (absValue >= 1000000000) {
    return '${signal}R\$ ${(absValue / 1000000000).toStringAsFixed(1).replaceAll('.', ',')}B';
  } else if (absValue >= 1000000) {
    return '${signal}R\$ ${(absValue / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
  } else if (absValue >= 1000) {
    return '${signal}R\$ ${(absValue / 1000).toStringAsFixed(1).replaceAll('.', ',')}K';
  } else {
    return formatCurrency(numericValue);
  }
}

/// ✅ Comparar valores monetários com tolerância
bool compareCurrencyValues(dynamic value1, dynamic value2, {double tolerance = 0.01}) {
  final num1 = value1 is num ? value1.toDouble() : parseCurrency(value1.toString());
  final num2 = value2 is num ? value2.toDouble() : parseCurrency(value2.toString());
  
  return (num1 - num2).abs() <= tolerance;
}

/// ✅ Validar se uma string é um valor monetário válido
bool isCurrencyValid(String value) {
  if (value.isEmpty) return false;
  
  try {
    final parsed = parseCurrency(value);
    return parsed.isFinite && !parsed.isNaN;
  } catch (e) {
    return false;
  }
}

/// ✅ Formatar um número simples com separadores brasileiros
String formatNumber(dynamic value, {int precision = 0}) {
  final numericValue = value is num ? value.toDouble() : parseCurrency(value.toString());
  
  if (!numericValue.isFinite || numericValue.isNaN) {
    return '0';
  }
  
  final formatted = numericValue.toStringAsFixed(precision);
  final parts = formatted.split('.');
  
  String integerPart = parts[0];
  
  // Adicionar separadores de milhares
  if (integerPart.length > 3) {
    String reversed = integerPart.split('').reversed.join('');
    List<String> chunks = [];
    
    for (int i = 0; i < reversed.length; i += 3) {
      int end = math.min(i + 3, reversed.length);
      chunks.add(reversed.substring(i, end));
    }
    
    integerPart = chunks.join('.').split('').reversed.join('');
  }
  
  if (precision > 0 && parts.length > 1) {
    return '$integerPart,${parts[1]}';
  } else {
    return integerPart;
  }
}

/// ✅ Mascarar input em tempo real para entrada de valores
String maskCurrencyInput(String inputValue, {String previousValue = ''}) {
  if (inputValue.isEmpty) return '';
  
  // Remove tudo que não é dígito
  final digitsOnly = inputValue.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (digitsOnly.isEmpty || digitsOnly == '0') return '';
  
  // Converte para centavos e formata
  final valueInCents = int.tryParse(digitsOnly) ?? 0;
  final valueInReais = valueInCents / 100;
  
  return formatCurrency(valueInReais);
}