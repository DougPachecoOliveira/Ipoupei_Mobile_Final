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

    // Filtrar categorias do tipo correto e ativas
    final categoriasDoTipo = categorias.where((c) => c.tipo == tipo && c.ativo).toList();
    log('🔎 [INICIO] Tipo: $tipo, Categorias disponíveis do tipo: ${categoriasDoTipo.length}');

    CategoriaModel? categoriaMatch;
    SubcategoriaModel? subcategoriaMatch;

    // 🎯 ESTRATÉGIA 0: Buscar no histórico do usuário (PRIORIDADE MÁXIMA)
    // Se o usuário já categorizou essa descrição exata antes, usar a mesma categoria
    const bool USAR_HISTORICO = false; // 🚫 DESABILITADO - histórico tem categorizações erradas antigas
    if (USAR_HISTORICO) {
    try {
      final db = LocalDatabase.instance.database;
      if (db == null) throw Exception('Database não inicializado');

      // Buscar transação com descrição EXATAMENTE igual e já categorizada
      final result = await db.query(
        'transacoes',
        where: 'LOWER(descricao) = ? AND tipo = ? AND categoria_id IS NOT NULL AND subcategoria_id IS NOT NULL',
        whereArgs: [descricao, tipo],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final historicoMap = result.first;
        final categoriaIdHistorico = historicoMap['categoria_id'] as String;
        final subcategoriaIdHistorico = historicoMap['subcategoria_id'] as String;

        debugPrint('🔍 [HISTÓRICO DEBUG] Descrição: "${transacao.descricao}"');
        debugPrint('🔍 [HISTÓRICO DEBUG] Banco retornou: categoria_id=$categoriaIdHistorico, subcategoria_id=$subcategoriaIdHistorico');

        // Encontrou! Usar a mesma categorização do usuário
        try {
          categoriaMatch = categorias.firstWhere((c) => c.id == categoriaIdHistorico);
          subcategoriaMatch = subcategorias.firstWhere((s) => s.id == subcategoriaIdHistorico);

          debugPrint('🔍 [HISTÓRICO DEBUG] Categoria encontrada: ${categoriaMatch.nome} (${categoriaMatch.id})');
          debugPrint('🔍 [HISTÓRICO DEBUG] Subcategoria encontrada: ${subcategoriaMatch.nome} (${subcategoriaMatch.id})');
          debugPrint('🔍 [HISTÓRICO DEBUG] Subcategoria.categoria_id: ${subcategoriaMatch.categoriaId}');

          // 🚨 VERIFICAÇÃO DE INTEGRIDADE
          if (subcategoriaMatch.categoriaId != categoriaMatch.id) {
            debugPrint('❌ [HISTÓRICO ERRO] Subcategoria ${subcategoriaMatch.nome} NÃO pertence à categoria ${categoriaMatch.nome}!');
            debugPrint('   Esperado: categoriaId=${categoriaMatch.id}');
            debugPrint('   Encontrado: categoriaId=${subcategoriaMatch.categoriaId}');
            throw Exception('Integridade quebrada: subcategoria não pertence à categoria');
          }

          log('🎯 [HISTÓRICO] "${transacao.descricao}" → ${categoriaMatch.nome}/${subcategoriaMatch.nome} (do histórico do usuário)');

          return transacao.copyWith(
            categoriaId: categoriaMatch.id,
            subcategoriaId: subcategoriaMatch.id,
          );
        } catch (e) {
          // Categoria/subcategoria do histórico não existe mais nas listas atuais
          debugPrint('⚠️ [HISTÓRICO] Erro ao buscar categoria/subcategoria: $e');
          log('⚠️ [HISTÓRICO] Categoria/subcategoria do histórico não encontrada ou inválida - usando keywords');
        }
      }
    } catch (e) {
      // Erro ao buscar histórico, continuar para próximas estratégias
      log('⚠️ [HISTÓRICO] Erro ao buscar: $e');
    }
    } // Fim do if USAR_HISTORICO

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

    // Se encontrou categoria E subcategoria, retornar transação atualizada
    if (categoriaMatch != null && subcategoriaMatch != null) {
      log('🎯 [FINAL] "${transacao.descricao}" → categoriaMatch: ${categoriaMatch.nome} (${categoriaMatch.id}), subcategoriaMatch: ${subcategoriaMatch.nome} (${subcategoriaMatch.id}, categoriaId: ${subcategoriaMatch.categoriaId})');

      return transacao.copyWith(
        categoriaId: categoriaMatch.id,
        subcategoriaId: subcategoriaMatch.id,
      );
    }

    // Se não encontrou AMBOS, retornar null para não categorizar
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
    ];
    return palavrasChave.any((p) => descricao.contains(p));
  }

  bool _matchVestuario(String descricao) {
    final palavrasChave = [
      'zara', 'renner', 'riachuelo', 'cea',
      'roupa', 'calça', 'camisa', 'sapato',
      'nike', 'adidas', 'puma',
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
    log('🔍 [DEBUG] Buscando categoria com palavras-chave: $palavrasChave');
    log('🔍 [DEBUG] Categorias disponíveis: ${categorias.map((c) => '${c.nome} (${c.id})').join(', ')}');

    for (var palavra in palavrasChave) {
      try {
        final match = categorias.firstWhere(
          (c) => c.nome.toLowerCase().contains(palavra.toLowerCase()),
        );
        log('✅ [DEBUG] Categoria encontrada: ${match.nome} (ID: ${match.id}) para palavra "$palavra"');
        return match;
      } catch (e) {
        // Continuar procurando
        log('⚠️ [DEBUG] Categoria não encontrada para palavra "$palavra"');
      }
    }
    log('❌ [DEBUG] Nenhuma categoria encontrada para palavras: $palavrasChave');
    return null;
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

    // Tentar match exato
    try {
      final match = subsDisponiveis.firstWhere(
        (s) => s.nome.toLowerCase().contains(nomeSubcategoria) || nomeSubcategoria.contains(s.nome.toLowerCase()),
      );
      log('✅ [DEBUG] Match encontrado: ${match.nome} (ID: ${match.id})');
      return match;
    } catch (e) {
      // Se não encontrou match exato, retornar primeira disponível
      log('⚠️ [DEBUG] Match exato não encontrado, usando primeira disponível: ${subsDisponiveis.first.nome}');
      return subsDisponiveis.first;
    }
  }
}
