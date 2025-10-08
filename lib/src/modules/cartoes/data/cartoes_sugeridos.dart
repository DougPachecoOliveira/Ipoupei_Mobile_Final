/// Dados dos cartões pré-configurados para importação rápida
/// Baseado nos cartões mais populares do Brasil
class CartoesSugeridos {
  /// Lista completa de cartões sugeridos
  static const List<Map<String, dynamic>> todos = [
    // ========== CARTÕES POPULARES ==========
    
    // BANCOS DIGITAIS
    {
      'nome': 'Nubank',
      'limite': 2000.0,
      'dia_fechamento': 15,
      'dia_vencimento': 25,
      'bandeira': 'MASTERCARD',
      'cor': '#8A05BE',
      'categoria': 'populares',
    },
    
    {
      'nome': 'Mercado Pago Visa',
      'limite': 1800.0,
      'dia_fechamento': 10,
      'dia_vencimento': 20,
      'bandeira': 'VISA',
      'cor': '#C0C0C0',
      'categoria': 'populares',
    },
    
    {
      'nome': 'Inter Visa',
      'limite': 1500.0,
      'dia_fechamento': 20,
      'dia_vencimento': 30,
      'bandeira': 'VISA',
      'cor': '#FF7A00',
      'categoria': 'populares',
    },
    
    {
      'nome': 'C6 Bank',
      'limite': 3000.0,
      'dia_fechamento': 5,
      'dia_vencimento': 15,
      'bandeira': 'MASTERCARD',
      'cor': '#1C1C1C',
      'categoria': 'populares',
    },
    
    {
      'nome': 'PicPay Visa',
      'limite': 1200.0,
      'dia_fechamento': 25,
      'dia_vencimento': 5,
      'bandeira': 'VISA',
      'cor': '#00D924',
      'categoria': 'populares',
    },
    
    {
      'nome': 'Will Bank',
      'limite': 1000.0,
      'dia_fechamento': 28,
      'dia_vencimento': 8,
      'bandeira': 'MASTERCARD',
      'cor': '#FFD100',
      'categoria': 'populares',
    },
    
    // BANCOS TRADICIONAIS
    {
      'nome': 'Itaú Click',
      'limite': 2500.0,
      'dia_fechamento': 12,
      'dia_vencimento': 22,
      'bandeira': 'MASTERCARD',
      'cor': '#EC7000',
      'categoria': 'populares',
    },
    
    {
      'nome': 'Bradesco Next',
      'limite': 2000.0,
      'dia_fechamento': 18,
      'dia_vencimento': 28,
      'bandeira': 'MASTERCARD',
      'cor': '#CC092F',
      'categoria': 'populares',
    },
    
    {
      'nome': 'Santander SX',
      'limite': 3500.0,
      'dia_fechamento': 8,
      'dia_vencimento': 18,
      'bandeira': 'MASTERCARD',
      'cor': '#EC0000',
      'categoria': 'populares',
    },
    
    {
      'nome': 'Banco do Brasil',
      'limite': 2200.0,
      'dia_fechamento': 6,
      'dia_vencimento': 16,
      'bandeira': 'ELO',
      'cor': '#FFDD00',
      'categoria': 'populares',
    },
    
    {
      'nome': 'Caixa Elo',
      'limite': 1800.0,
      'dia_fechamento': 14,
      'dia_vencimento': 24,
      'bandeira': 'ELO',
      'cor': '#0066CC',
      'categoria': 'populares',
    },

    // ========== PREMIUM ==========
    
    {
      'nome': 'BTG+ Mastercard',
      'limite': 8000.0,
      'dia_fechamento': 22,
      'dia_vencimento': 2,
      'bandeira': 'MASTERCARD',
      'cor': '#1E3A8A',
      'categoria': 'premium',
    },
    
    {
      'nome': 'XP Visa Infinite',
      'limite': 10000.0,
      'dia_fechamento': 10,
      'dia_vencimento': 20,
      'bandeira': 'VISA',
      'cor': '#000000',
      'categoria': 'premium',
    },
    
    {
      'nome': 'Itau The One Mastercard',
      'limite': 15000.0,
      'dia_fechamento': 5,
      'dia_vencimento': 15,
      'bandeira': 'MASTERCARD',
      'cor': '#000000',
      'categoria': 'premium',
    },
    
    {
      'nome': 'Unicred Ímpar Visa Infinite',
      'limite': 12000.0,
      'dia_fechamento': 8,
      'dia_vencimento': 18,
      'bandeira': 'VISA',
      'cor': '#000000',
      'categoria': 'premium',
    },
    
    {
      'nome': 'C6 Bank Graphene Mastercard Black',
      'limite': 20000.0,
      'dia_fechamento': 12,
      'dia_vencimento': 22,
      'bandeira': 'MASTERCARD',
      'cor': '#C0C0C0',
      'categoria': 'premium',
    },
    
    {
      'nome': 'Bradesco Aeternum Visa Infinite',
      'limite': 18000.0,
      'dia_fechamento': 15,
      'dia_vencimento': 25,
      'bandeira': 'VISA',
      'cor': '#000000',
      'categoria': 'premium',
    },
    
    {
      'nome': 'Caixa Investidor Visa Infinite',
      'limite': 14000.0,
      'dia_fechamento': 20,
      'dia_vencimento': 30,
      'bandeira': 'VISA',
      'cor': '#800020',
      'categoria': 'premium',
    },
    
    {
      'nome': 'BRB Dux Visa Infinite',
      'limite': 16000.0,
      'dia_fechamento': 25,
      'dia_vencimento': 5,
      'bandeira': 'VISA',
      'cor': '#2F2F2F',
      'categoria': 'premium',
    },
    
    {
      'nome': 'Amex Green',
      'limite': 5000.0,
      'dia_fechamento': 16,
      'dia_vencimento': 26,
      'bandeira': 'AMEX',
      'cor': '#006A4E',
      'categoria': 'premium',
    },
    
    {
      'nome': 'Amex Gold',
      'limite': 15000.0,
      'dia_fechamento': 24,
      'dia_vencimento': 4,
      'bandeira': 'AMEX',
      'cor': '#DAA520',
      'categoria': 'premium',
    },
    
    {
      'nome': 'Amex Platinum',
      'limite': 20000.0,
      'dia_fechamento': 3,
      'dia_vencimento': 13,
      'bandeira': 'AMEX',
      'cor': '#C0C0C0',
      'categoria': 'premium',
    },

    // ========== CO-BRANDED (VAREJO) ==========
    
    {
      'nome': 'Magazine Luiza',
      'limite': 2500.0,
      'dia_fechamento': 15,
      'dia_vencimento': 25,
      'bandeira': 'MASTERCARD',
      'cor': '#ADD8E6',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Renner',
      'limite': 1500.0,
      'dia_fechamento': 7,
      'dia_vencimento': 17,
      'bandeira': 'VISA',
      'cor': '#E31E24',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Riachuelo',
      'limite': 1400.0,
      'dia_fechamento': 13,
      'dia_vencimento': 23,
      'bandeira': 'MASTERCARD',
      'cor': '#000000',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'C&A',
      'limite': 1600.0,
      'dia_fechamento': 9,
      'dia_vencimento': 19,
      'bandeira': 'VISA',
      'cor': '#0066CC',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Carrefour',
      'limite': 2200.0,
      'dia_fechamento': 12,
      'dia_vencimento': 22,
      'bandeira': 'MASTERCARD',
      'cor': '#008080',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Casas Bahia',
      'limite': 2000.0,
      'dia_fechamento': 10,
      'dia_vencimento': 20,
      'bandeira': 'VISA',
      'cor': '#0033A0',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Lojas Americanas',
      'limite': 1500.0,
      'dia_fechamento': 25,
      'dia_vencimento': 5,
      'bandeira': 'VISA',
      'cor': '#E31E24',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Pão de Açúcar',
      'limite': 2800.0,
      'dia_fechamento': 18,
      'dia_vencimento': 28,
      'bandeira': 'VISA',
      'cor': '#228B22',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Passaí Visa',
      'limite': 1800.0,
      'dia_fechamento': 20,
      'dia_vencimento': 30,
      'bandeira': 'VISA',
      'cor': '#FFD700',
      'categoria': 'co-branded',
    },
    
    {
      'nome': 'Centauro',
      'limite': 1800.0,
      'dia_fechamento': 21,
      'dia_vencimento': 31,
      'bandeira': 'VISA',
      'cor': '#DC143C',
      'categoria': 'co-branded',
    },

    // ========== VIAGENS ==========
    
    {
      'nome': 'Azul Itaucard',
      'limite': 4000.0,
      'dia_fechamento': 4,
      'dia_vencimento': 14,
      'bandeira': 'VISA',
      'cor': '#003366',
      'categoria': 'viagens',
    },
    
    {
      'nome': 'TAP Miles&Go',
      'limite': 3500.0,
      'dia_fechamento': 27,
      'dia_vencimento': 7,
      'bandeira': 'VISA',
      'cor': '#0066CC',
      'categoria': 'viagens',
    },

    // ========== INTERNACIONAIS ==========
    
    {
      'nome': 'HSBC Premier',
      'limite': 8000.0,
      'dia_fechamento': 29,
      'dia_vencimento': 9,
      'bandeira': 'MASTERCARD',
      'cor': '#DB0011',
      'categoria': 'internacionais',
    },
    
    {
      'nome': 'Amazon Prime Visa',
      'limite': 4000.0,
      'dia_fechamento': 23,
      'dia_vencimento': 3,
      'bandeira': 'VISA',
      'cor': '#1E3A8A',
      'categoria': 'internacionais',
    },
    
    {
      'nome': 'Wise Card',
      'limite': 5000.0,
      'dia_fechamento': 1,
      'dia_vencimento': 11,
      'bandeira': 'MASTERCARD',
      'cor': '#00B04F',
      'categoria': 'internacionais',
    },

    // ========== INICIANTES ==========
    
    {
      'nome': 'Porto Seguro',
      'limite': 800.0,
      'dia_fechamento': 11,
      'dia_vencimento': 21,
      'bandeira': 'VISA',
      'cor': '#0066CC',
      'categoria': 'iniciantes',
    },
    
    {
      'nome': 'Pan Visa',
      'limite': 1000.0,
      'dia_fechamento': 19,
      'dia_vencimento': 29,
      'bandeira': 'VISA',
      'cor': '#004990',
      'categoria': 'iniciantes',
    },
    
    {
      'nome': 'Neon Mastercard',
      'limite': 600.0,
      'dia_fechamento': 26,
      'dia_vencimento': 6,
      'bandeira': 'MASTERCARD',
      'cor': '#00D4AA',
      'categoria': 'iniciantes',
    },
  ];

