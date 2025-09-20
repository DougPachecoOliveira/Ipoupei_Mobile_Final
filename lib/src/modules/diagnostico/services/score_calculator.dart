// 🧮 Score Calculator - iPoupei Mobile
//
// Calculadora de score financeiro para o diagnóstico
// Baseada no algoritmo do iPoupei Device
//
// Estrutura: Score de 0-100 pontos em 5 dimensões

import 'dart:developer';
import '../models/percepcao_financeira.dart';
import '../models/dividas_model.dart';

/// Resultado do cálculo de score
class ScoreResult {
  final int score;
  final String etapaJornada;
  final String descricao;
  final Map<String, int> scoresPorDimensao;
  final List<String> pontosFortes;
  final List<String> pontosLimite;
  final List<String> proximosPassos;

  const ScoreResult({
    required this.score,
    required this.etapaJornada,
    required this.descricao,
    required this.scoresPorDimensao,
    required this.pontosFortes,
    required this.pontosLimite,
    required this.proximosPassos,
  });

  @override
  String toString() {
    return 'ScoreResult{score: $score, etapa: $etapaJornada}';
  }
}

/// Dados consolidados para cálculo do score
class DiagnosticoData {
  final PercepcaoFinanceira? percepcao;
  final DividasDiagnostico? dividas;
  final double? rendaMensal;
  final List<Map<String, dynamic>> contas;
  final List<Map<String, dynamic>> cartoes;
  final List<Map<String, dynamic>> receitas;
  final List<Map<String, dynamic>> despesasFixas;
  final List<Map<String, dynamic>> despesasVariaveis;
  final List<Map<String, dynamic>> categorias;

  const DiagnosticoData({
    this.percepcao,
    this.dividas,
    this.rendaMensal,
    this.contas = const [],
    this.cartoes = const [],
    this.receitas = const [],
    this.despesasFixas = const [],
    this.despesasVariaveis = const [],
    this.categorias = const [],
  });

  /// Construtor a partir de dados coletados do diagnóstico
  factory DiagnosticoData.fromMap(Map<String, dynamic> dadosColetados) {
    PercepcaoFinanceira? percepcao;
    if (dadosColetados.containsKey('percepcao')) {
      percepcao = PercepcaoFinanceira.fromSupabase(dadosColetados['percepcao']);
    }

    DividasDiagnostico? dividas;
    if (dadosColetados.containsKey('dividas')) {
      dividas = DividasDiagnostico.fromSupabase(dadosColetados['dividas']);
    }

    double? rendaMensal;
    if (dadosColetados.containsKey('receitas') && dadosColetados['receitas']['renda_mensal'] != null) {
      rendaMensal = dadosColetados['receitas']['renda_mensal'].toDouble();
    }

    return DiagnosticoData(
      percepcao: percepcao,
      dividas: dividas,
      rendaMensal: rendaMensal,
      contas: _extrairLista(dadosColetados, 'contas'),
      cartoes: _extrairLista(dadosColetados, 'cartoes'),
      receitas: _extrairLista(dadosColetados, 'receitas'),
      despesasFixas: _extrairLista(dadosColetados, 'despesas-fixas'),
      despesasVariaveis: _extrairLista(dadosColetados, 'despesas-variaveis'),
      categorias: _extrairLista(dadosColetados, 'categorias'),
    );
  }

  static List<Map<String, dynamic>> _extrairLista(Map<String, dynamic> dados, String chave) {
    if (!dados.containsKey(chave)) return [];

    final item = dados[chave];
    if (item is List) return item.cast<Map<String, dynamic>>();
    if (item is Map && item.containsKey('quantidade')) {
      // Se só tem quantidade, criar lista fake para cálculo
      final quantidade = item['quantidade'] as int;
      return List.generate(quantidade, (index) => {'id': index});
    }

    return [];
  }
}

/// Calculadora principal de score
class ScoreCalculator {

