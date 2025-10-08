// 🔔 Notificação Service - iPoupei Mobile
// 
// Serviço para gerenciamento de notificações do sistema
// Sincroniza com Supabase e funciona offline
// 
// Baseado em: Notification Pattern + Repository Pattern

import 'dart:async';
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../database/local_database.dart';
import '../../../sync/connectivity_helper.dart';

class NotificacaoService {
  static NotificacaoService? _instance;
  static NotificacaoService get instance {
    _instance ??= NotificacaoService._internal();
    return _instance!;
  }
  
  NotificacaoService._internal();

  final LocalDatabase _localDB = LocalDatabase.instance;
  final ConnectivityHelper _connectivity = ConnectivityHelper.instance;

  /// 📤 CRIAR NOTIFICAÇÃO
  Future<void> criarNotificacao({
    required String titulo,
    required String mensagem,
    String tipo = 'info',
    String? categoriaNotificacao,
    String? referencia,
    bool importante = false,
  }) async {
    try {
      final userId = _localDB.currentUserId;
      if (userId == null) throw Exception('Usuário não logado');

      final notificacao = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': userId,
        'titulo': titulo,
        'mensagem': mensagem,
        'tipo': tipo,
        'categoria_notificacao': categoriaNotificacao,
        'referencia': referencia,
        'importante': importante ? 1 : 0,
        'lida': 0,
        'data_criacao': DateTime.now().toIso8601String(),
        'data_leitura': null,
        'arquivada': 0,
        'data_arquivamento': null,
        'sync_status': 'pending',
        'last_sync': null,
      };

      // Salva localmente
      await _localDB.insert('notificacoes', notificacao);

      log('✅ Notificação criada localmente');

      // Tenta sincronizar se estiver online
      if (await _connectivity.isOnline()) {
        await _sincronizarNotificacao(notificacao['id'] as String);
      }

    } catch (e) {
      log('❌ Erro ao criar notificação: $e');
      rethrow;
    }
  }

  /// 📋 BUSCAR NOTIFICAÇÕES
  Future<List<Map<String, dynamic>>> fetchNotificacoes({
    bool incluirLidas = true,
    bool incluirArquivadas = false,
    String? tipo,
    int? limit,
  }) async {
    try {
      // ✅ GARANTE QUE O LOCAL DATABASE ESTÁ INICIALIZADO
      if (!_localDB.isInitialized) {
        log('🔄 Inicializando LocalDatabase para notificações...');
        await _localDB.initialize();
      }

      // ✅ VERIFICA SE TEM USUÁRIO LOGADO
      if (_localDB.currentUserId == null) {
        log('⚠️ Usuário não logado - retornando lista vazia');
        return [];
      }

      String where = 'user_id = ?';
      List<dynamic> whereArgs = [_localDB.currentUserId];

      if (!incluirLidas) {
        where += ' AND lida = 0';
      }

      if (!incluirArquivadas) {
        where += ' AND arquivada = 0';
      }

      if (tipo != null) {
        where += ' AND tipo = ?';
        whereArgs.add(tipo);
      }

      final notificacoes = await _localDB.select(
        'notificacoes',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'data_criacao DESC',
        limit: limit,
      );

      log('📋 ${notificacoes.length} notificações carregadas');
      return notificacoes;

    } catch (e) {
      log('❌ Erro ao buscar notificações: $e');
      
      // ✅ SE FOR ERRO DE TABELA NÃO EXISTE, RETORNA LISTA VAZIA
      if (e.toString().contains('no such table: notificacoes')) {
        log('📝 Tabela notificacoes não existe ainda - retornando lista vazia');
        return [];
      }
      
      rethrow;
    }
  }

  /// 📖 MARCAR COMO LIDA
  Future<void> marcarComoLida(String notificacaoId) async {
    try {
      final agora = DateTime.now().toIso8601String();

      await _localDB.update(
        'notificacoes',
        {
          'lida': 1,
          'data_leitura': agora,
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [notificacaoId],
      );

      log('✅ Notificação marcada como lida');

      // Tenta sincronizar se estiver online
      if (await _connectivity.isOnline()) {
        await _sincronizarNotificacao(notificacaoId);
      }

    } catch (e) {
      log('❌ Erro ao marcar notificação como lida: $e');
      rethrow;
    }
  }

  /// 📦 ARQUIVAR NOTIFICAÇÃO
  Future<void> arquivarNotificacao(String notificacaoId) async {
    try {
      final agora = DateTime.now().toIso8601String();

      await _localDB.update(
        'notificacoes',
        {
          'arquivada': 1,
          'data_arquivamento': agora,
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [notificacaoId],
      );

      log('✅ Notificação arquivada');

      // Tenta sincronizar se estiver online
      if (await _connectivity.isOnline()) {
        await _sincronizarNotificacao(notificacaoId);
      }

    } catch (e) {
      log('❌ Erro ao arquivar notificação: $e');
      rethrow;
    }
  }

  /// 📊 CONTAR NOTIFICAÇÕES NÃO LIDAS
  Future<int> contarNaoLidas() async {
    try {
      // ✅ GARANTE QUE O LOCAL DATABASE ESTÁ INICIALIZADO
      if (!_localDB.isInitialized) {
        log('🔄 Inicializando LocalDatabase para contar notificações...');
        await _localDB.initialize();
      }

      // ✅ VERIFICA SE TEM USUÁRIO LOGADO
      if (_localDB.currentUserId == null) {
        log('⚠️ Usuário não logado - retornando 0 notificações');
        return 0;
      }

      final resultado = await _localDB.database!.rawQuery(
        'SELECT COUNT(*) as count FROM notificacoes WHERE user_id = ? AND lida = 0 AND arquivada = 0',
        [_localDB.currentUserId],
      );

      return resultado.first['count'] as int;

    } catch (e) {
      log('❌ Erro ao contar notificações não lidas: $e');
      
      // ✅ SE FOR ERRO DE TABELA NÃO EXISTE, RETORNA 0
      if (e.toString().contains('no such table: notificacoes')) {
        log('📝 Tabela notificacoes não existe ainda - retornando 0');
        return 0;
      }
      
      return 0;
    }
  }

  /// 🔄 SINCRONIZAR NOTIFICAÇÃO
  Future<void> _sincronizarNotificacao(String notificacaoId) async {
    try {
      final notificacao = await _localDB.select(
        'notificacoes',
        where: 'id = ?',
        whereArgs: [notificacaoId],
      );

      if (notificacao.isEmpty) return;

      final data = Map<String, dynamic>.from(notificacao.first);
      data.remove('sync_status');
      data.remove('last_sync');

      // Verifica se já existe no Supabase
      final existeRemoto = await Supabase.instance.client
          .from('notificacoes')
          .select('id')
          .eq('id', notificacaoId)
          .maybeSingle();

      if (existeRemoto == null) {
        // INSERT
        await Supabase.instance.client
            .from('notificacoes')
            .insert(data);
      } else {
        // UPDATE
        data.remove('id');
        data.remove('created_at');
        await Supabase.instance.client
            .from('notificacoes')
            .update(data)
            .eq('id', notificacaoId);
      }

      // Marca como sincronizado
      await _localDB.update(
        'notificacoes',
        {
          'sync_status': 'synced',
          'last_sync': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [notificacaoId],
      );

      log('✅ Notificação sincronizada: $notificacaoId');

    } catch (e) {
      log('❌ Erro ao sincronizar notificação: $e');
      // Mantém status pending para tentar depois
    }
  }

  /// 📥 SINCRONIZAR DO SERVIDOR
  Future<void> sincronizarDoServidor() async {
    try {
      if (!await _connectivity.isOnline()) return;

      final userId = _localDB.currentUserId;
      if (userId == null) return;

      final notificacoesRemotas = await Supabase.instance.client
          .from('notificacoes')
          .select()
          .eq('usuario_id', userId)
          .order('data_criacao', ascending: false)
          .limit(100);

      for (final notificacaoRemota in notificacoesRemotas) {
        // Verifica se já existe localmente
        final existeLocal = await _localDB.select(
          'notificacoes',
          where: 'id = ?',
          whereArgs: [notificacaoRemota['id']],
        );

        notificacaoRemota['sync_status'] = 'synced';
        notificacaoRemota['last_sync'] = DateTime.now().toIso8601String();

        if (existeLocal.isEmpty) {
          await _localDB.insert('notificacoes', notificacaoRemota);
        } else {
          await _localDB.update(
            'notificacoes',
            notificacaoRemota,
            where: 'id = ?',
            whereArgs: [notificacaoRemota['id']],
          );
        }
      }

      log('✅ Notificações sincronizadas do servidor');

    } catch (e) {
      log('❌ Erro ao sincronizar do servidor: $e');
    }
  }

  /// 🔔 NOTIFICAÇÕES DO SISTEMA
  Future<void> notificarSincronizacao(String status, {String? detalhes}) async {
    String titulo = '';
    String mensagem = '';
    String tipo = 'info';

    switch (status) {
      case 'sucesso':
        titulo = 'Sincronização Concluída';
        mensagem = 'Seus dados foram sincronizados com sucesso';
        tipo = 'sucesso';
        break;
      case 'falha':
        titulo = 'Erro na Sincronização';
        mensagem = detalhes ?? 'Ocorreu um erro durante a sincronização';
        tipo = 'erro';
        break;
      case 'offline':
        titulo = 'Modo Offline';
        mensagem = 'Você está offline. As alterações serão sincronizadas quando conectar';
        tipo = 'aviso';
        break;
    }

    await criarNotificacao(
      titulo: titulo,
      mensagem: mensagem,
      tipo: tipo,
      categoriaNotificacao: 'sistema',
    );
  }

  /// 🔔 NOTIFICAÇÃO DE SALDO BAIXO
  Future<void> notificarSaldoBaixo(String nomeConta, double saldo) async {
    await criarNotificacao(
      titulo: 'Saldo Baixo',
      mensagem: 'A conta $nomeConta está com saldo baixo: R\$ ${saldo.toStringAsFixed(2)}',
      tipo: 'aviso',
      categoriaNotificacao: 'financeiro',
      importante: true,
    );
  }

  /// 🔔 NOTIFICAÇÃO DE META ATINGIDA
  Future<void> notificarMetaAtingida(String nomeMeta, double valor) async {
    await criarNotificacao(
      titulo: 'Meta Atingida! 🎉',
      mensagem: 'Parabéns! Você atingiu a meta "$nomeMeta" de R\$ ${valor.toStringAsFixed(2)}',
      tipo: 'sucesso',
      categoriaNotificacao: 'metas',
      importante: true,
    );
  }

  /// 🗑️ LIMPAR NOTIFICAÇÕES ANTIGAS
  Future<void> limparNotificacoesAntigas({int diasRetencao = 30}) async {
    try {
      final dataLimite = DateTime.now()
          .subtract(Duration(days: diasRetencao))
          .toIso8601String();

      await _localDB.delete(
        'notificacoes',
        where: 'data_criacao < ? AND arquivada = 1',
        whereArgs: [dataLimite],
      );

      log('✅ Notificações antigas removidas');

    } catch (e) {
      log('❌ Erro ao limpar notificações antigas: $e');
    }
  }
}