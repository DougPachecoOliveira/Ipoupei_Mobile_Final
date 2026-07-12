import 'dart:developer';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fatura_model.dart';
import '../services/cartao_service.dart';
import '../../../database/local_database.dart';
import '../../../sync/sync_manager.dart';
import '../../../auth_integration.dart';
import '../../transacoes/models/transacao_model.dart';

class FaturaService {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;
  final SyncManager _syncManager = SyncManager.instance;
  final CartaoService _cartaoService = CartaoService.instance;
  static const Uuid _uuid = Uuid();

  /// ✅ 1. GERAR FATURA AUTOMÁTICA
  Future<FaturaModel> gerarFatura({
    required String cartaoId,
    required int ano,
    required int mes,
  }) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não logado');

      // ✅ VERIFICAR SE FATURA JÁ EXISTE
      final faturaExistente = await buscarFaturaPorPeriodo(cartaoId, ano, mes);
      if (faturaExistente != null) {
        return faturaExistente;
      }

      // ✅ BUSCAR CARTÃO
      final cartao = await _cartaoService.buscarCartaoPorId(cartaoId);
      if (cartao == null) throw Exception('Cartão não encontrado');

      // ✅ CALCULAR DATAS DA FATURA
      final dataFechamento = DateTime(ano, mes, cartao.diaFechamento);
      final dataVencimento = DateTime(ano, mes, cartao.diaVencimento);

      // ✅ AJUSTAR VENCIMENTO SE ANTES DO FECHAMENTO
      DateTime dataVencimentoFinal = dataVencimento;
      if (dataVencimento.isBefore(dataFechamento) || dataVencimento.isAtSameMomentAs(dataFechamento)) {
        dataVencimentoFinal = DateTime(ano, mes + 1, cartao.diaVencimento);
      }

      // ✅ CALCULAR VALOR TOTAL DAS DESPESAS
      final valorTotal = await _calcularValorFatura(cartaoId, dataFechamento);
      final valorMinimo = valorTotal * 0.15; // 15% do valor total

      final agora = DateTime.now();
      final faturaData = {
        'id': _uuid.v4(),
        'cartao_id': cartaoId,
        'usuario_id': userId,
        'ano': ano,
        'mes': mes,
        'data_fechamento': dataFechamento.toIso8601String().split('T')[0],
        'data_vencimento': dataVencimentoFinal.toIso8601String().split('T')[0],
        'valor_total': valorTotal,
        'valor_pago': 0.0,
        'valor_minimo': valorMinimo,
        'status': valorTotal > 0 ? 'fechada' : 'aberta',
        'paga': false, // ✅ CORRIGIDO: boolean como no React
        'data_pagamento': null,
        'observacoes': null,
        'created_at': agora.toIso8601String(),
        'updated_at': agora.toIso8601String(),
        'sincronizado': 0, // false
      };

      // ✅ SALVAR NO SQLITE
      await _localDb.database?.insert('faturas', faturaData);
      await _localDb.addToSyncQueue('faturas', faturaData['id'] as String, 'insert', faturaData);

      final fatura = FaturaModel.fromJson(faturaData);
      log('✅ Fatura gerada: ${fatura.periodoFormatado} - ${fatura.valorTotalFormatado}');
      
