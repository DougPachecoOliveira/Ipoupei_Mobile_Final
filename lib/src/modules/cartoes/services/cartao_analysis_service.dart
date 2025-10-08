import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';

/// ✅ ANÁLISES E CÁLCULOS DE CARTÃO - EQUIVALENTE AO analisesCalculos.js
/// Métodos para análise financeira baseados nos dados dos cartões
class CartaoAnalysisService {
  static final CartaoAnalysisService _instance = CartaoAnalysisService._internal();
  static CartaoAnalysisService get instance => _instance;
  CartaoAnalysisService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;
  
  String? get _userId => _authIntegration.authService.currentUser?.id;

  /// ✅ CALCULAR MÉDIA DE RECEITAS DOS ÚLTIMOS N MESES
  /// Equivalente ao calcularMediaReceitas do React
  Future<double> calcularMediaReceitas([int meses = 3]) async {
    final userId = _userId;
    if (userId == null) return 0.0;

    try {
      final dataLimite = DateTime.now().subtract(Duration(days: meses * 30));
      
      final result = await _localDb.database?.query(
        'transacoes',
        columns: ['valor'],
        where: '''
          usuario_id = ? 
          AND tipo = 'receita' 
          AND data >= ? 
          AND valor > 0
        ''',
        whereArgs: [userId, dataLimite.toIso8601String().split('T')[0]],
      ) ?? [];

      if (result.isEmpty) return 0.0;
      
      final totalReceitas = result.fold<double>(
        0.0, 
        (total, row) => total + ((row['valor'] as num?)?.toDouble() ?? 0.0),
      );
      
      return totalReceitas / meses;
    } catch (e) {
      log('❌ Erro ao calcular média de receitas: $e');
      return 0.0;
    }
  }

  /// ✅ CALCULAR MÉDIA DE DESPESAS DOS ÚLTIMOS N MESES
  /// Equivalente ao calcularMediaDespesas do React
  Future<double> calcularMediaDespesas([int meses = 3]) async {
    final userId = _userId;
    if (userId == null) return 0.0;

    try {
      final dataLimite = DateTime.now().subtract(Duration(days: meses * 30));
      
      final result = await _localDb.database?.query(
        'transacoes',
        columns: ['valor'],
        where: '''
          usuario_id = ? 
          AND tipo = 'despesa' 
          AND data >= ? 
          AND valor > 0
        ''',
        whereArgs: [userId, dataLimite.toIso8601String().split('T')[0]],
      ) ?? [];

      if (result.isEmpty) return 0.0;
      
      final totalDespesas = result.fold<double>(
        0.0, 
        (total, row) => total + ((row['valor'] as num?)?.toDouble() ?? 0.0),
      );
      
      return totalDespesas / meses;
    } catch (e) {
      log('❌ Erro ao calcular média de despesas: $e');
      return 0.0;
    }
  }

  /// ✅ CALCULAR SALDO MÉDIO MENSAL
  /// Equivalente ao calcularSaldoMedio do React
  Future<double> calcularSaldoMedio([int meses = 3]) async {
    final receitas = await calcularMediaReceitas(meses);
    final despesas = await calcularMediaDespesas(meses);
    return receitas - despesas;
  }

  /// ✅ CALCULAR HORAS DE TRABALHO NECESSÁRIAS
  /// Equivalente ao calcularHorasTrabalho do React
  int calcularHorasTrabalho(double valorMensal, double receitaMensal) {
    if (receitaMensal <= 0) return 0;
    
    // 22 dias úteis por mês, 8 horas por dia
    const horasTrabalhadasPorMes = 22 * 8;
    final salarioPorHora = receitaMensal / horasTrabalhadasPorMes;
    
    return (valorMensal / salarioPorHora).ceil();
  }

