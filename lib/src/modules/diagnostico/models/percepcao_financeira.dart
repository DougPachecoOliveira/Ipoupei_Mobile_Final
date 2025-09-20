// 🧠 Percepção Financeira Model - iPoupei Mobile
//
// Modelo para questionário de percepção e relação com dinheiro
// Baseado no questionário do iPoupei Device
//
// Campos: sentimento, controle, gastos, disciplina, relação

/// Modelo para dados de percepção financeira
class PercepcaoFinanceira {
  final String? sentimentoFinanceiro;
  final String? percepcaoControle;
  final String? percepcaoGastos;
  final String? disciplinaFinanceira;
  final String? relacaoDinheiro;

  // Campos de renda e trabalho
  final double? rendaMensal;
  final int? horasTrabalhadasMes;
  final String? tipoRenda;

  const PercepcaoFinanceira({
    this.sentimentoFinanceiro,
    this.percepcaoControle,
    this.percepcaoGastos,
    this.disciplinaFinanceira,
    this.relacaoDinheiro,
    this.rendaMensal,
    this.horasTrabalhadasMes,
    this.tipoRenda,
  });

  /// Construtor para estado vazio
  factory PercepcaoFinanceira.vazio() {
    return const PercepcaoFinanceira();
  }

  /// Construtor a partir de dados do Supabase/LocalDatabase
  factory PercepcaoFinanceira.fromSupabase(Map<String, dynamic> dados) {
    return PercepcaoFinanceira(
      sentimentoFinanceiro: dados['sentimento_financeiro'],
      percepcaoControle: dados['percepcao_controle'],
      percepcaoGastos: dados['percepcao_gastos'],
      disciplinaFinanceira: dados['disciplina_financeira'],
      relacaoDinheiro: dados['relacao_dinheiro'],
      rendaMensal: dados['renda_mensal']?.toDouble(),
      horasTrabalhadasMes: dados['media_horas_trabalhadas_mes']?.toInt(),
      tipoRenda: dados['tipo_renda'],
    );
  }

  /// Converter para Map para salvar no banco
  Map<String, dynamic> toSupabase() {
    return {
      'sentimento_financeiro': sentimentoFinanceiro,
      'percepcao_controle': percepcaoControle,
      'percepcao_gastos': percepcaoGastos,
      'disciplina_financeira': disciplinaFinanceira,
      'relacao_dinheiro': relacaoDinheiro,
      'renda_mensal': rendaMensal,
      'media_horas_trabalhadas_mes': horasTrabalhadasMes,
      'tipo_renda': tipoRenda,
    };
  }

  /// Verificar se campos obrigatórios estão completos
  bool get isObrigatoriosCompletos {
    return sentimentoFinanceiro != null &&
           sentimentoFinanceiro!.isNotEmpty &&
           percepcaoControle != null &&
           percepcaoControle!.isNotEmpty &&
           percepcaoGastos != null &&
           percepcaoGastos!.isNotEmpty &&
           disciplinaFinanceira != null &&
           disciplinaFinanceira!.isNotEmpty &&
           rendaMensal != null &&
           rendaMensal! > 0 &&
           horasTrabalhadasMes != null &&
           horasTrabalhadasMes! > 0 &&
           tipoRenda != null &&
           tipoRenda!.isNotEmpty;
  }

  /// Criar cópia com alterações
  PercepcaoFinanceira copyWith({
    String? sentimentoFinanceiro,
    String? percepcaoControle,
    String? percepcaoGastos,
    String? disciplinaFinanceira,
    String? relacaoDinheiro,
    double? rendaMensal,
    int? horasTrabalhadasMes,
    String? tipoRenda,
  }) {
    return PercepcaoFinanceira(
      sentimentoFinanceiro: sentimentoFinanceiro ?? this.sentimentoFinanceiro,
      percepcaoControle: percepcaoControle ?? this.percepcaoControle,
      percepcaoGastos: percepcaoGastos ?? this.percepcaoGastos,
      disciplinaFinanceira: disciplinaFinanceira ?? this.disciplinaFinanceira,
      relacaoDinheiro: relacaoDinheiro ?? this.relacaoDinheiro,
      rendaMensal: rendaMensal ?? this.rendaMensal,
      horasTrabalhadasMes: horasTrabalhadasMes ?? this.horasTrabalhadasMes,
      tipoRenda: tipoRenda ?? this.tipoRenda,
    );
  }

