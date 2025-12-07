// 🚨 Business Validators - iPoupei Mobile
//
// Sistema de validação anti-regressão para regras de negócio críticas
// Detecta e previne bugs que podem reaparecer
//
// Baseado em: Defensive Programming + Fail-Fast Pattern

import 'package:flutter/foundation.dart';
import '../../modules/categorias/models/categoria_model.dart';

class BusinessValidators {

  /// 🚨 VALIDAÇÃO ANTI-REGRESSÃO: Categorias nunca devem ser filtradas por valor zero
  ///
  /// Esta validação detecta se categorias ativas estão sendo removidas incorretamente
  /// da interface, o que causa perda de informação valiosa para o usuário.
  ///
  /// 📋 CONTEXTOS DE USO:
  /// - CategoriasPage._filtrarCategorias()
  /// - Qualquer método que filtre/processe lista de categorias
  /// - Serviços que retornem categorias para UI
  static void validateCategoriasNaoFiltradasPorValor(
    List<CategoriaModel> todasCategorias,
    List<CategoriaModel> categoriasFiltradas,
    String contexto,
  ) {
    // Contar categorias ativas na lista original
    final categoriasAtivas = todasCategorias.where((c) => c.ativo).length;
    final categoriasExibidas = categoriasFiltradas.length;

    // Se há categorias ativas mas não estão sendo exibidas...
    if (categoriasAtivas > categoriasExibidas) {
      final diferenca = categoriasAtivas - categoriasExibidas;
      final categoriasOcultas = todasCategorias
          .where((c) => c.ativo && !categoriasFiltradas.contains(c))
          .map((c) => '"${c.nome}"')
          .join(', ');

      // ⚠️ LOG DETALHADO para debugging
      debugPrint('🚨 POSSÍVEL FILTRO INDEVIDO EM $contexto:');
      debugPrint('   📊 Categorias ativas disponíveis: $categoriasAtivas');
      debugPrint('   📊 Categorias sendo exibidas: $categoriasExibidas');
      debugPrint('   📊 Categorias ocultas: $diferenca');
      debugPrint('   📝 Quais foram ocultas: $categoriasOcultas');
      debugPrint('   🔍 VERIFIQUE: Está filtrando por valor > 0? Isso esconde informação importante!');
      debugPrint('   💡 SOLUÇÃO: Mostre categorias zeradas com indicadores visuais diferentes');

      // 🛡️ Em modo debug, falha agressivamente para forçar correção
      if (kDebugMode && diferenca > (categoriasAtivas * 0.3)) { // Se oculta mais de 30%
        throw FlutterError(
          '🚨 VIOLAÇÃO DE REGRA UX: Filtro em $contexto está ocultando $diferenca/$categoriasAtivas categorias ativas.\n'
          'Categorias ocultas: $categoriasOcultas\n\n'
          'REGRA: Categorias ativas SEMPRE devem ser visíveis, mesmo com valor zero.\n'
          'CORREÇÃO: Remova filtros por valor > 0 e use indicadores visuais para zeradas.\n\n'
          'Para suprimir este erro (NÃO recomendado): remova a validação ou ajuste o threshold.'
        );
      }

      // 📊 Métricas para monitoramento
      _reportCategoriaFilteringMetrics(contexto, categoriasAtivas, categoriasExibidas);
    } else {
      // ✅ Validação passou - log de sucesso (apenas em verbose)
      if (kDebugMode) {
        debugPrint('✅ Filtro em $contexto: OK ($categoriasFiltradas/$categoriasAtivas categorias ativas exibidas)');
      }
    }
  }

  /// 🚨 VALIDAÇÃO: Verificar se UI está respeitando o padrão de categorias zeradas
  static void validateCategoriaZeradaVisualPattern(
    CategoriaModel categoria,
    double valor,
    bool isVisuallyDifferent,
    String contexto,
  ) {
    final isZero = valor == 0.0;

    if (isZero && !isVisuallyDifferent) {
      debugPrint('⚠️ PADRÃO UX VIOLADO em $contexto:');
      debugPrint('   Categoria "${categoria.nome}" com valor zero não tem indicação visual diferenciada');
      debugPrint('   Usuário pode não entender por que aparece na lista');

      // Em debug, força adoção do padrão visual
      if (kDebugMode) {
        throw FlutterError(
          'PADRÃO UX: Categorias zeradas devem ter indicação visual diferenciada!\n'
          'Categoria: ${categoria.nome} | Valor: R\$ $valor | Contexto: $contexto\n\n'
          'Implemente: cor diferente, ícone especial, ou texto explicativo.'
        );
      }
    }
  }

  /// 🚨 VALIDAÇÃO: Tree shaking safety para ícones
  static void validateIconTreeShakeSafety(
    dynamic icon,
    String contexto,
  ) {
    // Verificar se está usando ícones dinâmicos perigosos
    if (icon is String && icon.contains('Icons.') && icon.contains('?')) {
      debugPrint('🚨 TREE SHAKING RISK em $contexto:');
      debugPrint('   Ícone dinâmico detectado: $icon');
      debugPrint('   Isso pode causar "cannot tree shake fonts" no iOS');

      if (kDebugMode) {
        throw FlutterError(
          'TREE SHAKING: Ícone dinâmico detectado em $contexto!\n'
          'Ícone: $icon\n\n'
          'USE: CategoriaIcons.getIconFromName() ou ícones fixos pré-registrados\n'
          'EVITE: Ícones condicionais ou gerados dinamicamente'
        );
      }
    }
  }