  /// Calcular score completo
  ScoreResult calcular(DiagnosticoData dados) {
    try {
      log('🧮 [SCORE_CALCULATOR] Iniciando cálculo do score');

      // Calcular scores por dimensão (0-20 pontos cada)
      final scoreOrganizacao = _calcularOrganizacao(dados);
      final scoreControle = _calcularControle(dados);
      final scoreSaude = _calcularSaudeFinanceira(dados);
      final scorePercepcao = _calcularPercepcao(dados);
      final scoreGeral = _calcularGeral(dados);

      final scoresPorDimensao = {
        'organizacao': scoreOrganizacao,
        'controle': scoreControle,
        'saude': scoreSaude,
        'percepcao': scorePercepcao,
        'geral': scoreGeral,
      };

      // Score total (0-100)
      final scoreTotal = scoreOrganizacao + scoreControle + scoreSaude + scorePercepcao + scoreGeral;

      // Determinar etapa da jornada
      final etapaJornada = _determinarEtapaJornada(scoreTotal);
      final descricao = _getDescricaoScore(scoreTotal);

      // Analisar pontos fortes e fracos
      final pontosFortes = _analisarPontosFortes(scoresPorDimensao);
      final pontosLimite = _analisarPontosLimite(scoresPorDimensao);
      final proximosPassos = _gerarProximosPassos(scoresPorDimensao, dados);

      log('🎯 [SCORE_CALCULATOR] Score calculado: $scoreTotal pontos');

      return ScoreResult(
        score: scoreTotal,
        etapaJornada: etapaJornada,
        descricao: descricao,
        scoresPorDimensao: scoresPorDimensao,
        pontosFortes: pontosFortes,
        pontosLimite: pontosLimite,
        proximosPassos: proximosPassos,
      );

    } catch (e) {
      log('❌ [SCORE_CALCULATOR] Erro no cálculo: $e');

      // Retornar score mínimo em caso de erro
      return const ScoreResult(
        score: 0,
        etapaJornada: 'Iniciante',
        descricao: 'Erro no cálculo do score',
        scoresPorDimensao: {},
        pontosFortes: [],
        pontosLimite: ['Dados insuficientes para análise'],
        proximosPassos: ['Complete o diagnóstico novamente'],
      );
    }
  }

  /// Dimensão 1: Organização (0-20 pontos)
  int _calcularOrganizacao(DiagnosticoData dados) {
    int score = 0;

    // Categorias (0-5 pontos)
    if (dados.categorias.length >= 10) score += 5;
    else if (dados.categorias.length >= 5) score += 3;
    else if (dados.categorias.length >= 1) score += 1;

    // Contas cadastradas (0-5 pontos)
    if (dados.contas.length >= 3) score += 5;
    else if (dados.contas.length >= 2) score += 3;
    else if (dados.contas.length >= 1) score += 2;

    // Cartões cadastrados (0-3 pontos)
    if (dados.cartoes.length >= 2) score += 3;
    else if (dados.cartoes.length >= 1) score += 2;

    // Transações cadastradas (0-7 pontos)
    final totalTransacoes = dados.receitas.length + dados.despesasFixas.length + dados.despesasVariaveis.length;
    if (totalTransacoes >= 10) score += 7;
    else if (totalTransacoes >= 5) score += 5;
    else if (totalTransacoes >= 3) score += 3;
    else if (totalTransacoes >= 1) score += 1;

    return score.clamp(0, 20);
  }

  /// Dimensão 2: Controle (0-20 pontos)
  int _calcularControle(DiagnosticoData dados) {
    int score = 0;

    // Receitas cadastradas (0-8 pontos)
    if (dados.receitas.length >= 3) score += 8;
    else if (dados.receitas.length >= 2) score += 6;
    else if (dados.receitas.length >= 1) score += 4;

    // Despesas fixas cadastradas (0-6 pontos)
    if (dados.despesasFixas.length >= 5) score += 6;
    else if (dados.despesasFixas.length >= 3) score += 4;
    else if (dados.despesasFixas.length >= 1) score += 2;

    // Despesas variáveis cadastradas (0-6 pontos)
    if (dados.despesasVariaveis.length >= 5) score += 6;
    else if (dados.despesasVariaveis.length >= 3) score += 4;
    else if (dados.despesasVariaveis.length >= 1) score += 2;

    return score.clamp(0, 20);
  }

