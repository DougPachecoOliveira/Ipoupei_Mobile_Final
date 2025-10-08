// lib/src/modules/diagnostico/models/diagnostico_etapa.dart

import 'package:flutter/material.dart';

/// Tipos de etapas do diagnóstico financeiro
enum TipoDiagnosticoEtapa {
  intro,           // Introdução e boas-vindas
  cadastro,        // Etapas que chamam modais reais (contas, cartões, etc.)
  questionario,    // Questionários específicos (percepção, dívidas)
  processamento,   // Análise e cálculos
  resultado,       // Exibição do diagnóstico final
}

/// Configuração de vídeo YouTube para cada etapa
class VideoConfig {
  final String id;
  final String titulo;
  final String? subtitle;
  final String embedUrl;
  final Duration? duracaoEstimada;
  final bool autoPlay;

  const VideoConfig({
    required this.id,
    required this.titulo,
    this.subtitle,
    required this.embedUrl,
    this.duracaoEstimada,
    this.autoPlay = false,
  });

  /// URL completa para embed do YouTube
  String get urlEmbed => 'https://www.youtube.com/embed/$id';

  /// URL para thumbnail do vídeo
  String get urlThumbnail => 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
}

/// Modelo que define cada etapa do diagnóstico
class DiagnosticoEtapa {
  final String id;
  final String titulo;
  final String? subtitulo;
  final String? descricao;
  final IconData icone;
  final Color cor;
  final TipoDiagnosticoEtapa tipo;

  // Para etapas de cadastro - qual modal/página chamar
  final String? modal;

  // Configurações de validação
  final bool obrigatorio;
  final int? minimoItens;
  final String? mensagemValidacao;

  // Vídeo explicativo da etapa
  final VideoConfig? video;

  // Configurações visuais
  final bool mostrarProgresso;
  final bool permitirVoltar;
  final bool permitirPular;

  const DiagnosticoEtapa({
    required this.id,
    required this.titulo,
    this.subtitulo,
    this.descricao,
    required this.icone,
    required this.cor,
    required this.tipo,
    this.modal,
    this.obrigatorio = true,
    this.minimoItens,
    this.mensagemValidacao,
    this.video,
    this.mostrarProgresso = true,
    this.permitirVoltar = true,
    this.permitirPular = false,
  });

  /// Verifica se a etapa está completa baseada nos dados
  bool isCompleta(Map<String, dynamic> dadosColetados) {
    switch (tipo) {
      case TipoDiagnosticoEtapa.intro:
        return true; // Introdução sempre completa após visualizar

      case TipoDiagnosticoEtapa.cadastro:
        return _validarEtapaCadastro(dadosColetados);

      case TipoDiagnosticoEtapa.questionario:
        return _validarEtapaQuestionario(dadosColetados);

      case TipoDiagnosticoEtapa.processamento:
      case TipoDiagnosticoEtapa.resultado:
        return true;
    }
  }

  /// Validação específica para etapas de cadastro
  bool _validarEtapaCadastro(Map<String, dynamic> dados) {
    dynamic dadoEtapa;

    switch (id) {
      case 'categorias':
        dadoEtapa = dados['categorias'];
        // Nova implementação: verificar campo 'configurado'
        if (dadoEtapa is Map<String, dynamic>) {
          return dadoEtapa['configurado'] == true;
        }
        break;
      case 'contas':
        dadoEtapa = dados['contas'];
        // Nova implementação: verificar campo 'configurado'
        if (dadoEtapa is Map<String, dynamic>) {
          return dadoEtapa['configurado'] == true;
        }
        break;
      case 'cartoes':
        dadoEtapa = dados['cartoes'];
        // Nova implementação: verificar campo 'configurado' (cartões são opcionais)
        if (dadoEtapa is Map<String, dynamic>) {
          // Cartões são opcionais, então sempre retorna true se existem dados
          return dadoEtapa.isNotEmpty;
        }
        break;
      case 'receitas':
        dadoEtapa = dados['receitas'];
        // Nova implementação: verificar campo 'configurado'
        if (dadoEtapa is Map<String, dynamic>) {
          return dadoEtapa['configurado'] == true;
        }
        break;
      case 'despesas-fixas':
        dadoEtapa = dados['despesas-fixas'];
        // Nova implementação: verificar campo 'configurado'
        if (dadoEtapa is Map<String, dynamic>) {
          return dadoEtapa['configurado'] == true;
        }
        break;
      case 'despesas-variaveis':
        dadoEtapa = dados['despesas-variaveis'];
        // Nova implementação: verificar campo 'configurado'
        if (dadoEtapa is Map<String, dynamic>) {
          return dadoEtapa['configurado'] == true;
        }
        break;
    }

    if (!obrigatorio) return true;

    // Fallback para lista (implementação legado)
    if (dadoEtapa is List<dynamic>) {
      final lista = dadoEtapa;
      final quantidade = lista.length;
      final minimo = minimoItens ?? 1;
      return quantidade >= minimo;
    }

    // Se não for lista nem nulo, considera válido (pode ser Map)
    return dadoEtapa != null;
  }