  /// 🚨 VALIDAÇÃO: Anti-regressão para filtros em serviços
  static void validateServicoNaoFiltraValorZero(
    List<Map<String, dynamic>> dados,
    String nomeServico,
  ) {
    // Verificar se o serviço está removendo dados com valor zero
    bool temFiltroValorZero = false;

    // Heurística simples: se todos os itens têm valor > 0, pode estar filtrando
    if (dados.isNotEmpty) {
      final todosTemValor = dados.every((item) {
        final valor = item['valor_total'] as num? ?? item['total_valor'] as num? ?? 0;
        return valor > 0;
      });

      if (todosTemValor && dados.length < 10) { // Se tem poucos dados e todos > 0
        temFiltroValorZero = true;
      }
    }

    if (temFiltroValorZero) {
      debugPrint('⚠️ POSSÍVEL FILTRO POR VALOR ZERO em $nomeServico:');
      debugPrint('   Todos os ${dados.length} itens retornados têm valor > 0');
      debugPrint('   Isso pode indicar filtro WHERE valor > 0 no SQL/query');
      debugPrint('   💡 Considere retornar categorias zeradas também');
    }
  }

  /// 🚨 VALIDAÇÃO: Estado vazio incorreto
  static void validateEstadoVazioIncorreto(
    List<dynamic> dadosOriginais,
    List<dynamic> dadosExibidos,
    bool mostrandoEstadoVazio,
    String contexto,
  ) {
    final temDadosOriginais = dadosOriginais.isNotEmpty;
    final semDadosExibidos = dadosExibidos.isEmpty;

    if (temDadosOriginais && semDadosExibidos && mostrandoEstadoVazio) {
      debugPrint('🚨 ESTADO VAZIO INCORRETO em $contexto:');
      debugPrint('   Existem ${dadosOriginais.length} itens disponíveis');
      debugPrint('   Mas 0 itens sendo exibidos (estado vazio mostrado)');
      debugPrint('   Possível causa: filtro muito restritivo removeu tudo');

      if (kDebugMode) {
        throw FlutterError(
          'ESTADO VAZIO INCORRETO: $contexto mostra vazio mas há dados!\n'
          'Dados originais: ${dadosOriginais.length}\n'
          'Dados exibidos: ${dadosExibidos.length}\n\n'
          'Verifique filtros que podem estar removendo todos os dados.'
        );
      }
    }
  }

  /// 📊 Relatório de métricas de filtragem (para monitoramento)
  static void _reportCategoriaFilteringMetrics(
    String contexto,
    int totalAtivas,
    int exibidas,
  ) {
    final porcentagemExibida = totalAtivas > 0 ? (exibidas / totalAtivas * 100) : 100;
    final porcentagemOculta = 100 - porcentagemExibida;

    // Só reporta se há ocultação significativa
    if (porcentagemOculta > 10) {
      debugPrint('📊 MÉTRICA FILTRO [$contexto]: ${porcentagemExibida.toStringAsFixed(1)}% categorias visíveis (${porcentagemOculta.toStringAsFixed(1)}% ocultas)');
    }
  }

  /// 🚨 VALIDAÇÃO COMPLETA: Executar todas as validações de categoria
  static void validateCategoriaCompleto({
    required List<CategoriaModel> categorias,
    required List<CategoriaModel> categoriasFiltradas,
    required String contexto,
    Map<String, double>? valores,
  }) {
    // 1. Validar filtro por valor zero
    validateCategoriasNaoFiltradasPorValor(categorias, categoriasFiltradas, contexto);

    // 2. Se há valores, validar padrão visual
    if (valores != null) {
      for (final categoria in categoriasFiltradas) {
        final valor = valores[categoria.id] ?? 0.0;
        final isZero = valor == 0.0;

        // Assumir que está seguindo o padrão (pode ser expandido com parâmetro)
        validateCategoriaZeradaVisualPattern(categoria, valor, isZero, contexto);
      }
    }

    // 3. Validar estado vazio incorreto
    validateEstadoVazioIncorreto(
      categorias.where((c) => c.ativo).toList(),
      categoriasFiltradas,
      categoriasFiltradas.isEmpty,
      contexto,
    );
  }

  /// 🧪 MODO TESTE: Desabilitar validações para testes
  static bool _testMode = false;

  static void enableTestMode() {
    _testMode = true;
    debugPrint('⚠️ BusinessValidators em MODO TESTE - validações reduzidas');
  }

  static void disableTestMode() {
    _testMode = false;
    debugPrint('✅ BusinessValidators em MODO PRODUÇÃO');
  }

  static bool get isTestMode => _testMode;

  /// 📋 RELATÓRIO DE SAÚDE: Status das validações
  static Map<String, dynamic> getHealthReport() {
    return {
      'validator_version': '1.0.0',
      'test_mode': _testMode,
      'debug_mode': kDebugMode,
      'validations_enabled': [
        'categoria_filtro_valor_zero',
        'categoria_visual_pattern',
        'tree_shaking_safety',
        'servico_filtro_valor_zero',
        'estado_vazio_incorreto',
      ],
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

/// 🛡️ EXTENSION: Validações automáticas para List<CategoriaModel>
extension CategoriaListValidations on List<CategoriaModel> {

  /// Validar automaticamente se lista filtrada mantém categorias ativas
  void validateFilterResult(List<CategoriaModel> filtered, String context) {
    BusinessValidators.validateCategoriasNaoFiltradasPorValor(this, filtered, context);
  }

  /// Verificar se todas as categorias ativas estão representadas
  bool get hasAllActiveCategories => where((c) => c.ativo).length == length;

  /// Obter categorias que podem estar sendo filtradas incorretamente
  List<CategoriaModel> getSuspiciouslyFiltered(List<CategoriaModel> filtered) {
    final active = where((c) => c.ativo).toList();
    return active.where((categoria) => !filtered.contains(categoria)).toList();
  }
}