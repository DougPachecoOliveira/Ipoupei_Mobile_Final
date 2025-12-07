// 🧪 TESTES ANTI-REGRESSÃO: Filtros de Categoria
//
// Conjunto de testes que garantem que categorias zeradas nunca sejam filtradas incorretamente
// e que builds iOS não quebrem por tree shaking de ícones
//
// OBJETIVO: Garantir zero reincidência do problema original

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../../lib/src/modules/categorias/models/categoria_model.dart';
import '../../lib/src/modules/categorias/data/categoria_icons.dart';
import '../../lib/src/shared/validators/business_validators.dart';

void main() {
  group('🚨 ANTI-REGRESSÃO: Categorias com Valor Zero', () {

    /// 📋 DADOS DE TESTE
    late List<CategoriaModel> categoriasComZero;
    late List<CategoriaModel> categoriasTodasZero;
    late List<CategoriaModel> categoriasMistas;

    setUpAll(() {
      // Categorias com algumas zeradas
      categoriasComZero = [
        CategoriaModel(
          id: '1',
          nome: 'Alimentação',
          tipo: 'despesa',
          cor: '#FF0000',
          icone: 'restaurant',
          ativo: true,
          usuarioId: 'test',
        ),
        CategoriaModel(
          id: '2',
          nome: 'Transporte',
          tipo: 'despesa',
          cor: '#00FF00',
          icone: 'directions_car',
          ativo: true,
          usuarioId: 'test',
        ), // ← Esta vai ter valor ZERO
        CategoriaModel(
          id: '3',
          nome: 'Lazer',
          tipo: 'despesa',
          cor: '#0000FF',
          icone: 'sports_esports',
          ativo: true,
          usuarioId: 'test',
        ),
      ];

      // Todas as categorias com zero (cenário extremo)
      categoriasTodasZero = [
        CategoriaModel(
          id: 'z1',
          nome: 'Cat Zero 1',
          tipo: 'despesa',
          cor: '#FF0000',
          icone: 'folder',
          ativo: true,
          usuarioId: 'test',
        ),
        CategoriaModel(
          id: 'z2',
          nome: 'Cat Zero 2',
          tipo: 'despesa',
          cor: '#00FF00',
          icone: 'star',
          ativo: true,
          usuarioId: 'test',
        ),
      ];

      // Mix com ativas e inativas
      categoriasMistas = [
        ...categoriasComZero,
        CategoriaModel(
          id: '4',
          nome: 'Categoria Inativa',
          tipo: 'despesa',
          cor: '#888888',
          icone: 'help',
          ativo: false, // ← Inativa (pode ser filtrada)
          usuarioId: 'test',
        ),
      ];
    });

    test('✅ REGRA FUNDAMENTAL: Categorias ativas NUNCA devem ser filtradas por valor zero', () {
      // Simular filtros que PRESERVAM categorias zeradas
      final filtroCorreto = categoriasComZero.where((c) => c.ativo).toList();

      // Validar que TODAS as ativas foram preservadas
      expect(filtroCorreto.length, equals(3),
        reason: 'Filtro deve preservar TODAS as categorias ativas');

      expect(filtroCorreto.any((c) => c.nome == 'Transporte'), true,
        reason: 'Categoria "Transporte" (que terá valor zero) deve estar presente');

      // Validação anti-regressão
      expect(() => BusinessValidators.validateCategoriasNaoFiltradasPorValor(
        categoriasComZero, filtroCorreto, 'TEST'
      ), returnsNormally, reason: 'Validação anti-regressão deve passar');
    });

    test('❌ PADRÃO PROIBIDO: Filtrar categorias por valor > 0 DEVE FALHAR', () {
      // Simular o filtro INCORRETO que causava o problema
      final Map<String, double> valoresFalsos = {
        '1': 100.0,   // Alimentação com valor
        '2': 0.0,     // Transporte SEM valor (seria filtrada incorretamente)
        '3': 50.0,    // Lazer com valor
      };

      // Simular filtro incorreto que remove categorias zeradas
      final filtroIncorreto = categoriasComZero.where((c) {
        return c.ativo && (valoresFalsos[c.id] ?? 0.0) > 0.0; // ❌ PADRÃO ERRADO!
      }).toList();

      // Deve ter removido a categoria "Transporte" (valor zero)
      expect(filtroIncorreto.length, equals(2),
        reason: 'Filtro incorreto remove categorias zeradas');

      expect(filtroIncorreto.any((c) => c.nome == 'Transporte'), false,
        reason: 'Categoria zerada foi incorretamente removida');

      // Validação DEVE detectar o problema e falhar
      expect(() => BusinessValidators.validateCategoriasNaoFiltradasPorValor(
        categoriasComZero, filtroIncorreto, 'TEST_INCORRETO'
      ), throwsA(anything), reason: 'Validação DEVE detectar filtro incorreto');
    });

    test('🔬 CENÁRIO EXTREMO: Todas as categorias com valor zero', () {
      // Simular situação onde todas as categorias têm valor zero no período
      final Map<String, double> todosZero = {
        'z1': 0.0,
        'z2': 0.0,
      };

      // Filtro correto: mostra todas mesmo sendo zero
      final filtroCorreto = categoriasTodasZero.where((c) => c.ativo).toList();

      expect(filtroCorreto.length, equals(2),
        reason: 'Deve mostrar todas as categorias mesmo com valor zero');

      // Filtro incorreto: removeria todas
      final filtroIncorreto = categoriasTodasZero.where((c) =>
        c.ativo && (todosZero[c.id] ?? 0.0) > 0.0
      ).toList();

      expect(filtroIncorreto.length, equals(0),
        reason: 'Filtro incorreto resulta em lista vazia');

      // Validação DEVE detectar o problema crítico
      expect(() => BusinessValidators.validateCategoriasNaoFiltradasPorValor(
        categoriasTodasZero, filtroIncorreto, 'TEST_TODAS_ZERO'
      ), throwsA(anything), reason: 'Lista vazia por filtro incorreto deve ser detectada');
    });

    test('✅ FILTRO CORRETO: Remover apenas categorias inativas', () {
      // Filtro que remove apenas inativas (permitido)
      final filtroCorreto = categoriasMistas.where((c) => c.ativo).toList();

      expect(filtroCorreto.length, equals(3),
        reason: 'Deve manter 3 categorias ativas e remover 1 inativa');

      expect(filtroCorreto.any((c) => c.nome == 'Categoria Inativa'), false,
        reason: 'Categoria inativa pode ser removida');

      expect(filtroCorreto.any((c) => c.nome == 'Transporte'), true,
        reason: 'Categorias ativas (mesmo zeradas) devem permanecer');

      // Validação deve passar
      expect(() => BusinessValidators.validateCategoriasNaoFiltradasPorValor(
        categoriasMistas, filtroCorreto, 'TEST_CORRETO'
      ), returnsNormally);
    });

    test('🔍 BUSCA POR TEXTO: Deve preservar lógica correta', () {
      final busca = 'trans'; // Vai encontrar "Transporte"

      final resultadoBusca = categoriasComZero.where((c) =>
        c.ativo && c.nome.toLowerCase().contains(busca.toLowerCase())
      ).toList();

      expect(resultadoBusca.length, equals(1));
      expect(resultadoBusca.first.nome, equals('Transporte'));

      // Mesmo que "Transporte" tenha valor zero, deve aparecer na busca
      // (não deve ser filtrado por valor)
      expect(() => BusinessValidators.validateCategoriasNaoFiltradasPorValor(
        [resultadoBusca.first], // Lista original da busca
        resultadoBusca,         // Lista resultado
        'TEST_BUSCA'
      ), returnsNormally);
    });
  });

  group('🎯 ANTI-REGRESSÃO: Tree Shaking de Ícones', () {

    test('✅ ÍCONES PRÉ-REGISTRADOS: Todos devem ser acessíveis', () {
      // Lista de ícones críticos que causavam tree shaking
      final iconesCriticos = [
        'remove_circle_outline', // Para categorias zeradas
        'info_outline',          // Para indicadores
        'warning_outlined',      // Para alertas
        'restaurant',            // Alimentação
        'directions_car',        // Transporte
        'home',                  // Moradia
        'medical_services',      // Saúde
        'work',                  // Trabalho
      ];

      for (final iconeName in iconesCriticos) {
        // Deve conseguir obter o ícone sem erro
        expect(() => CategoriaIcons.getIconFromName(iconeName), returnsNormally,
          reason: 'Ícone "$iconeName" deve estar pré-registrado');

        final icon = CategoriaIcons.getIconFromName(iconeName);
        expect(icon, isA<IconData>(),
          reason: 'Deve retornar IconData válido para "$iconeName"');

        expect(icon, isNot(equals(Icons.category_outlined)),
          reason: 'Não deve retornar ícone fallback para "$iconeName"');
      }
    });

    test('✅ PRÉ-CARREGAMENTO: Método deve executar sem erro', () {
      // O método preloadAllIcons() deve executar sem exception
      expect(() => CategoriaIcons.preloadAllIcons(), returnsNormally,
        reason: 'Pré-carregamento de ícones deve executar sem erro');
    });

    test('✅ ÍCONE FIXO PARA ZERADAS: Sempre usar remove_circle_outline', () {
      // Para categorias zeradas, sempre usar ícone fixo (tree shake safe)
      final iconeZerada = Icons.remove_circle_outline;

      expect(iconeZerada, isA<IconData>());
      expect(iconeZerada.codePoint, isNotNull,
        reason: 'Ícone para categorias zeradas deve ser válido');

      // Validação tree shake safety
      expect(() => BusinessValidators.validateIconTreeShakeSafety(
        iconeZerada, 'TEST_ICON_ZERADA'
      ), returnsNormally, reason: 'Ícone fixo deve ser tree shake safe');
    });

    test('❌ ÍCONES DINÂMICOS: Devem ser detectados como perigosos', () {
      // Simular ícones dinâmicos que causam tree shaking
      final iconeDinamico = 'Icons.${true ? "warning" : "error"}'; // Perigoso!

      expect(() => BusinessValidators.validateIconTreeShakeSafety(
        iconeDinamico, 'TEST_ICON_DINAMICO'
      ), throwsA(anything), reason: 'Ícone dinâmico deve ser detectado como perigoso');
    });
  });

  group('📊 MÉTRICAS E MONITORAMENTO', () {

    test('📈 HEALTH REPORT: Sistema deve reportar status', () {
      final report = BusinessValidators.getHealthReport();

      expect(report, isA<Map<String, dynamic>>());
      expect(report['validator_version'], isNotNull);
      expect(report['validations_enabled'], isA<List>());
      expect(report['created_at'], isNotNull);
    });

    test('🧪 MODO TESTE: Deve desabilitar validações agressivas', () {
      // Habilitar modo teste
      BusinessValidators.enableTestMode();
      expect(BusinessValidators.isTestMode, true);

      // Desabilitar modo teste
      BusinessValidators.disableTestMode();
      expect(BusinessValidators.isTestMode, false);
    });

    test('📊 EXTENSION METHODS: Lista deve ter métodos de validação', () {
      final categorias = [
        CategoriaModel(
          id: 'test',
          nome: 'Test',
          tipo: 'despesa',
          cor: '#FF0000',
          icone: 'test',
          ativo: true,
          usuarioId: 'test',
        ),
      ];

      // Testar extension methods
      expect(categorias.hasAllActiveCategories, true);

      final filtered = categorias.where((c) => c.ativo).toList();
      expect(categorias.getSuspiciouslyFiltered(filtered), isEmpty);

      // Não deve dar erro ao validar
      expect(() => categorias.validateFilterResult(filtered, 'TEST'), returnsNormally);
    });
  });

  group('🔥 CENÁRIOS DE STRESS TEST', () {

    test('💀 STRESS: 1000 categorias com filtro incorreto', () {
      // Criar muitas categorias (stress test)
      final muitasCategorias = List.generate(1000, (index) {
        return CategoriaModel(
          id: 'stress_$index',
          nome: 'Categoria $index',
          tipo: 'despesa',
          cor: '#FF0000',
          icone: 'folder',
          ativo: true,
          usuarioId: 'test',
        );
      });

      // Simular filtro que remove metade (incorreto)
      final filtroIncorreto = muitasCategorias.take(500).toList();

      // Deve detectar o problema mesmo com muitos dados
      expect(() => BusinessValidators.validateCategoriasNaoFiltradasPorValor(
        muitasCategorias, filtroIncorreto, 'STRESS_TEST'
      ), throwsA(anything), reason: 'Deve detectar filtro incorreto mesmo com muitas categorias');
    });

    test('⚡ PERFORMANCE: Validações não devem ser lentas', () {
      final categorias = List.generate(100, (index) {
        return CategoriaModel(
          id: 'perf_$index',
          nome: 'Cat $index',
          tipo: 'despesa',
          cor: '#FF0000',
          icone: 'folder',
          ativo: true,
          usuarioId: 'test',
        );
      });

      // Medir tempo de validação
      final stopwatch = Stopwatch()..start();
      BusinessValidators.validateCategoriasNaoFiltradasPorValor(
        categorias, categorias, 'PERFORMANCE_TEST'
      );
      stopwatch.stop();

      // Não deve demorar mais que 100ms para 100 categorias
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
        reason: 'Validação deve ser rápida');
    });
  });
}

