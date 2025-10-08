// 📊 Conta Analytics Service - iPoupei Mobile
// 
// Serviço específico para análises e métricas de contas
// Usado na página de gestão de conta
// 
// Baseado em: Analytics Pattern + Repository Pattern

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../../database/local_database.dart';
import '../../../shared/models/categoria_valor.dart';

class ContaAnalyticsService {
  static ContaAnalyticsService? _instance;
  static ContaAnalyticsService get instance {
    _instance ??= ContaAnalyticsService._internal();
    return _instance!;
  }
  
  ContaAnalyticsService._internal();

  final _supabase = Supabase.instance.client;

  /// 📈 MÉTRICAS RESUMO DA CONTA - PADRÃO OFFLINE-FIRST
  Future<Map<String, dynamic>> fetchMetricasResumo({
    required String contaId,
    required DateTime mesAtual,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return _getMetricasVazias();

      log('📈 Buscando métricas resumo OFFLINE-FIRST para conta: $contaId');

      // 🔄 OFFLINE-FIRST: Buscar SQLite primeiro (como ContaService)
      final localData = await _fetchMetricasResumoOffline(contaId, userId, mesAtual);
      
      // Se SQLite tem dados, retorna (mesmo que sejam zeros - são válidos)
      if (!_isMetricasEmpty(localData)) {
        log('✅ Métricas encontradas no SQLite local');
        return localData;
      }

      // SQLite vazio - tentar sync inicial do Supabase
      log('🔄 SQLite vazio - fazendo sync inicial de métricas do Supabase...');
      try {
        await _syncInitialMetricasFromSupabase(contaId, userId, mesAtual);
        // Tenta buscar novamente após sync
        final localDataAfterSync = await _fetchMetricasResumoOffline(contaId, userId, mesAtual);
        return localDataAfterSync;
      } catch (syncError) {
        log('⚠️ Sync inicial falhou, tentando Supabase direto: $syncError');
        // Fallback para Supabase direto
        return await _fetchMetricasResumoOnline(contaId, userId, mesAtual);
      }
    } catch (e, stackTrace) {
      log('❌ Erro ao buscar métricas resumo: $e', stackTrace: stackTrace);
      return _getMetricasVazias();
    }
  }

