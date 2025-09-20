// 💰 Currency Formatter - iPoupei Mobile
// 
// Utilitário para formatação de valores monetários
// Padrão brasileiro: R$ 1.234,56

class CurrencyFormatter {
  /// Formatar valor para moeda brasileira
  static String format(double valor) {
    if (valor == 0.0) return 'R\$ 0,00';
    
    // Determinar sinal
    final isNegativo = valor < 0;
    final valorAbsoluto = valor.abs();
    
    // Converter para string com 2 casas decimais
    final valorString = valorAbsoluto.toStringAsFixed(2);
    
    // Separar parte inteira e decimal
    final parts = valorString.split('.');
    final parteInteira = parts[0];
    final parteDecimal = parts[1];
    
    // Adicionar separadores de milhares
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final parteInteiraFormatada = parteInteira.replaceAllMapped(
      regex, 
      (Match match) => '${match[1]}.',
    );
    
    // Montar resultado final
    final resultado = 'R\$ $parteInteiraFormatada,$parteDecimal';
    
    return isNegativo ? '-$resultado' : resultado;
  }

  /// Formatar valor para input (sem R$, só números)
  static String formatForInput(double valor) {
    if (valor == 0.0) return '0,00';
    
    final isNegativo = valor < 0;
    final valorAbsoluto = valor.abs();
    
    final valorString = valorAbsoluto.toStringAsFixed(2);
    final parts = valorString.split('.');
    final resultado = '${parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    )},${parts[1]}';
    
    return isNegativo ? '-$resultado' : resultado;
  }

  /// Extrair valor numérico de string formatada
  static double parse(String texto) {
    if (texto.isEmpty) return 0.0;
    
    // Detectar sinal negativo
    bool isNegative = texto.trim().startsWith('-');
    
    // Remove tudo exceto dígitos e vírgula
    String cleaned = texto.replaceAll(RegExp(r'[^0-9,]'), '');
    
    if (cleaned.isEmpty) return 0.0;
    
    double valor = 0.0;
    
    // Se tem vírgula, é formato brasileiro: X,XX
    if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length == 2) {
        final integerPart = int.tryParse(parts[0]) ?? 0;
        final decimalPart = int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0;
        valor = integerPart + (decimalPart / 100.0);
      } else {
        valor = double.tryParse(parts[0]) ?? 0.0;
      }
    } else {
      // Só números
      final number = int.tryParse(cleaned) ?? 0;
      valor = number.toDouble();
    }
    
    return isNegative ? -valor : valor;
  }

  /// Validar se string é um valor monetário válido
  static bool isValid(String texto) {
    if (texto.isEmpty) return false;
    
    try {
      parse(texto);
      return true;
    } catch (e) {
      return false;
    }
  }
}