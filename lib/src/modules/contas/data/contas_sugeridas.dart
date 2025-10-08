/// Dados das contas pré-configuradas para importação rápida
/// Baseado nos bancos mais populares do Brasil
class ContasSugeridas {
  /// Lista completa de contas sugeridas
  static const List<Map<String, dynamic>> todas = [
    // ========== BANCOS DIGITAIS ==========

    {
      'nome': 'Conta Corrente Nubank',
      'banco': 'Nubank',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#8A05BE',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente Inter',
      'banco': 'Inter',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#FF7A00',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente C6 Bank',
      'banco': 'C6 Bank',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#1C1C1C',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente PagBank',
      'banco': 'PagBank',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#00B24E',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente PicPay',
      'banco': 'PicPay',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#11C76F',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente Next',
      'banco': 'Next',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#CC092F',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente Neon',
      'banco': 'Neon',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#00D5E4',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente Will Bank',
      'banco': 'Will Bank',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#FFD100',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente Mercado Pago',
      'banco': 'Mercado Pago',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#009EE3',
      'icone': 'bank',
      'categoria': 'populares',
    },

    {
      'nome': 'Conta Corrente Digio',
      'banco': 'Digio',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#1E90FF',
      'icone': 'bank',
      'categoria': 'populares',
    },

    // ========== BANCOS TRADICIONAIS ==========

    {
      'nome': 'Conta Corrente Itaú',
      'banco': 'Itaú',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#EC7000',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente Bradesco',
      'banco': 'Bradesco',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#CC092F',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente Santander',
      'banco': 'Santander',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#EC0000',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente Banco do Brasil',
      'banco': 'Banco do Brasil',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#FFF100',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente Caixa',
      'banco': 'Caixa Econômica',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#0066B3',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente BTG Pactual',
      'banco': 'BTG Pactual',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#000000',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente Safra',
      'banco': 'Safra',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#0033A0',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente Banrisul',
      'banco': 'Banrisul',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#005EB8',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente Sicredi',
      'banco': 'Sicredi',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#006B3D',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },

    {
      'nome': 'Conta Corrente BV',
      'banco': 'BV',
      'tipo': 'corrente',
      'saldo_inicial': 0.0,
      'cor': '#003DA5',
      'icone': 'bank',
      'categoria': 'tradicionais',
    },
  ];

  /// Filtrar contas por categoria
  static List<Map<String, dynamic>> porCategoria(String categoria) {
    return todas.where((conta) => conta['categoria'] == categoria).toList();
  }

  /// Buscar contas por texto
  static List<Map<String, dynamic>> buscar(String query) {
    if (query.isEmpty) return todas;

    final queryLower = query.toLowerCase();
    return todas.where((conta) {
      final nome = (conta['nome'] as String).toLowerCase();
      final banco = (conta['banco'] as String).toLowerCase();
      return nome.contains(queryLower) || banco.contains(queryLower);
    }).toList();
  }
}
