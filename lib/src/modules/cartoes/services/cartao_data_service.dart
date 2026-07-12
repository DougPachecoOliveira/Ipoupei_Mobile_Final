import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../../transacoes/models/transacao_model.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';
import '../../../sync/connectivity_helper.dart';
import '../../../sync/sync_manager.dart';
import 'fatura_operations_service.dart';

/// ✅ SERVIÇO EQUIVALENTE AO useCartoesData.js
/// Responsável por buscar dados relacionados a cartões e faturas
class CartaoDataService {
  static final CartaoDataService _instance = CartaoDataService._internal();
  static CartaoDataService get instance => _instance;
  CartaoDataService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;
  final Uuid _uuid = const Uuid();

  // Getters para compatibilidade com os novos métodos
  SupabaseClient get _supabaseClient => Supabase.instance.client;
  String? get _userId => _authIntegration.authService.currentUser?.id;

  /// 🔧 Helper para conversão segura de boolean do SQLite
  bool _sqliteBooleanFromInt(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  /// Busca um cartão específico por ID
  Future<CartaoModel?> fetchCartao(String cartaoId) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return null;

    try {
      final result =
          await _localDb.database?.query(
            'cartoes',
            where: 'id = ? AND usuario_id = ?',
            whereArgs: [cartaoId, userId],
            limit: 1,
          ) ??
          [];

      if (result.isEmpty) return null;
      return CartaoModel.fromJson(result.first);
    } catch (e) {
      log('❌ Erro ao buscar cartão: $e');
      return null;
    }
  }

  /// ✅ CALCULAR FATURA ALVO CORRETO
  /// Equivalente à função calcularFaturaAlvoCorreto do React
  FaturaModel calcularFaturaAlvo(CartaoModel cartao, DateTime dataCompra) {
    try {
      final diaFechamento = cartao.diaFechamento;
      final diaVencimento = cartao.diaVencimento;

      // Cálculo da fatura alvo - logs removidos para performance
      final diaCompra = dataCompra.day;

      var anoFaturaAlvo = dataCompra.year;
      var mesFaturaAlvo = dataCompra.month;

      // Se a compra foi APÓS o fechamento, vai para próxima fatura
      if (diaCompra > diaFechamento) {
        mesFaturaAlvo = dataCompra.month + 1;

        if (mesFaturaAlvo > 12) {
          mesFaturaAlvo = 1;
          anoFaturaAlvo = dataCompra.year + 1;
        }
      }

      // Calcular data de vencimento da fatura alvo
      var dataVencimentoFinal = DateTime(
        anoFaturaAlvo,
        mesFaturaAlvo,
        diaVencimento,
      );

      // Se vencimento é antes ou igual ao fechamento, a fatura vence no mês seguinte
      if (diaVencimento <= diaFechamento) {
        final novoMes = mesFaturaAlvo + 1;
        if (novoMes > 12) {
          dataVencimentoFinal = DateTime(anoFaturaAlvo + 1, 1, diaVencimento);
        } else {
          dataVencimentoFinal = DateTime(anoFaturaAlvo, novoMes, diaVencimento);
        }
      }

      // Verificar se o dia existe no mês (ex: 31 em fevereiro)
      if (dataVencimentoFinal.day != diaVencimento) {
        // Usar último dia do mês
        dataVencimentoFinal = DateTime(
          dataVencimentoFinal.year,
          dataVencimentoFinal.month + 1,
          0,
        );
      }

      final faturaVencimentoString = dataVencimentoFinal
          .toIso8601String()
          .split('T')[0];
      final dataFechamento = DateTime(
        anoFaturaAlvo,
        mesFaturaAlvo,
        diaFechamento,
      );

      return FaturaModel(
        id: '${cartao.id}_${faturaVencimentoString}',
        cartaoId: cartao.id,
        usuarioId: cartao.usuarioId,
        ano: dataVencimentoFinal.year,
        mes: dataVencimentoFinal.month,
        dataFechamento: dataFechamento,
        dataVencimento: dataVencimentoFinal,
        valorTotal: 0.0,
        valorMinimo: 0.0,
        status: 'aberta',
        paga: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sincronizado: false,
      );
    } catch (err) {
      log('❌ Erro ao calcular fatura alvo: $err');
      // Fallback para próximo mês
      final hoje = DateTime.now();
      final proximoMes = DateTime(
        hoje.year,
        hoje.month + 1,
        cartao.diaVencimento,
      );
      return FaturaModel(
        id: '${cartao.id}_${proximoMes.toIso8601String().split('T')[0]}',
        cartaoId: cartao.id,
        usuarioId: cartao.usuarioId,
        ano: proximoMes.year,
        mes: proximoMes.month,
        dataFechamento: DateTime(
          hoje.year,
          hoje.month + 1,
          cartao.diaFechamento,
        ),
        dataVencimento: proximoMes,
        valorTotal: 0.0,
        valorMinimo: 0.0,
        status: 'aberta',
        paga: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sincronizado: false,
      );
    }
  }

  /// ✅ BUSCAR CARTÕES COM DADOS CALCULADOS
  Future<List<CartaoModel>> fetchCartoes() async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      // Buscar cartões básicos
      final result =
          await _localDb.database?.query(
            'cartoes',
            where: 'usuario_id = ?',
            whereArgs: [userId],
            orderBy: 'nome ASC',
          ) ??
          [];

      // Logs reduzidos - apenas essenciais
      if (result.length > 0) {
        log('📦 ${result.length} cartões encontrados');
      }

      // Se não tem cartões, criar um cartão básico para teste
      if (result.isEmpty) {
        log(
          '🔧 AVISO: Nenhum cartão encontrado no SQLite, criando cartão básico de teste...',
        );
        await _criarCartaoBasico(userId);

        // Buscar novamente
        final resultAfterCreate =
            await _localDb.database?.query(
              'cartoes',
              where: 'usuario_id = ?',
              whereArgs: [userId],
              orderBy: 'nome ASC',
            ) ??
            [];

        final cartoes = resultAfterCreate
            .map((data) => CartaoModel.fromJson(data))
            .toList();
        log('✅ Cartão básico criado: ${cartoes.length} cartões');
        return cartoes;
      }

      final cartoes = result.map((data) => CartaoModel.fromJson(data)).toList();

      // Para cada cartão, calcular dados adicionais
      for (var i = 0; i < cartoes.length; i++) {
        final cartao = cartoes[i];

        // Buscar gasto atual (transações não efetivadas)
        // 🎯 LIMITE INTELIGENTE: Distinguir parceladas vs recorrentes
        final mesAtual = DateTime.now().month;
        final gastoResult =
            await _localDb.database?.query(
              'transacoes',
              columns: ['valor'],
              where: '''
            cartao_id = ? AND usuario_id = ? AND efetivado = 0
            AND (
              eh_recorrente = 0 OR eh_recorrente IS NULL
              OR
              (eh_recorrente = 1 AND tipo_despesa = 'previsivel' AND parcela_atual = ?)
              OR
              (eh_recorrente = 1 AND tipo_despesa = 'parcelada')
            )
          ''',
              whereArgs: [cartao.id, userId, mesAtual],
            ) ??
            [];

        final gastoAtual = gastoResult.fold<double>(
          0.0,
          (total, row) => total + ((row['valor'] as num?)?.toDouble() ?? 0.0),
        );

        // Calcular próximo vencimento
        final proximaFatura = _calcularProximaFatura(cartao);

        // 🎯 Log para debug do limite inteligente
        if (gastoResult.isNotEmpty) {
          log(
            '🎯 ${cartao.nome}: R\$ ${gastoAtual.toStringAsFixed(2)} (mês $mesAtual - ${gastoResult.length} transações) - Recorrentes só parcela atual, Parceladas valor completo',
          );
        }
      }

