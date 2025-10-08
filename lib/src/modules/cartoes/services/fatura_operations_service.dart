import 'dart:developer';
import 'package:uuid/uuid.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';
import '../../../sync/sync_manager.dart';

/// ✅ SERVIÇO EQUIVALENTE AO useFaturaOperations.js
/// Responsável por operações em faturas e transações de cartão
class FaturaOperationsService {
  static final FaturaOperationsService _instance = FaturaOperationsService._internal();
  static FaturaOperationsService get instance => _instance;
  FaturaOperationsService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;
  final SyncManager _syncManager = SyncManager.instance;
  final Uuid _uuid = const Uuid();

  /// 🔧 Helper para conversão segura de boolean do SQLite
  bool _sqliteBooleanFromInt(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  /// 🔧 Converte boolean para INTEGER para compatibilidade SQLite
  Map<String, dynamic> _prepareSQLiteData(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is bool) {
        result[key] = value ? 1 : 0;  // Convert boolean to INTEGER
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// ✅ FORMATAR DATA PARA PADRÃO "Mar/25"
  String _formatarMesAno(String faturaVencimento) {
    try {
      final date = DateTime.parse(faturaVencimento);
      const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                     'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${meses[date.month - 1]}/${date.year.toString().substring(2)}';
    } catch (e) {
      return faturaVencimento; // Fallback para string original
    }
  }

  /// ✅ CRIAR ESTORNO PARA BALANCEAMENTO (Espelho do React)
  Future<Map<String, dynamic>> _criarEstornoBalanceamento({
    required String cartaoId,
    required String faturaVencimento,
    required double valorEstorno,
    required String descricaoEstorno,
    bool jaEfetivado = false,  // ✅ NOVO: parâmetro para criar já efetivado
    String? contaId,           // ✅ NOVO: conta para pagamentos já efetivados
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      final estornoId = _uuid.v4();
      
      final agora = DateTime.now().toIso8601String();
      
      final estornoData = {
        'id': estornoId, // ✅ CORRIGIDO: usar ID real
        'usuario_id': userId, // ✅ CORRIGIDO: usar userId real
        'cartao_id': cartaoId,
        'categoria_id': null, // Estorno não tem categoria específica
        'subcategoria_id': null,
        'tipo': 'despesa', // ✅ CORRIGIDO: React usa 'despesa'
        'descricao': descricaoEstorno, // ✅ CORRIGIDO: usar descrição real
        'valor': -valorEstorno.abs(), // Valor negativo para estorno
        'data': DateTime.now().toIso8601String().split('T')[0], // ✅ CORRIGIDO: campo correto
        'fatura_vencimento': faturaVencimento,
        'efetivado': jaEfetivado, // ✅ NOVO: usar parâmetro
        'data_efetivacao': jaEfetivado ? agora : null, // ✅ NOVO: data se já efetivado
        'conta_id': jaEfetivado ? contaId : null, // ✅ NOVO: conta se já efetivado
        'observacoes': 'Estorno automático para balanceamento do pagamento da fatura',
        'created_at': agora,
        'updated_at': agora,
        // ✅ CAMPOS ADICIONAIS DO REACT:
        'recorrente': false,
        'transferencia': false,
        'conta_destino_id': null,
        'compartilhada_com': null,
        'parcela_atual': null,
        'total_parcelas': null,
        'grupo_parcelamento': null,
        'tags': null,
        'localizacao': null,
        'origem_diagnostico': false,
        'sincronizado': true, // ✅ REACT: usa true
        'valor_parcela': null,
        'numero_parcelas': 1, // ✅ REACT: estorno tem numero_parcelas: 1
        'grupo_recorrencia': null,
        'eh_recorrente': false,
        'tipo_recorrencia': null,
        'numero_recorrencia': null,
        'total_recorrencias': null,
        'data_proxima_recorrencia': null,
        'ajuste_manual': false,
        'motivo_ajuste': null,
        'tipo_receita': null,
        'tipo_despesa': null,
      };

      // ✅ Inserir no SQLite local e sync queue com dados corretos
      final estornoDataSQLite = _prepareSQLiteData(estornoData);
      await _localDb.database?.insert('transacoes', estornoDataSQLite);
      await _localDb.addToSyncQueue('transacoes', estornoId, 'insert', estornoData);

      log('✅ Estorno de balanceamento criado:');
      log('   ID: $estornoId');
      log('   Usuario: $userId'); 
      log('   Tipo: ${estornoData['tipo']}');
      log('   Descrição: ${estornoData['descricao']}');
      log('   Valor: R\$ ${valorEstorno.toStringAsFixed(2)}');
      
      return {
        'success': true,
        'estorno_id': estornoId,
        'valor_estorno': valorEstorno,
      };

    } catch (err) {
      log('❌ Erro ao criar estorno de balanceamento: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ GARANTIR CATEGORIA "DÍVIDAS" E SUBCATEGORIA "CARTÃO DE CRÉDITO" (Espelho do React)
  Future<Map<String, dynamic>> _garantirCategoriaDividas() async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      // Buscar categoria "Dívidas" existente
      final categoriasResult = await _localDb.database?.query(
        'categorias',
        where: 'usuario_id = ? AND tipo = ? AND (nome LIKE ? OR nome LIKE ?)',
        whereArgs: [userId, 'despesa', '%dívida%', '%divida%'],
      ) ?? [];

      String categoriaId;
      
      if (categoriasResult.isNotEmpty) {
        categoriaId = categoriasResult.first['id'] as String;
        log('✅ Categoria "Dívidas" encontrada: $categoriaId');
      } else {
        // Criar categoria "Dívidas"
        categoriaId = _uuid.v4();
        
        final categoriaData = {
          'id': categoriaId,
          'usuario_id': userId,
          'nome': 'Dívidas',
          'tipo': 'despesa',
          'cor': '#DC2626',
          'icone': 'CreditCard',
          'descricao': 'Categoria para controle de dívidas e financiamentos',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          };

        final categoriaDataSQLite = _prepareSQLiteData(categoriaData);
        await _localDb.database?.insert('categorias', categoriaDataSQLite);
        await _localDb.addToSyncQueue('categorias', categoriaId, 'insert', categoriaData);
        
        log('✅ Categoria "Dívidas" criada: $categoriaId');
      }

      // Buscar subcategoria "Cartão de Crédito"
      final subcategoriasResult = await _localDb.database?.query(
        'subcategorias',
        where: 'categoria_id = ? AND (nome LIKE ? OR nome LIKE ?)',
        whereArgs: [categoriaId, '%cartão%', '%cartao%'],
      ) ?? [];

      String subcategoriaId;

      if (subcategoriasResult.isNotEmpty) {
        subcategoriaId = subcategoriasResult.first['id'] as String;
        log('✅ Subcategoria "Cartão de Crédito" encontrada: $subcategoriaId');
      } else {
        // Criar subcategoria "Cartão de Crédito"
        subcategoriaId = _uuid.v4();
        
        final subcategoriaData = {
          'id': subcategoriaId,
          'categoria_id': categoriaId,
          'nome': 'Cartão de Crédito',
          'descricao': 'Dívidas relacionadas a cartões de crédito',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          };

        final subcategoriaDataSQLite = _prepareSQLiteData(subcategoriaData);
        await _localDb.database?.insert('subcategorias', subcategoriaDataSQLite);
        await _localDb.addToSyncQueue('subcategorias', subcategoriaId, 'insert', subcategoriaData);
        
        log('✅ Subcategoria "Cartão de Crédito" criada: $subcategoriaId');
      }

      return {
        'success': true,
        'categoria_id': categoriaId,
        'subcategoria_id': subcategoriaId,
      };

    } catch (err) {
      log('❌ Erro ao garantir categoria de dívidas: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ EXCLUIR TRANSAÇÃO INDIVIDUAL
  Future<Map<String, dynamic>> excluirTransacao(String transacaoId) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('🗑️ Excluindo transação individual: $transacaoId');

      // Verificar se a transação existe e pertence ao usuário
      final transacaoResult = await _localDb.database?.query(
        'transacoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [transacaoId, userId],
        limit: 1,
      ) ?? [];

      if (transacaoResult.isEmpty) {
        return {'success': false, 'error': 'Transação não encontrada'};
      }

      final transacao = transacaoResult.first;
      final efetivado = _sqliteBooleanFromInt(transacao['efetivado']); // ✅ CORRIGIDO: conversão segura

      if (efetivado) {
        return {'success': false, 'error': 'Não é possível excluir transação efetivada'};
      }

      // Excluir a transação
      final rowsAffected = await _localDb.database?.delete(
        'transacoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [transacaoId, userId],
      ) ?? 0;

      if (rowsAffected > 0) {
        // Adicionar à fila de sincronização
        await _localDb.addToSyncQueue('transacoes', transacaoId, 'delete', {});
        
        log('✅ Transação excluída com sucesso: $transacaoId');
        return {
          'success': true,
          'message': 'Transação excluída com sucesso',
          'transacao_id': transacaoId,
        };
      } else {
        return {'success': false, 'error': 'Falha ao excluir transação'};
      }
    } catch (err) {
      log('❌ Erro ao excluir transação: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ EXCLUIR PARCELAMENTO COMPLETO
  Future<Map<String, dynamic>> excluirParcelamento(String grupoParcelamento) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('🗑️ Excluindo parcelamento completo: $grupoParcelamento');

      // Buscar todas as parcelas do grupo
      final parcelasResult = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND grupo_parcelamento = ?',
        whereArgs: [userId, grupoParcelamento],
        orderBy: 'parcela_atual ASC',
      ) ?? [];

      if (parcelasResult.isEmpty) {
        return {'success': false, 'error': 'Parcelamento não encontrado'};
      }

      // Verificar se alguma parcela foi efetivada
      final parcelasEfetivadas = parcelasResult.where((p) => _sqliteBooleanFromInt(p['efetivado'])).toList(); // ✅ CORRIGIDO: conversão segura
      
      if (parcelasEfetivadas.isNotEmpty) {
        return {
          'success': false, 
          'error': 'Não é possível excluir parcelamento com parcelas efetivadas (${parcelasEfetivadas.length} parcelas)'
        };
      }

      // Excluir todas as parcelas
      final rowsAffected = await _localDb.database?.delete(
        'transacoes',
        where: 'usuario_id = ? AND grupo_parcelamento = ?',
        whereArgs: [userId, grupoParcelamento],
      ) ?? 0;

      if (rowsAffected > 0) {
        // Adicionar cada parcela à fila de sincronização
        for (final parcela in parcelasResult) {
          await _localDb.addToSyncQueue('transacoes', parcela['id'] as String, 'delete', {});
        }
        
        log('✅ Parcelamento excluído: $grupoParcelamento ($rowsAffected parcelas)');
        return {
          'success': true,
          'message': 'Parcelamento excluído com sucesso',
          'grupo_parcelamento': grupoParcelamento,
          'parcelas_excluidas': rowsAffected,
        };
      } else {
        return {'success': false, 'error': 'Falha ao excluir parcelamento'};
      }
    } catch (err) {
      log('❌ Erro ao excluir parcelamento: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ EXCLUIR PARCELAS FUTURAS (A PARTIR DA PARCELA ATUAL)
  Future<Map<String, dynamic>> excluirParcelasFuturas(String grupoParcelamento, int parcelaAtual) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('🗑️ Excluindo parcelas futuras do grupo: $grupoParcelamento');
      log('   A partir da parcela: $parcelaAtual');

      // Buscar parcelas futuras (incluindo a atual)
      final parcelasFuturasResult = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND grupo_parcelamento = ? AND parcela_atual >= ?',
        whereArgs: [userId, grupoParcelamento, parcelaAtual],
        orderBy: 'parcela_atual ASC',
      ) ?? [];

      if (parcelasFuturasResult.isEmpty) {
        return {'success': false, 'error': 'Nenhuma parcela futura encontrada'};
      }

      // Verificar se alguma parcela futura foi efetivada
      final parcelasEfetivadas = parcelasFuturasResult.where((p) => _sqliteBooleanFromInt(p['efetivado'])).toList(); // ✅ CORRIGIDO: conversão segura
      
      if (parcelasEfetivadas.isNotEmpty) {
        return {
          'success': false, 
          'error': 'Não é possível excluir parcelas efetivadas (${parcelasEfetivadas.length} parcelas)'
        };
      }

      // Excluir parcelas futuras
      final rowsAffected = await _localDb.database?.delete(
        'transacoes',
        where: 'usuario_id = ? AND grupo_parcelamento = ? AND parcela_atual >= ?',
        whereArgs: [userId, grupoParcelamento, parcelaAtual],
      ) ?? 0;

      if (rowsAffected > 0) {
        // Adicionar cada parcela à fila de sincronização
        for (final parcela in parcelasFuturasResult) {
          await _localDb.addToSyncQueue('transacoes', parcela['id'] as String, 'delete', {});
        }
        
        log('✅ Parcelas futuras excluídas: $grupoParcelamento ($rowsAffected parcelas)');
        return {
          'success': true,
          'message': 'Parcelas futuras excluídas com sucesso',
          'grupo_parcelamento': grupoParcelamento,
          'parcela_inicial': parcelaAtual,
          'parcelas_excluidas': rowsAffected,
        };
      } else {
        return {'success': false, 'error': 'Falha ao excluir parcelas futuras'};
      }
    } catch (err) {
      log('❌ Erro ao excluir parcelas futuras: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ PAGAR FATURA (Método genérico - espelho do React)
  Future<Map<String, dynamic>> pagarFatura({
    required String cartaoId,
    required String faturaVencimento,
    required String contaId,
    DateTime? dataPagamento,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('💳 Efetivando pagamento da fatura:');
      log('   Cartão: $cartaoId');
      log('   Vencimento: $faturaVencimento');
      log('   Conta: $contaId');

      final dataEfetivacao = (dataPagamento ?? DateTime.now()).toIso8601String();

      // Primeiro, buscar as transações que serão afetadas (ANTES de efetivar)
      final transacoesParaEfetivar = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ? AND efetivado = ?',
        whereArgs: [userId, cartaoId, faturaVencimento, 0],
      ) ?? [];

      log('🔍 Transações encontradas para efetivar: ${transacoesParaEfetivar.length}');

      if (transacoesParaEfetivar.isEmpty) {
        return {
          'success': false,
          'error': 'Nenhuma transação pendente encontrada para efetivação',
        };
      }

      // Efetivar cada transação individualmente para garantir sync
      int transacoesEfetivadas = 0;
      for (final transacao in transacoesParaEfetivar) {
        final updateData = {
          'efetivado': true,
          'data_efetivacao': dataEfetivacao,
          'conta_id': contaId,
          'updated_at': DateTime.now().toIso8601String(),
        };
        final updateDataSQLite = _prepareSQLiteData(updateData);

        final rowsAffected = await _localDb.database?.update(
          'transacoes',
          updateDataSQLite,
          where: 'id = ?',
          whereArgs: [transacao['id']],
        ) ?? 0;

        if (rowsAffected > 0) {
          await _localDb.addToSyncQueue('transacoes', transacao['id'] as String, 'update', {});
          transacoesEfetivadas++;
          log('✅ Transação ${transacao['id']} efetivada e adicionada à sync queue');
        }
      }

      log('✅ Total de transações efetivadas: $transacoesEfetivadas');

      // 🚀 FORÇA SYNC IMEDIATO PARA SUPABASE
      log('🔄 Forçando sincronização imediata das transações...');
      try {
        await _syncManager.syncAll();
        log('✅ Sincronização concluída com sucesso');
      } catch (syncError) {
        log('⚠️ Erro na sincronização: $syncError');
      }

      return {
        'success': true,
        'transacoes_afetadas': transacoesEfetivadas,
        'conta_utilizada_id': contaId,
        'message': 'Fatura paga com sucesso. $transacoesEfetivadas transações efetivadas.',
      };

    } catch (err) {
      log('❌ Erro ao pagar fatura: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ PAGAR FATURA INTEGRAL
  Future<Map<String, dynamic>> pagarFaturaIntegral({
    required String cartaoId,
    required String faturaVencimento,
    required String contaId,
    DateTime? dataPagamento,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('💳 Pagando fatura integral:');
      log('   Cartão: $cartaoId');
      log('   Vencimento: $faturaVencimento');
      log('   Conta: $contaId');

      final dataEfetivacao = (dataPagamento ?? DateTime.now()).toIso8601String();

      // Buscar todas as transações da fatura (apenas não pagas, como no React)
      log('🔍 DEBUG: Buscando transações para efetivar:');
      log('   userId: $userId');
      log('   cartaoId: $cartaoId');
      log('   faturaVencimento: $faturaVencimento');
      log('   efetivado: 0 (false)');
      
      final transacoesResult = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ? AND efetivado = ?',
        whereArgs: [userId, cartaoId, faturaVencimento, 0], // 0 = false em SQLite
      ) ?? [];
      
      log('🔍 DEBUG: Query retornou ${transacoesResult.length} transações');
      
      // DEBUG: Buscar TODAS as transações deste cartão para comparar
      final todasTransacoes = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ?',
        whereArgs: [userId, cartaoId],
      ) ?? [];
      
      log('🔍 DEBUG: Total de transações do cartão: ${todasTransacoes.length}');
      for (int i = 0; i < todasTransacoes.length && i < 5; i++) {
        final t = todasTransacoes[i];
        log('   [$i] ${t['descricao']}: fatura_vencimento=${t['fatura_vencimento']}, efetivado=${t['efetivado']} (${t['efetivado'].runtimeType})');
      }

      log('🔍 Transações encontradas na fatura:');
      log('   Total de transações: ${transacoesResult.length}');
      for (int i = 0; i < transacoesResult.length; i++) {
        final t = transacoesResult[i];
        final efetivado = t['efetivado'];
        final valor = t['valor'];
        final descricao = t['descricao'];
        log('   [$i] ID: ${t['id']}, Valor: R\$ ${valor?.toString() ?? 'null'}, Efetivado: $efetivado (${efetivado.runtimeType}), Descrição: $descricao');
      }

      if (transacoesResult.isEmpty) {
        return {'success': false, 'error': 'Fatura já está totalmente paga ou nenhuma transação encontrada'};
      }

      // Efetivar todas as transações da fatura
      int transacoesEfetivadas = 0;
      
      log('💳 Iniciando efetivação das transações...');
      for (int i = 0; i < transacoesResult.length; i++) {
        final transacao = transacoesResult[i];
        final efetivado = transacao['efetivado'];
        
        log('   [$i] Processando transação ${transacao['id']}:');
        log('       Valor: R\$ ${transacao['valor']}');
        log('       Efetivado atual: $efetivado (${efetivado.runtimeType})');
        log('       Descrição: ${transacao['descricao']}');
        
        final updateData = {
          'efetivado': true, // ✅ CORRIGIDO: boolean como no React
          'data_efetivacao': dataEfetivacao,
          'conta_id': contaId,
          'updated_at': DateTime.now().toIso8601String(),
            };
        final updateDataSQLite = _prepareSQLiteData(updateData);
        
        log('       Dados para update: $updateDataSQLite');
        
        final rowsAffected = await _localDb.database?.update(
          'transacoes',
          updateDataSQLite,
          where: 'id = ?',
          whereArgs: [transacao['id']],
        ) ?? 0;

        log('       Linhas afetadas: $rowsAffected');

        if (rowsAffected > 0) {
          await _localDb.addToSyncQueue('transacoes', transacao['id'] as String, 'update', {});
          transacoesEfetivadas++;
          log('       ✅ Transação efetivada com sucesso');
        } else {
          log('       ❌ Falha ao efetivar transação');
        }
      }

      if (transacoesEfetivadas > 0) {
        log('✅ Fatura paga: $transacoesEfetivadas transações efetivadas');
        return {
          'success': true,
          'message': 'Fatura paga com sucesso',
          'cartao_id': cartaoId,
          'fatura_vencimento': faturaVencimento,
          'transacoes_efetivadas': transacoesEfetivadas,
          'conta_id': contaId,
          'data_pagamento': dataEfetivacao,
        };
      } else {
        return {'success': false, 'error': 'Falha ao efetivar transações'};
      }
    } catch (err) {
      log('❌ Erro ao pagar fatura: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ PAGAR FATURA PARCIAL - NOVA LÓGICA (Espelho do React)
  Future<Map<String, dynamic>> pagarFaturaParcial({
    required String cartaoId,
    required String faturaVencimento,
    required String contaId,
    required double valorTotal,     // VALOR TOTAL DA FATURA
    required double valorPago,      // VALOR QUE O USUÁRIO QUER PAGAR
    required String faturaDestino,
    DateTime? dataPagamento,
    String? cartaoNome,
    String? contaNome,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('💳 🚨 PAGAMENTO PARCIAL INICIADO - NOVA LÓGICA');
      log('   Cartão: $cartaoId');
      log('   Vencimento: $faturaVencimento');
      log('   Valor pago: R\$ ${valorPago.toStringAsFixed(2)}');
      log('   Fatura destino: $faturaDestino');

      final dataEfetivacao = (dataPagamento ?? DateTime.now()).toIso8601String();

      // Buscar transações da fatura (compatível com boolean e int)
      final transacoesResult = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ? AND (efetivado = 0 OR efetivado = ?)',
        whereArgs: [userId, cartaoId, faturaVencimento, 0],
      ) ?? [];

      if (transacoesResult.isEmpty) {
        return {'success': false, 'error': 'Nenhuma transação em aberto encontrada'};
      }

      log('🔍 DEBUG VALIDAÇÃO:');
      log('   valorPago: $valorPago');
      log('   valorTotal: $valorTotal');
      log('   valorPago <= 0: ${valorPago <= 0}');
      log('   valorPago >= valorTotal: ${valorPago >= valorTotal}');
      
      if (valorPago <= 0 || valorPago >= valorTotal) {
        return {'success': false, 'error': 'Valor pago deve ser maior que zero e menor que o total da fatura'};
      }

      final valorRestante = valorTotal - valorPago;
      final mesAnoOriginal = _formatarMesAno(faturaVencimento);
      final dataObj = DateTime.parse(dataEfetivacao);
      final dataFormatada = '${dataObj.day.toString().padLeft(2, '0')}/${dataObj.month.toString().padLeft(2, '0')}/${dataObj.year.toString().substring(2)}';

      log('💰 Valores calculados:');
      log('   Total da fatura: R\$ ${valorTotal.toStringAsFixed(2)}');
      log('   Valor pago: R\$ ${valorPago.toStringAsFixed(2)}');
      log('   Valor restante: R\$ ${valorRestante.toStringAsFixed(2)}');

      // ✅ ETAPA 1: PAGAR A FATURA INTEGRAL (que já funciona!)
      log('🚨 CHAMANDO pagarFaturaIntegral...');
      final resultadoPagamento = await pagarFaturaIntegral(
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        contaId: contaId,
        dataPagamento: dataPagamento,
      );

      log('🚨 RESULTADO pagarFatura: ${resultadoPagamento['success']}');
      if (!resultadoPagamento['success']) {
        throw Exception('Erro ao pagar fatura: ${resultadoPagamento['error']}');
      }

      // ✅ ETAPA 2: Criar crédito no mês atual
      final creditoId = _uuid.v4();
      final creditoData = {
        'id': creditoId,
        'usuario_id': userId,
        'cartao_id': cartaoId,
        'categoria_id': null,
        'subcategoria_id': null,
        'tipo': 'receita',
        'descricao': 'Crédito parcial da fatura $mesAnoOriginal',
        'valor': valorRestante,
        'data': dataEfetivacao.split('T')[0],
        'fatura_vencimento': faturaVencimento,
        'efetivado': true,
        'data_efetivacao': dataEfetivacao,
        'conta_id': contaId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final creditoDataSQLite = _prepareSQLiteData(creditoData);
      await _localDb.database?.insert('transacoes', creditoDataSQLite);
      await _localDb.addToSyncQueue('transacoes', creditoId, 'insert', creditoData);

      // ✅ ETAPA 3: Criar débito no próximo mês
      final debitoId = _uuid.v4();
      final debitoData = {
        'id': debitoId,
        'usuario_id': userId,
        'cartao_id': cartaoId,
        'categoria_id': null,
        'subcategoria_id': null,
        'tipo': 'despesa',
        'descricao': 'Saldo pendente da fatura $mesAnoOriginal',
        'valor': valorRestante,
        'data': dataEfetivacao.split('T')[0],
        'fatura_vencimento': faturaDestino,
        'efetivado': false,
        'data_efetivacao': null,
        'conta_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final debitoDataSQLite = _prepareSQLiteData(debitoData);
      await _localDb.database?.insert('transacoes', debitoDataSQLite);
      await _localDb.addToSyncQueue('transacoes', debitoId, 'insert', debitoData);

      log('✅ Pagamento parcial concluído - Nova lógica aplicada');

      return {
        'success': true,
        'message': 'Pagamento parcial realizado com sucesso',
        'cartao_id': cartaoId,
        'fatura_vencimento': faturaVencimento,
        'fatura_destino': faturaDestino,
        'valor_efetivado': valorTotal,
        'valor_pago_conta': valorPago,
        'valor_restante': valorRestante,
        'credito_id': creditoId,
        'debito_id': debitoId,
        'conta_id': contaId,
        'data_pagamento': dataEfetivacao,
      };

    } catch (err) {
      log('❌ Erro no pagamento parcial: $err');
      return {'success': false, 'error': err.toString()};
    }
  }


  /// ✅ PAGAR FATURA PARCELADO (Espelho do React)
  Future<Map<String, dynamic>> pagarFaturaParcelado({
    required String cartaoId,
    required String faturaVencimento,
    required String contaId,
    required double valorTotal,
    required int numeroParcelas,
    required double valorParcela,
    DateTime? dataPagamento,
    String? cartaoNome,
    String? contaNome,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('💳 NOVA LÓGICA - Pagamento parcelado:');
      log('   Cartão: $cartaoId');
      log('   Vencimento: $faturaVencimento');
      log('   Número de parcelas: $numeroParcelas');
      log('   Valor da parcela: R\$ ${valorParcela.toStringAsFixed(2)}');

      if (numeroParcelas <= 0 || numeroParcelas > 60) {
        return {'success': false, 'error': 'Número de parcelas deve ser entre 1 e 60'};
      }

      if (valorParcela <= 0) {
        return {'success': false, 'error': 'Valor da parcela deve ser maior que zero'};
      }

      final dataEfetivacao = (dataPagamento ?? DateTime.now()).toIso8601String();

      final valorTotalParcelado = numeroParcelas * valorParcela;
      
      // ✅ VALIDAÇÃO: No React, valor total parcelado não pode ser menor que o valor da fatura
      if (valorTotalParcelado < valorTotal) {
        return {
          'success': false, 
          'error': 'Valor total das parcelas (R\$ ${valorTotalParcelado.toStringAsFixed(2)}) não pode ser menor que o valor da fatura (R\$ ${valorTotal.toStringAsFixed(2)})'
        };
      }
      
      final prejuizoParcelamento = valorTotalParcelado - valorTotal;
      final percentualJuros = (prejuizoParcelamento / valorTotal) * 100;

      log('💰 Valores calculados:');
      log('   Total aberto: R\$ ${valorTotal.toStringAsFixed(2)}');
      log('   Total parcelado: R\$ ${valorTotalParcelado.toStringAsFixed(2)}');
      log('   Prejuízo: R\$ ${prejuizoParcelamento.toStringAsFixed(2)} (${percentualJuros.toStringAsFixed(1)}%)');

      final mesAnoOriginal = _formatarMesAno(faturaVencimento);
      final dataObj = DateTime.parse(dataEfetivacao);
      final dataFormatada = '${dataObj.day.toString().padLeft(2, '0')}/${dataObj.month.toString().padLeft(2, '0')}/${dataObj.year.toString().substring(2)}';

      // ✅ ETAPA 1: Pagar fatura integral PRIMEIRO (como demandado)
      final resultadoPagamento = await pagarFaturaIntegral(
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        contaId: contaId,
        dataPagamento: dataPagamento,
      );

      if (!resultadoPagamento['success']) {
        throw Exception('Erro ao efetivar fatura: ${resultadoPagamento['error']}');
      }

      // ✅ ETAPA 2: Criar estorno JÁ EFETIVADO (após pagamento)
      final resultadoEstorno = await _criarEstornoBalanceamento(
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        valorEstorno: valorTotal,
        descricaoEstorno: 'Estorno automático para balanceamento do pagamento da fatura', // ✅ REACT: texto exato
        jaEfetivado: true,   // ✅ EFETIVADO imediatamente
        contaId: contaId,    // ✅ Com a conta do pagamento
      );

      if (!resultadoEstorno['success']) {
        throw Exception('Erro ao criar estorno: ${resultadoEstorno['error']}');
      }

      // ✅ ETAPA 3: Criar parcelas nas próximas faturas
      final categorias = await _garantirCategoriaDividas();
      if (!categorias['success']) {
        throw Exception('Erro ao garantir categorias: ${categorias['error']}');
      }
      
      final DateTime faturaVencimentoDate = DateTime.parse(faturaVencimento);
      final grupoParcelamento = _uuid.v4();
      int parcelasGeradas = 0;

      for (int i = 0; i < numeroParcelas; i++) {
        // ✅ CORRIGIDO: Seguir exatamente a lógica do React
        // React usa: gerarDataFaturaParcela(faturaInicialString, i - 1, diaVencimento) no loop for (i = 1; i <= numero_parcelas; i++)
        // Quando i=0 no Flutter: month + i + 1 = próximo mês (correto)
        // Quando i=1 no Flutter: month + i + 1 = mês seguinte, etc.
        final mesDestino = DateTime(faturaVencimentoDate.year, faturaVencimentoDate.month + i + 1, faturaVencimentoDate.day);
        final faturaDestinoString = mesDestino.toIso8601String().split('T')[0];
        
        final parcelaId = _uuid.v4();
        
        final parcelaData = {
          'id': parcelaId,
          'usuario_id': userId,
          'cartao_id': cartaoId,
          'categoria_id': categorias['categoria_id'],
          'subcategoria_id': categorias['subcategoria_id'],
          'tipo': 'despesa', // ✅ CORRIGIDO: usar mesmo campo do React
          'descricao': 'Dívidas relacionadas a cartões de crédito', // ✅ IGUAL AO REACT
          'valor': valorParcela,
          'valor_parcela': valorParcela, // ✅ ADICIONADO: campo do React
          'numero_parcelas': numeroParcelas, // ✅ ADICIONADO: campo do React
          'data': dataEfetivacao.split('T')[0], // ✅ CORRIGIDO: campo correto
          'fatura_vencimento': faturaDestinoString,
          'efetivado': false, // ✅ CORRIGIDO: boolean como no React
          'data_efetivacao': null,
          'conta_id': null,
          'grupo_parcelamento': grupoParcelamento,
          'parcela_atual': i + 1,
          'total_parcelas': numeroParcelas,
          'observacoes': 'Parcelamento da fatura original de R\$ ${valorTotal.toStringAsFixed(2)} paga em $dataFormatada. Prejuízo: R\$ ${prejuizoParcelamento.toStringAsFixed(2)} (${percentualJuros.toStringAsFixed(1)}%)',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          // ✅ CAMPOS ADICIONAIS NECESSÁRIOS (iguais ao React):
          'recorrente': false,
          'transferencia': false,
          'conta_destino_id': null,
          'compartilhada_com': null,
          'tags': null,
          'localizacao': null,
          'origem_diagnostico': false,
          'sincronizado': true, // ✅ REACT: usa true para parcelas
          'grupo_recorrencia': null,
          'eh_recorrente': false,
          'tipo_recorrencia': null,
          'numero_recorrencia': null,
          'total_recorrencias': null,
          'data_proxima_recorrencia': null,
          'ajuste_manual': false,
          'motivo_ajuste': null,
          'tipo_receita': null,
          'tipo_despesa': null,
          };

        final parcelaDataSQLite = _prepareSQLiteData(parcelaData);
        await _localDb.database?.insert('transacoes', parcelaDataSQLite);
        await _localDb.addToSyncQueue('transacoes', parcelaId, 'insert', parcelaData);
        parcelasGeradas++;
      }

      log('✅ Pagamento parcelado concluído - Nova lógica aplicada');

      // ✅ ETAPA 4: Agendar sincronização após 10 segundos
      Future.delayed(const Duration(seconds: 10), () async {
        log('⏰ Executando sync agendado (10s) após pagamento parcelado');
        try {
          await _syncManager.syncAll();
          log('✅ Sync agendado concluído com sucesso');
        } catch (e) {
          log('⚠️ Erro no sync agendado: $e');
        }
      });

      return {
        'success': true,
        'message': 'Pagamento parcelado realizado com sucesso',
        'cartao_id': cartaoId,
        'fatura_vencimento': faturaVencimento,
        'valor_efetivado': valorTotal,
        'grupo_parcelamento': grupoParcelamento,
        'valor_total_parcelado': valorTotalParcelado,
        'valor_parcela': valorParcela,
        'numero_parcelas': numeroParcelas,
        'prejuizo_parcelamento': prejuizoParcelamento,
        'percentual_juros': percentualJuros,
        'parcelas_geradas': parcelasGeradas,
        'conta_id': contaId,
        'data_pagamento': dataEfetivacao,
      };

    } catch (err) {
      log('❌ Erro no pagamento parcelado: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ REABRIR FATURA (DESFAZER PAGAMENTO)
  Future<Map<String, dynamic>> reabrirFatura({
    required String cartaoId,
    required String faturaVencimento,
  }) async {
    log('🚀 INÍCIO reabrirFatura - Parâmetros recebidos:');
    log('   cartaoId: $cartaoId');
    log('   faturaVencimento: $faturaVencimento');
    
    // ✅ Verificar usuário logado e definir userId no escopo da função
    String? userId;
    try {
      log('🔐 Verificando usuário logado...');
      userId = _authIntegration.authService.currentUser?.id;
      log('   userId: $userId');
      
      if (userId == null) {
        log('❌ Usuário não logado');
        return {'success': false, 'error': 'Usuário não logado'};
      }
      
      log('✅ Usuário verificado, prosseguindo...');
    } catch (e) {
      log('❌ Erro ao verificar usuário: $e');
      return {'success': false, 'error': 'Erro ao verificar usuário: $e'};
    }

    try {
      log('🔓 Reabrindo fatura:');
      log('   Cartão: $cartaoId');
      log('   Vencimento: $faturaVencimento');

      // ✅ Buscar TODAS as transações efetivadas da fatura (igual ao React)
      // Isso inclui transações normais E parcelas que tenham o mesmo fatura_vencimento
      List<Map<String, Object?>> transacoesResult;
      try {
        log('🔍 Executando query para buscar transações efetivadas...');
        transacoesResult = await _localDb.database?.query(
          'transacoes',
          where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ? AND efetivado = ?',
          whereArgs: [userId, cartaoId, faturaVencimento, 1], // 1 = true em SQLite
        ) ?? [];
        
        log('🔍 Encontradas ${transacoesResult.length} transações efetivadas para reabrir na fatura $faturaVencimento');
      } catch (queryError) {
        log('❌ Erro na query de busca: $queryError');
        throw queryError;
      }

      if (transacoesResult.isEmpty) {
        return {'success': false, 'error': 'Fatura já está em aberto ou nenhuma transação encontrada'};
      }

      // Desfazer efetivação de todas as transações da fatura
      int transacoesReabertas = 0;
      
      try {
        for (final transacao in transacoesResult) {
          try {
            final descricao = transacao['descricao'] as String? ?? '';
            final isParcela = transacao['grupo_parcelamento'] != null;
            final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
            final contaAnterior = transacao['conta_id'] as String?;
            
            log('🔓 Reabrindo: ${isParcela ? "Parcela" : "Transação"} - $descricao (R\$ $valor)');
            log('   📋 ID: ${transacao['id']}');
            log('   🏦 Conta anterior: $contaAnterior');
            
            final updateData = {
              'efetivado': false, // ✅ CORRIGIDO: boolean como no React
              'data_efetivacao': null,
              'conta_id': null,
              'updated_at': DateTime.now().toIso8601String(),
                };
            final updateDataSQLite = _prepareSQLiteData(updateData);
            
            log('   🔄 Dados para update: $updateDataSQLite');
            
            final rowsAffected = await _localDb.database?.update(
              'transacoes',
              updateDataSQLite,
              where: 'id = ?',
              whereArgs: [transacao['id']],
            ) ?? 0;

            log('   📊 Rows affected: $rowsAffected');

            if (rowsAffected > 0) {
              await _localDb.addToSyncQueue('transacoes', transacao['id'] as String, 'update', {});
              transacoesReabertas++;
              log('   ✅ Transação reaberta com sucesso');
            } else {
              log('   ❌ Falha ao reabrir transação');
            }
          } catch (transacaoError) {
            log('❌ Erro ao processar transação ${transacao['id']}: $transacaoError');
            throw transacaoError;
          }
        }
      } catch (loopError) {
        log('❌ Erro no loop de reabertura: $loopError');
        throw loopError;
      }

      if (transacoesReabertas > 0) {
        log('✅ Fatura reaberta: $transacoesReabertas transações/parcelas desefetivadas');
        
        // Agendar sincronização após 10 segundos
        Future.delayed(const Duration(seconds: 10), () async {
          log('⏰ Executando sync agendado (10s) após reabrir fatura');
          try {
            await _syncManager.syncAll();
            log('✅ Sync agendado concluído com sucesso');
          } catch (e) {
            log('⚠️ Erro no sync agendado: $e');
          }
        });
        
        return {
          'success': true,
          'message': 'Fatura reaberta com sucesso',
          'cartao_id': cartaoId,
          'fatura_vencimento': faturaVencimento,
          'transacoes_reabertas': transacoesReabertas,
        };
      } else {
        return {'success': false, 'error': 'Falha ao reabrir fatura'};
      }
    } catch (err) {
      log('❌ Erro ao reabrir fatura: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ ESTORNAR FATURA PARCIALMENTE
  Future<Map<String, dynamic>> estornarFatura({
    required String cartaoId,
    required String faturaVencimento,
    required List<String> transacaoIds,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('↩️ Estornando transações da fatura:');
      log('   Cartão: $cartaoId');
      log('   Vencimento: $faturaVencimento');
      log('   Transações: ${transacaoIds.length}');

      if (transacaoIds.isEmpty) {
        return {'success': false, 'error': 'Nenhuma transação selecionada'};
      }

      // Verificar se as transações existem e estão efetivadas
      final transacoesResult = await _localDb.database?.query(
        'transacoes',
        where: '''
          usuario_id = ? 
          AND cartao_id = ? 
          AND fatura_vencimento = ?
          AND id IN (${transacaoIds.map((_) => '?').join(',')})
        ''',
        whereArgs: [userId, cartaoId, faturaVencimento, ...transacaoIds],
      ) ?? [];

      if (transacoesResult.isEmpty) {
        return {'success': false, 'error': 'Nenhuma transação válida encontrada'};
      }

      // Verificar se estão efetivadas
      final transacoesEfetivadas = transacoesResult.where((t) => _sqliteBooleanFromInt(t['efetivado'])).toList(); // ✅ CORRIGIDO: conversão segura
      if (transacoesEfetivadas.isEmpty) {
        return {'success': false, 'error': 'Nenhuma transação efetivada para estornar'};
      }

      // Estornar transações selecionadas
      int transacoesEstornadas = 0;
      
      for (final transacao in transacoesEfetivadas) {
        final rowsAffected = await _localDb.database?.update(
          'transacoes',
          {
            'efetivado': false, // ✅ CORRIGIDO: boolean como no React
            'data_efetivacao': null,
            'conta_id': null,
            'updated_at': DateTime.now().toIso8601String(),
              },
          where: 'id = ?',
          whereArgs: [transacao['id']],
        ) ?? 0;

        if (rowsAffected > 0) {
          await _localDb.addToSyncQueue('transacoes', transacao['id'] as String, 'update', {});
          transacoesEstornadas++;
        }
      }

      if (transacoesEstornadas > 0) {
        log('✅ Estorno realizado: $transacoesEstornadas transações estornadas');
        return {
          'success': true,
          'message': 'Estorno realizado com sucesso',
          'cartao_id': cartaoId,
          'fatura_vencimento': faturaVencimento,
          'transacoes_estornadas': transacoesEstornadas,
          'total_solicitadas': transacaoIds.length,
        };
      } else {
        return {'success': false, 'error': 'Falha ao estornar transações'};
      }
    } catch (err) {
      log('❌ Erro ao estornar fatura: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ ALTERAR LIMITE DE CARTÃO
  Future<Map<String, dynamic>> alterarLimite({
    required String cartaoId,
    required double novoLimite,
    String? motivo,
  }) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      log('📊 Alterando limite do cartão: $cartaoId');
      log('   Novo limite: R\$ ${novoLimite.toStringAsFixed(2)}');
      log('   Motivo: ${motivo ?? 'Não informado'}');

      if (novoLimite <= 0) {
        return {'success': false, 'error': 'Limite deve ser maior que zero'};
      }

      // Verificar se o cartão existe
      final cartaoResult = await _localDb.database?.query(
        'cartoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
        limit: 1,
      ) ?? [];

      if (cartaoResult.isEmpty) {
        return {'success': false, 'error': 'Cartão não encontrado'};
      }

      final limiteAnterior = (cartaoResult.first['limite'] as num).toDouble();

      // Atualizar limite
      final rowsAffected = await _localDb.database?.update(
        'cartoes',
        {
          'limite': novoLimite,
          'updated_at': DateTime.now().toIso8601String(),
          },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      ) ?? 0;

      if (rowsAffected > 0) {
        await _localDb.addToSyncQueue('cartoes', cartaoId, 'update', {});
        
        log('✅ Limite alterado com sucesso');
        return {
          'success': true,
          'message': 'Limite alterado com sucesso',
          'cartao_id': cartaoId,
          'limite_anterior': limiteAnterior,
          'limite_novo': novoLimite,
          'motivo': motivo,
        };
      } else {
        return {'success': false, 'error': 'Falha ao alterar limite'};
      }
    } catch (err) {
      log('❌ Erro ao alterar limite: $err');
      return {'success': false, 'error': err.toString()};
    }
  }

  /// ✅ BUSCAR HISTÓRICO DE ALTERAÇÕES
  Future<List<Map<String, dynamic>>> buscarHistoricoAlteracoes(String cartaoId) async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      // Em uma implementação real, você teria uma tabela de histórico
      // Por enquanto, vamos simular com logs das sync_queue
      final result = await _localDb.database?.query(
        'sync_queue',
        where: 'table_name = ? AND record_id = ? AND operation = ?',
        whereArgs: ['cartoes', cartaoId, 'update'],
        orderBy: 'created_at DESC',
        limit: 50,
      ) ?? [];

      return result.map((row) => {
        'id': row['id'],
        'data': row['created_at'],
        'operacao': 'Atualização',
        'detalhes': 'Limite ou dados do cartão alterados',
      }).toList();
    } catch (err) {
      log('❌ Erro ao buscar histórico: $err');
      return [];
    }
  }

  /// ✅ VALIDAR OPERAÇÃO
  bool _validarOperacao(String cartaoId, String faturaVencimento) {
    if (cartaoId.isEmpty || faturaVencimento.isEmpty) {
      return false;
    }

    try {
      DateTime.parse(faturaVencimento);
      return true;
    } catch (e) {
      return false;
    }
  }
}