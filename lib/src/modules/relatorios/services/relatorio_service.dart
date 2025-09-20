// 📊 Relatorio Service - iPoupei Mobile
// 
// Serviço para geração de relatórios e análises financeiras
// 
// Baseado em: Analytics Pattern + Repository Pattern

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class RelatorioService {
  static RelatorioService? _instance;
  static RelatorioService get instance {
    _instance ??= RelatorioService._internal();
    return _instance!;
  }
  
  RelatorioService._internal();

  final _supabase = Supabase.instance.client;

  /// 📈 RELATÓRIO DE EVOLUÇÃO MENSAL
  Future<Map<String, dynamic>> fetchEvolucaoMensal({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'meses': [], 'series': []};

      log('📈 Gerando relatório de evolução mensal');

      // Buscar transações do período
      final response = await _supabase
          .from('transacoes')
          .select('data, valor, tipo')
          .eq('usuario_id', userId)
          .eq('efetivado', true)
          .gte('data', dataInicio.toIso8601String().split('T')[0])
          .lte('data', dataFim.toIso8601String().split('T')[0])
          .order('data');

      if (response is! List) return {'meses': [], 'series': []};

      // Agrupar por mês
      final Map<String, Map<String, double>> dadosPorMes = {};

      for (final item in response) {
        final data = DateTime.parse(item['data']);
        final mesAno = '${data.year}-${data.month.toString().padLeft(2, '0')}';
        final valor = (item['valor'] as num).toDouble();
        final tipo = item['tipo'] as String;

        dadosPorMes[mesAno] ??= {'receitas': 0.0, 'despesas': 0.0};

        if (tipo == 'receita') {
          dadosPorMes[mesAno]!['receitas'] = dadosPorMes[mesAno]!['receitas']! + valor;
        } else if (tipo == 'despesa') {
          dadosPorMes[mesAno]!['despesas'] = dadosPorMes[mesAno]!['despesas']! + valor;
        }
      }

      // Converter para formato de série temporal
      final meses = dadosPorMes.keys.toList()..sort();
      final receitas = <double>[];
      final despesas = <double>[];
      final saldos = <double>[];

      for (final mes in meses) {
        final receitasMes = dadosPorMes[mes]!['receitas']!;
        final despesasMes = dadosPorMes[mes]!['despesas']!;
        final saldoMes = receitasMes - despesasMes;

        receitas.add(receitasMes);
        despesas.add(despesasMes);
        saldos.add(saldoMes);
      }

      return {
        'meses': meses,
        'series': [
          {'nome': 'Receitas', 'dados': receitas, 'cor': '#10B981'},
          {'nome': 'Despesas', 'dados': despesas, 'cor': '#EF4444'},
          {'nome': 'Saldo', 'dados': saldos, 'cor': '#3B82F6'},
        ],
      };
    } catch (e) {
      log('❌ Erro ao gerar evolução mensal: $e');
      return {'meses': [], 'series': []};
    }
  }

  /// 📊 RELATÓRIO POR CATEGORIA
  Future<Map<String, dynamic>> fetchRelatorioPorCategoria({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? tipoTransacao,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'categorias': [], 'total': 0.0};

      log('📊 Gerando relatório por categoria');

      // Query base
      var query = _supabase
          .from('transacoes')
          .select('''
            valor,
            tipo,
            categoria_id,
            categorias!inner(nome, cor, icone)
          ''')
          .eq('usuario_id', userId)
          .eq('efetivado', true)
          .gte('data', dataInicio.toIso8601String().split('T')[0])
          .lte('data', dataFim.toIso8601String().split('T')[0]);

      if (tipoTransacao != null) {
        query = query.eq('tipo', tipoTransacao);
      }

      final response = await query;

      if (response is! List) return {'categorias': [], 'total': 0.0};

      // Agrupar por categoria
      final Map<String, Map<String, dynamic>> dadosPorCategoria = {};
      double totalGeral = 0.0;

      for (final item in response) {
        final valor = (item['valor'] as num).toDouble();
        final categoria = item['categorias'];
        
        if (categoria != null) {
          final categoriaId = item['categoria_id'] as String;
          final categoriaNome = categoria['nome'] as String;
          final categoriaCor = categoria['cor'] as String?;
          final categoriaIcone = categoria['icone'] as String?;

          dadosPorCategoria[categoriaId] ??= {
            'nome': categoriaNome,
            'cor': categoriaCor ?? '#3B82F6',
            'icone': categoriaIcone,
            'valor': 0.0,
            'quantidade': 0,
          };

          dadosPorCategoria[categoriaId]!['valor'] = 
              dadosPorCategoria[categoriaId]!['valor'] + valor;
          dadosPorCategoria[categoriaId]!['quantidade'] = 
              dadosPorCategoria[categoriaId]!['quantidade'] + 1;
          
          totalGeral += valor;
        }
      }

      // Converter para lista e calcular percentuais
      final categorias = dadosPorCategoria.entries.map((entry) {
        final valor = entry.value['valor'] as double;
        final percentual = totalGeral > 0 ? (valor / totalGeral) * 100 : 0.0;

        return {
          'id': entry.key,
          'nome': entry.value['nome'],
          'cor': entry.value['cor'],
          'icone': entry.value['icone'],
          'valor': valor,
          'quantidade': entry.value['quantidade'],
          'percentual': percentual,
        };
      }).toList();

      // Ordenar por valor decrescente
      categorias.sort((a, b) => (b['valor'] as double).compareTo(a['valor'] as double));

      return {
        'categorias': categorias,
        'total': totalGeral,
      };
    } catch (e) {
      log('❌ Erro ao gerar relatório por categoria: $e');
      return {'categorias': [], 'total': 0.0};
    }
  }

  /// 💰 RELATÓRIO POR CONTA
  Future<Map<String, dynamic>> fetchRelatorioPorConta({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'contas': []};

      log('💰 Gerando relatório por conta');

      // Buscar transações com dados das contas
      final response = await _supabase
          .from('transacoes')
          .select('''
            valor,
            tipo,
            conta_id,
            contas!inner(nome, tipo, cor, saldo)
          ''')
          .eq('usuario_id', userId)
          .eq('efetivado', true)
          .gte('data', dataInicio.toIso8601String().split('T')[0])
          .lte('data', dataFim.toIso8601String().split('T')[0]);

      if (response is! List) return {'contas': []};

      // Agrupar por conta
      final Map<String, Map<String, dynamic>> dadosPorConta = {};

      for (final item in response) {
        final valor = (item['valor'] as num).toDouble();
        final tipo = item['tipo'] as String;
        final conta = item['contas'];
        
        if (conta != null) {
          final contaId = item['conta_id'] as String;
          final contaNome = conta['nome'] as String;
          final contaTipo = conta['tipo'] as String;
          final contaCor = conta['cor'] as String?;
          final contaSaldo = (conta['saldo'] as num?)?.toDouble() ?? 0.0;

          dadosPorConta[contaId] ??= {
            'nome': contaNome,
            'tipo': contaTipo,
            'cor': contaCor ?? '#3B82F6',
            'saldo': contaSaldo,
            'receitas': 0.0,
            'despesas': 0.0,
            'transacoes': 0,
          };

          if (tipo == 'receita') {
            dadosPorConta[contaId]!['receitas'] = 
                dadosPorConta[contaId]!['receitas'] + valor;
          } else if (tipo == 'despesa') {
            dadosPorConta[contaId]!['despesas'] = 
                dadosPorConta[contaId]!['despesas'] + valor;
          }
          
          dadosPorConta[contaId]!['transacoes'] = 
              dadosPorConta[contaId]!['transacoes'] + 1;
        }
      }

      // Converter para lista e calcular variação
      final contas = dadosPorConta.entries.map((entry) {
        final receitas = entry.value['receitas'] as double;
        final despesas = entry.value['despesas'] as double;
        final variacao = receitas - despesas;

        return {
          'id': entry.key,
          'nome': entry.value['nome'],
          'tipo': entry.value['tipo'],
          'cor': entry.value['cor'],
          'saldo': entry.value['saldo'],
          'receitas': receitas,
          'despesas': despesas,
          'variacao': variacao,
          'transacoes': entry.value['transacoes'],
        };
      }).toList();

      // Ordenar por variação decrescente
      contas.sort((a, b) => (b['variacao'] as double).compareTo(a['variacao'] as double));

      return {'contas': contas};
    } catch (e) {
      log('❌ Erro ao gerar relatório por conta: $e');
      return {'contas': []};
    }
  }

  /// 🎯 RESUMO EXECUTIVO
  Future<Map<String, dynamic>> fetchResumoExecutivo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      log('🎯 Gerando resumo executivo');

      // Buscar dados em paralelo
      final futures = await Future.wait([
        // Totais do período
        _supabase
            .from('transacoes')
            .select('valor, tipo')
            .eq('usuario_id', userId)
            .eq('efetivado', true)
            .gte('data', dataInicio.toIso8601String().split('T')[0])
            .lte('data', dataFim.toIso8601String().split('T')[0]),
        
        // Saldo atual das contas
        _supabase.rpc('ip_prod_calcular_saldo_atual', params: {'p_usuario_id': userId}),
        
        // Quantidade de transações
        _supabase
            .from('transacoes')
            .select('id')
            .eq('usuario_id', userId)
            .eq('efetivado', true)
            .gte('data', dataInicio.toIso8601String().split('T')[0])
            .lte('data', dataFim.toIso8601String().split('T')[0]),
      ]);

      final transacoes = futures[0] as List;
      final saldoTotal = (futures[1] as num?)?.toDouble() ?? 0.0;
      final totalTransacoes = (futures[2] as List).length;

      // Calcular totais
      double totalReceitas = 0.0;
      double totalDespesas = 0.0;
      int quantReceitas = 0;
      int quantDespesas = 0;

      for (final item in transacoes) {
        final valor = (item['valor'] as num).toDouble();
        final tipo = item['tipo'] as String;

        if (tipo == 'receita') {
          totalReceitas += valor;
          quantReceitas++;
        } else if (tipo == 'despesa') {
          totalDespesas += valor;
          quantDespesas++;
        }
      }

      final saldoPeriodo = totalReceitas - totalDespesas;
      final mediaReceitas = quantReceitas > 0 ? totalReceitas / quantReceitas : 0.0;
      final mediaDespesas = quantDespesas > 0 ? totalDespesas / quantDespesas : 0.0;

      return {
        'periodo': {
          'inicio': dataInicio.toIso8601String().split('T')[0],
          'fim': dataFim.toIso8601String().split('T')[0],
          'dias': dataFim.difference(dataInicio).inDays + 1,
        },
        'totais': {
          'receitas': totalReceitas,
          'despesas': totalDespesas,
          'saldo_periodo': saldoPeriodo,
          'saldo_atual': saldoTotal,
        },
        'quantidades': {
          'receitas': quantReceitas,
          'despesas': quantDespesas,
          'total_transacoes': totalTransacoes,
        },
        'medias': {
          'receita_media': mediaReceitas,
          'despesa_media': mediaDespesas,
        },
        'indicadores': {
          'taxa_economia': totalReceitas > 0 ? (saldoPeriodo / totalReceitas) * 100 : 0.0,
          'gasto_diario_medio': totalDespesas / (dataFim.difference(dataInicio).inDays + 1),
          'receita_diaria_media': totalReceitas / (dataFim.difference(dataInicio).inDays + 1),
        },
      };
    } catch (e) {
      log('❌ Erro ao gerar resumo executivo: $e');
      return {};
    }
  }

  /// 📅 COMPARATIVO PERÍODOS
  Future<Map<String, dynamic>> fetchComparativoPeriodos({
    required DateTime periodo1Inicio,
    required DateTime periodo1Fim,
    required DateTime periodo2Inicio,
    required DateTime periodo2Fim,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      log('📅 Gerando comparativo de períodos');

      // Buscar dados dos dois períodos em paralelo
      final futures = await Future.wait([
        // Período 1
        _supabase
            .from('transacoes')
            .select('valor, tipo')
            .eq('usuario_id', userId)
            .eq('efetivado', true)
            .gte('data', periodo1Inicio.toIso8601String().split('T')[0])
            .lte('data', periodo1Fim.toIso8601String().split('T')[0]),
        
        // Período 2
        _supabase
            .from('transacoes')
            .select('valor, tipo')
            .eq('usuario_id', userId)
            .eq('efetivado', true)
            .gte('data', periodo2Inicio.toIso8601String().split('T')[0])
            .lte('data', periodo2Fim.toIso8601String().split('T')[0]),
      ]);

      final transacoesPeriodo1 = futures[0] as List;
      final transacoesPeriodo2 = futures[1] as List;

      // Processar período 1
      double receitas1 = 0.0, despesas1 = 0.0;
      for (final item in transacoesPeriodo1) {
        final valor = (item['valor'] as num).toDouble();
        if (item['tipo'] == 'receita') {
          receitas1 += valor;
        } else if (item['tipo'] == 'despesa') {
          despesas1 += valor;
        }
      }

      // Processar período 2
      double receitas2 = 0.0, despesas2 = 0.0;
      for (final item in transacoesPeriodo2) {
        final valor = (item['valor'] as num).toDouble();
        if (item['tipo'] == 'receita') {
          receitas2 += valor;
        } else if (item['tipo'] == 'despesa') {
          despesas2 += valor;
        }
      }

      // Calcular variações
      final variacaoReceitas = receitas1 > 0 ? ((receitas2 - receitas1) / receitas1) * 100 : 0.0;
      final variacaoDespesas = despesas1 > 0 ? ((despesas2 - despesas1) / despesas1) * 100 : 0.0;
      final saldo1 = receitas1 - despesas1;
      final saldo2 = receitas2 - despesas2;
      final variacaoSaldo = saldo1 != 0 ? ((saldo2 - saldo1) / saldo1.abs()) * 100 : 0.0;

      return {
        'periodo1': {
          'receitas': receitas1,
          'despesas': despesas1,
          'saldo': saldo1,
          'transacoes': transacoesPeriodo1.length,
        },
        'periodo2': {
          'receitas': receitas2,
          'despesas': despesas2,
          'saldo': saldo2,
          'transacoes': transacoesPeriodo2.length,
        },
        'variacoes': {
          'receitas': variacaoReceitas,
          'despesas': variacaoDespesas,
          'saldo': variacaoSaldo,
          'transacoes': transacoesPeriodo2.length - transacoesPeriodo1.length,
        },
      };
    } catch (e) {
      log('❌ Erro ao gerar comparativo de períodos: $e');
      return {};
    }
  }
}