  /// 📊 EVOLUÇÃO DO SALDO - PADRÃO OFFLINE-FIRST
  Future<List<Map<String, dynamic>>> fetchEvolucaoSaldo({
    required String contaId,
    required DateTime mesAtual,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('📊 Buscando evolução do saldo OFFLINE-FIRST para conta: $contaId');

      // 🔄 OFFLINE-FIRST: Buscar SQLite primeiro
      final localData = await _fetchEvolucaoSaldoOffline(contaId, userId, mesAtual);
      
      // Se SQLite tem dados (mesmo que vazios - são válidos), retorna
      if (localData.isNotEmpty || await _hasTransactionData(contaId, userId)) {
        log('✅ Evolução encontrada no SQLite local: ${localData.length} registros');
        return localData;
      }

      // SQLite sem dados - tentar sync inicial
      log('🔄 SQLite vazio - fazendo sync inicial de transações do Supabase...');
      try {
        await _syncInitialTransacoesFromSupabase(contaId, userId, mesAtual);
        final localDataAfterSync = await _fetchEvolucaoSaldoOffline(contaId, userId, mesAtual);
        return localDataAfterSync;
      } catch (syncError) {
        log('⚠️ Sync inicial falhou, tentando Supabase direto: $syncError');
        return await _fetchEvolucaoSaldoOnline(contaId, userId, mesAtual);
      }
    } catch (e, stackTrace) {
      log('❌ Erro ao buscar evolução do saldo: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// 💸 ENTRADAS VS SAÍDAS - PADRÃO OFFLINE-FIRST
  Future<List<Map<String, dynamic>>> fetchEntradasVsSaidas({
    required String contaId,
    required DateTime mesAtual,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('💸 Buscando entradas vs saídas OFFLINE-FIRST para conta: $contaId');

      // 🔄 OFFLINE-FIRST: Buscar SQLite primeiro
      final localData = await _fetchEntradasVsSaidasOffline(contaId, userId, mesAtual);
      
      // Se SQLite tem dados (mesmo que vazios - são válidos), retorna
      if (localData.isNotEmpty || await _hasTransactionData(contaId, userId)) {
        log('✅ Entradas vs saídas encontradas no SQLite local: ${localData.length} registros');
        return localData;
      }

      // SQLite sem dados - tentar sync inicial
      log('🔄 SQLite vazio - fazendo sync inicial de transações do Supabase...');
      try {
        await _syncInitialTransacoesFromSupabase(contaId, userId, mesAtual);
        final localDataAfterSync = await _fetchEntradasVsSaidasOffline(contaId, userId, mesAtual);
        return localDataAfterSync;
      } catch (syncError) {
        log('⚠️ Sync inicial falhou, tentando Supabase direto: $syncError');
        return await _fetchEntradasVsSaidasOnline(contaId, userId, mesAtual);
      }
    } catch (e, stackTrace) {
      log('❌ Erro ao buscar entradas vs saídas: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// 🏷️ GASTOS POR CATEGORIA - PADRÃO OFFLINE-FIRST
  Future<List<CategoriaValor>> fetchGastosPorCategoria({
    required String contaId,
    required DateTime mesAtual,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('🏷️ Buscando gastos por categoria OFFLINE-FIRST para conta: $contaId');

      // 🔄 OFFLINE-FIRST: Buscar SQLite primeiro
      final localData = await _fetchGastosPorCategoriaOffline(contaId, userId, mesAtual);
      
      // Se SQLite tem dados (mesmo que vazios - são válidos), retorna
      if (localData.isNotEmpty || await _hasTransactionData(contaId, userId)) {
        log('✅ Gastos por categoria encontrados no SQLite local: ${localData.length} categorias');
        return localData;
      }

      // SQLite sem dados - tentar sync inicial
      log('🔄 SQLite vazio - fazendo sync inicial de transações do Supabase...');
      try {
        await _syncInitialTransacoesFromSupabase(contaId, userId, mesAtual);
        final localDataAfterSync = await _fetchGastosPorCategoriaOffline(contaId, userId, mesAtual);
        return localDataAfterSync;
      } catch (syncError) {
        log('⚠️ Sync inicial falhou, tentando Supabase direto: $syncError');
        return await _fetchGastosPorCategoriaOnline(contaId, userId, mesAtual);
      }
    } catch (e, stackTrace) {
      log('❌ Erro ao buscar gastos por categoria: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// 🌐 MÉTODOS ONLINE (Supabase)

  Future<Map<String, dynamic>> _fetchMetricasResumoOnline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    // Saldo médio dos últimos 3 meses
    final inicioTresMeses = DateTime(mesAtual.year, mesAtual.month - 3, 1);
    final fimTresMeses = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    final inicioMesAtual = DateTime(mesAtual.year, mesAtual.month, 1);
    final fimMesAtual = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    
    try {
      // CORRIGIDO: Usar queries normais ao invés de RPC inexistente
      
      // Buscar todas as transações do período
      final transacoes = await _supabase
          .from('transacoes')
          .select('valor, tipo, data')
          .eq('usuario_id', userId)
          .eq('conta_id', contaId)
          .eq('efetivado', true)
          .gte('data', inicioTresMeses.toIso8601String().split('T')[0])
          .lte('data', fimTresMeses.toIso8601String().split('T')[0]);

      if (transacoes.isEmpty) return _getMetricasVazias();

      // Calcular métricas manualmente (igual ao método offline)
      double saldoMedio = 0.0;
      double maiorEntrada = 0.0;
      double maiorSaida = 0.0;
      double entradaMesAtual = 0.0;
      double saidaMesAtual = 0.0;
      
      final inicioMesStr = inicioMesAtual.toIso8601String().split('T')[0];
      final fimMesStr = fimMesAtual.toIso8601String().split('T')[0];
      
      for (final transacao in transacoes) {
        final valor = ((transacao['valor'] as num?) ?? 0.0).toDouble();
        final tipo = transacao['tipo'] as String;
        final data = transacao['data'] as String;
        
        // ❌ REMOVIDO: Cálculo incorreto de saldo médio
        // saldoMedio += (tipo == 'receita') ? valor : -valor;
        
        // Maior entrada e saída
        if (tipo == 'receita' && valor > maiorEntrada) {
          maiorEntrada = valor;
        }
        if (tipo == 'despesa' && valor > maiorSaida) {
          maiorSaida = valor;
        }
        
        // Entradas e saídas do mês atual
        if (data.compareTo(inicioMesStr) >= 0 && data.compareTo(fimMesStr) <= 0) {
          if (tipo == 'receita') {
            entradaMesAtual += valor;
          } else {
            saidaMesAtual += valor;
          }
        }
      }
      
      // ✅ SALDO MÉDIO CORRETO: Usar saldo atual da conta
      try {
        // Buscar saldo atual da conta
        final contaData = await _supabase
            .from('contas')
            .select('saldo')
            .eq('id', contaId)
            .single();
        
        saldoMedio = ((contaData['saldo'] as num?) ?? 0.0).toDouble();
        log('💰 Usando saldo atual da conta como saldo médio: R\$ ${saldoMedio.toStringAsFixed(2)}');
      } catch (e) {
        log('⚠️ Erro ao buscar saldo da conta: $e');
        saldoMedio = 0.0;
      }
      
      return {
        'saldoMedio': saldoMedio,
        'maiorEntrada': maiorEntrada,
        'maiorSaida': maiorSaida,
        'entradaMesAtual': entradaMesAtual,
        'saidaMesAtual': saidaMesAtual,
      };
      
    } catch (e) {
      log('❌ Erro ao buscar métricas online: $e');
      return _getMetricasVazias();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEvolucaoSaldoOnline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    final List<Map<String, dynamic>> evolucao = [];
    
    // Buscar saldo inicial e data de criação da conta
    final contaResponse = await _supabase
        .from('contas')
        .select('saldo_inicial, created_at')
        .eq('id', contaId)
        .eq('usuario_id', userId)
        .single();
    
    final saldoInicial = ((contaResponse['saldo_inicial'] as num?) ?? 0.0).toDouble();
    final dataCriacaoConta = DateTime.tryParse(contaResponse['created_at'] as String? ?? '') ?? DateTime.now();
    
    // Formato otimizado: 9 meses passado + 3 meses futuro = 12 pontos total
    for (int i = -8; i <= 3; i++) {
      final mes = DateTime(mesAtual.year, mesAtual.month + i, 1);
      final fimMes = DateTime(mes.year, mes.month + 1, 0);
      final isPassado = i < 0;
      final isAtual = i == 0;
      final isFuturo = i > 0;
      
      // Se o mês é anterior à criação da conta, saldo é zero
      if (fimMes.isBefore(dataCriacaoConta)) {
        evolucao.add({
          'mes': _formatarMesAbrev(mes),
          'saldo': 0.0, // Zero antes da conta existir
          'isAtual': isAtual,
          'isProjecao': false,
          'isPassado': isPassado,
        });
        continue;
      }
      
      // Buscar transações baseado no tipo de mês
      var query = _supabase
          .from('transacoes')
          .select('valor, tipo')
          .eq('usuario_id', userId)
          .eq('conta_id', contaId)
          .lte('data', fimMes.toIso8601String().split('T')[0]);
      
      // Filtrar por efetivado apenas para passado/atual
      if (!isFuturo) {
        query = query.eq('efetivado', true);
      }
      // Para futuro: incluir todas (efetivadas + pendentes)
      
      // Se o mês inclui a data de criação, filtrar desde a criação
      if (mes.isBefore(dataCriacaoConta.add(const Duration(days: 30)))) {
        query = query.gte('data', dataCriacaoConta.toIso8601String().split('T')[0]);
      }
      
      final response = await query;
      
      double movimentoTotal = 0.0;
      for (final transacao in response) {
        final valor = ((transacao['valor'] as num?) ?? 0.0).toDouble();
        final tipo = transacao['tipo'] as String;
        movimentoTotal += tipo == 'receita' ? valor : -valor;
      }
      
      final saldoFinalMes = saldoInicial + movimentoTotal;
      
      evolucao.add({
        'mes': _formatarMesAbrev(mes),
        'saldo': saldoFinalMes, 
        'isAtual': isAtual,
        'isProjecao': isFuturo, // NOVO: Marcar se é projeção
        'isPassado': isPassado,
      });
    }
    
    return evolucao;
  }

  Future<List<Map<String, dynamic>>> _fetchEntradasVsSaidasOnline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    final List<Map<String, dynamic>> dadosMensais = [];
    
    // Mesma lógica da evolução: 3 passado + atual + 2 futuro = 6 pontos  
    for (int i = -2; i <= 3; i++) {
      final mes = DateTime(mesAtual.year, mesAtual.month + i, 1);
      final inicioMes = DateTime(mes.year, mes.month, 1);
      final fimMes = DateTime(mes.year, mes.month + 1, 0);
      final isFuturo = i > 0;
      
      // Query com lógica de projeção
      var query = _supabase
          .from('transacoes')
          .select('valor, tipo')
          .eq('usuario_id', userId)
          .eq('conta_id', contaId)
          .gte('data', inicioMes.toIso8601String().split('T')[0])
          .lte('data', fimMes.toIso8601String().split('T')[0]);
      
      // Para passado/atual: só efetivadas
      // Para futuro: todas (efetivadas + pendentes)
      if (!isFuturo) {
        query = query.eq('efetivado', true);
      }
      
      final response = await query;
      
      double entradas = 0.0;
      double saidas = 0.0;
      
      for (final transacao in response) {
        final valor = ((transacao['valor'] as num?) ?? 0.0).toDouble();
        final tipo = transacao['tipo'] as String;
        if (tipo == 'receita') {
          entradas += valor;
        } else {
          saidas += valor;
        }
      }
      
      dadosMensais.add({
        'mes': _formatarMesAbrev(mes),
        'entradas': entradas,
        'saidas': saidas,
        'isAtual': i == 0,
        'isProjecao': isFuturo,
        'isPassado': i < 0,
      });
    }
    
    return dadosMensais;
  }

  Future<List<CategoriaValor>> _fetchGastosPorCategoriaOnline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    final inicioMes = DateTime(mesAtual.year, mesAtual.month, 1);
    final fimMes = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    
    final response = await _supabase
        .from('transacoes')
        .select('''
          valor,
          categorias!inner(nome, cor)
        ''')
        .eq('usuario_id', userId)
        .eq('conta_id', contaId)
        .eq('tipo', 'despesa')
        .eq('efetivado', true)
        .gte('data', inicioMes.toIso8601String().split('T')[0])
        .lte('data', fimMes.toIso8601String().split('T')[0])
        .order('valor', ascending: false)
        .limit(5);
    
    // O Supabase sempre retorna List aqui
    
    final Map<String, CategoriaValor> categoriaMap = {};
    
    for (final item in response) {
      final categoria = item['categorias'];
      final nome = categoria['nome'] as String;
      final cor = categoria['cor'] as String? ?? '#6B7280';
      final valor = ((item['valor'] as num?) ?? 0.0).toDouble();
      
      if (categoriaMap.containsKey(nome)) {
        categoriaMap[nome] = CategoriaValor(
          nome: nome,
          valor: categoriaMap[nome]!.valor + valor,
          color: cor,
        );
      } else {
        categoriaMap[nome] = CategoriaValor(
          nome: nome,
          valor: valor,
          color: cor,
        );
      }
    }
    
    final categorias = categoriaMap.values.toList();
    categorias.sort((a, b) => b.valor.compareTo(a.valor));
    return categorias.take(5).toList();
  }

  /// 📱 MÉTODOS OFFLINE (SQLite local)

  Future<Map<String, dynamic>> _fetchMetricasResumoOffline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    final db = LocalDatabase.instance.database;
    if (db == null) return _getMetricasVazias();
    
    // Saldo médio dos últimos 3 meses
    final inicioTresMeses = DateTime(mesAtual.year, mesAtual.month - 3, 1);
    final fimTresMeses = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    
    // Query complexa para métricas - CORRIGIDA
    final inicioMesAtual = DateTime(mesAtual.year, mesAtual.month, 1).toIso8601String().split('T')[0];
    final fimMesAtual = DateTime(mesAtual.year, mesAtual.month + 1, 0).toIso8601String().split('T')[0];
    final inicioTresMesesStr = inicioTresMeses.toIso8601String().split('T')[0];
    final fimTresMesesStr = fimTresMeses.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT 
        MAX(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END) as maior_entrada,
        MAX(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END) as maior_saida,
        SUM(CASE WHEN tipo = 'receita' AND data >= ? AND data <= ? THEN valor ELSE 0 END) as entrada_mes_atual,
        SUM(CASE WHEN tipo = 'despesa' AND data >= ? AND data <= ? THEN valor ELSE 0 END) as saida_mes_atual
      FROM transacoes 
      WHERE usuario_id = ? AND conta_id = ? AND efetivado = 1
        AND data >= ? AND data <= ?
    ''', [
      inicioMesAtual,
      fimMesAtual,
      inicioMesAtual,
      fimMesAtual,
      userId,
      contaId,
      inicioTresMesesStr,
      fimTresMesesStr,
    ]);
    
    // ✅ BUSCAR SALDO ATUAL DA CONTA NO SQLITE
    final contaResult = await db.rawQuery('''
      SELECT saldo FROM contas WHERE id = ? AND usuario_id = ?
    ''', [contaId, userId]);
    
    if (result.isEmpty) return _getMetricasVazias();
    
    final row = result.first;
    
    // ✅ SALDO MÉDIO: Usar saldo atual da conta
    double saldoMedio = 0.0;
    if (contaResult.isNotEmpty) {
      saldoMedio = (contaResult.first['saldo'] as num?)?.toDouble() ?? 0.0;
    }
    
    return {
      'saldoMedio': saldoMedio,
      'maiorEntrada': (row['maior_entrada'] as num?)?.toDouble() ?? 0.0,
      'maiorSaida': (row['maior_saida'] as num?)?.toDouble() ?? 0.0,
      'entradaMesAtual': (row['entrada_mes_atual'] as num?)?.toDouble() ?? 0.0,
      'saidaMesAtual': (row['saida_mes_atual'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchEvolucaoSaldoOffline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    final db = LocalDatabase.instance.database;
    log('🔍 DEBUGANDO DB: LocalDatabase.instance.database = $db');
    if (db == null) {
      log('❌ PROBLEMA: LocalDatabase.instance.database é NULL!');
      return [];
    }
    
    final List<Map<String, dynamic>> evolucao = [];
    
    // Buscar saldo ATUAL e data de criação da conta
    final contaResult = await db.query(
      'contas',
      columns: ['saldo', 'saldo_inicial', 'created_at'],
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, userId],
    );
    
    final saldoAtual = contaResult.isNotEmpty 
        ? ((contaResult.first['saldo'] as num?) ?? 0.0).toDouble()
        : 0.0;
    
    final saldoInicial = contaResult.isNotEmpty 
        ? ((contaResult.first['saldo_inicial'] as num?) ?? 0.0).toDouble()
        : 0.0;
    
    final dataCriacaoConta = contaResult.isNotEmpty
        ? DateTime.tryParse(contaResult.first['created_at'] as String? ?? '') ?? DateTime.now()
        : DateTime.now();
    
    // Formato otimizado: 9 meses passado + 3 meses futuro = 12 pontos total  
    for (int i = -8; i <= 3; i++) {
      final mes = DateTime(mesAtual.year, mesAtual.month + i, 1);
      final fimMes = DateTime(mes.year, mes.month + 1, 0);
      final isPassado = i < 0;
      final isAtual = i == 0;
      final isFuturo = i > 0;
      
      // Se o mês é anterior à criação da conta, saldo é zero
      if (fimMes.isBefore(dataCriacaoConta)) {
        evolucao.add({
          'mes': _formatarMesAbrev(mes),
          'saldo': 0.0, // Zero antes da conta existir
          'isAtual': isAtual,
          'isProjecao': false,
          'isPassado': isPassado,
        });
        continue;
      }
      
      // Determinar que tipo de dados buscar
      String efetivoFilter;
      if (isFuturo) {
        // Para meses futuros: buscar tanto efetivadas quanto pendentes
        efetivoFilter = ''; // Sem filtro de efetivado
      } else {
        // Para passado e atual: só efetivadas
        efetivoFilter = 'AND efetivado = 1';
      }
      
      // Se o mês inclui a data de criação, usar saldo inicial + transações após criação
      final dataInicial = fimMes.isBefore(dataCriacaoConta.add(const Duration(days: 30))) 
          ? dataCriacaoConta.toIso8601String().split('T')[0]
          : '';
      
      // Buscar transações baseado no tipo de mês
      final result = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN tipo = 'receita' THEN valor WHEN tipo = 'despesa' THEN -valor END) as movimento_total
        FROM transacoes 
        WHERE usuario_id = ? AND conta_id = ? $efetivoFilter
          AND data <= ?
          ${dataInicial.isNotEmpty ? 'AND data >= ?' : ''}
      ''', dataInicial.isNotEmpty 
          ? [userId, contaId, fimMes.toIso8601String().split('T')[0], dataInicial]
          : [userId, contaId, fimMes.toIso8601String().split('T')[0]]);
      
      final movimentoTotal = result.isEmpty ? 0.0 : ((result.first['movimento_total'] as num?) ?? 0.0).toDouble();
      
      // ✅ CORREÇÃO: Para mês atual, usar saldo REAL da conta
      final saldoFinalMes = isAtual ? saldoAtual : (saldoInicial + movimentoTotal);
      
      evolucao.add({
        'mes': _formatarMesAbrev(mes),
        'saldo': saldoFinalMes, 
        'isAtual': isAtual,
        'isProjecao': isFuturo, // NOVO: Marcar se é projeção
        'isPassado': isPassado,
      });
    }
    
    return evolucao;
  }

  Future<List<Map<String, dynamic>>> _fetchEntradasVsSaidasOffline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    final db = LocalDatabase.instance.database;
    if (db == null) return [];
    
    final List<Map<String, dynamic>> dadosMensais = [];
    
    // Mesma lógica: 3 passado + atual + 2 futuro = 6 pontos
    for (int i = -2; i <= 3; i++) {
      final mes = DateTime(mesAtual.year, mesAtual.month + i, 1);
      final inicioMes = DateTime(mes.year, mes.month, 1);
      final fimMes = DateTime(mes.year, mes.month + 1, 0);
      final isFuturo = i > 0;
      
      // Query com lógica de projeção
      String efetivoFilter = isFuturo ? '' : 'AND efetivado = 1';
      
      final result = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END) as entradas,
          SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END) as saidas
        FROM transacoes 
        WHERE usuario_id = ? AND conta_id = ? $efetivoFilter
          AND data >= ? AND data <= ?
      ''', [
        userId,
        contaId,
        inicioMes.toIso8601String().split('T')[0],
        fimMes.toIso8601String().split('T')[0],
      ]);
      
      final entradas = result.isEmpty ? 0.0 : (result.first['entradas'] as num?)?.toDouble() ?? 0.0;
      final saidas = result.isEmpty ? 0.0 : (result.first['saidas'] as num?)?.toDouble() ?? 0.0;
      
      dadosMensais.add({
        'mes': _formatarMesAbrev(mes),
        'entradas': entradas,
        'saidas': saidas,
        'isAtual': i == 0,
        'isProjecao': isFuturo,
        'isPassado': i < 0,
      });
    }
    
    return dadosMensais;
  }

  Future<List<CategoriaValor>> _fetchGastosPorCategoriaOffline(
    String contaId, 
    String userId, 
    DateTime mesAtual
  ) async {
    final db = LocalDatabase.instance.database;
    if (db == null) return [];
    
    final inicioMes = DateTime(mesAtual.year, mesAtual.month, 1);
    final fimMes = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    
    final result = await db.rawQuery('''
      SELECT 
        c.nome,
        c.cor,
        SUM(t.valor) as total
      FROM transacoes t
      LEFT JOIN categorias c ON t.categoria_id = c.id
      WHERE t.usuario_id = ? AND t.conta_id = ? AND t.tipo = 'despesa' 
        AND t.efetivado = 1 AND c.nome IS NOT NULL
        AND date(t.data) >= date(?) AND date(t.data) <= date(?)
      GROUP BY c.id, c.nome, c.cor
      ORDER BY total DESC
      LIMIT 5
    ''', [
      userId,
      contaId,
      inicioMes.toIso8601String().split('T')[0],
      fimMes.toIso8601String().split('T')[0],
    ]);
    
    return result.map((row) => CategoriaValor(
      nome: row['nome'] as String,
      valor: ((row['total'] as num?) ?? 0.0).toDouble(),
      color: row['cor'] as String? ?? '#6B7280',
    )).toList();
  }

  /// 🛠️ HELPERS

  Map<String, dynamic> _getMetricasVazias() {
    return {
      'saldoMedio': 0.0,
      'maiorEntrada': 0.0,
      'maiorSaida': 0.0,
      'entradaMesAtual': 0.0,
      'saidaMesAtual': 0.0,
    };
  }

  String _formatarMesAbrev(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return meses[data.month - 1];
  }

  /// 🔍 MÉTODOS AUXILIARES PARA PADRÃO OFFLINE-FIRST

  /// Verifica se as métricas não foram calculadas ainda
  bool _isMetricasEmpty(Map<String, dynamic> metricas) {
    // CORREÇÃO CRÍTICA: Zeros podem ser dados válidos!
    // Só considera vazio se:
    // 1. Map está vazio 
    // 2. Ou não tem as chaves necessárias (não foi calculado ainda)
    
    if (metricas.isEmpty) return true;
    
    final hasRequiredKeys = metricas.containsKey('saldoMedio') &&
                           metricas.containsKey('maiorEntrada') &&
                           metricas.containsKey('maiorSaida') &&
                           metricas.containsKey('entradaMesAtual') &&
                           metricas.containsKey('saidaMesAtual');
    
    // Se não tem as chaves, não foi calculado ainda
    return !hasRequiredKeys;
  }

  /// Verifica se há dados de transação no SQLite para a conta
  Future<bool> _hasTransactionData(String contaId, String userId) async {
    try {
      final db = LocalDatabase.instance.database;
      if (db == null) return false;

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM transacoes 
        WHERE usuario_id = ? AND conta_id = ?
      ''', [userId, contaId]);

      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      log('❌ Erro ao verificar dados de transação: $e');
      return false;
    }
  }