  /// Calcular valor da hora trabalhada
  double? get valorHoraTrabalhada {
    if (rendaMensal != null && horasTrabalhadasMes != null &&
        rendaMensal! > 0 && horasTrabalhadasMes! > 0) {
      return rendaMensal! / horasTrabalhadasMes!;
    }
    return null;
  }

  @override
  String toString() {
    return 'PercepcaoFinanceira{sentimento: $sentimentoFinanceiro, controle: $percepcaoControle, gastos: $percepcaoGastos, disciplina: $disciplinaFinanceira, relacao: $relacaoDinheiro, renda: $rendaMensal, horas: $horasTrabalhadasMes, tipo: $tipoRenda}';
  }
}

/// Opções do questionário de percepção financeira
class PercepcaoQuestionario {
  /// Pergunta 1: Como você se sente em relação à sua situação financeira atual?
  static const Map<String, String> sentimentoFinanceiro = {
    'muito_satisfeito': 'Muito satisfeito - Estou no controle total',
    'satisfeito': 'Satisfeito - As coisas estão indo bem',
    'neutro': 'Neutro - Nem bem, nem mal',
    'preocupado': 'Preocupado - Preciso melhorar algumas coisas',
    'muito_preocupado': 'Muito preocupado - Estou em dificuldades',
  };

  /// Pergunta 2: Como você avalia seu controle sobre seus gastos?
  static const Map<String, String> percepcaoControle = {
    'total_controle': 'Tenho controle total - Sei exatamente onde gasto cada centavo',
    'bom_controle': 'Tenho bom controle - Acompanho a maioria dos gastos',
    'controle_medio': 'Controle médio - Às vezes perco a noção dos gastos',
    'pouco_controle': 'Pouco controle - Frequentemente gasto mais do que deveria',
    'sem_controle': 'Sem controle - Não faço ideia de onde vai meu dinheiro',
  };

  /// Pergunta 3: Como você percebe seus gastos mensais?
  static const Map<String, String> percepcaoGastos = {
    'muito_baixos': 'Muito baixos - Gasto bem menos do que ganho',
    'baixos': 'Baixos - Consigo economizar uma boa quantia',
    'equilibrados': 'Equilibrados - Gasto quase tudo que ganho',
    'altos': 'Altos - Às vezes gasto mais do que ganho',
    'muito_altos': 'Muito altos - Sempre gasto mais do que ganho',
  };

  /// Pergunta 4: Como você avalia sua disciplina financeira?
  static const Map<String, String> disciplinaFinanceira = {
    'muito_disciplinado': 'Muito disciplinado - Sempre sigo meu planejamento',
    'disciplinado': 'Disciplinado - Na maioria das vezes me controlo',
    'meio_disciplinado': 'Meio disciplinado - Às vezes me deixo levar por impulsos',
    'pouco_disciplinado': 'Pouco disciplinado - Frequentemente compro por impulso',
    'nada_disciplinado': 'Nada disciplinado - Não consigo me controlar',
  };

  /// Pergunta 5: Como é sua relação emocional com dinheiro? (opcional)
  static const Map<String, String> relacaoDinheiro = {
    'tranquila': 'Tranquila - Dinheiro é apenas uma ferramenta',
    'cautelosa': 'Cautelosa - Prefiro não arriscar e economizar',
    'ansiosa': 'Ansiosa - Fico preocupado(a) com questões financeiras',
    'impulsiva': 'Impulsiva - Tendo a gastar quando estou emocionado(a)',
    'evitativa': 'Evitativa - Prefiro não pensar muito sobre dinheiro',
  };

