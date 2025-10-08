// 💳 Dívidas Model - iPoupei Mobile
//
// Modelo para questionário de dívidas do diagnóstico
// Baseado no questionário do iPoupei Device
//
// Estrutura: Levantamento de dívidas atuais

/// Modelo para uma dívida individual
class DividaIndividual {
  final String? id;
  final String descricao;
  final String? instituicao;
  final double valorTotal;
  final double? valorParcela;
  final int? parcelasRestantes;
  final int? parcelasTotais;
  final String situacao; // 'em_dia', 'atrasada', 'quitada'
  final DateTime? dataVencimento;

  const DividaIndividual({
    this.id,
    required this.descricao,
    this.instituicao,
    required this.valorTotal,
    this.valorParcela,
    this.parcelasRestantes,
    this.parcelasTotais,
    this.situacao = 'em_dia',
    this.dataVencimento,
  });

  /// Construtor a partir de Map
  factory DividaIndividual.fromMap(Map<String, dynamic> map) {
    return DividaIndividual(
      id: map['id'],
      descricao: map['descricao'] ?? '',
      instituicao: map['instituicao'],
      valorTotal: (map['valor_total'] ?? 0.0).toDouble(),
      valorParcela: map['valor_parcela']?.toDouble(),
      parcelasRestantes: map['parcelas_restantes'],
      parcelasTotais: map['parcelas_totais'],
      situacao: map['situacao'] ?? 'em_dia',
      dataVencimento: map['data_vencimento'] != null
          ? DateTime.tryParse(map['data_vencimento'])
          : null,
    );
  }

  /// Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'instituicao': instituicao,
      'valor_total': valorTotal,
      'valor_parcela': valorParcela,
      'parcelas_restantes': parcelasRestantes,
      'parcelas_totais': parcelasTotais,
      'situacao': situacao,
      'data_vencimento': dataVencimento?.toIso8601String(),
    };
  }

  /// Criar cópia com alterações
  DividaIndividual copyWith({
    String? id,
    String? descricao,
    String? instituicao,
    double? valorTotal,
    double? valorParcela,
    int? parcelasRestantes,
    int? parcelasTotais,
    String? situacao,
    DateTime? dataVencimento,
  }) {
    return DividaIndividual(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      instituicao: instituicao ?? this.instituicao,
      valorTotal: valorTotal ?? this.valorTotal,
      valorParcela: valorParcela ?? this.valorParcela,
      parcelasRestantes: parcelasRestantes ?? this.parcelasRestantes,
      parcelasTotais: parcelasTotais ?? this.parcelasTotais,
      situacao: situacao ?? this.situacao,
      dataVencimento: dataVencimento ?? this.dataVencimento,
    );
  }

  /// Getter para propriedades comuns (compatibilidade)
  double get valor => valorTotal;
}

/// Alias para compatibilidade
typedef DividaItem = DividaIndividual;

/// Modelo principal para dados de dívidas do diagnóstico
class DividasDiagnostico {
  final bool temDividas;
  final List<DividaIndividual> dividas;
  final String? motivoPrincipal;
  final String? estrategiaPagamento;
  final bool conseguePagar;

  const DividasDiagnostico({
    this.temDividas = false,
    this.dividas = const [],
    this.motivoPrincipal,
    this.estrategiaPagamento,
    this.conseguePagar = true,
  });

  /// Construtor para estado vazio
  factory DividasDiagnostico.vazio() {
    return const DividasDiagnostico();
  }

  /// Construtor a partir de dados do Supabase/LocalDatabase
  factory DividasDiagnostico.fromSupabase(Map<String, dynamic> dados) {
    final dividasData = dados['dividas_lista'] as List<dynamic>? ?? [];
    final dividas = dividasData
        .map((d) => DividaIndividual.fromMap(d as Map<String, dynamic>))
        .toList();

    return DividasDiagnostico(
      temDividas: dados['tem_dividas'] ?? false,
      dividas: dividas,
      motivoPrincipal: dados['motivo_principal'],
      estrategiaPagamento: dados['estrategia_pagamento'],
      conseguePagar: dados['consegue_pagar'] ?? true,
    );
  }

  /// Converter para Map para salvar no banco
  Map<String, dynamic> toSupabase() {
    return {
      'tem_dividas': temDividas,
      'dividas_lista': dividas.map((d) => d.toMap()).toList(),
      'motivo_principal': motivoPrincipal,
      'estrategia_pagamento': estrategiaPagamento,
      'consegue_pagar': conseguePagar,
      'total_dividas': totalDividas,
      'dividas_em_atraso': dividasEmAtraso,
    };
  }

  /// Calcular total das dívidas
  double get totalDividas {
    return dividas.fold(0.0, (total, divida) => total + divida.valorTotal);
  }

  /// Contar dívidas em atraso
  int get dividasEmAtraso {
    return dividas.where((d) => d.situacao == 'atrasada').length;
  }

  /// Calcular total de parcelas mensais
  double get totalParcelasMensais {
    return dividas.fold(0.0, (total, divida) {
      return total + (divida.valorParcela ?? 0.0);
    });
  }