  /// Sync inicial das métricas do Supabase para SQLite
  Future<void> _syncInitialMetricasFromSupabase(String contaId, String userId, DateTime mesAtual) async {
    // Para métricas, não há dados específicos a sincronizar
    // As métricas são calculadas a partir das transações
    await _syncInitialTransacoesFromSupabase(contaId, userId, mesAtual);
  }

  /// Sync inicial das transações do Supabase para SQLite
  Future<void> _syncInitialTransacoesFromSupabase(String contaId, String userId, DateTime mesAtual) async {
    try {
      // Buscar transações dos últimos 12 meses para a conta
      final inicioUltimos12Meses = DateTime(mesAtual.year - 1, mesAtual.month, 1);
      
      final response = await _supabase
          .from('transacoes')
          .select('*')
          .eq('usuario_id', userId)
          .eq('conta_id', contaId)
          .gte('data', inicioUltimos12Meses.toIso8601String().split('T')[0])
          .order('data', ascending: false);

      if (response.isNotEmpty) {
        // Salvar transações no SQLite
        final db = LocalDatabase.instance.database;
        if (db != null) {
          for (final transacao in response) {
            await db.insert(
              'transacoes',
              transacao,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          log('✅ Sincronizadas ${response.length} transações da conta $contaId');
        }
      }
    } catch (e) {
      log('❌ Erro ao sincronizar transações iniciais: $e');
      rethrow;
    }
  }
}