// 💳 Faturas Pendentes Service - iPoupei Mobile (with debug)
//
// Serviço para detectar faturas de cartão vencidas ou próximas ao vencimento
// Critérios: Vencidas OU vencendo nos próximos 3 dias
//
// Integração: Local Database + Alertas críticos

import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../../cartoes/services/cartao_data_service.dart';
import '../models/fatura_pendente_model.dart';

class FaturasPendentesService {
  static FaturasPendentesService? _instance;
  static FaturasPendentesService get instance => _instance ??= FaturasPendentesService._();
  FaturasPendentesService._();

  final LocalDatabase _db = LocalDatabase.instance;

  /// 🚨 Buscar faturas pendentes críticas
  /// Retorna apenas faturas vencidas OU vencendo nos próximos 3 dias
  /// Usa o sistema de faturas real baseado em transações
  Future<List<FaturaPendente>> buscarFaturasPendentes({bool forceMostrar = false}) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ Usuário não autenticado para buscar faturas pendentes');
        return [];
      }

      debugPrint('💳 Buscando faturas pendentes para usuário: $userId');

      final hoje = DateTime.now();
      final hojeBase = DateTime(hoje.year, hoje.month, hoje.day);
      final dataLimite = hojeBase.add(const Duration(days: 3));
      final cartaoDataService = CartaoDataService.instance;

      // Buscar cartões ativos do usuário
      final cartoesResult = await _db.select(
        'cartoes',
        where: 'usuario_id = ? AND ativo = 1',
        whereArgs: [userId],
      );

      debugPrint('💳 Cartões ativos encontrados: ${cartoesResult.length}');

      final faturasPendentes = <FaturaPendente>[];

      for (final cartaoData in cartoesResult) {
        try {
          final cartaoId = cartaoData['id'] as String;
          final nomeCartao = cartaoData['nome'] as String? ?? 'Cartão';

          debugPrint('💳 🔍 Buscando transações por fatura_vencimento: $nomeCartao ($cartaoId)');

          final transacoesResult = await _db.select(
            'transacoes',
            where: '''
              usuario_id = ?
              AND cartao_id = ?
              AND fatura_vencimento IS NOT NULL
              AND DATE(fatura_vencimento) <= DATE(?)
            ''',
            whereArgs: [
              userId,
              cartaoId,
              dataLimite.toIso8601String().split('T')[0],
            ],
          );

          if (transacoesResult.isEmpty) {
            debugPrint('💳 ℹ️ Nenhuma transação encontrada para $nomeCartao');
            continue;
          }

          final Map<String, List<Map<String, dynamic>>> transacoesPorVencimento = {};

          for (final transacaoData in transacoesResult) {
            final faturaVencimentoStr =
                transacaoData['fatura_vencimento'] as String?;
            if (faturaVencimentoStr == null || faturaVencimentoStr.isEmpty) {
              continue;
            }
            final dataVencimento = DateTime.tryParse(faturaVencimentoStr);
            if (dataVencimento == null) {
              debugPrint(
                '⚠️ Fatura vencimento inválido: $faturaVencimentoStr',
              );
              continue;
            }

            final chave = dataVencimento.toIso8601String().split('T')[0];
            transacoesPorVencimento.putIfAbsent(chave, () => []);
            transacoesPorVencimento[chave]!.add(transacaoData);
          }

          for (final entry in transacoesPorVencimento.entries) {
            final dataVencimento = DateTime.parse(entry.key);
            final diasAteVencimento =
                dataVencimento.difference(hojeBase).inDays;
            final isVencida = diasAteVencimento < 0;
            final venceHoje = diasAteVencimento == 0;
            final venceEm3Dias =
                diasAteVencimento > 0 && diasAteVencimento <= 3;

            if (!forceMostrar && !(isVencida || venceHoje || venceEm3Dias)) {
              continue;
            }

            double valorTransacoes = 0.0;
            bool temPendente = false;

            for (final transacao in entry.value) {
              valorTransacoes +=
                  (transacao['valor'] as num?)?.toDouble() ?? 0.0;
              final efetivado =
                  (transacao['efetivado'] as num?)?.toInt() == 1;
              if (!efetivado) {
                temPendente = true;
              }
            }

            if (valorTransacoes <= 0.01) {
              continue;
            }

            if (!temPendente && !forceMostrar) {
              debugPrint(
                '💳 ℹ️ Fatura paga ignorada: $nomeCartao (${entry.key})',
              );
              continue;
            }

            final mesReferencia = DateTime(
              dataVencimento.year,
              dataVencimento.month,
            );
            final faturaReal = await cartaoDataService.buscarFaturaReal(
              cartaoId,
              mesReferencia: mesReferencia,
            );

            final valorFatura = faturaReal?.valorTotal ?? valorTransacoes;
            final dataVencimentoFinal =
                faturaReal?.dataVencimento ?? dataVencimento;

            if (valorFatura <= 0.01) {
              continue;
            }

            final fatura = FaturaPendente(
              cartaoId: cartaoId,
              nomeCartao: nomeCartao,
              valorFatura: valorFatura,
              dataVencimento: dataVencimentoFinal,
              corCartao: cartaoData['cor'] as String?,
            );

            faturasPendentes.add(fatura);
            debugPrint(
              '💳 ✅ Fatura crítica: $nomeCartao - ${fatura.statusTexto} - R\$ ${valorFatura.toStringAsFixed(2)}',
            );
          }
        } catch (e) {
          debugPrint('❌ Erro ao processar cartão ${cartaoData['nome']}: $e');
        }
      }

      // Ordenar por prioridade (mais críticas primeiro)
      final faturasOrdenadas = faturasPendentes.ordenadasPorPrioridade;

      debugPrint('💳 Total de faturas pendentes críticas: ${faturasOrdenadas.length}');

      if (faturasOrdenadas.isNotEmpty) {
        debugPrint('💳 Resumo:');
        debugPrint('   - Vencidas: ${faturasOrdenadas.quantidadeVencidas}');
        debugPrint('   - Vencendo em 3 dias: ${faturasOrdenadas.quantidadeVencendo3Dias}');
        debugPrint('   - Valor total: R\$ ${faturasOrdenadas.valorTotalPendente.toStringAsFixed(2)}');
      }

      return faturasOrdenadas;

    } catch (e) {
      debugPrint('❌ Erro ao buscar faturas pendentes: $e');
      return [];
    }
  }

  /// 🔍 Verificar se cartão específico tem fatura pendente
  Future<FaturaPendente?> verificarFaturaPendente(String cartaoId) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) return null;

      final result = await _db.select(
        'cartoes',
        where: 'id = ? AND usuario_id = ? AND ativo = 1',
        whereArgs: [cartaoId, userId],
      );

      if (result.isEmpty) return null;

      final cartaoData = result.first;
      final saldoAtual = (cartaoData['saldo_atual'] as num?)?.toDouble() ?? 0.0;

      if (saldoAtual <= 0) return null; // Sem dívida

      final fatura = FaturaPendente(
        cartaoId: cartaoData['id'] ?? '',
        nomeCartao: cartaoData['nome'] ?? 'Cartão',
        valorFatura: saldoAtual,
        dataVencimento: DateTime.parse(cartaoData['data_vencimento'] ?? DateTime.now().toIso8601String()),
        corCartao: cartaoData['cor'],
      );

      // Retornar apenas se for crítica
      return (fatura.isVencida || fatura.venceEm3Dias || fatura.venceHoje) ? fatura : null;

    } catch (e) {
      debugPrint('❌ Erro ao verificar fatura pendente do cartão $cartaoId: $e');
      return null;
    }
  }

  /// 📊 Obter resumo de faturas pendentes
  Future<Map<String, dynamic>> obterResumoFaturas() async {
    try {
      final faturas = await buscarFaturasPendentes();

      return {
        'total_faturas': faturas.length,
        'faturas_vencidas': faturas.quantidadeVencidas,
        'faturas_vencendo': faturas.quantidadeVencendo3Dias,
        'valor_total': faturas.valorTotalPendente,
        'tem_faturas_criticas': faturas.isNotEmpty,
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter resumo de faturas: $e');
      return {
        'total_faturas': 0,
        'faturas_vencidas': 0,
        'faturas_vencendo': 0,
        'valor_total': 0.0,
        'tem_faturas_criticas': false,
      };
    }
  }

  /// 🔄 Atualizar status de fatura (após pagamento)
  Future<void> marcarFaturaPaga(String cartaoId) async {
    try {
      final userId = _db.currentUserId;
      if (userId == null) return;

      // Zerar saldo do cartão (marca como pago)
      await _db.update(
        'cartoes',
        {
          'saldo_atual': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      );

      debugPrint('💳 Fatura marcada como paga: $cartaoId');
    } catch (e) {
      debugPrint('❌ Erro ao marcar fatura como paga: $e');
    }
  }

  /// 🧹 Limpar cache (para forçar nova busca)
  void limparCache() {
    debugPrint('🧹 Cache de faturas pendentes limpo');
    // Por enquanto não temos cache, mas pode ser implementado depois
  }

  /// 🧪 Método para teste - força mostrar todas as faturas com saldo
  Future<List<FaturaPendente>> buscarFaturasParaTeste() async {
    return await buscarFaturasPendentes(forceMostrar: true);
  }
}
