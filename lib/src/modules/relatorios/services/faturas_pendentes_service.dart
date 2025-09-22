// 💳 Faturas Pendentes Service - iPoupei Mobile (with debug)
//
// Serviço para detectar faturas de cartão vencidas ou próximas ao vencimento
// Critérios: Vencidas OU vencendo nos próximos 3 dias
//
// Integração: Local Database + Alertas críticos

import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
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
          final diaVencimento = cartaoData['dia_vencimento'] as int? ?? 15;

          // Calcular data de vencimento para o mês atual/anterior
          final mesAtual = DateTime(hoje.year, hoje.month, diaVencimento);
          final mesAnterior = DateTime(hoje.year, hoje.month - 1, diaVencimento);

          // Se hoje passou do vencimento do mês atual, considera vencida
          // Se ainda não passou, verifica se há transações do mês anterior não pagas
          DateTime dataVencimento;
          if (hoje.day > diaVencimento) {
            // Já passou do vencimento deste mês - fatura vencida
            dataVencimento = mesAtual;
          } else {
            // Ainda não chegou o vencimento - verifica fatura do mês anterior
            dataVencimento = mesAnterior;
          }

          // Calcular período da fatura (desde vencimento anterior até a data atual)
          final inicioFatura = DateTime(dataVencimento.year, dataVencimento.month - 1, diaVencimento);
          final fimFatura = dataVencimento;

          debugPrint('💳 🔍 Buscando transações para cartão $nomeCartao ($cartaoId)');
          debugPrint('💳 🔍 Período da fatura: ${inicioFatura.toIso8601String().split('T')[0]} até ${fimFatura.toIso8601String().split('T')[0]}');

          final transacoesResult = await _db.rawQuery('''
            SELECT
              SUM(CASE WHEN t.tipo = 'despesa' THEN t.valor ELSE -t.valor END) as valor_total,
              COUNT(*) as quantidade
            FROM transacoes t
            WHERE t.cartao_id = ?
              AND t.efetivado = 0
              AND DATE(t.data) > DATE(?)
              AND DATE(t.data) <= DATE(?)
          ''', [cartaoId, inicioFatura.toIso8601String().split('T')[0], fimFatura.toIso8601String().split('T')[0]]);

          debugPrint('💳 🔍 Resultado query: ${transacoesResult.first}');

          final valorFatura = (transacoesResult.first['valor_total'] as num?)?.toDouble() ?? 0.0;
          final quantidadeTransacoes = (transacoesResult.first['quantidade'] as num?)?.toInt() ?? 0;

          debugPrint('💳 Cartão $nomeCartao: R\$ ${valorFatura.toStringAsFixed(2)} ($quantidadeTransacoes transações)');

          // Só considera se tem valor > 0 e está vencida ou vencendo em 3 dias
          if (valorFatura > 0.01) {
            final diasAteVencimento = dataVencimento.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
            final isVencida = diasAteVencimento < 0;
            final venceHoje = diasAteVencimento == 0;
            final venceEm3Dias = diasAteVencimento > 0 && diasAteVencimento <= 3;

            debugPrint('💳 📊 $nomeCartao: Vencimento em $diasAteVencimento dias (${dataVencimento.day}/${dataVencimento.month})');

            if (isVencida || venceHoje || venceEm3Dias || forceMostrar) {
              final fatura = FaturaPendente(
                cartaoId: cartaoId,
                nomeCartao: nomeCartao,
                valorFatura: valorFatura,
                dataVencimento: dataVencimento,
                corCartao: cartaoData['cor'] as String?,
              );

              faturasPendentes.add(fatura);
              debugPrint('💳 ✅ Fatura crítica: $nomeCartao - ${fatura.statusTexto} - R\$ ${valorFatura.toStringAsFixed(2)}');
            } else {
              debugPrint('💳 ℹ️ Fatura não crítica: $nomeCartao - ${diasAteVencimento} dias');
            }
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