  /// ✅ ANALISAR GASTOS POR CATEGORIA
  /// Equivalente ao analisarGastosPorCategoria do React
  Future<Map<String, dynamic>> analisarGastosPorCategoria([int meses = 3]) async {
    final userId = _userId;
    if (userId == null) return _analiseVazia();

    try {
      final receitas = await calcularMediaReceitas(meses);
      final dataLimite = DateTime.now().subtract(Duration(days: meses * 30));
      
      final despesasResult = await _localDb.database?.query(
        'transacoes',
        columns: ['valor', 'categoria_id', 'descricao'],
        where: '''
          usuario_id = ? 
          AND tipo = 'despesa' 
          AND data >= ? 
          AND valor > 0
        ''',
        whereArgs: [userId, dataLimite.toIso8601String().split('T')[0]],
      ) ?? [];

      if (despesasResult.isEmpty) return _analiseVazia();

      // Agrupar por categoria
      final gastosPorCategoria = <String, Map<String, dynamic>>{};
      
      for (final row in despesasResult) {
        final valor = ((row['valor'] as num?)?.toDouble() ?? 0.0);
        final categoriaId = row['categoria_id'] as String?;
        
        // Buscar nome e ícone da categoria
        String categoriaNome = 'Sem categoria';
        String categoriaIcone = _obterIconeCategoria(categoriaNome);
        
        if (categoriaId != null) {
          final categoriaResult = await _localDb.database?.query(
            'categorias',
            columns: ['nome', 'icone'],
            where: 'id = ?',
            whereArgs: [categoriaId],
            limit: 1,
          ) ?? [];
          
          if (categoriaResult.isNotEmpty) {
            categoriaNome = categoriaResult.first['nome'] as String;
            categoriaIcone = categoriaResult.first['icone'] as String? ?? _obterIconeCategoria(categoriaNome);
          }
        }

        if (!gastosPorCategoria.containsKey(categoriaNome)) {
          gastosPorCategoria[categoriaNome] = {
            'nome': categoriaNome,
            'icone': categoriaIcone,
            'valor': 0.0,
            'quantidade': 0,
            'transacoes': <Map<String, dynamic>>[],
          };
        }

        final categoria = gastosPorCategoria[categoriaNome]!;
        categoria['valor'] = (categoria['valor'] as double) + valor;
        categoria['quantidade'] = (categoria['quantidade'] as int) + 1;
        (categoria['transacoes'] as List<Map<String, dynamic>>).add(row);
      }

      // Converter para lista e calcular métricas
      final categorias = gastosPorCategoria.values.map((categoria) {
        final valor = categoria['valor'] as double;
        final valorMedio = valor / meses;
        
        return {
          ...categoria,
          'valor_medio': valorMedio,
          'percentual_renda': receitas > 0 ? (valorMedio / receitas) * 100 : 0.0,
          'horas_trabalho': calcularHorasTrabalho(valorMedio, receitas),
          'percentual_despesas': 0.0, // Calculado depois
        };
      }).toList();

      // Ordenar por valor médio
      categorias.sort((a, b) => (b['valor_medio'] as double).compareTo(a['valor_medio'] as double));

      // Calcular percentual das despesas totais
      final totalDespesas = categorias.fold<double>(0.0, (sum, c) => sum + (c['valor_medio'] as double));
      
      for (final categoria in categorias) {
        categoria['percentual_despesas'] = totalDespesas > 0 ? 
          ((categoria['valor_medio'] as double) / totalDespesas) * 100 : 0.0;
      }

      // Selecionar categorias principais (até 90% das despesas)
      double acumulado = 0.0;
      final categoriasPrincipais = <Map<String, dynamic>>[];
      
      for (final categoria in categorias) {
        categoriasPrincipais.add(categoria);
        acumulado += categoria['valor_medio'] as double;
        
        if (totalDespesas > 0 && (acumulado / totalDespesas) >= 0.9) {
          break;
        }
      }

      return {
        'todas': categorias,
        'principais': categoriasPrincipais,
        'total_categorias': categorias.length,
        'representatividade_principais': totalDespesas > 0 ? (acumulado / totalDespesas) * 100 : 0.0,
      };

    } catch (e) {
      log('❌ Erro ao analisar gastos por categoria: $e');
      return _analiseVazia();
    }
  }

