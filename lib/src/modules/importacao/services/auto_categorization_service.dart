// 🤖 Auto Categorization Service - iPoupei Mobile
//
// Serviço inteligente de auto-categorização de transações
// Estratégias:
// 1. Keywords avançadas com RegEx (categoria_keywords_mapping_advanced.dart)
// 2. Keywords básicas com 300+ referências (categoria_keywords_mapping.dart)
// 3. Padrões genéricos como fallback
//
// Usage: AutoCategorizationService.instance.categorizarAutomaticamente(transacoes, categorias)

import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/transacao_importada_model.dart';
import '../../categorias/models/categoria_model.dart';
import '../data/categoria_keywords_mapping_advanced.dart';
import '../data/categoria_keywords_mapping.dart';
import '../../../database/local_database.dart';

class AutoCategorizationService {
  static final AutoCategorizationService instance = AutoCategorizationService._();
  AutoCategorizationService._();

  /// Categoriza automaticamente uma lista de transações
  /// Retorna lista de transações com categoria/subcategoria preenchidas
  Future<List<TransacaoImportada>> categorizarAutomaticamente({
    required List<TransacaoImportada> transacoes,
    required List<CategoriaModel> categorias,
    required List<SubcategoriaModel> subcategorias,
  }) async {
    log('🤖 [AUTO-CAT] Iniciando auto-categorização de ${transacoes.length} transações');

    final transacoesCategorizadas = <TransacaoImportada>[];
    int sucessos = 0;

    for (var transacao in transacoes) {
      // Pular se já tem categoria E subcategoria
      if (transacao.categoriaId != null &&
          transacao.categoriaId!.isNotEmpty &&
          transacao.subcategoriaId != null &&
          transacao.subcategoriaId!.isNotEmpty) {
        transacoesCategorizadas.add(transacao);
        continue;
      }

      // Tentar categorizar
      final resultado = await _categorizarTransacao(
        transacao: transacao,
        categorias: categorias,
        subcategorias: subcategorias,
      );

      if (resultado != null) {
        transacoesCategorizadas.add(resultado);
        sucessos++;
        log('✅ [AUTO-CAT] "${transacao.descricao}" → ${resultado.categoriaId}/${resultado.subcategoriaId}');
      } else {
        transacoesCategorizadas.add(transacao);
        log('⚠️ [AUTO-CAT] "${transacao.descricao}" → Sem match');
      }
    }

    log('🎯 [AUTO-CAT] Finalizado: $sucessos/${transacoes.length} categorizadas');
    return transacoesCategorizadas;
  }

