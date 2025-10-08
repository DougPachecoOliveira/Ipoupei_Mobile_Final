// 📊 Resumo Financeiro Service - iPoupei Mobile
//
// Serviço para carregar dados do resumo financeiro
// Agrega dados de contas, transações e cartões
//
// Baseado em: RelatorioService + ContaService + TransacaoService

import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../models/resumo_financeiro_model.dart';

class ResumoFinanceiroService {
  static ResumoFinanceiroService? _instance;
  static ResumoFinanceiroService get instance => _instance ??= ResumoFinanceiroService._();
  ResumoFinanceiroService._();

  final LocalDatabase _db = LocalDatabase.instance;

  /// 📊 Carregar resumo financeiro para um período
  Future<ResumoFinanceiroData> carregarResumo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('📊 Carregando resumo financeiro: ${dataInicio.toIso8601String()} - ${dataFim.toIso8601String()}');

      // 1. Saldo atual das contas
      final saldoContas = await _calcularSaldoContas(userId);

      // 2. Total de receitas no período
      final totalReceitas = await _calcularTotalReceitas(userId, dataInicio, dataFim);

      // 3. Total de despesas no período
      final totalDespesas = await _calcularTotalDespesas(userId, dataInicio, dataFim);

      // 4. Balanço de transferências no período
      final saldoTransferencias = await _calcularSaldoTransferencias(userId, dataInicio, dataFim);

      // 5. Total usado em cartões no período
      final totalCartoes = await _calcularTotalCartoes(userId, dataInicio, dataFim);

      debugPrint('📊 Resumo calculado: Contas=$saldoContas, Receitas=$totalReceitas, Despesas=$totalDespesas, Transferências=$saldoTransferencias, Cartões=$totalCartoes');

      return ResumoFinanceiroData.fromServiceData(
        saldoContas: saldoContas,
        totalReceitas: totalReceitas,
        totalDespesas: totalDespesas,
        saldoTransferencias: saldoTransferencias,
        totalCartoes: totalCartoes,
      );

    } catch (e) {
      debugPrint('❌ Erro ao carregar resumo financeiro: $e');
      rethrow;
    }
  }

  /// 💰 Calcular saldo atual das contas (usando mesmo método do ContaService)
  Future<double> _calcularSaldoContas(String userId) async {
    try {
      // ✅ Usar método correto que aplica filtro 'incluir_soma_total'
      await _db.setCurrentUser(userId);
      return await _db.calcularSaldoTotalLocal();
    } catch (e) {
      debugPrint('❌ Erro ao calcular saldo das contas: $e');
      return 0.0;
    }
  }

  /// 📈 Calcular total de receitas no período (IGUAL REACT)
  Future<double> _calcularTotalReceitas(String userId, DateTime inicio, DateTime fim) async {
    try {
      // 1️⃣ TRANSAÇÕES DE CARTÃO (usar fatura_vencimento)
      final resultCartao = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ? AND cartao_id IS NOT NULL AND efetivado = ? AND DATE(fatura_vencimento) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, 'receita', 1, inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );

      // 2️⃣ TRANSAÇÕES NORMAIS (usar data, EXCLUIR transferências)
      final resultNormais = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ? AND cartao_id IS NULL AND efetivado = ? AND (transferencia IS NULL OR transferencia = 0 OR transferencia = ?) AND DATE(data) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, 'receita', 1, 0, inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );

      // 3️⃣ SOMAR TUDO (receitas efetivadas = já recebidas)
      double totalReceitas = 0.0;

      for (final row in resultCartao) {
        totalReceitas += (row['valor'] as num?)?.toDouble() ?? 0.0;
      }

      for (final row in resultNormais) {
        totalReceitas += (row['valor'] as num?)?.toDouble() ?? 0.0;
      }

      debugPrint('📈 Receitas calculadas: Cartão=${resultCartao.length}, Normais=${resultNormais.length}, Total=R\$${totalReceitas.toStringAsFixed(2)}');

      return totalReceitas;
    } catch (e) {
      debugPrint('❌ Erro ao calcular total de receitas: $e');
      return 0.0;
    }
  }

  /// 📉 Calcular total de despesas no período (IGUAL REACT - INCLUINDO CARTÕES)
  Future<double> _calcularTotalDespesas(String userId, DateTime inicio, DateTime fim) async {
    try {
      // 1️⃣ TRANSAÇÕES DE CARTÃO (usar fatura_vencimento)
      final resultCartao = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ? AND cartao_id IS NOT NULL AND efetivado = ? AND DATE(fatura_vencimento) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, 'despesa', 1, inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );

      // 2️⃣ TRANSAÇÕES NORMAIS (usar data, EXCLUIR transferências)
      final resultNormais = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ? AND cartao_id IS NULL AND efetivado = ? AND (transferencia IS NULL OR transferencia = 0 OR transferencia = ?) AND DATE(data) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, 'despesa', 1, 0, inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );

      // 3️⃣ SOMAR TUDO (despesas efetivadas = já gastas, INCLUINDO CARTÕES)
      double totalDespesas = 0.0;

      for (final row in resultCartao) {
        totalDespesas += (row['valor'] as num?)?.toDouble() ?? 0.0;
      }

      for (final row in resultNormais) {
        totalDespesas += (row['valor'] as num?)?.toDouble() ?? 0.0;
      }

      debugPrint('📉 Despesas calculadas: Cartão=${resultCartao.length}, Normais=${resultNormais.length}, Total=R\$${totalDespesas.toStringAsFixed(2)}');

      return totalDespesas;
    } catch (e) {
      debugPrint('❌ Erro ao calcular total de despesas: $e');
      return 0.0;
    }
  }

  /// 🔄 Calcular balanço de transferências no período
  Future<double> _calcularSaldoTransferencias(String userId, DateTime inicio, DateTime fim) async {
    try {
      // Por enquanto retorna 0, mas pode ser implementado depois
      // quando tivermos transferências entre contas
      return 0.0;
    } catch (e) {
      debugPrint('❌ Erro ao calcular saldo de transferências: $e');
      return 0.0;
    }
  }

  /// 💳 Calcular total em cartões (TODAS as despesas de cartão - PAGAS + PENDENTES)
  Future<double> _calcularTotalCartoes(String userId, DateTime inicio, DateTime fim) async {
    try {
      // ✅ TODAS as despesas de cartão (efetivado = true E false)
      final result = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ? AND cartao_id IS NOT NULL AND DATE(fatura_vencimento) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, 'despesa', inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );

      double totalCartoes = 0.0;
      int pagas = 0;
      int pendentes = 0;

      for (final row in result) {
        final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;
        totalCartoes += valor;

        // Contabilizar para debug
        final efetivado = (row['efetivado'] as int?) == 1;
        if (efetivado) {
          pagas++;
        } else {
          pendentes++;
        }
      }

      debugPrint('💳 Cartões TOTAL: ${result.length} transações (${pagas} pagas + ${pendentes} pendentes), Total=R\$${totalCartoes.toStringAsFixed(2)}');

      return totalCartoes;
    } catch (e) {
      debugPrint('❌ Erro ao calcular total de cartões: $e');
      return 0.0;
    }
  }
}