  /// ✅ CALCULAR SAÚDE FINANCEIRA
  /// Equivalente ao calcularSaudeFinanceira do React
  Future<Map<String, dynamic>> calcularSaudeFinanceira([int meses = 3]) async {
    try {
      final receitas = await calcularMediaReceitas(meses);
      final despesas = await calcularMediaDespesas(meses);
      final saldo = receitas - despesas;
      final comprometimento = receitas > 0 ? (despesas / receitas) * 100 : 100.0;

      // Determinar status da situação
      Map<String, dynamic> status;
      
      if (saldo < 0) {
        status = {
          'tipo': 'critica',
          'icone': '🔴',
          'titulo': 'Situação Crítica',
          'descricao': 'Suas despesas excedem suas receitas. É necessário ação imediata.',
          'cor': 'danger'
        };
      } else if (receitas == 0) {
        status = {
          'tipo': 'sem_dados',
          'icone': '⚪',
          'titulo': 'Dados Insuficientes',
          'descricao': 'Continue registrando transações para análise completa.',
          'cor': 'neutral'
        };
      } else if (saldo / receitas < 0.05) {
        status = {
          'tipo': 'atencao',
          'icone': '🟡',
          'titulo': 'Situação de Atenção',
          'descricao': 'Margem muito baixa para emergências. Revisar gastos.',
          'cor': 'warning'
        };
      } else if (saldo / receitas < 0.15) {
        status = {
          'tipo': 'regular',
          'icone': '🟠',
          'titulo': 'Situação Regular',
          'descricao': 'Situação estável, mas há oportunidades de melhoria.',
          'cor': 'info'
        };
      } else if (saldo / receitas < 0.25) {
        status = {
          'tipo': 'boa',
          'icone': '🟢',
          'titulo': 'Situação Boa',
          'descricao': 'Finanças equilibradas com boa margem de segurança.',
          'cor': 'success'
        };
      } else {
        status = {
          'tipo': 'excelente',
          'icone': '🟢',
          'titulo': 'Situação Excelente',
          'descricao': 'Ótima capacidade de poupança e investimento.',
          'cor': 'success'
        };
      }

      return {
        'receitas': receitas,
        'despesas': despesas,
        'saldo': saldo,
        'comprometimento': comprometimento,
        'taxa_poupanca': receitas > 0 ? ((saldo / receitas) * 100).clamp(0.0, 100.0) : 0.0,
        'dias_trabalhados_para_despesas': receitas > 0 ? ((despesas / receitas) * 30).ceil() : 30,
        'status': status,
      };

    } catch (e) {
      log('❌ Erro ao calcular saúde financeira: $e');
      return {
        'receitas': 0.0,
        'despesas': 0.0,
        'saldo': 0.0,
        'comprometimento': 0.0,
        'taxa_poupanca': 0.0,
        'dias_trabalhados_para_despesas': 0,
        'status': {
          'tipo': 'erro',
          'icone': '❌',
          'titulo': 'Erro no Cálculo',
          'descricao': 'Não foi possível calcular a saúde financeira.',
          'cor': 'error'
        },
      };
    }
  }

