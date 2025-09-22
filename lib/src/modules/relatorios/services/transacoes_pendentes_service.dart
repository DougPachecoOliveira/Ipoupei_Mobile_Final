// 📌 Transações Pendentes Service - iPoupei Mobile
//
// Serviço para detectar transações vencidas e não efetivadas
// Inclui dados da categoria para exibição visual
//
// Critérios: efetivado = 0 AND data < hoje (apenas transações vencidas)

import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../models/transacao_pendente_model.dart';

class TransacoesPendentesService {
  static TransacoesPendentesService? _instance;
  static TransacoesPendentesService get instance => _instance ??= TransacoesPendentesService._();
  TransacoesPendentesService._();

  final LocalDatabase _db = LocalDatabase.instance;

  /// 📌 Buscar transações pendentes vencidas
  /// Retorna apenas transações não efetivadas com data < hoje
  /// Busca no ano todo para pegar todas as pendências
  Future<List<TransacaoPendente>> buscarTransacoesPendentes() async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ Usuário não autenticado para buscar transações pendentes');
        return [];
      }

      final hoje = DateTime.now();

      debugPrint('📌 Buscando transações pendentes vencidas para usuário: $userId');

      // Query com JOIN para pegar dados da categoria
      final result = await _db.rawQuery('''
        SELECT
          t.id,
          t.descricao,
          t.valor,
          t.data,
          t.tipo,
          t.categoria_id,
          c.nome as categoria_nome,
          c.cor as categoria_cor,
          c.icone as categoria_icone
        FROM transacoes t
        LEFT JOIN categorias c ON t.categoria_id = c.id
        WHERE t.usuario_id = ?
          AND t.efetivado = 0
          AND DATE(t.data) < DATE(?)
      ''', [userId, hoje.toIso8601String().split('T')[0]]);

      debugPrint('📌 Transações pendentes encontradas: ${result.length}');

      final transacoesPendentes = <TransacaoPendente>[];

      for (final transacaoData in result) {
        try {
          final transacao = TransacaoPendente.fromMap(transacaoData);
          transacoesPendentes.add(transacao);

          debugPrint('📌 Transação pendente: ${transacao.descricao} - ${transacao.textoAtraso} - ${transacao.valor}');
        } catch (e) {
          debugPrint('❌ Erro ao processar transação ${transacaoData['id']}: $e');
        }
      }

      // Filtrar novamente para garantir que só vencidas passem (dupla verificação)
      final transacoesFiltradas = transacoesPendentes.apenasVencidas;

      // Ordenar por data (mais antigas primeiro = mais críticas)
      final transacoesOrdenadas = transacoesFiltradas.ordenadasPorData;

      debugPrint('📌 Total de transações pendentes vencidas: ${transacoesOrdenadas.length}');

      if (transacoesOrdenadas.isNotEmpty) {
        debugPrint('📌 Resumo:');
        debugPrint('   - Receitas pendentes: ${transacoesOrdenadas.quantidadePorTipo('receita')}');
        debugPrint('   - Despesas pendentes: ${transacoesOrdenadas.quantidadePorTipo('despesa')}');
        debugPrint('   - Valor total: ${transacoesOrdenadas.valorTotal}');
        debugPrint('   - Transações críticas (>7 dias): ${transacoesOrdenadas.apenasCriticas.length}');
      }

      return transacoesOrdenadas;

    } catch (e) {
      debugPrint('❌ Erro ao buscar transações pendentes: $e');
      return [];
    }
  }

  /// 📊 Obter resumo agrupado por data
  Future<ResumoTransacoesPendentes> obterResumoAgrupado() async {
    try {
      final transacoes = await buscarTransacoesPendentes();
      return transacoes.agrupadoPorData;
    } catch (e) {
      debugPrint('❌ Erro ao obter resumo agrupado: $e');
      return ResumoTransacoesPendentes.fromTransacoes([]);
    }
  }

  /// 🔍 Buscar transações pendentes por categoria
  Future<List<TransacaoPendente>> buscarPorCategoria(String categoriaId) async {
    try {
      final todasTransacoes = await buscarTransacoesPendentes();
      return todasTransacoes.where((t) => t.categoriaId == categoriaId).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar transações pendentes por categoria: $e');
      return [];
    }
  }

  /// 🔍 Buscar transações pendentes por período específico
  Future<List<TransacaoPendente>> buscarPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) return [];

      final result = await _db.rawQuery('''
        SELECT
          t.id,
          t.descricao,
          t.valor,
          t.data,
          t.tipo,
          t.categoria_id,
          c.nome as categoria_nome,
          c.cor as categoria_cor,
          c.icone as categoria_icone
        FROM transacoes t
        LEFT JOIN categorias c ON t.categoria_id = c.id
        WHERE t.usuario_id = ?
          AND t.efetivado = 0
          AND DATE(t.data) BETWEEN DATE(?) AND DATE(?)
          AND DATE(t.data) < DATE(?)
      ''', [
        userId,
        dataInicio.toIso8601String().split('T')[0],
        dataFim.toIso8601String().split('T')[0],
        DateTime.now().toIso8601String().split('T')[0], // Apenas vencidas
      ]);

      return result
          .map((data) => TransacaoPendente.fromMap(data))
          .toList()
          .ordenadasPorData;

    } catch (e) {
      debugPrint('❌ Erro ao buscar transações pendentes por período: $e');
      return [];
    }
  }

  /// 📊 Obter estatísticas rápidas
  Future<Map<String, dynamic>> obterEstatisticas() async {
    try {
      final transacoes = await buscarTransacoesPendentes();
      final resumo = transacoes.agrupadoPorData;

      return {
        'total_transacoes': resumo.totalTransacoes,
        'total_dias_com_pendencias': resumo.totalDias,
        'valor_total': resumo.valorTotal,
        'transacoes_criticas': resumo.quantidadeCriticas,
        'tem_transacoes_pendentes': resumo.hasTransacoes,
        'tem_transacoes_criticas': resumo.hasTransacoesCriticas,
        'receitas_pendentes': transacoes.quantidadePorTipo('receita'),
        'despesas_pendentes': transacoes.quantidadePorTipo('despesa'),
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter estatísticas: $e');
      return {
        'total_transacoes': 0,
        'total_dias_com_pendencias': 0,
        'valor_total': 0.0,
        'transacoes_criticas': 0,
        'tem_transacoes_pendentes': false,
        'tem_transacoes_criticas': false,
        'receitas_pendentes': 0,
        'despesas_pendentes': 0,
      };
    }
  }

  /// ✅ Marcar transação como efetivada (resolver pendência)
  Future<void> marcarComoEfetivada(String transacaoId) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) return;

      await _db.update(
        'transacoes',
        {
          'efetivado': 1,
          'data_efetivacao': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [transacaoId, userId],
      );

      debugPrint('✅ Transação marcada como efetivada: $transacaoId');
    } catch (e) {
      debugPrint('❌ Erro ao marcar transação como efetivada: $e');
    }
  }

  /// ✅ Marcar múltiplas transações como efetivadas
  Future<void> marcarMultiplasComoEfetivadas(List<String> transacaoIds) async {
    try {
      for (final id in transacaoIds) {
        await marcarComoEfetivada(id);
      }
      debugPrint('✅ ${transacaoIds.length} transações marcadas como efetivadas');
    } catch (e) {
      debugPrint('❌ Erro ao marcar múltiplas transações: $e');
    }
  }

  /// 🗑️ Excluir transação pendente
  Future<void> excluirTransacaoPendente(String transacaoId) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) return;

      await _db.update(
        'transacoes',
        {
          'excluido': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [transacaoId, userId],
      );

      debugPrint('🗑️ Transação pendente excluída: $transacaoId');
    } catch (e) {
      debugPrint('❌ Erro ao excluir transação pendente: $e');
    }
  }

  /// 🧹 Limpar cache (para forçar nova busca)
  void limparCache() {
    debugPrint('🧹 Cache de transações pendentes limpo');
    // Por enquanto não temos cache, mas pode ser implementado depois
  }
}