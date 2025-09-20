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

  /// 💰 Calcular saldo atual das contas
  Future<double> _calcularSaldoContas(String userId) async {
    try {
      final result = await _db.select(
        'contas',
        where: 'usuario_id = ? AND ativo = 1',
        whereArgs: [userId],
      );
      
      double totalSaldo = 0.0;
      for (final row in result) {
        totalSaldo += (row['saldo_atual'] as num?)?.toDouble() ?? 0.0;
      }

      return totalSaldo;
    } catch (e) {
      debugPrint('❌ Erro ao calcular saldo das contas: $e');
      return 0.0;
    }
  }

  /// 📈 Calcular total de receitas no período
  Future<double> _calcularTotalReceitas(String userId, DateTime inicio, DateTime fim) async {
    try {
      final result = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ? AND DATE(data) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, 'receita', inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );
      
      double totalReceitas = 0.0;
      for (final row in result) {
        totalReceitas += (row['valor'] as num?)?.toDouble() ?? 0.0;
      }

      return totalReceitas;
    } catch (e) {
      debugPrint('❌ Erro ao calcular total de receitas: $e');
      return 0.0;
    }
  }

  /// 📉 Calcular total de despesas no período
  Future<double> _calcularTotalDespesas(String userId, DateTime inicio, DateTime fim) async {
    try {
      final result = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ? AND DATE(data) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, 'despesa', inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );
      
      double totalDespesas = 0.0;
      for (final row in result) {
        totalDespesas += (row['valor'] as num?)?.toDouble() ?? 0.0;
      }

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

  /// 💳 Calcular total usado em cartões no período
  Future<double> _calcularTotalCartoes(String userId, DateTime inicio, DateTime fim) async {
    try {
      final result = await _db.select(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id IS NOT NULL AND DATE(data) BETWEEN DATE(?) AND DATE(?)',
        whereArgs: [userId, inicio.toIso8601String().split('T')[0], fim.toIso8601String().split('T')[0]],
      );
      
      double totalCartoes = 0.0;
      for (final row in result) {
        totalCartoes += (row['valor'] as num?)?.toDouble() ?? 0.0;
      }

      return totalCartoes;
    } catch (e) {
      debugPrint('❌ Erro ao calcular total de cartões: $e');
      return 0.0;
    }
  }
}