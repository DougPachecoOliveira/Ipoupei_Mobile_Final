// 📊 Gráficos Categoria Service - iPoupei Mobile
//
// Serviço para buscar dados dos gráficos de categoria
// Busca despesas e receitas agrupadas por categoria
//
// Baseado em: LocalDatabase queries + gestão de cartões

import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';

class GraficosCategoriaService {
  static GraficosCategoriaService? _instance;
  static GraficosCategoriaService get instance => _instance ??= GraficosCategoriaService._();
  GraficosCategoriaService._();

  final LocalDatabase _db = LocalDatabase.instance;

  /// 📊 Buscar despesas agrupadas por categoria
  Future<List<Map<String, dynamic>>> buscarDespesasPorCategoria(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('📊 Buscando despesas por categoria: ${dataInicio.toIso8601String()} - ${dataFim.toIso8601String()}');

      final database = _db.database;
      if (database == null) return [];

      final result = await database.rawQuery('''
        SELECT
          c.nome as categoria,
          COUNT(t.id) as total_transacoes,
          SUM(t.valor) as total_valor
        FROM transacoes t
        INNER JOIN categorias c ON t.categoria_id = c.id
        WHERE t.usuario_id = ?
          AND t.tipo = ?
          AND DATE(t.data) BETWEEN DATE(?) AND DATE(?)
          AND c.ativo = 1
          AND c.tipo = ?
          AND (t.transferencia IS NULL OR t.transferencia = 0)
        GROUP BY c.id, c.nome
        ORDER BY total_valor DESC
        LIMIT 10
      ''', [
        userId,
        'despesa',
        dataInicio.toIso8601String().split('T')[0],
        dataFim.toIso8601String().split('T')[0],
        'despesa'
      ]);

      final dados = result.map((row) {
        return {
          'categoria': row['categoria'] as String,
          'total_transacoes': row['total_transacoes'] as int,
          'total_valor': (row['total_valor'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();

      // ✅ CORREÇÃO ANTI-REGRESSÃO: NÃO filtrar categorias com valor zero
      // Categorias zeradas são informação valiosa para análise
      // REMOVIDO: .where((item) => (item['total_valor'] as double) > 0)

      debugPrint('📊 Encontradas ${dados.length} categorias de despesas');
      for (final item in dados.take(5)) {
        debugPrint('  • ${item['categoria']}: ${item['total_transacoes']} transações = R\$ ${(item['total_valor'] as double).toStringAsFixed(2)}');
      }

      return dados;
    } catch (e) {
      debugPrint('❌ Erro ao buscar despesas por categoria: $e');
      return [];
    }
  }

  /// 📈 Buscar receitas agrupadas por categoria
  Future<List<Map<String, dynamic>>> buscarReceitasPorCategoria(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('📈 Buscando receitas por categoria: ${dataInicio.toIso8601String()} - ${dataFim.toIso8601String()}');

      final database = _db.database;
      if (database == null) return [];

      final result = await database.rawQuery('''
        SELECT
          c.nome as categoria,
          COUNT(t.id) as total_transacoes,
          SUM(t.valor) as total_valor
        FROM transacoes t
        INNER JOIN categorias c ON t.categoria_id = c.id
        WHERE t.usuario_id = ?
          AND t.tipo = ?
          AND DATE(t.data) BETWEEN DATE(?) AND DATE(?)
          AND c.ativo = 1
          AND c.tipo = ?
          AND (t.transferencia IS NULL OR t.transferencia = 0)
        GROUP BY c.id, c.nome
        ORDER BY total_valor DESC
        LIMIT 10
      ''', [
        userId,
        'receita',
        dataInicio.toIso8601String().split('T')[0],
        dataFim.toIso8601String().split('T')[0],
        'receita'
      ]);

      final dados = result.map((row) {
        return {
          'categoria': row['categoria'] as String,
          'total_transacoes': row['total_transacoes'] as int,
          'total_valor': (row['total_valor'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();

      // ✅ CORREÇÃO ANTI-REGRESSÃO: NÃO filtrar categorias com valor zero
      // Categorias zeradas são informação valiosa para análise
      // REMOVIDO: .where((item) => (item['total_valor'] as double) > 0)

      debugPrint('📈 Encontradas ${dados.length} categorias de receitas');
      for (final item in dados.take(5)) {
        debugPrint('  • ${item['categoria']}: ${item['total_transacoes']} transações = R\$ ${(item['total_valor'] as double).toStringAsFixed(2)}');
      }

      return dados;
    } catch (e) {
      debugPrint('❌ Erro ao buscar receitas por categoria: $e');
      return [];
    }
  }
}