  /// Dimensão 3: Saúde Financeira (0-20 pontos)
  int _calcularSaudeFinanceira(DiagnosticoData dados) {
    int score = 15; // Base otimista

    // Análise de dívidas
    if (dados.dividas != null) {
      score = DividasQuestionario.calcularScore(dados.dividas!, dados.rendaMensal);
    }

    // Bônus por ter renda cadastrada
    if (dados.rendaMensal != null && dados.rendaMensal! > 0) {
      score += 2;
    }

    // Bônus por diversificação de contas
    if (dados.contas.length >= 2) {
      score += 1;
    }

    return score.clamp(0, 20);
  }

  /// Dimensão 4: Percepção (0-20 pontos)
  int _calcularPercepcao(DiagnosticoData dados) {
    if (dados.percepcao == null) return 10; // Score neutro se não preencheu

    // Usar calculadora da própria percepção (0-45 pontos) e normalizar para 0-20
    final scorePercepcao = PercepcaoQuestionario.calcularScore(dados.percepcao!);
    return ((scorePercepcao / 45.0) * 20).round().clamp(0, 20);
  }

  /// Dimensão 5: Geral (0-20 pontos)
  int _calcularGeral(DiagnosticoData dados) {
    int score = 0;

    // Completude do diagnóstico (0-10 pontos)
    int etapasCompletas = 0;
    if (dados.percepcao != null) etapasCompletas++;
    if (dados.contas.isNotEmpty) etapasCompletas++;
    if (dados.receitas.isNotEmpty) etapasCompletas++;
    if (dados.despesasFixas.isNotEmpty) etapasCompletas++;
    if (dados.categorias.isNotEmpty) etapasCompletas++;

    score += (etapasCompletas * 2).clamp(0, 10);

    // Diversificação financeira (0-5 pontos)
    if (dados.contas.length >= 2) score += 2;
    if (dados.cartoes.length >= 1) score += 1;
    if (dados.receitas.length >= 2) score += 2;

    // Planejamento (0-5 pontos)
    if (dados.despesasFixas.isNotEmpty && dados.despesasVariaveis.isNotEmpty) {
      score += 3; // Tem controle de ambos tipos de despesas
    }
    if (dados.categorias.length >= 5) {
      score += 2; // Bem organizado com categorias
    }

    return score.clamp(0, 20);
  }

  /// Determinar etapa da jornada baseada no score
  String _determinarEtapaJornada(int score) {
    if (score >= 85) return 'Expert';
    if (score >= 70) return 'Avançado';
    if (score >= 55) return 'Intermediário';
    if (score >= 35) return 'Iniciante Avançado';
    if (score >= 20) return 'Iniciante';
    return 'Começando';
  }

  /// Obter descrição do score
  String _getDescricaoScore(int score) {
    if (score >= 85) return 'Excelente! Você tem controle total das suas finanças.';
    if (score >= 70) return 'Muito bom! Suas finanças estão bem organizadas.';
    if (score >= 55) return 'Bom! Você está no caminho certo.';
    if (score >= 35) return 'Razoável. Há espaço para melhorias importantes.';
    if (score >= 20) return 'Início da jornada. Vamos organizar suas finanças!';
    return 'Muitas oportunidades de melhoria. Vamos começar!';
  }