      return fatura;
    } catch (e) {
      log('❌ Erro ao gerar fatura: $e');
      rethrow;
    }
  }

  /// ✅ 2. BUSCAR FATURA POR PERÍODO
  Future<FaturaModel?> buscarFaturaPorPeriodo(String cartaoId, int ano, int mes) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return null;

      final result = await _localDb.database?.query(
        'faturas',
        where: 'cartao_id = ? AND usuario_id = ? AND ano = ? AND mes = ?',
        whereArgs: [cartaoId, userId, ano, mes],
        limit: 1,
      ) ?? [];

      if (result.isEmpty) return null;
      
      return FaturaModel.fromJson(result.first);
    } catch (e) {
      log('❌ Erro ao buscar fatura: $e');
      return null;
    }
  }

  /// ✅ 3. LISTAR FATURAS DO CARTÃO
  Future<List<FaturaModel>> listarFaturasCartao(String cartaoId, {int? limite}) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'faturas',
        where: 'cartao_id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
        orderBy: 'ano DESC, mes DESC',
        limit: limite,
      ) ?? [];

      return result.map((data) => FaturaModel.fromJson(data)).toList();
    } catch (e) {
      log('❌ Erro ao listar faturas: $e');
      return [];
    }
  }

  /// ✅ 4. LISTAR FATURAS VENCIDAS
  Future<List<FaturaModel>> listarFaturasVencidas() async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final hoje = DateTime.now().toIso8601String().split('T')[0];

      final result = await _localDb.database?.query(
        'faturas',
        where: 'usuario_id = ? AND paga = 0 AND data_vencimento < ?',
        whereArgs: [userId, hoje],
        orderBy: 'data_vencimento ASC',
      ) ?? [];

      return result.map((data) => FaturaModel.fromJson(data)).toList();
    } catch (e) {
      log('❌ Erro ao listar faturas vencidas: $e');
      return [];
    }
  }

  /// ✅ 5. LISTAR FATURAS PRÓXIMAS DO VENCIMENTO
  Future<List<FaturaModel>> listarFaturasProximasVencimento({int dias = 5}) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final hoje = DateTime.now();
      final limite = hoje.add(Duration(days: dias));

      final result = await _localDb.database?.query(
        'faturas',
        where: 'usuario_id = ? AND paga = 0 AND data_vencimento >= ? AND data_vencimento <= ?',
        whereArgs: [
          userId, 
          hoje.toIso8601String().split('T')[0], 
          limite.toIso8601String().split('T')[0],
        ],
        orderBy: 'data_vencimento ASC',
      ) ?? [];

      return result.map((data) => FaturaModel.fromJson(data)).toList();
    } catch (e) {
      log('❌ Erro ao listar faturas próximas: $e');
      return [];
    }
  }

  /// ✅ 10. RECALCULAR VALOR DA FATURA
  Future<bool> recalcularFatura(String faturaId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      final fatura = await buscarFaturaPorId(faturaId);
      if (fatura == null) throw Exception('Fatura não encontrada');

      // ✅ RECALCULAR VALOR BASEADO NAS DESPESAS
      final novoValorTotal = await _calcularValorFatura(
        fatura.cartaoId, 
        fatura.dataFechamento,
      );

      final novoValorMinimo = novoValorTotal * 0.15;

      await _localDb.database?.update(
        'faturas',
        {
          'valor_total': novoValorTotal,
          'valor_minimo': novoValorMinimo,
          'updated_at': DateTime.now().toIso8601String(),
          'sincronizado': 0, // false
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [faturaId, userId],
      );

      await _localDb.addToSyncQueue('faturas', faturaId, 'update', {});
      log('✅ Fatura recalculada: R\$ ${novoValorTotal.toStringAsFixed(2)}');
      
      return true;
    } catch (e) {
      log('❌ Erro ao recalcular fatura: $e');
      return false;
    }
  }

  /// ✅ 11. BUSCAR FATURA POR ID
  Future<FaturaModel?> buscarFaturaPorId(String faturaId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return null;

      final result = await _localDb.database?.query(
        'faturas',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [faturaId, userId],
        limit: 1,
      ) ?? [];

      if (result.isEmpty) return null;
      
      return FaturaModel.fromJson(result.first);
    } catch (e) {
      log('❌ Erro ao buscar fatura por ID: $e');
      return null;
    }
  }

  /// ✅ 12. LISTAR DESPESAS DA FATURA
  Future<List<TransacaoModel>> listarDespesasFatura(String cartaoId, DateTime dataFechamento) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      // ✅ BUSCAR DESPESAS ATÉ A DATA DE FECHAMENTO
      final result = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND is_cartao_credito = 1 AND (observacoes LIKE ? OR observacoes LIKE ?) AND data <= ?',
        whereArgs: [
          userId, 
          '%$cartaoId%', 
          '%cartao:$cartaoId%', 
          dataFechamento.toIso8601String().split('T')[0],
        ],
        orderBy: 'data DESC',
      ) ?? [];

      return result.map((data) => TransacaoModel.fromJson(data)).toList();
    } catch (e) {
      log('❌ Erro ao listar despesas da fatura: $e');
      return [];
    }
  }

  /// ✅ MÉTODO AUXILIAR - CALCULAR VALOR TOTAL DA FATURA
  Future<double> _calcularValorFatura(String cartaoId, DateTime dataLimite) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return 0.0;

      final result = await _localDb.database?.rawQuery(
        '''
        SELECT SUM(valor) as total 
        FROM transacoes 
        WHERE usuario_id = ? 
          AND is_cartao_credito = 1 
          AND (observacoes LIKE ? OR observacoes LIKE ?)
          AND data <= ?
        ''',
        [
          userId, 
          '%$cartaoId%', 
          '%cartao:$cartaoId%', 
          dataLimite.toIso8601String().split('T')[0],
        ],
      ) ?? [];

      if (result.isEmpty || result.first['total'] == null) return 0.0;
      
      return (result.first['total'] as num).toDouble();
    } catch (e) {
      log('❌ Erro ao calcular valor da fatura: $e');
      return 0.0;
    }
  }

  /// ✅ 13. RELATÓRIO DE FATURAS
  Future<Map<String, dynamic>> gerarRelatorioFaturas({
    String? cartaoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return {};

      String where = 'usuario_id = ?';
      List<dynamic> whereArgs = [userId];

      if (cartaoId != null) {
        where += ' AND cartao_id = ?';
        whereArgs.add(cartaoId);
      }

      if (dataInicio != null) {
        where += ' AND data_vencimento >= ?';
        whereArgs.add(dataInicio.toIso8601String().split('T')[0]);
      }

      if (dataFim != null) {
        where += ' AND data_vencimento <= ?';
        whereArgs.add(dataFim.toIso8601String().split('T')[0]);
      }

      final faturas = await _localDb.database?.query(
        'faturas',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'data_vencimento DESC',
      ) ?? [];

      final faturasList = faturas.map((data) => FaturaModel.fromJson(data)).toList();
      
      // ✅ CALCULAR ESTATÍSTICAS
      final totalFaturas = faturasList.length;
      final faturasPagas = faturasList.where((f) => f.paga).length;
      final faturasVencidas = faturasList.where((f) => f.isVencida).length;
      final valorTotalGasto = faturasList.fold<double>(0, (sum, f) => sum + f.valorTotal);
      final valorTotalPago = faturasList.fold<double>(0, (sum, f) => sum + f.valorPago);
      final valorTotalDevedor = valorTotalGasto - valorTotalPago;

      return {
        'faturas': faturasList,
        'estatisticas': {
          'total_faturas': totalFaturas,
          'faturas_pagas': faturasPagas,
          'faturas_vencidas': faturasVencidas,
          'percentual_pagamento': totalFaturas > 0 ? (faturasPagas / totalFaturas * 100) : 0,
          'valor_total_gasto': valorTotalGasto,
          'valor_total_pago': valorTotalPago,
          'valor_total_devedor': valorTotalDevedor,
        },
      };
    } catch (e) {
      log('❌ Erro ao gerar relatório: $e');
      return {};
    }
  }

  /// ✅ 14. SINCRONIZAR FATURAS
  Future<bool> sincronizarFaturas() async {
    try {
      final isOnline = _syncManager.isOnline;
      if (!isOnline) {
        log('📡 Offline - sincronização de faturas adiada');
        return false;
      }

      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      // ✅ SYNC CHANGES PRIMEIRO
      await _syncManager.syncAll();

      // ✅ BAIXAR FATURAS DO SUPABASE
      final faturasSupabase = await Supabase.instance.client
          .from('faturas')
          .select()
          .eq('usuario_id', userId)
          .order('created_at');

      // ✅ ATUALIZAR DADOS LOCAIS
      for (final faturaData in faturasSupabase) {
        final faturaLocal = await buscarFaturaPorId(faturaData['id']);
        
        if (faturaLocal == null) {
          // ✅ FATURA NOVA - INSERIR
          await _localDb.database?.insert('faturas', {
            ...faturaData,
            'paga': faturaData['paga'] ? 1 : 0,
            'sincronizado': 1, // true
          });
        } else if (!faturaLocal.sincronizado) {
          // ✅ FATURA DESATUALIZADA - ATUALIZAR
          await _localDb.database?.update(
            'faturas',
            {
              ...faturaData,
              'paga': faturaData['paga'] ? 1 : 0,
              'sincronizado': 1, // true
            },
            where: 'id = ?',
            whereArgs: [faturaData['id']],
          );
        }
      }

      log('✅ Sincronização de faturas concluída');
      return true;
    } catch (e) {
      log('❌ Erro na sincronização de faturas: $e');
      return false;
    }
  }
}