  /// Cartões por categoria
  static List<Map<String, dynamic>> porCategoria(String categoria) {
    return todos.where((cartao) => cartao['categoria'] == categoria).toList();
  }

  /// Cartões por bandeira
  static List<Map<String, dynamic>> porBandeira(String bandeira) {
    return todos.where((cartao) => cartao['bandeira'] == bandeira).toList();
  }

  /// Cartões populares (top 5)
  static List<Map<String, dynamic>> get populares => porCategoria('populares').take(5).toList();

  /// Cartões para iniciantes (limite baixo)
  static List<Map<String, dynamic>> get iniciantes => porCategoria('iniciantes');

  /// Cartões premium (limite alto)
  static List<Map<String, dynamic>> get premium => porCategoria('premium');

  /// Cartões co-branded (varejo)
  static List<Map<String, dynamic>> get coBranded => porCategoria('co-branded');

  /// Cartões de viagens
  static List<Map<String, dynamic>> get viagens => porCategoria('viagens');

  /// Cartões internacionais
  static List<Map<String, dynamic>> get internacionais => porCategoria('internacionais');

  /// Buscar cartão por nome
  static Map<String, dynamic>? buscarPorNome(String nome) {
    try {
      return todos.firstWhere(
        (cartao) => cartao['nome'].toString().toLowerCase().contains(nome.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Obter bandeiras disponíveis
  static List<String> get bandeirasDisponiveis {
    return todos.map((cartao) => cartao['bandeira'] as String).toSet().toList();
  }

  /// Obter cores disponíveis
  static List<String> get coresDisponiveis {
    return todos.map((cartao) => cartao['cor'] as String).toSet().toList();
  }

  /// Validar se cartão já existe na lista
  static bool jaExiste(String nome) {
    return todos.any(
      (cartao) => cartao['nome'].toString().toLowerCase() == nome.toLowerCase(),
    );
  }
}