  /// Validação específica para etapas de questionário
  bool _validarEtapaQuestionario(Map<String, dynamic> dados) {
    switch (id) {
      case 'percepcao':
        final percepcao = dados['percepcao'] as Map<String, dynamic>?;
        return _validarPercepcaoCompleta(percepcao);
      case 'dividas':
        // Dívidas são opcionais
        return true;
      default:
        return true;
    }
  }

  /// Valida se todos os campos obrigatórios da percepção foram preenchidos
  bool _validarPercepcaoCompleta(Map<String, dynamic>? percepcao) {
    if (percepcao == null) return false;

    // Campos obrigatórios do questionário de percepção
    const camposObrigatorios = [
      'sentimento_financeiro',
      'percepcao_controle',
      'percepcao_gastos',
      'disciplina_financeira',
      'tipo_renda',
      // relacao_dinheiro é opcional
    ];

    // Validar campos de texto
    for (final campo in camposObrigatorios) {
      final valor = percepcao[campo];
      if (valor == null || (valor is String && valor.trim().isEmpty)) {
        return false;
      }
    }

    // Validar campos numéricos obrigatórios
    final rendaMensal = percepcao['renda_mensal'];
    if (rendaMensal == null || (rendaMensal is num && rendaMensal <= 0)) {
      return false;
    }

    final horasTrabalhadasMes = percepcao['media_horas_trabalhadas_mes'];
    if (horasTrabalhadasMes == null || (horasTrabalhadasMes is num && horasTrabalhadasMes <= 0)) {
      return false;
    }

    return true;
  }

  /// Mensagem de erro específica para a etapa
  String? getMensagemErro(Map<String, dynamic> dadosColetados) {
    if (isCompleta(dadosColetados)) return null;

    if (mensagemValidacao != null) return mensagemValidacao;

    switch (tipo) {
      case TipoDiagnosticoEtapa.cadastro:
        return _getMensagemErroCadastro();
      case TipoDiagnosticoEtapa.questionario:
        return _getMensagemErroQuestionario();
      default:
        return 'Esta etapa precisa ser concluída';
    }
  }

  String _getMensagemErroCadastro() {
    final minimo = minimoItens ?? 1;

    switch (id) {
      case 'categorias':
        return 'Selecione pelo menos $minimo categoria${minimo > 1 ? 's' : ''}';
      case 'contas':
        return 'Cadastre pelo menos $minimo conta bancária';
      case 'cartoes':
        return 'Importe pelo menos $minimo cartão de crédito';
      case 'receitas':
        return 'Cadastre pelo menos $minimo fonte de renda';
      case 'despesas-fixas':
        return 'Cadastre pelo menos $minimo despesa fixa';
      case 'despesas-variaveis':
        return 'Cadastre pelo menos $minimo despesa variável';
      default:
        return 'Complete o cadastro desta etapa';
    }
  }