  /// ✅ VERIFICAR ELEGIBILIDADE PARA ANÁLISE
  /// Equivalente ao verificarElegibilidadeAnalise do React
  Future<Map<String, dynamic>> verificarElegibilidadeAnalise() async {
    final userId = _userId;
    if (userId == null) {
      return {
        'elegivel': false,
        'motivo': 'Usuário não autenticado',
        'progresso': 0.0,
      };
    }

    try {
      // Buscar todas as transações
      final transacoesResult = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ?',
        whereArgs: [userId],
      ) ?? [];

      if (transacoesResult.isEmpty) {
        return {
          'elegivel': false,
          'motivo': 'Nenhuma transação encontrada',
          'progresso': 0.0,
        };
      }

      if (transacoesResult.length < 10) {
        return {
          'elegivel': false,
          'motivo': 'Mínimo de 10 transações necessárias (atual: ${transacoesResult.length})',
          'progresso': transacoesResult.length / 10,
        };
      }

      final temReceitas = transacoesResult.any((t) => t['tipo'] == 'receita' && (t['valor'] as num) > 0);
      if (!temReceitas) {
        return {
          'elegivel': false,
          'motivo': 'Necessário ter pelo menos uma receita registrada',
          'progresso': 0.5,
        };
      }

      final temDespesas = transacoesResult.any((t) => t['tipo'] == 'despesa' && (t['valor'] as num) > 0);
      if (!temDespesas) {
        return {
          'elegivel': false,
          'motivo': 'Necessário ter pelo menos uma despesa registrada',
          'progresso': 0.7,
        };
      }

      final categorias = transacoesResult
          .map((t) => t['categoria_id'])
          .where((id) => id != null)
          .toSet()
          .length;
      
      if (categorias < 2) {
        return {
          'elegivel': false,
          'motivo': 'Necessário usar pelo menos 2 categorias diferentes',
          'progresso': 0.8,
        };
      }

      // Verificar transações recentes (últimos 60 dias)
      final dataLimite = DateTime.now().subtract(Duration(days: 60));
      final transacoesRecentes = transacoesResult.where((t) {
        final dataTransacao = DateTime.tryParse(t['data'] as String);
        return dataTransacao != null && dataTransacao.isAfter(dataLimite);
      }).length;

      if (transacoesRecentes < 5) {
        return {
          'elegivel': false,
          'motivo': 'Necessário ter atividade financeira recente (últimos 2 meses)',
          'progresso': 0.9,
        };
      }

      return {
        'elegivel': true,
        'progresso': 1.0,
        'motivo': 'Dados suficientes para análise completa',
      };

    } catch (e) {
      log('❌ Erro ao verificar elegibilidade: $e');
      return {
        'elegivel': false,
        'motivo': 'Erro interno ao verificar dados',
        'progresso': 0.0,
      };
    }
  }

  /// ===== MÉTODOS AUXILIARES =====

  /// Mapeia categorias para ícones padrão (equivalente ao React)
  String _obterIconeCategoria(String? nomeCategoria) {
    if (nomeCategoria == null || nomeCategoria.isEmpty) return '📝';
    
    final categoria = nomeCategoria.toLowerCase();
    
    const mapeamento = {
      'alimentacao': '🍽️',
      'alimentação': '🍽️',
      'comida': '🍽️',
      'supermercado': '🛒',
      'mercado': '🛒',
      'transporte': '🚗',
      'combustivel': '⛽',
      'combustível': '⛽',
      'gasolina': '⛽',
      'uber': '🚕',
      'taxi': '🚕',
      'moradia': '🏠',
      'aluguel': '🏠',
      'casa': '🏠',
      'condominio': '🏠',
      'condomínio': '🏠',
      'saude': '💊',
      'saúde': '💊',
      'medico': '👩‍⚕️',
      'médico': '👩‍⚕️',
      'farmacia': '💊',
      'farmácia': '💊',
      'lazer': '🎉',
      'entretenimento': '🎬',
      'cinema': '🎬',
      'restaurante': '🍽️',
      'bar': '🍺',
      'viagem': '✈️',
      'educacao': '📚',
      'educação': '📚',
      'escola': '🎓',
      'curso': '📖',
      'roupas': '👕',
      'vestuario': '👗',
      'vestuário': '👗',
      'shopping': '🛍️',
      'cartao': '💳',
      'cartão': '💳',
      'financiamento': '🏦',
      'emprestimo': '💰',
      'empréstimo': '💰',
      'investimento': '📈',
      'poupanca': '💰',
      'poupança': '💰',
      'trabalho': '💼',
      'salario': '💰',
      'salário': '💰',
      'freelance': '💻',
      'outros': '📝',
      'diversos': '📄'
    };
    
    for (final entry in mapeamento.entries) {
      if (categoria.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return '📝'; // Ícone padrão
  }

  Map<String, dynamic> _analiseVazia() {
    return {
      'todas': <Map<String, dynamic>>[],
      'principais': <Map<String, dynamic>>[],
      'total_categorias': 0,
      'representatividade_principais': 0.0,
    };
  }
}