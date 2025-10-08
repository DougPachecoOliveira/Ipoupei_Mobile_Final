// 💳 Pagamento Fatura Service - iPoupei Mobile
//
// Implementa o pagamento de faturas IGUAL ao React
// Muda efetivado = false → true nas transações
//
// Baseado em: useFaturaOperations.js (linha 184)

import 'dart:async';
import 'dart:developer';
import '../models/fatura_model.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';
import '../../../sync/sync_manager.dart';
import '../../../shared/services/contas_refresh_notifier.dart';

class PagamentoFaturaService {
  static final PagamentoFaturaService _instance = PagamentoFaturaService._internal();
  static PagamentoFaturaService get instance => _instance;
  PagamentoFaturaService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;
  final SyncManager _syncManager = SyncManager.instance;

  /// ✅ PAGAR FATURA COMPLETA (IGUAL REACT)
  /// Marca efetivado = true em todas transações da fatura
  Future<Map<String, dynamic>> pagarFaturaCompleta({
    required String cartaoId,
    required String faturaVencimento,
    required double valorPago,
    required DateTime dataPagamento,
    String? contaId,
  }) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não logado'};
      }

      log('💳 Pagando fatura: $cartaoId - Vencimento: $faturaVencimento');

      // ✅ LÓGICA IGUAL REACT: Atualizar transações para efetivado = true
      final result = await _localDb.database?.rawQuery(
        '''
        UPDATE transacoes
        SET
          efetivado = 1,
          data_efetivacao = ?,
          conta_id = ?,
          updated_at = ?
        WHERE usuario_id = ?
          AND cartao_id = ?
          AND fatura_vencimento = ?
          AND efetivado = 0
        ''',
        [
          dataPagamento.toIso8601String(),
          contaId,
          DateTime.now().toIso8601String(),
          userId,
          cartaoId,
          faturaVencimento,
        ],
      );

      // Contar transações afetadas
      final transacoesAfetadas = await _contarTransacoesAfetadas(cartaoId, faturaVencimento, userId);

      // 🏦 Aplica DELTA no saldo LOCAL da conta (método correto offline!)
      // Pagar fatura = despesa, então saldo diminui
      if (contaId != null) {
        await _localDb.aplicarDeltaSaldo(contaId, -valorPago);
      }

      // Adicionar à fila de sincronização
      await _adicionarSyncFila(cartaoId, faturaVencimento, userId);

      // 🔔 Notifica páginas de contas (usuário vê atualização imediata)
      ContasRefreshNotifier.instance.notificarMudancaContas();

      // ⚡ FORÇA SYNC IMEDIATO (se online) para evitar sobrescrita pelo sync periódico
      if (_syncManager.isOnline) {
        _syncManager.syncAll();
      }

      log('✅ Fatura paga: $transacoesAfetadas transações efetivadas');

      return {
        'success': true,
        'transacoes_afetadas': transacoesAfetadas,
        'valor_efetivado': valorPago,
        'conta_utilizada_id': contaId,
        'message': 'Fatura paga com sucesso. $transacoesAfetadas transações efetivadas.',
      };

    } catch (e) {
      log('❌ Erro ao pagar fatura: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ✅ REABRIR FATURA (REVERTER PAGAMENTO)
  /// Marca efetivado = true → false
  Future<Map<String, dynamic>> reabrirFatura({
    required String cartaoId,
    required String faturaVencimento,
  }) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não logado'};
      }

      log('🔄 Reabrindo fatura: $cartaoId - Vencimento: $faturaVencimento');

      // ⚡ Buscar conta_id(s) e valores ANTES de atualizar (para calcular deltas)
      final contasValores = await _localDb.database?.rawQuery(
        '''
        SELECT conta_id, SUM(valor) as total_valor
        FROM transacoes
        WHERE usuario_id = ?
          AND cartao_id = ?
          AND fatura_vencimento = ?
          AND efetivado = 1
          AND conta_id IS NOT NULL
        GROUP BY conta_id
        ''',
        [userId, cartaoId, faturaVencimento],
      );

      // ✅ LÓGICA IGUAL REACT: Reverter efetivação
      await _localDb.database?.rawQuery(
        '''
        UPDATE transacoes
        SET
          efetivado = 0,
          data_efetivacao = NULL,
          conta_id = NULL,
          updated_at = ?
        WHERE usuario_id = ?
          AND cartao_id = ?
          AND fatura_vencimento = ?
          AND efetivado = 1
        ''',
        [
          DateTime.now().toIso8601String(),
          userId,
          cartaoId,
          faturaVencimento,
        ],
      );

      // Contar transações afetadas
      final transacoesAfetadas = await _contarTransacoesAfetadas(cartaoId, faturaVencimento, userId, efetivado: false);

      // 🏦 Aplica DELTA REVERSO no saldo LOCAL das contas afetadas (método correto offline!)
      // Reabrir fatura = reverter despesa, então saldo aumenta
      if (contasValores != null && contasValores.isNotEmpty) {
        for (final row in contasValores) {
          final contaId = row['conta_id'] as String?;
          final valorTotal = (row['total_valor'] as num?)?.toDouble();
          if (contaId != null && valorTotal != null) {
            await _localDb.aplicarDeltaSaldo(contaId, valorTotal); // Positivo = recupera o dinheiro
          }
        }
      }

      await _adicionarSyncFila(cartaoId, faturaVencimento, userId);

      // 🔔 Notifica páginas de contas (usuário vê atualização imediata)
      ContasRefreshNotifier.instance.notificarMudancaContas();

      // ⚡ FORÇA SYNC IMEDIATO (se online) para evitar sobrescrita pelo sync periódico
      if (_syncManager.isOnline) {
        _syncManager.syncAll();
      }

      log('✅ Fatura reaberta: $transacoesAfetadas transações marcadas como pendentes');

      return {
        'success': true,
        'transacoes_afetadas': transacoesAfetadas,
        'message': 'Fatura reaberta com sucesso. $transacoesAfetadas transações marcadas como pendentes.',
      };

    } catch (e) {
      log('❌ Erro ao reabrir fatura: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ✅ CONTAR TRANSAÇÕES AFETADAS
  Future<int> _contarTransacoesAfetadas(String cartaoId, String faturaVencimento, String userId, {bool efetivado = true}) async {
    try {
      final result = await _localDb.database?.rawQuery(
        '''
        SELECT COUNT(*) as total
        FROM transacoes 
        WHERE usuario_id = ? 
          AND cartao_id = ? 
          AND fatura_vencimento = ?
          AND efetivado = ?
        ''',
        [userId, cartaoId, faturaVencimento, efetivado ? 1 : 0],
      );

      if (result != null && result.isNotEmpty) {
        return (result.first['total'] as int?) ?? 0;
      }
      return 0;

    } catch (e) {
      log('❌ Erro ao contar transações: $e');
      return 0;
    }
  }

  /// ✅ ADICIONAR À FILA DE SINCRONIZAÇÃO
  Future<void> _adicionarSyncFila(String cartaoId, String faturaVencimento, String userId) async {
    try {
      // Buscar todas as transações da fatura para adicionar à sync queue
      final transacoes = await _localDb.database?.query(
        'transacoes',
        columns: ['id'],
        where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ?',
        whereArgs: [userId, cartaoId, faturaVencimento],
      );

      if (transacoes != null) {
        for (final transacao in transacoes) {
          await _localDb.addToSyncQueue(
            'transacoes', 
            transacao['id'] as String, 
            'UPDATE', 
            {}
          );
        }
      }

    } catch (e) {
      log('❌ Erro ao adicionar à fila de sync: $e');
    }
  }

  /// ✅ BUSCAR DETALHES DA FATURA PARA PAGAMENTO
  Future<Map<String, dynamic>> obterDetalhesFatura(String cartaoId, String faturaVencimento) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return {};

      final result = await _localDb.database?.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_transacoes,
          SUM(valor) as valor_total,
          MIN(data) as primeira_transacao,
          MAX(data) as ultima_transacao
        FROM transacoes 
        WHERE usuario_id = ? 
          AND cartao_id = ? 
          AND fatura_vencimento = ?
          AND efetivado = 0
        ''',
        [userId, cartaoId, faturaVencimento],
      );

      if (result != null && result.isNotEmpty) {
        final dados = result.first;
        return {
          'total_transacoes': dados['total_transacoes'] ?? 0,
          'valor_total': (dados['valor_total'] as num?)?.toDouble() ?? 0.0,
          'primeira_transacao': dados['primeira_transacao'],
          'ultima_transacao': dados['ultima_transacao'],
          'valor_minimo': ((dados['valor_total'] as num?)?.toDouble() ?? 0.0) * 0.15,
        };
      }

      return {};

    } catch (e) {
      log('❌ Erro ao obter detalhes da fatura: $e');
      return {};
    }
  }

  /// ✅ LISTAR TRANSAÇÕES DA FATURA
  Future<List<Map<String, dynamic>>> listarTransacoesFatura(String cartaoId, String faturaVencimento) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ?',
        whereArgs: [userId, cartaoId, faturaVencimento],
        orderBy: 'data DESC',
      ) ?? [];

      return result;

    } catch (e) {
      log('❌ Erro ao listar transações da fatura: $e');
      return [];
    }
  }

  /// ✅ VERIFICAR SE FATURA PODE SER PAGA
  Future<bool> podeSerPaga(String cartaoId, String faturaVencimento) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      final result = await _localDb.database?.rawQuery(
        '''
        SELECT COUNT(*) as pendentes
        FROM transacoes 
        WHERE usuario_id = ? 
          AND cartao_id = ? 
          AND fatura_vencimento = ?
          AND efetivado = 0
        ''',
        [userId, cartaoId, faturaVencimento],
      );

      if (result != null && result.isNotEmpty) {
        final pendentes = (result.first['pendentes'] as int?) ?? 0;
        return pendentes > 0;
      }

      return false;

    } catch (e) {
      log('❌ Erro ao verificar se pode ser paga: $e');
      return false;
    }
  }
}