  String _getMensagemErroQuestionario() {
    switch (id) {
      case 'percepcao':
        return 'Responda todas as perguntas sobre sua relação com dinheiro';
      default:
        return 'Complete o questionário desta etapa';
    }
  }

  @override
  String toString() => 'DiagnosticoEtapa($id: $titulo)';
}

/// Lista completa das etapas do diagnóstico financeiro
/// Seguindo a estratégia: Categorias → Contas → Cartões → Receitas → Despesas → Questionário → Resultado
class DiagnosticoEtapas {
  static const List<DiagnosticoEtapa> fluxoCompleto = [
    // 🎯 INTRODUÇÃO
    DiagnosticoEtapa(
      id: 'intro',
      titulo: '🎯 Bem-vindo ao Diagnóstico',
      subtitulo: 'Descubra sua situação financeira atual',
      descricao: 'Em poucos passos, vamos mapear sua vida financeira e criar seu plano personalizado',
      icone: Icons.rocket_launch,
      cor: Color(0xFF667eea),
      tipo: TipoDiagnosticoEtapa.intro,
      obrigatorio: false,
      permitirPular: true,
      video: VideoConfig(
        id: 'GBKcmAFiUf8',
        titulo: '🎯 Introdução ao Diagnóstico Financeiro',
        embedUrl: 'https://www.youtube.com/embed/GBKcmAFiUf8',
        duracaoEstimada: Duration(minutes: 3),
      ),
    ),

    // 💭 STEP 0.5: PERCEPÇÃO FINANCEIRA
    DiagnosticoEtapa(
      id: 'percepcao',
      titulo: '💭 Sua Percepção Financeira',
      subtitulo: 'Como você se relaciona com o dinheiro?',
      descricao: 'Responda algumas perguntas sobre sua relação com dinheiro e informe sua renda',
      icone: Icons.psychology,
      cor: Color(0xFF8b5cf6),
      tipo: TipoDiagnosticoEtapa.questionario,
      obrigatorio: true,
      mensagemValidacao: 'Responda todas as perguntas sobre sua percepção financeira',
    ),

    // 📂 STEP 1: CATEGORIAS
    DiagnosticoEtapa(
      id: 'categorias',
      titulo: '📂 Organize suas Categorias',
      subtitulo: 'Defina como classificar seus gastos',
      descricao: 'Vamos começar organizando as categorias que você usará para classificar receitas e despesas',
      icone: Icons.category,
      cor: Color(0xFF10b981),
      tipo: TipoDiagnosticoEtapa.cadastro,
      modal: 'CategoriasPage',
      obrigatorio: true,
      minimoItens: 3,
      mensagemValidacao: 'Selecione pelo menos 3 categorias para organizar seus gastos',
      video: VideoConfig(
        id: 'AouQXjW93Bg',
        titulo: '📂 Organizando suas Categorias',
        embedUrl: 'https://www.youtube.com/embed/AouQXjW93Bg',
      ),
    ),

    // 🏦 STEP 2: CONTAS
    DiagnosticoEtapa(
      id: 'contas',
      titulo: '🏦 Suas Contas Bancárias',
      subtitulo: 'Registre onde você guarda seu dinheiro',
      descricao: 'Cadastre suas contas correntes, poupanças e outras contas onde você movimenta dinheiro',
      icone: Icons.account_balance,
      cor: Color(0xFF3b82f6),
      tipo: TipoDiagnosticoEtapa.cadastro,
      modal: 'ContasModal',
      obrigatorio: true,
      minimoItens: 1,
      mensagemValidacao: 'Cadastre pelo menos uma conta bancária',
      video: VideoConfig(
        id: '5I-U3RN9-3Q',
        titulo: '🏦 Cadastrando suas Contas',
        embedUrl: 'https://www.youtube.com/embed/5I-U3RN9-3Q',
      ),
    ),

    // 💳 STEP 3: CARTÕES (OBRIGATÓRIO)
    DiagnosticoEtapa(
      id: 'cartoes',
      titulo: '💳 Cartões de Crédito',
      subtitulo: 'Import ou cadastre seus cartões',
      descricao: 'Adicione seus cartões de crédito para ter um controle completo dos seus gastos',
      icone: Icons.credit_card,
      cor: Color(0xFF8b5cf6),
      tipo: TipoDiagnosticoEtapa.cadastro,
      modal: 'CartoesModal',
      obrigatorio: true,
      minimoItens: 1,
      permitirPular: false,
      mensagemValidacao: 'Importe pelo menos 1 cartão para continuar',
      video: VideoConfig(
        id: 'AGuET6z-SSA',
        titulo: '💳 Gerenciando Cartões de Crédito',
        embedUrl: 'https://www.youtube.com/embed/AGuET6z-SSA',
      ),
    ),

    // 📈 STEP 4: RECEITAS
    DiagnosticoEtapa(
      id: 'receitas',
      titulo: '📈 Suas Fontes de Renda',
      subtitulo: 'Cadastre de onde vem seu dinheiro',
      descricao: 'Registre seu salário, freelances, aluguéis e outras fontes de receita',
      icone: Icons.trending_up,
      cor: Color(0xFF10b981),
      tipo: TipoDiagnosticoEtapa.cadastro,
      modal: 'ReceitasModal',
      obrigatorio: true,
      minimoItens: 1,
      mensagemValidacao: 'Cadastre pelo menos uma fonte de renda',
      video: VideoConfig(
        id: 'cMzyREdUwp8',
        titulo: '📈 Cadastrando Receitas',
        embedUrl: 'https://www.youtube.com/embed/cMzyREdUwp8',
      ),
    ),

    // 🏠 STEP 5: DESPESAS FIXAS
    DiagnosticoEtapa(
      id: 'despesas-fixas',
      titulo: '🏠 Despesas Fixas',
      subtitulo: 'Gastos que se repetem todo mês',
      descricao: 'Cadastre aluguel, financiamentos, assinaturas e outros gastos fixos mensais',
      icone: Icons.home,
      cor: Color(0xFFef4444),
      tipo: TipoDiagnosticoEtapa.cadastro,
      modal: 'DespesasModal',
      obrigatorio: true,
      minimoItens: 1,
      mensagemValidacao: 'Cadastre pelo menos uma despesa fixa',
      video: VideoConfig(
        id: 'pJYSccgETGk',
        titulo: '🏠 Mapeando Despesas Fixas',
        embedUrl: 'https://www.youtube.com/embed/pJYSccgETGk',
      ),
    ),

    // 🛒 STEP 6: DESPESAS VARIÁVEIS
    DiagnosticoEtapa(
      id: 'despesas-variaveis',
      titulo: '🛒 Despesas Variáveis',
      subtitulo: 'Gastos que mudam de valor',
      descricao: 'Cadastre mercado, combustível, lazer e outros gastos que variam mensalmente',
      icone: Icons.shopping_cart,
      cor: Color(0xFFf59e0b),
      tipo: TipoDiagnosticoEtapa.cadastro,
      modal: 'DespesasModal',
      obrigatorio: true,
      minimoItens: 1,
      mensagemValidacao: 'Cadastre pelo menos uma despesa variável',
      video: VideoConfig(
        id: '-yEZX2ar8WI',
        titulo: '🛒 Controlando Despesas Variáveis',
        embedUrl: 'https://www.youtube.com/embed/-yEZX2ar8WI',
      ),
    ),

    // 🤔 STEP 7: QUESTIONÁRIO PERCEPÇÃO
    DiagnosticoEtapa(
      id: 'percepcao',
      titulo: '🤔 Sua Relação com Dinheiro',
      subtitulo: 'Questionário sobre comportamento financeiro',
      descricao: 'Responda algumas perguntas para entendermos melhor seu perfil e comportamento financeiro',
      icone: Icons.psychology,
      cor: Color(0xFF3b82f6),
      tipo: TipoDiagnosticoEtapa.questionario,
      obrigatorio: true,
      mensagemValidacao: 'Complete o questionário para calcularmos seu diagnóstico',
    ),

    // ⚠️ STEP 8: DÍVIDAS (OPCIONAL)
    DiagnosticoEtapa(
      id: 'dividas',
      titulo: '⚠️ Suas Dívidas',
      subtitulo: 'Mapeamento de pendências financeiras',
      descricao: 'Informe suas dívidas atuais para incluirmos no diagnóstico (opcional)',
      icone: Icons.warning,
      cor: Color(0xFFef4444),
      tipo: TipoDiagnosticoEtapa.questionario,
      obrigatorio: false,
      permitirPular: true,
      video: VideoConfig(
        id: 'B6dQWtSoafc',
        titulo: '⚠️ Mapeando suas Dívidas',
        embedUrl: 'https://www.youtube.com/embed/B6dQWtSoafc',
      ),
    ),

    // 🧮 PROCESSAMENTO
    DiagnosticoEtapa(
      id: 'processamento',
      titulo: '🧮 Analisando seus Dados',
      subtitulo: 'Calculando seu diagnóstico financeiro',
      descricao: 'Estamos processando todas as informações para gerar seu diagnóstico personalizado',
      icone: Icons.analytics,
      cor: Color(0xFF8b5cf6),
      tipo: TipoDiagnosticoEtapa.processamento,
      obrigatorio: false,
      mostrarProgresso: false,
      permitirVoltar: false,
    ),

    // 🎉 RESULTADO
    DiagnosticoEtapa(
      id: 'resultado',
      titulo: '🎉 Seu Diagnóstico Está Pronto',
      subtitulo: null, // Removido para dar mais espaço aos botões
      descricao: 'Baseado nos seus dados, criamos um diagnóstico completo e um plano personalizado',
      icone: Icons.celebration,
      cor: Color(0xFF10b981),
      tipo: TipoDiagnosticoEtapa.resultado,
      obrigatorio: false,
      mostrarProgresso: false,
      permitirVoltar: false,
    ),
  ];