  /// Pergunta 6: Como você caracteriza sua renda? (obrigatória)
  static const Map<String, String> tipoRenda = {
    'fixa': '💼 Salário Fixo - CLT, funcionário público',
    'variavel': '📈 Renda Variável - Comissões, freelancer',
    'mista': '⚖️ Mista - Fixo + variável',
    'autonomo': '🏪 Autônomo - Negócio próprio',
  };

  /// Obter todas as perguntas
  static List<Map<String, dynamic>> get todasPerguntas {
    return [
      {
        'id': 'sentimento_financeiro',
        'pergunta': 'Como você se sente em relação à sua situação financeira atual?',
        'opcoes': sentimentoFinanceiro,
        'obrigatoria': true,
      },
      {
        'id': 'percepcao_controle',
        'pergunta': 'Como você avalia seu controle sobre seus gastos?',
        'opcoes': percepcaoControle,
        'obrigatoria': true,
      },
      {
        'id': 'percepcao_gastos',
        'pergunta': 'Como você percebe seus gastos mensais?',
        'opcoes': percepcaoGastos,
        'obrigatoria': true,
      },
      {
        'id': 'disciplina_financeira',
        'pergunta': 'Como você avalia sua disciplina financeira?',
        'opcoes': disciplinaFinanceira,
        'obrigatoria': true,
      },
      {
        'id': 'relacao_dinheiro',
        'pergunta': 'Como é sua relação emocional com dinheiro?',
        'opcoes': relacaoDinheiro,
        'obrigatoria': false,
      },
      {
        'id': 'tipo_renda',
        'pergunta': 'Como você caracteriza sua renda?',
        'opcoes': tipoRenda,
        'obrigatoria': true,
      },
    ];
  }

  /// Obter valor de score para uma resposta
  static int getScoreResposta(String pergunta, String resposta) {
    switch (pergunta) {
      case 'sentimento_financeiro':
        switch (resposta) {
          case 'muito_satisfeito': return 10;
          case 'satisfeito': return 8;
          case 'neutro': return 5;
          case 'preocupado': return 3;
          case 'muito_preocupado': return 0;
          default: return 0;
        }

      case 'percepcao_controle':
        switch (resposta) {
          case 'total_controle': return 10;
          case 'bom_controle': return 8;
          case 'controle_medio': return 5;
          case 'pouco_controle': return 3;
          case 'sem_controle': return 0;
          default: return 0;
        }

      case 'percepcao_gastos':
        switch (resposta) {
          case 'muito_baixos': return 10;
          case 'baixos': return 8;
          case 'equilibrados': return 6;
          case 'altos': return 3;
          case 'muito_altos': return 0;
          default: return 0;
        }

      case 'disciplina_financeira':
        switch (resposta) {
          case 'muito_disciplinado': return 10;
          case 'disciplinado': return 8;
          case 'meio_disciplinado': return 5;
          case 'pouco_disciplinado': return 3;
          case 'nada_disciplinado': return 0;
          default: return 0;
        }

      case 'relacao_dinheiro':
        switch (resposta) {
          case 'tranquila': return 5;
          case 'cautelosa': return 4;
          case 'ansiosa': return 2;
          case 'impulsiva': return 1;
          case 'evitativa': return 0;
          default: return 0;
        }

      default:
        return 0;
    }
  }

  /// Calcular score total da percepção (0-45 pontos)
  static int calcularScore(PercepcaoFinanceira percepcao) {
    int score = 0;

    if (percepcao.sentimentoFinanceiro != null) {
      score += getScoreResposta('sentimento_financeiro', percepcao.sentimentoFinanceiro!);
    }

    if (percepcao.percepcaoControle != null) {
      score += getScoreResposta('percepcao_controle', percepcao.percepcaoControle!);
    }

    if (percepcao.percepcaoGastos != null) {
      score += getScoreResposta('percepcao_gastos', percepcao.percepcaoGastos!);
    }

    if (percepcao.disciplinaFinanceira != null) {
      score += getScoreResposta('disciplina_financeira', percepcao.disciplinaFinanceira!);
    }

    if (percepcao.relacaoDinheiro != null) {
      score += getScoreResposta('relacao_dinheiro', percepcao.relacaoDinheiro!);
    }

    return score;
  }
}