  /// Analisar pontos fortes
  List<String> _analisarPontosFortes(Map<String, int> scores) {
    List<String> pontosFortes = [];

    scores.forEach((dimensao, score) {
      if (score >= 15) {
        switch (dimensao) {
          case 'organizacao':
            pontosFortes.add('Excelente organização financeira');
            break;
          case 'controle':
            pontosFortes.add('Bom controle de receitas e despesas');
            break;
          case 'saude':
            pontosFortes.add('Saúde financeira sólida');
            break;
          case 'percepcao':
            pontosFortes.add('Boa consciência financeira');
            break;
          case 'geral':
            pontosFortes.add('Perfil financeiro bem desenvolvido');
            break;
        }
      }
    });

    return pontosFortes;
  }

  /// Analisar pontos que precisam de atenção
  List<String> _analisarPontosLimite(Map<String, int> scores) {
    List<String> pontosLimite = [];

    scores.forEach((dimensao, score) {
      if (score < 10) {
        switch (dimensao) {
          case 'organizacao':
            pontosLimite.add('Organização financeira precisa de atenção');
            break;
          case 'controle':
            pontosLimite.add('Controle de gastos pode melhorar');
            break;
          case 'saude':
            pontosLimite.add('Situação financeira requer cuidado');
            break;
          case 'percepcao':
            pontosLimite.add('Autoconhecimento financeiro em desenvolvimento');
            break;
          case 'geral':
            pontosLimite.add('Perfil financeiro em construção');
            break;
        }
      }
    });

    return pontosLimite;
  }

  /// Gerar próximos passos personalizados
  List<String> _gerarProximosPassos(Map<String, int> scores, DiagnosticoData dados) {
    List<String> passos = [];

    // Sugestões baseadas em pontos fracos
    if (scores['organizacao']! < 10) {
      if (dados.categorias.length < 5) {
        passos.add('📋 Importe mais categorias para organizar seus gastos');
      }
      if (dados.contas.length < 2) {
        passos.add('🏦 Cadastre suas contas bancárias principais');
      }
    }

    if (scores['controle']! < 10) {
      if (dados.receitas.isEmpty) {
        passos.add('💰 Registre suas fontes de renda');
      }
      if (dados.despesasFixas.isEmpty) {
        passos.add('🏠 Cadastre seus gastos fixos mensais');
      }
    }

    if (scores['saude']! < 15) {
      if (dados.dividas?.temDividas == true) {
        passos.add('⚠️ Crie um plano para quitar suas dívidas');
      }
      passos.add('📊 Analise seus gastos para encontrar economia');
    }

    // Passos gerais se não há problemas específicos
    if (passos.isEmpty) {
      passos.add('📈 Continue registrando suas transações diariamente');
      passos.add('🎯 Defina metas financeiras para os próximos meses');
      passos.add('💡 Explore relatórios para insights avançados');
    }

    return passos.take(5).toList(); // Máximo 5 sugestões
  }

  /// Calcular resultado completo do diagnóstico
  Future<Map<String, dynamic>> calcularResultadoCompleto({
    required PercepcaoFinanceira percepcao,
    required List<DividaItem> dividas,
    required int contasCount,
    required int cartoesCount,
    required int categoriasCount,
  }) async {
    // Criar dados consolidados
    final dividasDiagnostico = DividasDiagnostico(
      temDividas: dividas.isNotEmpty,
      dividas: dividas,
    );

    final dados = DiagnosticoData(
      percepcao: percepcao,
      dividas: dividasDiagnostico,
      contas: List.generate(contasCount, (i) => {}),
      cartoes: List.generate(cartoesCount, (i) => {}),
      categorias: List.generate(categoriasCount, (i) => {}),
      receitas: [],
      despesasFixas: [],
      despesasVariaveis: [],
    );

    // Calcular score
    final scoreResult = calcular(dados);

    // Retornar no formato esperado
    return {
      'score_total': scoreResult.score,
      'scores': scoreResult.scoresPorDimensao,
      'interpretacao': scoreResult.descricao,
      'etapa_jornada': scoreResult.etapaJornada,
      'pontos_fortes': scoreResult.pontosFortes,
      'pontos_limite': scoreResult.pontosLimite,
      'proximos_passos': scoreResult.proximosPassos,
    };
  }
}