/// 🎭 HELPER: Simulador de dados para testes
class CategoriaTestHelper {

  static CategoriaModel createCategoria({
    required String nome,
    required String tipo,
    bool ativo = true,
    String icone = 'folder',
  }) {
    return CategoriaModel(
      id: nome.toLowerCase().replaceAll(' ', '_'),
      nome: nome,
      tipo: tipo,
      cor: '#FF0000',
      icone: icone,
      ativo: ativo,
      usuarioId: 'test',
    );
  }

  static List<CategoriaModel> createCategoriasComValores(
    Map<String, double> nomeValorMap,
    String tipo,
  ) {
    return nomeValorMap.entries.map((entry) {
      return createCategoria(nome: entry.key, tipo: tipo);
    }).toList();
  }

  /// Simular um filtro INCORRETO que remove categorias zeradas
  static List<CategoriaModel> filtroIncorreto(
    List<CategoriaModel> categorias,
    Map<String, double> valores,
  ) {
    return categorias.where((categoria) {
      final valor = valores[categoria.id] ?? 0.0;
      return categoria.ativo && valor > 0.0; // ❌ FILTRO ERRADO!
    }).toList();
  }

  /// Simular um filtro CORRETO que preserva categorias zeradas
  static List<CategoriaModel> filtroCorreto(
    List<CategoriaModel> categorias,
  ) {
    return categorias.where((categoria) => categoria.ativo).toList(); // ✅ CORRETO!
  }
}