  /// Categoriza uma transação individual usando keywords avançadas
  Future<TransacaoImportada?> _categorizarTransacao({
    required TransacaoImportada transacao,
    required List<CategoriaModel> categorias,
    required List<SubcategoriaModel> subcategorias,
  }) async {
    log('🔎 [INICIO] Categorizando: "${transacao.descricao}"');

    final descricao = transacao.descricao.toLowerCase();
    final descricaoNormalizada = _normalizarTexto(descricao);
    final tipo = transacao.tipo;

    // 🔥 RESET FORÇADO - Se a transação já foi categorizada ERRADO como "Vendas", limpar
    if (transacao.categoriaId != null && transacao.categoriaId == '37079136-12b6-4625-8ca3-fff096b9185e') {
      log('🧹 [RESET] Limpando categoria ERRADA "Vendas" para "${transacao.descricao}"');
      transacao = transacao.copyWith(categoriaId: null, subcategoriaId: null);
    }

    // Filtrar categorias do tipo correto e ativas
    final categoriasDoTipo = categorias.where((c) => c.tipo == tipo && c.ativo).toList();
    log('🔎 [INICIO] Tipo: $tipo, Categorias disponíveis do tipo: ${categoriasDoTipo.length}');

    CategoriaModel? categoriaMatch;
    SubcategoriaModel? subcategoriaMatch;

    // 🎯 ESTRATÉGIA 0: Buscar no histórico do usuário (PRIORIDADE MÁXIMA)
    // Busca inteligente por similaridade com score de confiança
    const bool USAR_HISTORICO = true; // ✅ HABILITADO COM BUSCA INTELIGENTE
    if (USAR_HISTORICO) {
      // 🧠 Busca inteligente no histórico por similaridade
      final historicoResult = await _buscarPorSimilaridade(descricaoNormalizada, tipo);

      if (historicoResult != null && historicoResult['score'] >= 60.0) {
        try {
          final categoriaIdHistorico = historicoResult['categoria_id'] as String;
          final subcategoriaIdHistorico = historicoResult['subcategoria_id'] as String;
          final scoreConfianca = historicoResult['score'] as double;
          final matchType = historicoResult['match_type'] as String;

          log('🔍 [HISTÓRICO] Tentando match: ${historicoResult['descricao_historico']} (score: ${scoreConfianca}%, tipo: $matchType)');

          // Validar se categoria/subcategoria ainda existem
          categoriaMatch = categorias.where((c) => c.id == categoriaIdHistorico).firstOrNull;
          subcategoriaMatch = subcategorias.where((s) => s.id == subcategoriaIdHistorico).firstOrNull;

          if (categoriaMatch != null && subcategoriaMatch != null) {
            // 🚨 VERIFICAÇÃO DE INTEGRIDADE
            if (subcategoriaMatch!.categoriaId == categoriaMatch!.id) {
              log('🎯 [HISTÓRICO SUCESSO] "${transacao.descricao}" → ${categoriaMatch!.nome}/${subcategoriaMatch!.nome} (${scoreConfianca}% confiança, $matchType)');

              return transacao.copyWith(
                categoriaId: categoriaMatch!.id,
                subcategoriaId: subcategoriaMatch!.id,
              );
            } else {
              log('⚠️ [HISTÓRICO INTEGRIDADE] Subcategoria ${subcategoriaMatch!.nome} não pertence à categoria ${categoriaMatch!.nome}');
            }
          } else {
            log('⚠️ [HISTÓRICO] Categoria/subcategoria do histórico não encontrada nas listas atuais');
          }
        } catch (e) {
          log('⚠️ [HISTÓRICO ERRO] Erro ao processar resultado: $e');
        }
      } else {
        log('🔍 [HISTÓRICO] Nenhum match com confiança suficiente (≥60%) encontrado');
      }
    }

    // 🔍 ESTRATÉGIA 1: Tentar keywords BÁSICAS (300+ referências testadas)
    final basicMatch = CategoriaKeywordsService.buscarPorDescricao(descricaoNormalizada, tipo: tipo);
    if (basicMatch != null) {
      log('📋 [BASIC MATCH] Encontrado mapping: ${basicMatch.categoria}/${basicMatch.subcategoria} para "${transacao.descricao}"');

      categoriaMatch = _findCategoria(categoriasDoTipo, [basicMatch.categoria.toLowerCase()]);

      if (categoriaMatch != null) {
        log('📋 [BASIC] Categoria match: ${categoriaMatch.nome} (${categoriaMatch.id})');

        subcategoriaMatch = _findSubcategoriaExata(
          subcategorias,
          categoriaMatch.id,
          basicMatch.subcategoria.toLowerCase()
        );

        if (subcategoriaMatch != null) {
          log('✅ [BASIC] "${transacao.descricao}" → ${basicMatch.categoria}/${basicMatch.subcategoria} (conf: ${basicMatch.confidence})');
        }
      } else {
        log('❌ [BASIC] Categoria "${basicMatch.categoria}" não encontrada nas categorias disponíveis!');
      }
    }

    // 🚀 ESTRATÉGIA 2: Tentar keywords AVANÇADAS com RegEx (se básico não resolveu)
    if (categoriaMatch == null || subcategoriaMatch == null) {
      final advancedMatch = AdvancedCategoriaKeywordsService.buscarMelhorMatch(descricaoNormalizada);
      if (advancedMatch != null) {
        // Encontrar categoria correspondente
        categoriaMatch = _findCategoria(categoriasDoTipo, [advancedMatch.categoria.toLowerCase()]);

        if (categoriaMatch != null) {
          // Encontrar subcategoria correspondente
          subcategoriaMatch = _findSubcategoriaExata(
            subcategorias,
            categoriaMatch.id,
            advancedMatch.subcategoria.toLowerCase()
          );

          if (subcategoriaMatch != null) {
            log('🎯 [ADVANCED] "${transacao.descricao}" → ${advancedMatch.categoria}/${advancedMatch.subcategoria} (conf: ${advancedMatch.confidence})');
          }
        }
      }
    }

    // 🎯 ESTRATÉGIA 3: Fallback para padrões genéricos (último recurso)
    if (categoriaMatch == null && tipo == 'despesa') {
      if (_matchAlimentacao(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['alimentação', 'alimentacao', 'comida']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
      else if (_matchTransporte(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['transporte', 'mobilidade']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
      else if (_matchSaude(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['saúde', 'saude', 'medicina']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
      else if (_matchLazer(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['lazer', 'entretenimento']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
      else if (_matchMoradia(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['moradia', 'habitação', 'habitacao', 'casa']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
      else if (_matchVestuario(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['vestuário', 'vestuario', 'roupa']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
      else if (_matchEducacao(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['educação', 'educacao', 'estudo']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
    }
    else if (categoriaMatch == null && tipo == 'receita') {
      if (_matchSalario(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['salário', 'salario']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      } else if (_matchFreelance(descricao)) {
        categoriaMatch = _findCategoria(categoriasDoTipo, ['freelance', 'extra']);
        if (categoriaMatch != null) {
          subcategoriaMatch = _findSubcategoria(subcategorias, categoriaMatch.id, descricao);
        }
      }
    }

    // 🎯 ESTRATÉGIA FINAL: Categorizar se encontrou pelo menos categoria
    if (categoriaMatch != null) {
      // Se não encontrou subcategoria, tentar buscar a primeira da categoria
      if (subcategoriaMatch == null) {
        final subsDisponiveis = subcategorias.where((s) => s.categoriaId == categoriaMatch!.id && s.ativo).toList();
        if (subsDisponiveis.isNotEmpty) {
          subcategoriaMatch = subsDisponiveis.first;
          log('🔄 [FALLBACK] Usando primeira subcategoria da categoria ${categoriaMatch.nome}: ${subcategoriaMatch.nome}');
        }
      }

      if (subcategoriaMatch != null) {
        log('🎯 [FINAL SUCESSO] "${transacao.descricao}" → ${categoriaMatch.nome}/${subcategoriaMatch.nome}');
        return transacao.copyWith(
          categoriaId: categoriaMatch.id,
          subcategoriaId: subcategoriaMatch.id,
        );
      } else {
        log('⚠️ [FINAL PARCIAL] "${transacao.descricao}" → ${categoriaMatch.nome}/SEM_SUBCATEGORIA');
        // MESMO SEM SUBCATEGORIA, ainda categoriza só com categoria
        return transacao.copyWith(
          categoriaId: categoriaMatch.id,
          // Deixa subcategoriaId como null
        );
      }
    }

    // Se não encontrou nem categoria, não categorizar
    log('❌ [FINAL FALHA] "${transacao.descricao}" → SEM_CATEGORIA');
    return null;
  }

  /// Normaliza texto removendo acentos e caracteres especiais
  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ========== MATCHERS DE PADRÕES ==========

  bool _matchAlimentacao(String descricao) {
    final palavrasChave = [
      'ifood', 'rappi', 'uber eats', 'delivery',
      'mercado', 'supermercado', 'padaria', 'açougue', 'acougue',
      'restaurante', 'lanchonete', 'pizzaria', 'hamburger',
      'mcdonalds', 'bobs', 'burguer', 'subway',
      // FATURAS - Adicionando padrões específicos
      'mercadolivre*nestl', 'mercadolivre*nestle', 'mercadolivre',
      'carrefour', 'pao de acucar', 'pão de açúcar', 'extra',
      'drogaria', 'drogasil', 'pague menos',
      'hortifrtuti', 'hortifruti', 'saude', 'supermercado',
      'cannoleria', 'gelateria', 'bacio di latte', 'cacau show',
      'tasca', 'san paolo', 'bullguer',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchTransporte(String descricao) {
    final palavrasChave = [
      'uber', '99', 'cabify', 'taxi',
      'posto', 'gasolina', 'etanol', 'combustivel', 'combustível',
      'estacionamento', 'pedagio', 'pedágio',
      'onibus', 'ônibus', 'metro', 'metrô',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchSaude(String descricao) {
    final palavrasChave = [
      'farmacia', 'farmácia', 'drogaria',
      'hospital', 'clinica', 'clínica', 'medico', 'médico',
      'consulta', 'exame', 'laboratorio', 'laboratório',
      'drogasil', 'pacheco', 'droga raia',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchLazer(String descricao) {
    final palavrasChave = [
      'netflix', 'spotify', 'amazon prime', 'disney', 'hbo',
      'cinema', 'ingresso', 'show', 'teatro',
      'youtube premium', 'apple music', 'deezer',
      // FATURAS - Adicionando padrões específicos
      'google youtube', 'youtube', 'totalpass',
      'fila rb', 'fila br', 'fila',
      'bacio di latte', 'indigo',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchMoradia(String descricao) {
    final palavrasChave = [
      'aluguel', 'condominio', 'condomínio',
      'energia', 'eletricidade', 'celpe', 'cemig', 'enel',
      'água', 'agua', 'saneamento', 'sabesp',
      'internet', 'vivo', 'claro', 'tim', 'oi',
      'iptu', 'taxa',
      // FATURAS - Adicionando padrões específicos
      'airbnb', 'madeiramadeira', 'kombina',
      'estac shop', 'estacionamento',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchVestuario(String descricao) {
    final palavrasChave = [
      'zara', 'renner', 'riachuelo', 'cea',
      'roupa', 'calça', 'camisa', 'sapato',
      'nike', 'adidas', 'puma',
      // FATURAS - Adicionando padrões específicos
      'niazi chohfi', 'chohfi', 'lojas americanas',
      'centauro', 'netshoes', 'mlp*netshoes',
      'shopee *hotrodcamiseta', 'hotrodcamiseta',
      'daiso brasil', 'brasilpark',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchEducacao(String descricao) {
    final palavrasChave = [
      'mensalidade', 'escola', 'faculdade', 'universidade',
      'curso', 'aula', 'udemy', 'coursera',
      'livro', 'apostila', 'material escolar',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchSalario(String descricao) {
    final palavrasChave = [
      'salario', 'salário', 'vencimento', 'pagamento',
      'credito salarial', 'crédito salarial',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchFreelance(String descricao) {
    final palavrasChave = [
      'freelance', 'freela', 'extra',
      'bico', 'serviço', 'servico',
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  // ========== HELPERS ==========

  CategoriaModel? _findCategoria(List<CategoriaModel> categorias, List<String> palavrasChave) {
    log('🔍 [FIND-CAT] Procurando categoria para palavras: $palavrasChave');
    log('🔍 [FIND-CAT] Categorias disponíveis: ${categorias.map((c) => c.nome).toList()}');

    // 🎯 ESTRATÉGIA 1: Match exato por nome
    for (var palavra in palavrasChave) {
      try {
        final match = categorias.firstWhere(
          (c) => c.nome.toLowerCase().contains(palavra.toLowerCase()),
        );
        log('✅ [FIND-CAT] Match direto: "${match.nome}" contém "$palavra"');
        return match;
      } catch (e) {
        // Continuar procurando próxima palavra
      }
    }

    // 🎯 ESTRATÉGIA 2: Match semântico flexível (para qualquer categoria existente)
    for (var palavra in palavrasChave) {
      for (var categoria in categorias) {
        final nomeCat = categoria.nome.toLowerCase();
        final palavraLower = palavra.toLowerCase();

        // Match por similaridade semântica para diferentes possibilidades
        if (_isSimilarCategory(nomeCat, palavraLower)) {
          log('✅ [FIND-CAT] Match semântico: "${categoria.nome}" é similar a "$palavra"');
          return categoria;
        }
      }
    }

    log('❌ [FIND-CAT] Nenhuma categoria encontrada para: $palavrasChave');
    return null;
  }

  /// Verifica se uma categoria é semanticamente similar a uma palavra-chave
  bool _isSimilarCategory(String nomeCategoria, String palavraChave) {
    // Mapeamentos semânticos comuns
    final Map<String, List<String>> sinonimos = {
      'alimentação': ['comida', 'restaurante', 'food', 'meal', 'refeição', 'alimento'],
      'alimentacao': ['comida', 'restaurante', 'food', 'meal', 'refeição', 'alimento'],
      'comida': ['alimentação', 'restaurante', 'food', 'meal', 'refeição'],
      'transporte': ['mobilidade', 'uber', 'taxi', 'combustivel', 'combustível', 'gasolina'],
      'saude': ['medicina', 'medico', 'médico', 'farmacia', 'farmácia', 'hospital'],
      'saúde': ['medicina', 'medico', 'médico', 'farmacia', 'farmácia', 'hospital'],
      'lazer': ['entretenimento', 'diversão', 'diversao', 'cinema', 'show'],
      'moradia': ['casa', 'habitação', 'habitacao', 'aluguel', 'condominio', 'condomínio'],
      'vestuario': ['roupa', 'vestuário', 'moda', 'roupas'],
      'vestuário': ['roupa', 'vestuario', 'moda', 'roupas'],
      'educacao': ['educação', 'estudo', 'escola', 'curso', 'faculdade'],
      'educação': ['educacao', 'estudo', 'escola', 'curso', 'faculdade'],
    };

    // Verificar se a categoria contém a palavra ou seus sinônimos
    for (var categoria in sinonimos.keys) {
      if (nomeCategoria.contains(categoria)) {
        if (sinonimos[categoria]!.contains(palavraChave)) {
          return true;
        }
      }
    }

    // Verificar se a palavra-chave está nos sinônimos da categoria
    if (sinonimos.containsKey(palavraChave)) {
      for (var sinonimo in sinonimos[palavraChave]!) {
        if (nomeCategoria.contains(sinonimo)) {
          return true;
        }
      }
    }

    return false;
  }


  SubcategoriaModel? _findSubcategoria(
    List<SubcategoriaModel> subcategorias,
    String categoriaId,
    String descricao,
  ) {
    // Filtrar subcategorias da categoria
    final subsDisponiveis = subcategorias.where((s) => s.categoriaId == categoriaId && s.ativo).toList();

    if (subsDisponiveis.isEmpty) return null;

    // Tentar match específico na descrição
    final palavrasDescricao = descricao.split(' ');

    for (var sub in subsDisponiveis) {
      final nomeSub = sub.nome.toLowerCase();
      if (palavrasDescricao.any((palavra) => nomeSub.contains(palavra) || palavra.contains(nomeSub))) {
        return sub;
      }
    }

    // Se não achou match específico, retornar primeira subcategoria
    return subsDisponiveis.first;
  }

  /// Busca subcategoria EXATA pelo nome (usado com keywords mapping)
  SubcategoriaModel? _findSubcategoriaExata(
    List<SubcategoriaModel> subcategorias,
    String categoriaId,
    String nomeSubcategoria,
  ) {
    log('🔍 [DEBUG] Buscando subcategoria "$nomeSubcategoria" na categoria $categoriaId');
    log('🔍 [DEBUG] Total de subcategorias disponíveis: ${subcategorias.length}');

    // Filtrar subcategorias da categoria
    final subsDisponiveis = subcategorias.where((s) => s.categoriaId == categoriaId && s.ativo).toList();

    log('🔍 [DEBUG] Subcategorias filtradas para categoria $categoriaId: ${subsDisponiveis.length}');
    for (final sub in subsDisponiveis) {
      log('   - ${sub.nome} (ID: ${sub.id}, categoriaId: ${sub.categoriaId})');
    }

    if (subsDisponiveis.isEmpty) {
      log('⚠️ [DEBUG] Nenhuma subcategoria encontrada para categoria $categoriaId');
      return null;
    }

    // 🎯 ESTRATÉGIA 1: Match exato
    try {
      final match = subsDisponiveis.firstWhere(
        (s) => s.nome.toLowerCase().contains(nomeSubcategoria) || nomeSubcategoria.contains(s.nome.toLowerCase()),
      );
      log('✅ [DEBUG] Match exato encontrado: ${match.nome} (ID: ${match.id})');
      return match;
    } catch (e) {
      log('⚠️ [DEBUG] Match exato não encontrado para "$nomeSubcategoria"');
    }

    // 🎯 ESTRATÉGIA 2: Match flexível (palavras-chave)
    final mapeamentoSubcategorias = {
      'supermercado': ['mercado', 'atacado', 'hiper', 'extra'],
      'restaurante': ['rest', 'comida', 'refeição', 'refeicao'],
      'lanche': ['fast food', 'delivery', 'ifood', 'rappi'],
      'combustível': ['combustivel', 'gasolina', 'posto', 'etanol'],
      'taxi': ['uber', '99', 'corrida', 'viagem'],
      'manutenção': ['manutencao', 'oficina', 'conserto', 'reparo'],
      'farmacia': ['farmácia', 'remedio', 'medicamento', 'drogaria'],
    };

    for (var entry in mapeamentoSubcategorias.entries) {
      final palavraChave = entry.key;
      final sinonimos = entry.value;

      if (nomeSubcategoria.toLowerCase().contains(palavraChave) ||
          sinonimos.any((s) => nomeSubcategoria.toLowerCase().contains(s))) {

        // Buscar subcategoria que contenha a palavra-chave
        for (var sub in subsDisponiveis) {
          if (sub.nome.toLowerCase().contains(palavraChave) ||
              sinonimos.any((s) => sub.nome.toLowerCase().contains(s))) {
            log('✅ [DEBUG FLEXÍVEL] Subcategoria encontrada: ${sub.nome} (ID: ${sub.id}) para "$nomeSubcategoria" → "$palavraChave"');
            return sub;
          }
        }
      }
    }

    // 🎯 ESTRATÉGIA 3: Se não encontrou nada, usar primeira disponível
    log('⚠️ [DEBUG] Usando primeira subcategoria disponível: ${subsDisponiveis.first.nome}');
    return subsDisponiveis.first;
  }

  /// 🧠 Busca inteligente no histórico do usuário por similaridade
  /// Retorna Map com categoria_id, subcategoria_id, score e match_type ou null
  Future<Map<String, dynamic>?> _buscarPorSimilaridade(String descricao, String tipo) async {
    try {
      final db = LocalDatabase.instance.database;
      if (db == null) throw Exception('Database não inicializado');

      log('🔍 [SIMILARIDADE] Buscando no histórico para: "$descricao" (tipo: $tipo)');

      // 🎯 ESTRATÉGIA 1: Busca exata (100% confiança)
      var result = await db.query(
        'transacoes',
        where: 'LOWER(descricao) = ? AND tipo = ? AND categoria_id IS NOT NULL AND subcategoria_id IS NOT NULL',
        whereArgs: [descricao.toLowerCase(), tipo],
        limit: 1,
      );

      if (result.isNotEmpty) {
        log('✅ [SIMILARIDADE EXATA] Match 100%: "${result.first['descricao']}"');
        return {
          'categoria_id': result.first['categoria_id'],
          'subcategoria_id': result.first['subcategoria_id'],
          'descricao_historico': result.first['descricao'],
          'score': 100.0,
          'match_type': 'exato',
        };
      }

      // 🎯 ESTRATÉGIA 2: Busca por contenção (80% confiança)
      // A descrição atual contém uma descrição do histórico OU vice-versa
      final words = descricao.split(' ').where((w) => w.length > 3).toList();
      if (words.isNotEmpty) {
        // Buscar transações que contenham qualquer palavra significativa
        for (final word in words) {
          result = await db.query(
            'transacoes',
            where: 'LOWER(descricao) LIKE ? AND tipo = ? AND categoria_id IS NOT NULL AND subcategoria_id IS NOT NULL',
            whereArgs: ['%${word.toLowerCase()}%', tipo],
            limit: 5,
          );

          for (final row in result) {
            final descricaoHistorico = (row['descricao'] as String).toLowerCase();
            final score = _calcularSimilaridadePorPalavras(descricao, descricaoHistorico);

            if (score >= 70.0) {
              log('✅ [SIMILARIDADE PALAVRA] Match ${score}%: "$descricaoHistorico" vs "$descricao"');
              return {
                'categoria_id': row['categoria_id'],
                'subcategoria_id': row['subcategoria_id'],
                'descricao_historico': row['descricao'],
                'score': score,
                'match_type': 'palavras_comuns',
              };
            }
          }
        }
      }

      // 🎯 ESTRATÉGIA 3: Busca por descrição personalizada (85% confiança)
      // Reconhece padrões: "Descrição Original (Anotação)" ou "Descrição Original | Categoria"
      final matchPersonalizado = await _buscarDescricaoPersonalizada(descricao, tipo, db);
      if (matchPersonalizado != null) {
        return matchPersonalizado;
      }

      // 🎯 ESTRATÉGIA 4: Busca por estabelecimento/padrão (70% confiança)
      final estabelecimento = _extrairEstabelecimento(descricao);
      if (estabelecimento.isNotEmpty && estabelecimento.length > 4) {
        result = await db.query(
          'transacoes',
          where: 'LOWER(descricao) LIKE ? AND tipo = ? AND categoria_id IS NOT NULL AND subcategoria_id IS NOT NULL',
          whereArgs: ['%${estabelecimento.toLowerCase()}%', tipo],
          limit: 3,
        );

        if (result.isNotEmpty) {
          log('✅ [SIMILARIDADE ESTABELECIMENTO] Match 70%: estabelecimento "$estabelecimento"');
          return {
            'categoria_id': result.first['categoria_id'],
            'subcategoria_id': result.first['subcategoria_id'],
            'descricao_historico': result.first['descricao'],
            'score': 70.0,
            'match_type': 'estabelecimento',
          };
        }
      }

      log('❌ [SIMILARIDADE] Nenhum match encontrado no histórico');
      return null;

    } catch (e) {
      log('❌ [SIMILARIDADE ERRO] Erro na busca: $e');
      return null;
    }
  }

  /// 🎨 Busca por descrições personalizadas pelo usuário
  /// Reconhece padrões como: "Descrição Original (Anotação)" ou "Descrição Original | Categoria"
  Future<Map<String, dynamic>?> _buscarDescricaoPersonalizada(String descricao, String tipo, dynamic db) async {
    try {
      log('🎨 [PERSONALIZADA] Analisando: "$descricao"');

      // 🎯 PADRÃO 1: Se a descrição atual tem personalização, extrair a parte original
      // Ex: "IFOOD DELIVERY (Jantar)" → buscar por "IFOOD DELIVERY"
      final descricaoOriginal = _extrairDescricaoOriginal(descricao);
      if (descricaoOriginal != descricao && descricaoOriginal.length > 4) {
        log('🎨 [PERSONALIZADA] Extraída parte original: "$descricaoOriginal" de "$descricao"');

        // Buscar exatamente pela parte original (sem personalização)
        var result = await db.query(
          'transacoes',
          where: 'LOWER(descricao) = ? AND tipo = ? AND categoria_id IS NOT NULL AND subcategoria_id IS NOT NULL',
          whereArgs: [descricaoOriginal.toLowerCase(), tipo],
          limit: 1,
        );

        if (result.isNotEmpty) {
          log('✅ [PERSONALIZADA] Match 95%: encontrou versão original "$descricaoOriginal" para personalizada "$descricao"');
          return {
            'categoria_id': result.first['categoria_id'],
            'subcategoria_id': result.first['subcategoria_id'],
            'descricao_historico': result.first['descricao'],
            'score': 95.0,
            'match_type': 'personalizada_para_original',
          };
        }

        // Se não encontrou a versão original exata, buscar por versões personalizadas similares
        result = await db.query(
          'transacoes',
          where: 'LOWER(descricao) LIKE ? AND tipo = ? AND categoria_id IS NOT NULL AND subcategoria_id IS NOT NULL',
          whereArgs: ['${descricaoOriginal.toLowerCase()}%', tipo],
          limit: 10,
        );

        for (final row in result) {
          final descricaoHistorico = row['descricao'] as String;
          final parteOriginalHistorico = _extrairDescricaoOriginal(descricaoHistorico);

          // Verificar se a parte original é praticamente idêntica (95%+ similaridade)
          if (_isParteOriginalIdentica(descricaoOriginal, parteOriginalHistorico)) {
            log('✅ [PERSONALIZADA] Match 90%: partes originais idênticas "$descricaoOriginal" ↔ "$parteOriginalHistorico"');
            return {
              'categoria_id': row['categoria_id'],
              'subcategoria_id': row['subcategoria_id'],
              'descricao_historico': row['descricao'],
              'score': 90.0,
              'match_type': 'personalizada_partes_identicas',
            };
          }
        }
      }

      // 🎯 PADRÃO 2: Se a descrição atual é "limpa", buscar versões personalizadas
      // Ex: "IFOOD DELIVERY" → encontrar "IFOOD DELIVERY (Almoço trabalho)"
      var result = await db.query(
        'transacoes',
        where: 'LOWER(descricao) LIKE ? AND tipo = ? AND categoria_id IS NOT NULL AND subcategoria_id IS NOT NULL',
        whereArgs: ['${descricao.toLowerCase()}%', tipo],
        limit: 15,
      );

      for (final row in result) {
        final descricaoHistorico = row['descricao'] as String;
        final parteOriginalHistorico = _extrairDescricaoOriginal(descricaoHistorico);

        // Se a parte original do histórico é idêntica à nossa descrição atual
        if (_isParteOriginalIdentica(descricao, parteOriginalHistorico)) {
          log('✅ [PERSONALIZADA] Match 92%: descrição limpa "$descricao" encontrou personalizada "$descricaoHistorico"');
          return {
            'categoria_id': row['categoria_id'],
            'subcategoria_id': row['subcategoria_id'],
            'descricao_historico': row['descricao'],
            'score': 92.0,
            'match_type': 'original_para_personalizada',
          };
        }
      }

      return null;
    } catch (e) {
      log('❌ [SIMILARIDADE PERSONALIZADA] Erro: $e');
      return null;
    }
  }

  /// Verifica se uma descrição é uma versão personalizada de outra
  bool _isDescricaoPersonalizada(String descricaoCompleta, String descricaoBase) {
    // Remove espaços extras
    descricaoCompleta = descricaoCompleta.trim();
    descricaoBase = descricaoBase.trim();

    // Deve começar exatamente com a descrição base
    if (!descricaoCompleta.startsWith(descricaoBase)) {
      return false;
    }

    // Pegar o que vem depois da descrição base
    final restante = descricaoCompleta.substring(descricaoBase.length).trim();

    // Verificar padrões de personalização comuns
    final padroes = [
      RegExp(r'^\s*\(.+\)$'), // " (Anotação)"
      RegExp(r'^\s*\|.+$'),   // " | Categoria"
      RegExp(r'^\s*-.+$'),    // " - Observação"
      RegExp(r'^\s*\[.+\]$'), // " [Tag]"
    ];

    return padroes.any((padrao) => padrao.hasMatch(restante));
  }

  /// Extrai a descrição original removendo personalizações
  String _extrairDescricaoOriginal(String descricao) {
    // Remove padrões de personalização no final
    String limpa = descricao
        .replaceAll(RegExp(r'\s*\([^)]*\)$'), '') // Remove " (Anotação)" no final
        .replaceAll(RegExp(r'\s*\|[^|]*$'), '')   // Remove " | Categoria" no final
        .replaceAll(RegExp(r'\s*-[^-]*$'), '')    // Remove " - Observação" no final
        .replaceAll(RegExp(r'\s*\[[^\]]*\]$'), '') // Remove " [Tag]" no final
        .trim();

    return limpa;
  }

  /// Calcula similaridade entre duas descrições baseada em palavras comuns
  double _calcularSimilaridadePorPalavras(String desc1, String desc2) {
    final palavras1 = desc1.toLowerCase().split(' ').where((w) => w.length > 2).toSet();
    final palavras2 = desc2.toLowerCase().split(' ').where((w) => w.length > 2).toSet();

    if (palavras1.isEmpty || palavras2.isEmpty) return 0.0;

    final palavrasComuns = palavras1.intersection(palavras2);
    final palavrasTotal = palavras1.union(palavras2);

    // Score baseado na proporção de palavras comuns
    final score = (palavrasComuns.length / palavrasTotal.length) * 100;
    return score;
  }

  /// Verifica se duas descrições originais são praticamente idênticas (95%+ similaridade)
  /// Usado para comparar partes originais de descrições personalizadas
  bool _isParteOriginalIdentica(String descricao1, String descricao2) {
    // Normalizar ambas as descrições
    final desc1Norm = _normalizarTexto(descricao1.toLowerCase().trim());
    final desc2Norm = _normalizarTexto(descricao2.toLowerCase().trim());

    // Se são exatamente iguais = 100%
    if (desc1Norm == desc2Norm) {
      log('🎯 [PARTES IDÊNTICAS] 100% - "$desc1Norm" == "$desc2Norm"');
      return true;
    }

    // Se uma está contida na outra com diferença mínima = 95%+
    final tamanhoMin = math.min(desc1Norm.length, desc2Norm.length);
    final tamanhoMax = math.max(desc1Norm.length, desc2Norm.length);

    // Se a diferença de tamanho é muito grande, não são idênticas
    if (tamanhoMax - tamanhoMin > 3) {
      return false;
    }

    // Verificar se uma contém a outra
    if (desc1Norm.contains(desc2Norm) || desc2Norm.contains(desc1Norm)) {
      final percentualSimilaridade = (tamanhoMin.toDouble() / tamanhoMax.toDouble()) * 100;
      if (percentualSimilaridade >= 95.0) {
        log('🎯 [PARTES IDÊNTICAS] ${percentualSimilaridade}% - "$desc1Norm" ↔ "$desc2Norm"');
        return true;
      }
    }

    // Calcular similaridade por palavras comuns com threshold alto
    final palavras1 = desc1Norm.split(' ').where((w) => w.length > 2).toSet();
    final palavras2 = desc2Norm.split(' ').where((w) => w.length > 2).toSet();

    if (palavras1.isEmpty || palavras2.isEmpty) {
      return false;
    }

    final palavrasComuns = palavras1.intersection(palavras2);
    final palavrasTotal = palavras1.union(palavras2);
    final scorePalavras = (palavrasComuns.length / palavrasTotal.length) * 100;

    if (scorePalavras >= 95.0) {
      log('🎯 [PARTES IDÊNTICAS] ${scorePalavras}% (palavras) - "$desc1Norm" ↔ "$desc2Norm"');
      return true;
    }

    return false;
  }

  /// Extrai o nome do estabelecimento/empresa da descrição
  String _extrairEstabelecimento(String descricao) {
    // Remove prefixos comuns de cartão/PIX
    String limpa = descricao
        .replaceAll(RegExp(r'^(pix\s+|ted\s+|transferencia\s+)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\d+/\d+'), '') // Remove datas
        .replaceAll(RegExp(r'\d{2}:\d{2}'), '') // Remove horários
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Pegar primeiras palavras significativas (até 3 palavras)
    final palavras = limpa.split(' ').where((w) => w.length > 2).take(3).toList();
    return palavras.join(' ');
  }
}