  /// Retorna uma etapa específica pelo ID
  static DiagnosticoEtapa? getEtapaPorId(String id) {
    try {
      return fluxoCompleto.firstWhere((etapa) => etapa.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retorna o índice de uma etapa pelo ID
  static int getIndiceEtapa(String id) {
    return fluxoCompleto.indexWhere((etapa) => etapa.id == id);
  }

  /// Retorna a próxima etapa baseada no ID atual
  static DiagnosticoEtapa? getProximaEtapa(String idAtual) {
    final indiceAtual = getIndiceEtapa(idAtual);
    if (indiceAtual == -1 || indiceAtual >= fluxoCompleto.length - 1) {
      return null;
    }
    return fluxoCompleto[indiceAtual + 1];
  }

  /// Retorna a etapa anterior baseada no ID atual
  static DiagnosticoEtapa? getEtapaAnterior(String idAtual) {
    final indiceAtual = getIndiceEtapa(idAtual);
    if (indiceAtual <= 0) return null;
    return fluxoCompleto[indiceAtual - 1];
  }

  /// Calcula o progresso geral baseado na etapa atual
  static double calcularProgresso(String idEtapaAtual) {
    final indice = getIndiceEtapa(idEtapaAtual);
    if (indice == -1) return 0.0;
    return ((indice + 1) / fluxoCompleto.length) * 100;
  }

  /// Retorna apenas as etapas obrigatórias
  static List<DiagnosticoEtapa> get etapasObrigatorias {
    return fluxoCompleto.where((etapa) => etapa.obrigatorio).toList();
  }

  /// Retorna apenas as etapas de cadastro
  static List<DiagnosticoEtapa> get etapasCadastro {
    return fluxoCompleto.where((etapa) => etapa.tipo == TipoDiagnosticoEtapa.cadastro).toList();
  }

  /// Retorna apenas as etapas de questionário
  static List<DiagnosticoEtapa> get etapasQuestionario {
    return fluxoCompleto.where((etapa) => etapa.tipo == TipoDiagnosticoEtapa.questionario).toList();
  }

  // Aliases para compatibilidade com código antigo
  static List<DiagnosticoEtapa> get todas => fluxoCompleto;
  static DiagnosticoEtapa? getPorId(String id) => getEtapaPorId(id);

  /// Calcula o progresso geral baseado no índice da etapa (versão antiga)
  static double calcularProgressoPorIndice(int etapaIndex) {
    if (etapaIndex < 0 || etapaIndex >= fluxoCompleto.length) return 0.0;
    return ((etapaIndex + 1) / fluxoCompleto.length) * 100;
  }
}

/// Estrutura dos dados coletados do diagnóstico
class DiagnosticoData {
  final List<dynamic> contas;
  final List<dynamic> receitas;
  final List<dynamic> despesasFixas;
  final List<dynamic> despesasVariaveis;
  final Map<String, dynamic> percepcao;
  final Map<String, dynamic> dividas;

  // Campos do diagnóstico antigo para compatibilidade
  double? rendaMensal;
  String? sobraOuFalta;
  Map<String, double> gastosMensais;
  String? temDividas;
  List<Map<String, dynamic>> dividasLista;
  String? vilaoOrcamento;
  String? saldoContas;
  double? valorSaldo;
  Map<String, dynamic>? resultado;

  DiagnosticoData({
    this.contas = const [],
    this.receitas = const [],
    this.despesasFixas = const [],
    this.despesasVariaveis = const [],
    this.percepcao = const {},
    this.dividas = const {},
    this.rendaMensal,
    this.sobraOuFalta,
    Map<String, double>? gastosMensais,
    this.temDividas,
    List<Map<String, dynamic>>? dividasLista,
    this.vilaoOrcamento,
    this.saldoContas,
    this.valorSaldo,
    this.resultado,
  }) : gastosMensais = gastosMensais ?? {
         'moradia': 0,
         'transporte': 0,
         'alimentacao': 0,
         'cartao': 0,
         'lazer': 0,
         'outros': 0,
       },
       dividasLista = dividasLista ?? [];

  /// Criar a partir de um Map (para compatibilidade com dados coletados)
  factory DiagnosticoData.fromMap(Map<String, dynamic> dados) {
    return DiagnosticoData(
      contas: _extractList(dados['contas']),
      receitas: _extractList(dados['receitas']),
      despesasFixas: _extractList(dados['despesas-fixas']),
      despesasVariaveis: _extractList(dados['despesas-variaveis']),
      percepcao: _extractMap(dados['percepcao']),
      dividas: _extractMap(dados['dividas']),
    );
  }

  /// Extrai lista de dados diversos formatos
  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      // Se é um Map, pode ter uma lista dentro
      if (data.containsKey('dados')) return data['dados'] as List? ?? [];
      if (data.containsKey('lista')) return data['lista'] as List? ?? [];
      // Ou pode ser metadados - retornar lista vazia
      return [];
    }
    return [];
  }

  /// Extrai map de dados diversos formatos
  static Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Map<String, dynamic> toMap() {
    return {
      'contas': contas,
      'receitas': receitas,
      'despesas-fixas': despesasFixas,
      'despesas-variaveis': despesasVariaveis,
      'percepcao': percepcao,
      'dividas': dividas,
      'renda_mensal': rendaMensal,
      'sobra_ou_falta': sobraOuFalta,
      'gastos_mensais': gastosMensais,
      'tem_dividas': temDividas,
      'dividas_lista': dividasLista,
      'vilao_orcamento': vilaoOrcamento,
      'saldo_contas': saldoContas,
      'valor_saldo': valorSaldo,
      'resultado': resultado,
    };
  }

  /// Verificar se etapa está completa
  bool isEtapaCompleta(int etapa) {
    switch (etapa) {
      case 0: return true; // Welcome sempre completa
      case 1: return rendaMensal != null && sobraOuFalta != null;
      case 2: return gastosMensais.values.any((v) => v > 0);
      case 3: return temDividas != null;
      case 4: return vilaoOrcamento != null;
      case 5: return saldoContas != null;
      case 6: return resultado != null;
      case 7: return true; // Plano sempre acessível após resumo
      default: return false;
    }
  }
}