  /// Verificar se tem dívidas críticas (> R$ 10.000 ou em atraso)
  bool get temDividasCriticas {
    return dividas.any((d) =>
      d.valorTotal > 10000 ||
      d.situacao == 'atrasada'
    );
  }

  /// Getter para compatibilidade
  List<DividaIndividual> get itens => dividas;
  double get valorTotal => totalDividas;

  /// Criar cópia com alterações
  DividasDiagnostico copyWith({
    bool? temDividas,
    List<DividaIndividual>? dividas,
    String? motivoPrincipal,
    String? estrategiaPagamento,
    bool? conseguePagar,
  }) {
    return DividasDiagnostico(
      temDividas: temDividas ?? this.temDividas,
      dividas: dividas ?? this.dividas,
      motivoPrincipal: motivoPrincipal ?? this.motivoPrincipal,
      estrategiaPagamento: estrategiaPagamento ?? this.estrategiaPagamento,
      conseguePagar: conseguePagar ?? this.conseguePagar,
    );
  }

  /// Adicionar nova dívida
  DividasDiagnostico adicionarDivida(DividaIndividual novaDivida) {
    final novaLista = List<DividaIndividual>.from(dividas);
    novaLista.add(novaDivida);

    return copyWith(
      temDividas: true,
      dividas: novaLista,
    );
  }

  /// Remover dívida
  DividasDiagnostico removerDivida(int index) {
    if (index < 0 || index >= dividas.length) return this;

    final novaLista = List<DividaIndividual>.from(dividas);
    novaLista.removeAt(index);

    return copyWith(
      dividas: novaLista,
      temDividas: novaLista.isNotEmpty,
    );
  }

  @override
  String toString() {
    return 'DividasDiagnostico{temDividas: $temDividas, totalDividas: R\$ ${totalDividas.toStringAsFixed(2)}, quantidade: ${dividas.length}}';
  }
}

/// Opções do questionário de dívidas
class DividasQuestionario {
  /// Motivos principais das dívidas
  static const Map<String, String> motivosPrincipais = {
    'emergencia_medica': 'Emergência médica ou de saúde',
    'perda_emprego': 'Perda de emprego ou redução de renda',
    'investimento_imovel': 'Compra de imóvel ou investimento',
    'educacao': 'Educação ou cursos profissionalizantes',
    'consumo_excessivo': 'Consumo excessivo ou falta de controle',
    'ajuda_familia': 'Ajuda à família ou terceiros',
    'oportunidade_negocio': 'Oportunidade de negócio',
    'outros': 'Outros motivos',
  };

  /// Estratégias de pagamento
  static const Map<String, String> estrategiasPagamento = {
    'parcela_minima': 'Pago sempre a parcela mínima',
    'quando_possivel': 'Pago quando é possível',
    'renegociacao': 'Estou renegociando as dívidas',
    'quitacao_vista': 'Pretendo quitar à vista',
    'consolidacao': 'Vou consolidar todas em uma',
    'nao_consegue': 'Não consigo pagar no momento',
    'ignorando': 'Estou ignorando por enquanto',
  };

  /// Tipos de dívida mais comuns
  static const List<String> tiposDividaComuns = [
    'Cartão de Crédito',
    'Financiamento Veículo',
    'Financiamento Imobiliário',
    'Empréstimo Pessoal',
    'Crediário/Carnê',
    'Conta de Luz/Água',
    'FIES/Financiamento Estudantil',
    'Empréstimo Consignado',
    'Cheque Especial',
    'IPVA/IPTU',
    'Outros',
  ];

  /// Calcular score de dívidas (0-20 pontos)
  static int calcularScore(DividasDiagnostico dividas, double? rendaMensal) {
    if (!dividas.temDividas) return 20; // Sem dívidas = score máximo

    int score = 15; // Base para quem tem dívidas

    // Penalizar por valor total das dívidas em relação à renda
    if (rendaMensal != null && rendaMensal > 0) {
      final proporcao = dividas.totalDividas / (rendaMensal * 12); // Proporção anual

      if (proporcao > 3.0) score -= 10; // Mais de 3x a renda anual
      else if (proporcao > 2.0) score -= 7;
      else if (proporcao > 1.0) score -= 5;
      else if (proporcao > 0.5) score -= 3;
      else if (proporcao > 0.2) score -= 1;
    }

    // Penalizar por dívidas em atraso
    if (dividas.dividasEmAtraso > 0) {
      score -= dividas.dividasEmAtraso * 2; // -2 pontos por dívida em atraso
    }

    // Bonificar por estratégia de pagamento
    switch (dividas.estrategiaPagamento) {
      case 'quitacao_vista':
      case 'renegociacao':
        score += 2;
        break;
      case 'consolidacao':
      case 'parcela_minima':
        score += 1;
        break;
      case 'nao_consegue':
      case 'ignorando':
        score -= 3;
        break;
    }

    return score.clamp(0, 20);
  }
}