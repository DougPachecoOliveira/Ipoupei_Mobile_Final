// lib/shared/utils/fatura_formatters.dart

import 'package:intl/intl.dart';

/// Formatadores específicos para faturas e períodos
class FaturaFormatters {
  /// Formata data para o padrão "Jul/25"
  static String formatarMesAno(DateTime data) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    
    final mes = meses[data.month - 1];
    final ano = data.year.toString().substring(2);
    
    return '$mes/$ano';
  }

  /// Formata período completo "Julho de 2025"
  static String formatarPeriodoCompleto(DateTime data) {
    return DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(data);
  }

  /// Obtém nome do mês
  static String getNomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    
    return meses[mes - 1];
  }

  /// Formata valor da fatura
  static String formatarValorFatura(double valor) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(valor);
  }
}