      return cartoes;
    } catch (err) {
      log('❌ Erro ao buscar cartões: $err');
      return [];
    }
  }

  /// ✅ BUSCAR RESUMO CONSOLIDADO POR MÊS
  Future<Map<String, dynamic>> fetchResumoConsolidado(
    String mesSelecionado,
  ) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return _resumoVazio();

    try {
      final partes = mesSelecionado.split('-');
      final ano = int.parse(partes[0]);
      final mes = int.parse(partes[1]);

      final dataInicio = DateTime(ano, mes, 1);
      final dataFim = DateTime(ano, mes + 1, 0);

      // Buscar cartões ativos
      final cartoesResult =
          await _localDb.database?.query(
            'cartoes',
            columns: ['id', 'limite', 'dia_vencimento'],
            where: 'usuario_id = ? AND ativo = 1',
            whereArgs: [userId],
          ) ??
          [];

      if (cartoesResult.isEmpty) {
        return _resumoVazio();
      }

      final cartoes = cartoesResult
          .map(
            (row) => {
              'id': row['id'] as String,
              'limite': ((row['limite'] as num?) ?? 0).toDouble(),
              'dia_vencimento': row['dia_vencimento'] as int,
            },
          )
          .toList();

      final limiteTotal = cartoes.fold<double>(
        0.0,
        (total, cartao) => total + (cartao['limite'] as double),
      );

      final cartaoIds = cartoes.map((c) => c['id'] as String).toList();

      // Buscar gastos do período
      final transacoesResult =
          await _localDb.database?.query(
            'transacoes',
            columns: ['valor', 'efetivado'],
            where:
                '''
          usuario_id = ? 
          AND cartao_id IN (${cartaoIds.map((_) => '?').join(',')})
          AND data >= ? 
          AND data <= ?
        ''',
            whereArgs: [
              userId,
              ...cartaoIds,
              dataInicio.toIso8601String().split('T')[0],
              dataFim.toIso8601String().split('T')[0],
            ],
          ) ??
          [];

      double totalGastoPeriodo = 0.0;
      double totalFaturasAbertas = 0.0;

      for (final row in transacoesResult) {
        final valor = ((row['valor'] as num?) ?? 0).toDouble();
        final efetivado = _sqliteBooleanFromInt(
          row['efetivado'],
        ); // ✅ CORRIGIDO: conversão segura

        totalGastoPeriodo += valor;
        if (!efetivado) {
          totalFaturasAbertas += valor;
        }
      }

      // Calcular próximo vencimento geral
      final hoje = DateTime.now();
      DateTime? proximaFaturaVencimento;
      int diasProximoVencimento = 999999;

      for (final cartao in cartoes) {
        final proximaFatura = _calcularProximaFaturaSync(
          cartao['dia_vencimento'] as int,
          hoje,
        );
        final dias = proximaFatura.difference(hoje).inDays;

        if (dias < diasProximoVencimento) {
          diasProximoVencimento = dias;
          proximaFaturaVencimento = proximaFatura;
        }
      }

      final percentualUtilizacaoMedio = limiteTotal > 0
          ? (totalFaturasAbertas / limiteTotal) * 100
          : 0.0;

      return {
        'total_faturas_abertas': totalFaturasAbertas,
        'limite_total': limiteTotal,
        'total_gasto_periodo': totalGastoPeriodo,
        'percentual_utilizacao_medio': percentualUtilizacaoMedio,
        'proxima_fatura_vencimento': proximaFaturaVencimento
            ?.toIso8601String()
            .split('T')[0],
        'dias_proximo_vencimento': diasProximoVencimento == 999999
            ? 0
            : diasProximoVencimento,
        'cartoes_ativos': cartoes.length,
      };
    } catch (err) {
      log('❌ Erro ao buscar resumo consolidado: $err');
      return _resumoVazio();
    }
  }

  /// ✅ BUSCAR TRANSAÇÕES DE FATURA COM SUPORTE A PARCELAS EXTERNAS
  Future<List<Map<String, dynamic>>> fetchTransacoesFatura(
    String cartaoId,
    String faturaVencimento, {
    bool incluirParcelasExternas = false,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      // ETAPA 1: Buscar transações da fatura atual
      final transacoesFaturaAtual =
          await _localDb.database?.query(
            'transacoes',
            where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ?',
            whereArgs: [userId, cartaoId, faturaVencimento],
            orderBy: 'data DESC',
          ) ??
          [];

      var todasTransacoes = [...transacoesFaturaAtual];

      // ETAPA 2: Se solicitado, buscar parcelas relacionadas de outras faturas
      if (incluirParcelasExternas) {
        // Identificar grupos de parcelamento
        final gruposParcelamento = transacoesFaturaAtual
            .where((t) => t['grupo_parcelamento'] != null)
            .map((t) => t['grupo_parcelamento'] as String)
            .toSet()
            .toList();

        if (gruposParcelamento.isNotEmpty) {
          // Buscar TODAS as parcelas dos grupos encontrados (de outras faturas)
          final parcelasExternas =
              await _localDb.database?.query(
                'transacoes',
                where:
                    '''
              usuario_id = ? 
              AND cartao_id = ? 
              AND grupo_parcelamento IN (${gruposParcelamento.map((_) => '?').join(',')})
              AND fatura_vencimento != ?
            ''',
                whereArgs: [
                  userId,
                  cartaoId,
                  ...gruposParcelamento,
                  faturaVencimento,
                ],
                orderBy: 'parcela_atual ASC',
              ) ??
              [];

          // Marcar como externas para tratamento diferenciado
          final parcelasComMarcacao = parcelasExternas
              .map(
                (p) => {
                  ...p,
                  'eh_parcela_externa': 1,
                  'pode_editar': !_sqliteBooleanFromInt(p['efetivado'])
                      ? 1
                      : 0, // ✅ CORRIGIDO: conversão segura
                  'pode_excluir': !_sqliteBooleanFromInt(p['efetivado'])
                      ? 1
                      : 0, // ✅ CORRIGIDO: conversão segura
                },
              )
              .toList();

          todasTransacoes.addAll(parcelasComMarcacao);
        }
      }

      // ETAPA 3: Marcar transações da fatura atual
      final transacoesMarcadas = todasTransacoes
          .map(
            (t) => {
              ...t,
              'eh_da_fatura_atual': t['fatura_vencimento'] == faturaVencimento
                  ? 1
                  : 0,
              'eh_parcela_externa': t['eh_parcela_externa'] ?? 0,
              'pode_editar':
                  t['pode_editar'] ??
                  (!_sqliteBooleanFromInt(t['efetivado'])
                      ? 1
                      : 0), // ✅ CORRIGIDO: conversão segura
              'pode_excluir':
                  t['pode_excluir'] ??
                  (!_sqliteBooleanFromInt(t['efetivado'])
                      ? 1
                      : 0), // ✅ CORRIGIDO: conversão segura
            },
          )
          .toList();

      // ETAPA 4: Enriquecer com dados de categoria e conta
      final transacoesEnriquecidas = <Map<String, dynamic>>[];

      for (final transacao in transacoesMarcadas) {
        String? categoriaNome;
        String? categoriaCor;
        String? categoriaIcone;
        String? contaPagamentoNome;
        String? contaPagamentoTipo;

        // Buscar categoria
        if (transacao['categoria_id'] != null) {
          final categoriaResult =
              await _localDb.database?.query(
                'categorias',
                columns: ['nome', 'cor', 'icone'],
                where: 'id = ?',
                whereArgs: [transacao['categoria_id']],
                limit: 1,
              ) ??
              [];

          if (categoriaResult.isNotEmpty) {
            final categoria = categoriaResult.first;
            categoriaNome = categoria['nome'] as String?;
            categoriaCor = categoria['cor'] as String?;
            categoriaIcone = categoria['icone'] as String?;
          }
        }

        // Buscar informações da conta se transação foi efetivada
        if (transacao['conta_id'] != null) {
          final contaResult =
              await _localDb.database?.query(
                'contas',
                columns: ['nome', 'tipo', 'banco'],
                where: 'id = ?',
                whereArgs: [transacao['conta_id']],
                limit: 1,
              ) ??
              [];

          if (contaResult.isNotEmpty) {
            final conta = contaResult.first;
            contaPagamentoNome = conta['nome'] as String?;
            contaPagamentoTipo = conta['tipo'] as String?;
          }
        }

        // Calcular data correta da parcela
        String dataExibicao = transacao['data'] as String;
        if (transacao['grupo_parcelamento'] != null &&
            transacao['fatura_vencimento'] != null) {
          dataExibicao = _calcularDataParcela(
            transacao['fatura_vencimento'] as String,
            transacao['data'] as String,
          );
        }

        transacoesEnriquecidas.add({
          ...transacao,
          'data_exibicao': dataExibicao,
          'categoria_nome': categoriaNome ?? 'Sem categoria',
          'categoria_cor': categoriaCor ?? '#6B7280',
          'categoria_icone': categoriaIcone ?? 'help',
          'conta_pagamento_nome': contaPagamentoNome,
          'conta_pagamento_tipo': contaPagamentoTipo,
        });
      }

      // Log resumido apenas para debug crítico
      // log('✅ ${transacoesEnriquecidas.length} transações processadas');

      return transacoesEnriquecidas;
    } catch (err) {
      log('❌ Erro ao buscar transações da fatura: $err');
      return [];
    }
  }

  /// ✅ BUSCAR FATURAS DISPONÍVEIS COM INFORMAÇÕES DE PAGAMENTO
  Future<List<FaturaModel>> fetchFaturasDisponiveis(String cartaoId) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      log('💳 Buscando faturas com informações de pagamento: $cartaoId');

      final result =
          await _localDb.database?.query(
            'transacoes',
            columns: [
              'fatura_vencimento',
              'efetivado',
              'data_efetivacao',
              'conta_id',
              'valor',
            ],
            where:
                'usuario_id = ? AND cartao_id = ? AND fatura_vencimento IS NOT NULL',
            whereArgs: [userId, cartaoId],
            orderBy: 'fatura_vencimento ASC',
          ) ??
          [];

      log('📊 Transações encontradas para agrupamento: ${result.length}');

      // Agrupar por fatura_vencimento
      final faturasPorVencimento = <String, Map<String, dynamic>>{};

      for (final transacao in result) {
        final chave = transacao['fatura_vencimento'] as String;

        if (!faturasPorVencimento.containsKey(chave)) {
          faturasPorVencimento[chave] = {
            'fatura_vencimento': chave,
            'valor_total': 0.0,
            'total_transacoes': 0,
            'transacoes_efetivadas': 0,
            'data_efetivacao': null,
            'status_paga': false,
            'conta_pagamento_id': null,
            'conta_pagamento_nome': null,
            'formas_pagamento': <String>{},
          };
        }

        final fatura = faturasPorVencimento[chave]!;
        final faturaValor = (fatura['valor_total'] as double?) ?? 0.0;
        final transacaoValor = ((transacao['valor'] as num?) ?? 0).toDouble();
        fatura['valor_total'] = faturaValor + transacaoValor;
        final totalAtual = (fatura['total_transacoes'] as int?) ?? 0;
        fatura['total_transacoes'] = totalAtual + 1;

        final efetivado = _sqliteBooleanFromInt(
          transacao['efetivado'],
        ); // ✅ CORRIGIDO: conversão segura
        if (efetivado) {
          final efetivatasAtual =
              (fatura['transacoes_efetivadas'] as int?) ?? 0;
          fatura['transacoes_efetivadas'] = efetivatasAtual + 1;

          if (transacao['data_efetivacao'] != null &&
              fatura['data_efetivacao'] == null) {
            fatura['data_efetivacao'] = transacao['data_efetivacao'];
          }

          if (transacao['conta_id'] != null) {
            (fatura['formas_pagamento'] as Set<String>).add(
              transacao['conta_id'] as String,
            );

            if (fatura['conta_pagamento_id'] == null) {
              fatura['conta_pagamento_id'] = transacao['conta_id'];
            }
          }
        }
      }

      // Buscar nomes das contas de pagamento
      final faturas = <FaturaModel>[];

      for (final faturaData in faturasPorVencimento.values) {
        // Determinar status_paga
        final totalTransacoes = faturaData['total_transacoes'] as int;
        final transacoesEfetivadas = faturaData['transacoes_efetivadas'] as int;
        faturaData['status_paga'] =
            totalTransacoes > 0 && transacoesEfetivadas == totalTransacoes;

        // Buscar nome da conta principal de pagamento
        if (faturaData['conta_pagamento_id'] != null) {
          final contaResult =
              await _localDb.database?.query(
                'contas',
                columns: ['nome', 'tipo'],
                where: 'id = ?',
                whereArgs: [faturaData['conta_pagamento_id']],
                limit: 1,
              ) ??
              [];

          if (contaResult.isNotEmpty) {
            final conta = contaResult.first;
            faturaData['conta_pagamento_nome'] = conta['nome'];
            faturaData['conta_pagamento_tipo'] = conta['tipo'];
          }
        }

        final dataVencimento = DateTime.parse(
          faturaData['fatura_vencimento'] as String,
        );

        // Converter para FaturaModel
        final fatura = FaturaModel(
          id: '${cartaoId}_${faturaData['fatura_vencimento']}',
          cartaoId: cartaoId,
          usuarioId: userId,
          ano: dataVencimento.year,
          mes: dataVencimento.month,
          dataFechamento: DateTime(
            dataVencimento.year,
            dataVencimento.month,
            1,
          ), // Simplificado
          dataVencimento: dataVencimento,
          valorTotal: faturaData['valor_total'] as double,
          valorMinimo: 0.0, // TODO: Calcular valor mínimo real
          status: faturaData['status_paga'] as bool ? 'paga' : 'aberta',
          paga: faturaData['status_paga'] as bool,
          dataPagamento: faturaData['data_efetivacao'] != null
              ? DateTime.parse(faturaData['data_efetivacao'] as String)
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sincronizado: true,
        );

        faturas.add(fatura);
      }

      faturas.sort((a, b) => a.dataVencimento.compareTo(b.dataVencimento));

      log(
        '✅ Faturas processadas com informações de pagamento: ${faturas.length}',
      );
      return faturas;
    } catch (err) {
      log('❌ Erro ao buscar faturas disponíveis: $err');
      return [];
    }
  }

  /// ✅ BUSCAR PARCELAS COMPLETAS DE UM GRUPO (ESPELHO DO REACT)
  /// Busca todas as parcelas de um grupo específico de parcelamento
  Future<List<Map<String, dynamic>>> fetchParcelasCompletas(
    String grupoParcelamento,
  ) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      log('🔗 Buscando parcelas completas do grupo: $grupoParcelamento');

      final result =
          await _localDb.database?.query(
            'transacoes',
            where: 'usuario_id = ? AND grupo_parcelamento = ?',
            whereArgs: [userId, grupoParcelamento],
            orderBy: 'parcela_atual ASC',
          ) ??
          [];

      // Enriquecer com dados de categoria e conta
      final parcelasComDados = <Map<String, dynamic>>[];

      for (final parcela in result) {
        String? categoriaNome;
        String? categoriaCor;
        String? categoriaIcone;
        String? contaPagamentoNome;
        String? contaPagamentoTipo;
        String? contaPagamentoBanco;

        // Buscar categoria
        if (parcela['categoria_id'] != null) {
          final categoriaResult =
              await _localDb.database?.query(
                'categorias',
                columns: ['nome', 'cor', 'icone'],
                where: 'id = ?',
                whereArgs: [parcela['categoria_id']],
                limit: 1,
              ) ??
              [];

          if (categoriaResult.isNotEmpty) {
            final categoria = categoriaResult.first;
            categoriaNome = categoria['nome'] as String?;
            categoriaCor = categoria['cor'] as String?;
            categoriaIcone = categoria['icone'] as String?;
          }
        }

        // Buscar informações da conta se transação foi efetivada
        if (parcela['conta_id'] != null) {
          final contaResult =
              await _localDb.database?.query(
                'contas',
                columns: ['nome', 'tipo', 'banco'],
                where: 'id = ?',
                whereArgs: [parcela['conta_id']],
                limit: 1,
              ) ??
              [];

          if (contaResult.isNotEmpty) {
            final conta = contaResult.first;
            contaPagamentoNome = conta['nome'] as String?;
            contaPagamentoTipo = conta['tipo'] as String?;
            contaPagamentoBanco = conta['banco'] as String?;
          }
        }

        // Calcular data correta da parcela
        String dataExibicao = parcela['data'] as String? ?? '';
        if (parcela['grupo_parcelamento'] != null &&
            parcela['fatura_vencimento'] != null) {
          dataExibicao = _calcularDataParcela(
            parcela['fatura_vencimento'] as String,
            parcela['data'] as String,
          );
        }

        parcelasComDados.add({
          ...parcela,
          'data_exibicao': dataExibicao,
          'categoria_nome': categoriaNome ?? 'Sem categoria',
          'categoria_cor': categoriaCor ?? '#6B7280',
          'categoria_icone': categoriaIcone ?? 'help',
          'conta_pagamento_nome': contaPagamentoNome,
          'conta_pagamento_tipo': contaPagamentoTipo,
          'conta_pagamento_banco': contaPagamentoBanco,
          'pode_editar': !_sqliteBooleanFromInt(parcela['efetivado']),
          'pode_excluir': !_sqliteBooleanFromInt(parcela['efetivado']),
        });
      }

      log('✅ Parcelas completas carregadas: ${parcelasComDados.length}');
      return parcelasComDados;
    } catch (err) {
      log('❌ Erro ao buscar parcelas completas: $err');
      return [];
    }
  }

  /// ✅ BUSCAR GASTOS POR CATEGORIA EM FATURA
  Future<List<Map<String, dynamic>>> fetchGastosPorCategoria(
    String cartaoId,
    String faturaVencimento,
  ) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final result =
          await _localDb.database?.query(
            'transacoes',
            columns: ['valor', 'categoria_id'],
            where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ?',
            whereArgs: [userId, cartaoId, faturaVencimento],
          ) ??
          [];

      // Agrupar por categoria
      final gastosPorCategoria = <String, Map<String, dynamic>>{};
      double valorTotal = 0.0;

      for (final row in result) {
        final valor = ((row['valor'] as num?) ?? 0).toDouble();
        valorTotal += valor;

        final categoriaId = row['categoria_id'] as String?;

        // Buscar dados da categoria
        String categoriaNome = 'Sem categoria';
        String categoriaCor = '#6B7280';
        String categoriaIcone = 'help';

        if (categoriaId != null) {
          final categoriaResult =
              await _localDb.database?.query(
                'categorias',
                columns: ['nome', 'cor', 'icone'],
                where: 'id = ?',
                whereArgs: [categoriaId],
                limit: 1,
              ) ??
              [];

          if (categoriaResult.isNotEmpty) {
            final categoria = categoriaResult.first;
            categoriaNome = categoria['nome'] as String;
            categoriaCor = categoria['cor'] as String;
            categoriaIcone = categoria['icone'] as String;
          }
        }

        final chave = categoriaNome;

        if (!gastosPorCategoria.containsKey(chave)) {
          gastosPorCategoria[chave] = {
            'categoria_id': categoriaId,
            'categoria_nome': categoriaNome,
            'categoria_cor': categoriaCor,
            'categoria_icone': categoriaIcone,
            'valor_total': 0.0,
            'quantidade_transacoes': 0,
          };
        }

        final categoria = gastosPorCategoria[chave]!;
        final valorAtual = (categoria['valor_total'] as double?) ?? 0.0;
        final quantidadeAtual =
            (categoria['quantidade_transacoes'] as int?) ?? 0;
        categoria['valor_total'] = valorAtual + valor;
        categoria['quantidade_transacoes'] = quantidadeAtual + 1;
      }

      // Converter para lista e calcular percentuais
      final resultado = gastosPorCategoria.values.map((categoria) {
        final valorCategoria = categoria['valor_total'] as double;
        return {
          ...categoria,
          'percentual': valorTotal > 0
              ? (valorCategoria / valorTotal) * 100
              : 0.0,
        };
      }).toList();

      resultado.sort(
        (a, b) =>
            (b['valor_total'] as double).compareTo(a['valor_total'] as double),
      );

      return resultado;
    } catch (err) {
      log('❌ Erro ao buscar gastos por categoria: $err');
      return [];
    }
  }

  /// ✅ VERIFICAR STATUS DE FATURA COM INFORMAÇÕES DE PAGAMENTO
  Future<Map<String, dynamic>> verificarStatusFatura(
    String cartaoId,
    String faturaVencimento,
  ) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return _statusFaturaVazio();
    }

    try {
      final result =
          await _localDb.database?.query(
            'transacoes',
            columns: ['efetivado', 'data_efetivacao', 'conta_id'],
            where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ?',
            whereArgs: [userId, cartaoId, faturaVencimento],
          ) ??
          [];

      final transacoesEfetivadas = result
          .where((t) => _sqliteBooleanFromInt(t['efetivado']))
          .length; // ✅ CORRIGIDO: conversão segura
      final statusPaga =
          result.isNotEmpty && transacoesEfetivadas == result.length;
      final dataEfetivacao =
          result.firstWhere(
                (t) => t['data_efetivacao'] != null,
                orElse: () => {'data_efetivacao': null},
              )['data_efetivacao']
              as String?;

      // Identificar contas de pagamento
      final contasPagamento = result
          .where((t) => t['conta_id'] != null)
          .map((t) => t['conta_id'] as String)
          .toSet()
          .toList();

      final contaPrincipal = contasPagamento.isNotEmpty
          ? contasPagamento.first
          : null;

      String? contaPagamentoNome;
      if (contaPrincipal != null) {
        final contaResult =
            await _localDb.database?.query(
              'contas',
              columns: ['nome'],
              where: 'id = ?',
              whereArgs: [contaPrincipal],
              limit: 1,
            ) ??
            [];

        contaPagamentoNome = contaResult.isNotEmpty
            ? contaResult.first['nome'] as String?
            : null;
      }

      return {
        'status_paga': statusPaga,
        'total_transacoes': result.length,
        'transacoes_efetivadas': transacoesEfetivadas,
        'data_efetivacao': dataEfetivacao,
        'conta_pagamento_id': contaPrincipal,
        'conta_pagamento_nome': contaPagamentoNome,
        'formas_pagamento': contasPagamento,
      };
    } catch (err) {
      log('❌ Erro ao verificar status da fatura: $err');
      return _statusFaturaVazio();
    }
  }

  /// ✅ REABRIR FATURA (desfazer pagamento) - IGUAL AO REACT
  Future<Map<String, dynamic>> reabrirFatura(
    String cartaoId,
    String faturaVencimento,
  ) async {
    return FaturaOperationsService.instance.reabrirFatura(
      cartaoId: cartaoId,
      faturaVencimento: faturaVencimento,
    );
  }

  /// ✅ BUSCAR FATURA REAL (IGUAL TELA FATURAS) - SUBSTITUI FaturaDetectionService
  Future<FaturaModel?> buscarFaturaReal(
    String cartaoId, {
    DateTime? mesReferencia,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return null;

    try {
      final mesAtual = mesReferencia ?? DateTime.now();
      final dataVencimento = await _calcularDataVencimentoMes(
        cartaoId,
        mesAtual,
      );
      final faturaVencimentoStr = dataVencimento.toIso8601String().split(
        'T',
      )[0];

      log(
        '🔍 Buscando fatura REAL: $faturaVencimentoStr para cartão: $cartaoId',
      );

      // 1. Buscar na tabela 'faturas' primeiro (dados reais)
      final faturaLocal = await _localDb.database?.query(
        'faturas',
        where: 'usuario_id = ? AND cartao_id = ? AND data_vencimento = ?',
        whereArgs: [userId, cartaoId, faturaVencimentoStr],
        limit: 1,
      );

      if (faturaLocal != null && faturaLocal.isNotEmpty) {
        final faturaData = faturaLocal.first;
        log(
          '✅ Fatura encontrada na tabela faturas: ${faturaData['valor_total']} - Paga: ${faturaData['paga']}',
        );

        return FaturaModel(
          id: faturaData['id'] as String,
          cartaoId: faturaData['cartao_id'] as String,
          usuarioId: faturaData['usuario_id'] as String,
          ano: dataVencimento.year,
          mes: dataVencimento.month,
          dataFechamento: DateTime.parse(
            faturaData['data_fechamento'] as String,
          ),
          dataVencimento: DateTime.parse(
            faturaData['data_vencimento'] as String,
          ),
          valorTotal: (faturaData['valor_total'] as num?)?.toDouble() ?? 0.0,
          valorPago: (faturaData['valor_pago'] as num?)?.toDouble() ?? 0.0,
          valorMinimo: (faturaData['valor_minimo'] as num?)?.toDouble() ?? 0.0,
          status: faturaData['status'] as String? ?? 'aberta',
          paga: _sqliteBooleanFromInt(
            faturaData['paga'],
          ), // ✅ CORRIGIDO: conversão segura
          dataPagamento: faturaData['data_pagamento'] != null
              ? DateTime.parse(faturaData['data_pagamento'] as String)
              : null,
          observacoes: faturaData['observacoes'] as String?,
          createdAt: DateTime.parse(faturaData['created_at'] as String),
          updatedAt: faturaData['updated_at'] != null
              ? DateTime.parse(faturaData['updated_at'] as String)
              : DateTime.now(),
        );
      }

      // 2. Se não existe na tabela faturas, buscar transações para criar fatura dinâmica
      log('📋 Fatura não existe na tabela, buscando transações...');

      final transacoes =
          await _localDb.database?.query(
            'transacoes',
            where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ?',
            whereArgs: [userId, cartaoId, faturaVencimentoStr],
          ) ??
          [];

      if (transacoes.isEmpty) {
        log('⚪ Nenhuma transação encontrada para $faturaVencimentoStr');
        return null;
      }

      // 3. Calcular dados da fatura dinamicamente
      double valorTotal = 0.0;
      double valorPago = 0.0;
      int transacoesEfetivadas = 0;
      DateTime? ultimaEfetivacao;

      for (final transacao in transacoes) {
        final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
        valorTotal += valor;

        final efetivado = _sqliteBooleanFromInt(
          transacao['efetivado'],
        ); // ✅ CORRIGIDO: conversão segura
        if (efetivado) {
          valorPago += valor;
          transacoesEfetivadas++;

          if (transacao['data_efetivacao'] != null) {
            final dataEfetivacao = DateTime.parse(
              transacao['data_efetivacao'] as String,
            );
            if (ultimaEfetivacao == null ||
                dataEfetivacao.isAfter(ultimaEfetivacao)) {
              ultimaEfetivacao = dataEfetivacao;
            }
          }
        }
      }

      // Determinar status (igual tela faturas)
      final isPaga =
          transacoes.isNotEmpty && transacoesEfetivadas == transacoes.length;
      final hoje = DateTime.now();
      final isVencida = dataVencimento.isBefore(hoje) && !isPaga;

      String status;
      if (isPaga) {
        status = 'paga';
      } else if (isVencida) {
        status = 'vencida';
      } else if (valorTotal > 0) {
        status = 'aberta';
      } else {
        status = 'futura';
      }

      log(
        '📊 Fatura dinâmica: Total: R\$ ${valorTotal.toStringAsFixed(2)} - Paga: $isPaga - Status: $status',
      );

      return FaturaModel(
        id: '${cartaoId}_$faturaVencimentoStr',
        cartaoId: cartaoId,
        usuarioId: userId,
        ano: dataVencimento.year,
        mes: dataVencimento.month,
        dataFechamento: _calcularDataFechamentoFromString(
          faturaVencimentoStr,
          _obterDiaFechamentoCartao(cartaoId),
        ),
        dataVencimento: dataVencimento,
        valorTotal: valorTotal,
        valorPago: valorPago,
        valorMinimo: valorTotal * 0.15,
        status: status,
        paga: isPaga, // ✅ BASEADO EM DADOS REAIS
        dataPagamento: ultimaEfetivacao,
        observacoes:
            '${transacoes.length} transações - $transacoesEfetivadas efetivadas',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (error) {
      log('❌ Erro ao buscar fatura real: $error');
      return null;
    }
  }

  /// 🎯 CALCULAR DATA DE VENCIMENTO PARA UM MÊS ESPECÍFICO
  Future<DateTime> _calcularDataVencimentoMes(
    String cartaoId,
    DateTime mes,
  ) async {
    final cartao = await fetchCartao(cartaoId);
    final diaVencimento = cartao?.diaVencimento ?? 13;

    // Sempre fixa na combinação ano/mês solicitada; se o dia não existir (ex: 31/02),
    // usa o último dia do mês para garantir que a fatura de referência permaneça no mês alvo.
    final ultimoDiaDoMes = DateTime(mes.year, mes.month + 1, 0).day;
    final diaSeguro = diaVencimento > ultimoDiaDoMes
        ? ultimoDiaDoMes
        : diaVencimento;

    return DateTime(mes.year, mes.month, diaSeguro);
  }

  /// 🎯 OBTER DIA DE FECHAMENTO DO CARTÃO
  int _obterDiaFechamentoCartao(String cartaoId) {
    // Por enquanto, usar valor padrão. Posteriormente buscar do cartão.
    return 13; // Valor padrão para Nu
  }

  /// 🎯 CALCULAR DATA DE FECHAMENTO A PARTIR DE STRING
  DateTime _calcularDataFechamentoFromString(
    String faturaVencimentoStr,
    int diaFechamento,
  ) {
    final dataVencimento = DateTime.parse(faturaVencimentoStr);

    // Data de fechamento é sempre no mês anterior ao vencimento
    var anoFechamento = dataVencimento.year;
    var mesFechamento = dataVencimento.month - 1;

    if (mesFechamento <= 0) {
      mesFechamento = 12;
      anoFechamento -= 1;
    }

    return DateTime(anoFechamento, mesFechamento, diaFechamento);
  }

  // ===== MÉTODOS AUXILIARES =====

  DateTime _calcularProximaFatura(CartaoModel cartao) {
    final hoje = DateTime.now();
    final mesAtual = hoje.month;
    final anoAtual = hoje.year;

    var proximoVencimento = DateTime(anoAtual, mesAtual, cartao.diaVencimento);

    if (proximoVencimento.isBefore(hoje) ||
        proximoVencimento.isAtSameMomentAs(hoje)) {
      proximoVencimento = DateTime(
        anoAtual,
        mesAtual + 1,
        cartao.diaVencimento,
      );
    }

    return proximoVencimento;
  }

  DateTime _calcularProximaFaturaSync(int diaVencimento, DateTime hoje) {
    final mesAtual = hoje.month;
    final anoAtual = hoje.year;

    var proximoVencimento = DateTime(anoAtual, mesAtual, diaVencimento);

    if (proximoVencimento.isBefore(hoje) ||
        proximoVencimento.isAtSameMomentAs(hoje)) {
      proximoVencimento = DateTime(anoAtual, mesAtual + 1, diaVencimento);
    }

    return proximoVencimento;
  }

  String _calcularDataParcela(String faturaVencimento, String dataOriginal) {
    try {
      final dataFatura = DateTime.parse(faturaVencimento);
      final diaOriginal = DateTime.parse(dataOriginal).day;

      var dataParcela = DateTime(
        dataFatura.year,
        dataFatura.month,
        diaOriginal,
      );

      // Se o dia não existe no mês da fatura, usar último dia
      if (dataParcela.day != diaOriginal) {
        dataParcela = DateTime(dataFatura.year, dataFatura.month + 1, 0);
      }

      return dataParcela.toIso8601String().split('T')[0];
    } catch (err) {
      log('❌ Erro ao calcular data da parcela: $err');
      return dataOriginal; // Fallback para data original
    }
  }

  Map<String, dynamic> _resumoVazio() {
    return {
      'total_faturas_abertas': 0.0,
      'limite_total': 0.0,
      'total_gasto_periodo': 0.0,
      'percentual_utilizacao_medio': 0.0,
      'proxima_fatura_vencimento': null,
      'dias_proximo_vencimento': 0,
      'cartoes_ativos': 0,
    };
  }

  Map<String, dynamic> _statusFaturaVazio() {
    return {
      'status_paga': false,
      'total_transacoes': 0,
      'transacoes_efetivadas': 0,
      'data_efetivacao': null,
      'conta_pagamento_id': null,
      'conta_pagamento_nome': null,
      'formas_pagamento': <String>[],
    };
  }

  // ========== MÉTODOS DE SALVAMENTO ==========

  /// Cria despesa simples no cartão (parcela única)
  Future<Map<String, dynamic>> criarDespesaCartao({
    required String cartaoId,
    required String categoriaId,
    String? subcategoriaId,
    required String descricao,
    required double valorTotal,
    required String dataCompra,
    required String faturaVencimento,
    String? observacoes,
  }) async {
    log('💳 Criando despesa OFFLINE-FIRST no cartão: $cartaoId');

    try {
      // 🔍 VERIFICA CONECTIVIDADE PRIMEIRO
      final isOnline = await ConnectivityHelper.instance.isOnline();
      log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

      final now = DateTime.now();
      final transacaoId = _uuid.v4();

      final transacao = {
        'id': transacaoId,
        'usuario_id': _userId,
        'cartao_id': cartaoId,
        'categoria_id': categoriaId,
        'subcategoria_id': subcategoriaId,
        'descricao': descricao,
        'valor': valorTotal,
        'data': '${dataCompra}T00:00:00Z',
        'tipo': 'despesa',
        'numero_parcelas': 1,
        'total_parcelas': 1,
        'fatura_vencimento': faturaVencimento,
        'observacoes': observacoes,
        'efetivado': false,
        'recorrente': false,
        'eh_recorrente': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sincronizado': isOnline,
      };

      // ✅ SEMPRE SALVA NO SQLITE LOCAL PRIMEIRO (OFFLINE-FIRST)
      await LocalDatabase.instance.addTransacaoLocal(transacao);
      log('💾 Despesa salva no SQLite: $transacaoId');

      // ✅ SE ESTIVER ONLINE, TENTA SALVAR NO SUPABASE TAMBÉM
      if (isOnline) {
        try {
          // Preparar dados para Supabase (sem campos locais)
          final transacaoSupabase = Map<String, dynamic>.from(transacao);
          transacaoSupabase.remove('sincronizado');

          await _supabaseClient.from('transacoes').insert(transacaoSupabase);

          // Atualizar fatura correspondente
          await _atualizarValorFatura(faturaVencimento, cartaoId, valorTotal);

          log('☁️ Despesa sincronizada com Supabase: $transacaoId');
        } catch (onlineError) {
          log(
            '⚠️ Erro ao sincronizar online (dados salvos offline): $onlineError',
          );

          // Marca como não sincronizado para tentar depois
          await LocalDatabase.instance.updateTransacaoLocal(transacaoId, {
            'sincronizado': false,
          });
        }
      }

      log('✅ Despesa de cartão criada com sucesso (offline-first)');

      return {'success': true, 'data': transacao};
    } catch (error) {
      log('❌ Erro ao criar despesa de cartão: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Cria despesa parcelada no cartão
  Future<Map<String, dynamic>> criarDespesaParcelada({
    required String cartaoId,
    required String categoriaId,
    String? subcategoriaId,
    required String descricao,
    required double valorTotal,
    required int numeroParcelas,
    required String dataCompra,
    required String faturaVencimento,
    String? observacoes,
  }) async {
    log(
      '💳 Criando despesa parcelada: ${numeroParcelas}x de ${valorTotal / numeroParcelas}',
    );

    try {
      final valorParcela = valorTotal / numeroParcelas;
      final transacoes = <Map<String, dynamic>>[];

      // Buscar dados do cartão para pegar dia de vencimento
      final cartao = await fetchCartao(cartaoId);
      if (cartao == null) {
        throw Exception('Cartão não encontrado');
      }

      // Usar método unificado para parcelamento (igual React)
      return await criarDespesaRecorrente(
        cartaoId: cartaoId,
        categoriaId: categoriaId,
        subcategoriaId: subcategoriaId,
        descricao: descricao,
        valorMensal: valorParcela,
        totalRecorrencias: numeroParcelas,
        dataInicial: dataCompra,
        faturaVencimentoInicial: faturaVencimento,
        observacoes: observacoes,
        frequencia: 'mensal',
        isParcela: true, // Marca como parcelamento
        primeiroEfetivado: false,
      );
    } catch (error) {
      log('❌ Erro ao criar despesa parcelada: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Atualiza o valor total de uma fatura específica
  /// Atualiza o valor total de uma fatura (OFFLINE-FIRST)
  Future<void> _atualizarValorFatura(
    String faturaVencimento,
    String cartaoId,
    double valorAdicionado,
  ) async {
    try {
      // 🔍 VERIFICA CONECTIVIDADE
      final isOnline = await ConnectivityHelper.instance.isOnline();

      // ✅ BUSCAR FATURA DO SQLITE LOCAL
      final result = await _localDb.database?.query(
        'faturas',
        where: 'cartao_id = ? AND data_vencimento = ?',
        whereArgs: [cartaoId, faturaVencimento],
      );

      if (result != null && result.isNotEmpty) {
        // Fatura existe - atualizar valor
        final faturaExistente = result.first;
        final novoValor =
            ((faturaExistente['valor_total'] as num?)?.toDouble() ?? 0.0) +
            valorAdicionado;

        await _localDb.database?.update(
          'faturas',
          {
            'valor_total': novoValor,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [faturaExistente['id']],
        );

        log(
          '💾 Fatura atualizada no SQLite: +R\$ ${valorAdicionado.toStringAsFixed(2)} = R\$ ${novoValor.toStringAsFixed(2)}',
        );

        // Tentar sincronizar com Supabase se online
        if (isOnline) {
          try {
            await _supabaseClient
                .from('faturas')
                .update({
                  'valor_total': novoValor,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', faturaExistente['id'] as Object);

            log('☁️ Fatura sincronizada com Supabase');
          } catch (onlineError) {
            log('⚠️ Erro ao sincronizar fatura com Supabase: $onlineError');
          }
        }
      } else {
        // Fatura não existe - criar nova
        final cartao = await fetchCartao(cartaoId);
        final dataFechamento = _calcularDataFechamento(
          faturaVencimento,
          cartao?.diaFechamento ?? 1,
        );
        final now = DateTime.now();
        final faturaId = const Uuid().v4();

        final novaFatura = {
          'id': faturaId,
          'usuario_id': _userId,
          'cartao_id': cartaoId,
          'ano': int.parse(faturaVencimento.split('-')[0]),
          'mes': int.parse(faturaVencimento.split('-')[1]),
          'data_fechamento': dataFechamento,
          'data_vencimento': faturaVencimento,
          'valor_total': valorAdicionado,
          'valor_pago': 0.0,
          'valor_minimo': 0.0,
          'status': 'aberta',
          'paga': 0, // SQLite boolean
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        await _localDb.database?.insert('faturas', novaFatura);
        log(
          '💾 Nova fatura criada no SQLite: R\$ ${valorAdicionado.toStringAsFixed(2)}',
        );

        // Tentar sincronizar com Supabase se online
        if (isOnline) {
          try {
            final faturaSupabase = Map<String, dynamic>.from(novaFatura);
            faturaSupabase['paga'] = false; // Boolean para Supabase

            await _supabaseClient.from('faturas').insert(faturaSupabase);
            log('☁️ Nova fatura sincronizada com Supabase');
          } catch (onlineError) {
            log(
              '⚠️ Erro ao sincronizar nova fatura com Supabase: $onlineError',
            );
          }
        }
      }
    } catch (error) {
      log('❌ Erro ao atualizar valor da fatura: $error');
    }
  }

  /// 🔧 CRIA CARTÃO BÁSICO PARA TESTE
  Future<void> _criarCartaoBasico(String userId) async {
    final now = DateTime.now();
    final cartaoId = const Uuid().v4();

    final cartaoBasico = {
      'id': cartaoId,
      'usuario_id': userId,
      'nome': 'Cartão de Crédito',
      'limite': 5000.0,
      'dia_fechamento': 25,
      'dia_vencimento': 10,
      'bandeira': 'Visa',
      'banco': 'Banco Teste',
      'cor': '#3F51B5',
      'ativo': 1,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'sync_status': 'pending',
    };

    await _localDb.database?.insert('cartoes', cartaoBasico);
    log('✅ Cartão básico criado: ${cartaoBasico['nome']}');
  }

  /// Calcula data de fechamento baseada no vencimento
  String _calcularDataFechamento(String dataVencimento, int diaFechamento) {
    final vencimento = DateTime.parse(dataVencimento);

    // Se dia de fechamento é menor que vencimento, fechamento é no mês anterior
    if (diaFechamento < vencimento.day) {
      final fechamento = DateTime(
        vencimento.year,
        vencimento.month - 1,
        diaFechamento,
      );
      return fechamento.toIso8601String().split('T')[0];
    } else {
      final fechamento = DateTime(
        vencimento.year,
        vencimento.month,
        diaFechamento,
      );
      return fechamento.toIso8601String().split('T')[0];
    }
  }

  /// Gera data de fatura para parcela específica - REGRAS DO REACT
  /// Implementa exatamente a mesma lógica de gerarDataFaturaParcela do React
  String _gerarDataFaturaParcela(
    String faturaInicialString,
    int mesesAFrente,
    int diaVencimento,
  ) {
    try {
      // Converter para DateTime com hora específica para evitar problemas de timezone
      final dataInicial = DateTime.parse(faturaInicialString + 'T00:00:00');
      final anoInicial = dataInicial.year;
      final mesInicial = dataInicial.month - 1; // JavaScript usa 0-based months

      // Calcular novo ano e mês (mesmo algoritmo do React)
      final novoAno = anoInicial + ((mesInicial + mesesAFrente) / 12).floor();
      final novoMes = (mesInicial + mesesAFrente) % 12;

      // Criar nova data (converter mês de volta para 1-based)
      var novaData = DateTime(novoAno, novoMes + 1, diaVencimento);

      // ✅ REGRA CRÍTICA: Se o dia não existe no mês (ex: 31 em fev), vai para último dia
      if (novaData.day != diaVencimento) {
        // setDate(0) do JavaScript = último dia do mês anterior
        novaData = DateTime(
          novoAno,
          novoMes + 1,
          0,
        ); // Dart: dia 0 = último dia do mês anterior
      }

      return novaData.toIso8601String().split('T')[0];
    } catch (err) {
      log('❌ Erro ao gerar data da parcela: $err');
      // Fallback: simplesmente somar meses
      final dataInicial = DateTime.parse(faturaInicialString);
      final novaData = DateTime(
        dataInicial.year,
        dataInicial.month + mesesAFrente,
        dataInicial.day,
      );
      return novaData.toIso8601String().split('T')[0];
    }
  }

  /// Cria despesa recorrente (idêntica ao React - DespesasModal/ReceitasModal)
  Future<Map<String, dynamic>> criarDespesaRecorrente({
    required String cartaoId,
    required String categoriaId,
    String? subcategoriaId,
    required String descricao,
    required double valorMensal,
    required int totalRecorrencias,
    required String dataInicial,
    required String faturaVencimentoInicial,
    String? observacoes,
    String frequencia =
        'mensal', // semanal, quinzenal, mensal, anual - IGUAL REACT
    bool isParcela = false, // true = parcelada, false = recorrente
    bool primeiroEfetivado = false,
  }) async {
    log(
      '💳 Criando despesa recorrente/parcelada: ${totalRecorrencias}x de R\$ ${valorMensal.toStringAsFixed(2)} ($frequencia)',
    );

    try {
      final transacoes = <Map<String, dynamic>>[];

      // Buscar dados do cartão
      final cartao = await fetchCartao(cartaoId);
      if (cartao == null) {
        throw Exception('Cartão não encontrado');
      }

      // Gerar UUID para grupo (igual React)
      final grupoId = _gerarUUID();
      final dataBase = DateTime.parse(dataInicial);

      // Gerar todas as recorrências/parcelas
      for (int i = 0; i < totalRecorrencias; i++) {
        // Calcular data usando MESMA LÓGICA do React
        final dataTransacao = _calcularDataPorFrequencia(
          dataBase,
          frequencia,
          i,
        );
        final faturaVencimento = _gerarDataFaturaParcela(
          faturaVencimentoInicial,
          _calcularMesesPorFrequencia(frequencia, i),
          cartao.diaVencimento,
        );

        // 🔍 DEBUG: Verificar formato das datas
        log(
          '🔍 [$i] dataTransacao: $dataTransacao (${dataTransacao.runtimeType})',
        );
        log(
          '🔍 [$i] faturaVencimento: $faturaVencimento (${faturaVencimento.runtimeType})',
        );

        // Status efetivado (primeira sempre segue o parâmetro, demais false)
        final efetivoStatus = i == 0 ? primeiroEfetivado : false;

        // Sufixo na descrição (igual React)
        final sufixo = isParcela ? ' (${i + 1}/$totalRecorrencias)' : '';

        final transacao = {
          // ✅ Deixar id vazio para auto-generate UUID do Supabase
          'usuario_id': _userId,
          'cartao_id': cartaoId,
          'categoria_id': categoriaId,
          'subcategoria_id': subcategoriaId,
          'descricao': '$descricao$sufixo',
          'valor': valorMensal,
          'data': '${dataTransacao}T00:00:00Z', // ✅ Timestamp completo
          'tipo': 'despesa',
          'tipo_despesa': isParcela
              ? 'parcelada'
              : 'previsivel', // ✅ Campo existe no schema
          'observacoes': observacoes,
          'efetivado': efetivoStatus,
          'recorrente': true, // ✅ Campo existe no schema
          'eh_recorrente': true, // ✅ Campo adicional necessário
          // CAMPOS ESPECÍFICOS
          'grupo_recorrencia': !isParcela ? grupoId : null,
          'grupo_parcelamento': isParcela ? grupoId : null,
          'parcela_atual': isParcela ? i + 1 : null,
          'total_parcelas': isParcela ? totalRecorrencias : null,
          'numero_recorrencia': !isParcela ? i + 1 : null,
          'total_recorrencias': !isParcela ? totalRecorrencias : null,
          'numero_parcelas': isParcela
              ? totalRecorrencias
              : 1, // ✅ Campo obrigatório
          'fatura_vencimento': faturaVencimento,
          // ✅ Não enviar timestamps - deixar Supabase gerenciar
        };

        // ✅ GARANTIR que não tem campo 'id'
        transacao.remove('id');

        transacoes.add(transacao);
      }

      // 🔍 DEBUG: Dados sendo enviados para Supabase (parceladas/recorrentes)
      log(
        '🔍 ENVIANDO ${transacoes.length} TRANSAÇÕES PARCELADAS/RECORRENTES:',
      );
      for (int i = 0; i < transacoes.length && i < 2; i++) {
        // Mostrar só as 2 primeiras
        final t = transacoes[i];
        log('   [$i] TODOS OS CAMPOS:');
        t.forEach((key, value) {
          // 🔍 DESTACAR campos de data
          if (key.contains('data') ||
              key.contains('Data') ||
              key.toLowerCase().contains('date')) {
            log('      🔍 CAMPO DATA: $key: $value (${value.runtimeType})');
          } else {
            log('      $key: $value');
          }
        });
        log('   [$i] ----------');
      }

      // 🔧 OFFLINE-FIRST: Salvar transações no banco LOCAL primeiro
      log(
        '💾 Salvando ${transacoes.length} transações no banco local (offline-first)...',
      );

      for (int i = 0; i < transacoes.length; i++) {
        final transacao = transacoes[i];

        // Garantir que tem um ID único (UUID)
        if (transacao['id'] == null) {
          transacao['id'] = const Uuid().v4();
        }

        // Converter data para formato SQLite (apenas YYYY-MM-DD)
        if (transacao['data'] != null) {
          final dateStr = transacao['data'] as String;
          transacao['data'] = dateStr.split('T')[0];
        }

        // Garantir timestamps obrigatórios
        final now = DateTime.now().toIso8601String();
        transacao['created_at'] = now;
        transacao['updated_at'] = now;

        try {
          // ✅ USAR MÉTODO PADRONIZADO (igual TransacaoService)
          await LocalDatabase.instance.addTransacaoLocal(transacao);
          log(
            '💾 Transação ${i + 1}/${transacoes.length} salva localmente: ${transacao['descricao']}',
          );
        } catch (e) {
          log('❌ Erro ao salvar transação ${i + 1} localmente: $e');
          throw Exception('Erro ao salvar transação no banco local: $e');
        }

        // Atualizar a transação na lista
        transacoes[i] = transacao;
      }

      // 🔥 OFFLINE-FIRST: Não sincronizar imediatamente para evitar duplicação
      // A sync queue irá gerenciar a sincronização adequadamente
      log(
        '📱 OFFLINE-FIRST: ${transacoes.length} despesa(s) ${isParcela ? "parcelada(s)" : "recorrente(s)"} salva(s) localmente',
      );
      log('⏳ Sync queue irá sincronizar automaticamente quando apropriado');

      log(
        '✅ Despesa ${isParcela ? "parcelada" : "recorrente"} criada OFFLINE-FIRST: ${transacoes.length} itens',
      );

      return {'success': true, 'data': transacoes, 'grupo_id': grupoId};
    } catch (error) {
      log('❌ Erro ao criar despesa recorrente/parcelada: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Calcula data de recorrência baseada na data inicial
  String _calcularDataRecorrencia(String dataInicial, int mesesAFrente) {
    final inicial = DateTime.parse(dataInicial);
    final novaData = DateTime(
      inicial.year,
      inicial.month + mesesAFrente,
      inicial.day,
    );

    // Aplicar regra de fim de mês se necessário
    if (novaData.day != inicial.day) {
      // Ir para último dia do mês
      final ultimoDia = DateTime(novaData.year, novaData.month + 1, 0);
      return ultimoDia.toIso8601String().split('T')[0];
    }

    return novaData.toIso8601String().split('T')[0];
  }

  /// Gerar UUID real (compatível com Supabase)
  String _gerarUUID() {
    // Usar biblioteca UUID para gerar UUID válido
    return const Uuid().v4();
  }

  /// Calcular data por frequência - IGUAL LÓGICA DO REACT
  String _calcularDataPorFrequencia(
    DateTime dataBase,
    String frequencia,
    int indice,
  ) {
    switch (frequencia) {
      case 'semanal':
        final novaData = dataBase.add(Duration(days: 7 * indice));
        return novaData.toIso8601String().split('T')[0];
      case 'quinzenal':
        final novaData = dataBase.add(Duration(days: 14 * indice));
        return novaData.toIso8601String().split('T')[0];
      case 'mensal':
        final novaData = DateTime(
          dataBase.year,
          dataBase.month + indice,
          dataBase.day,
        );
        // Regra de fim de mês automática do Dart
        return novaData.toIso8601String().split('T')[0];
      case 'anual':
        final novaData = DateTime(
          dataBase.year + indice,
          dataBase.month,
          dataBase.day,
        );
        return novaData.toIso8601String().split('T')[0];
      default: // mensal
        final novaData = DateTime(
          dataBase.year,
          dataBase.month + indice,
          dataBase.day,
        );
        return novaData.toIso8601String().split('T')[0];
    }
  }

  /// Calcular equivalente em meses para frequência (usado para faturas)
  int _calcularMesesPorFrequencia(String frequencia, int indice) {
    switch (frequencia) {
      case 'semanal':
      case 'quinzenal':
        // Para semanal/quinzenal, aproximar para meses (divisão por ~4 semanas)
        return (indice * (frequencia == 'semanal' ? 0.25 : 0.5)).round();
      case 'mensal':
        return indice;
      case 'anual':
        return indice * 12;
      default:
        return indice;
    }
  }

  /// ✅ CALCULAR LIMITE UTILIZADO DO CARTÃO
  /// Método principal para buscar transações não efetivadas do cartão
  Future<double> calcularLimiteUtilizado(String cartaoId) async {
    if (_userId == null) {
      log('❌ Usuário não logado');
      return 0.0;
    }

    try {
      // Buscar transações não efetivadas (pendentes) do cartão
      final result =
          await _localDb.database?.query(
            'transacoes',
            columns: ['valor', 'tipo_recorrencia', 'fatura_vencimento'],
            where: 'usuario_id = ? AND cartao_id = ? AND efetivado = 0',
            whereArgs: [_userId, cartaoId],
          ) ??
          [];

      // Log reduzido
      if (result.length > 0) {
        log('📦 ${result.length} transações pendentes');
      }

      double valorUtilizado = 0.0;
      final hoje = DateTime.now();
      final mesAtual = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}';

      for (final transacao in result) {
        final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
        final tipoRecorrencia = transacao['tipo_recorrencia'] as String?;
        final faturaVencimento = transacao['fatura_vencimento'] as String?;

        // ✅ LÓGICA DO REACT: Transações simples e parceladas sempre contam
        if (tipoRecorrencia == null || tipoRecorrencia == 'parcelada') {
          valorUtilizado += valor;
        }
        // ✅ Transações previsíveis só contam se a fatura já "venceu"
        else if (tipoRecorrencia == 'previsivel' && faturaVencimento != null) {
          try {
            final faturaData = DateTime.parse(faturaVencimento);

            // Comparar apenas ano-mês (incluir fatura do mês atual)
            final mesFaturaNumero = faturaData.year * 12 + faturaData.month;
            final mesAtualNumero = hoje.year * 12 + hoje.month;

            if (mesFaturaNumero <= mesAtualNumero) {
              valorUtilizado += valor;
            }
          } catch (e) {
            log('⚠️ Erro ao parsear fatura_vencimento: $faturaVencimento');
          }
        }
      }

      // Log apenas se valor significativo
      if (valorUtilizado > 0) {
        log('💳 Limite utilizado: R\$ ${valorUtilizado.toStringAsFixed(2)}');
      }
      return valorUtilizado;
    } catch (e) {
      log('❌ Erro ao calcular limite utilizado: $e');
      return 0.0;
    }
  }

  /// ✅ BUSCAR FATURAS DE UM CARTÃO PARA UM MÊS ESPECÍFICO
  Future<List<FaturaModel>> buscarFaturasCartao(
    String cartaoId, {
    DateTime? mesReferencia,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final fatura = await buscarFaturaReal(
        cartaoId,
        mesReferencia: mesReferencia,
      );
      return fatura != null ? [fatura] : [];
    } catch (e) {
      log('❌ Erro ao buscar faturas do cartão: $e');
      return [];
    }
  }

  /// ✅ CALCULAR TOTAIS DE TODOS OS CARTÕES
  /// Equivalente ao método do React para calcular limite total e utilizado
  Future<Map<String, double>> calcularTotaisCartoes() async {
    if (_userId == null) {
      return {'limiteTotal': 0.0, 'totalUtilizado': 0.0};
    }

    try {
      log('📊 Calculando totais de todos os cartões...');

      // Buscar cartões ativos
      final cartoesResult =
          await _localDb.database?.query(
            'cartoes',
            columns: ['id', 'limite'],
            where: 'usuario_id = ? AND ativo = 1',
            whereArgs: [_userId],
          ) ??
          [];

      if (cartoesResult.isEmpty) {
        log('⚠️ Nenhum cartão ativo encontrado');
        return {'limiteTotal': 0.0, 'totalUtilizado': 0.0};
      }

      double limiteTotal = 0.0;
      double totalUtilizado = 0.0;

      for (final cartaoData in cartoesResult) {
        final cartaoId = cartaoData['id'] as String;
        final limite = (cartaoData['limite'] as num?)?.toDouble() ?? 0.0;

        limiteTotal += limite;

        // Calcular valor utilizado para este cartão
        final valorUtilizado = await calcularLimiteUtilizado(cartaoId);
        totalUtilizado += valorUtilizado;

        log(
          '💳 Cartão $cartaoId: Limite R\$ ${limite.toStringAsFixed(2)} | Utilizado R\$ ${valorUtilizado.toStringAsFixed(2)}',
        );
      }

      log(
        '📊 TOTAIS FINAIS: Limite R\$ ${limiteTotal.toStringAsFixed(2)} | Utilizado R\$ ${totalUtilizado.toStringAsFixed(2)}',
      );

      return {'limiteTotal': limiteTotal, 'totalUtilizado': totalUtilizado};
    } catch (e) {
      log('❌ Erro ao calcular totais: $e');
      return {'limiteTotal': 0.0, 'totalUtilizado': 0.0};
    }
  }
}
