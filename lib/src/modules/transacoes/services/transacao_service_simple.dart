// 💳 Transacao Service Simples - iPoupei Mobile
// 
// Versão simplificada sem filtros complexos do Supabase
// Funcionalidades básicas funcionais
// 
// Baseado em: Repository Pattern Simplificado

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transacao_model.dart';
import '../../../database/local_database.dart';

class TransacaoServiceSimple {
  static TransacaoServiceSimple? _instance;
  static TransacaoServiceSimple get instance {
    _instance ??= TransacaoServiceSimple._internal();
    return _instance!;
  }
  
  TransacaoServiceSimple._internal();

  final _supabase = Supabase.instance.client;

  /// 📋 BUSCAR TRANSAÇÕES BÁSICAS
  Future<List<TransacaoModel>> fetchTransacoes({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
    String? contaId,
    String? categoriaId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('💳 Buscando transações do SQLITE para: ${_supabase.auth.currentUser?.email}');

      // ✅ BUSCA DO SQLITE (mesma fonte que recalcularSaldoConta)
      final db = LocalDatabase.instance;
      await db.setCurrentUser(userId);

      // Query do SQLite
      String whereClause = 'usuario_id = ?';
      List<dynamic> whereArgs = [userId];

      if (tipo != null) {
        whereClause += ' AND tipo = ?';
        whereArgs.add(tipo);
      }

      if (contaId != null) {
        whereClause += ' AND conta_id = ?';
        whereArgs.add(contaId);
      }

      if (categoriaId != null) {
        whereClause += ' AND categoria_id = ?';
        whereArgs.add(categoriaId);
      }

      if (dataInicio != null) {
        whereClause += ' AND data >= ?';
        whereArgs.add(dataInicio.toIso8601String().split('T')[0]);
      }

      if (dataFim != null) {
        whereClause += ' AND data <= ?';
        whereArgs.add(dataFim.toIso8601String().split('T')[0]);
      }

      final response = await db.database?.query(
        'transacoes',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data DESC',
        limit: 100,
      ) ?? [];

      log('✅ SQLite retornou ${response.length} transações');

      return response.map<TransacaoModel>((item) {
        return TransacaoModel.fromJson(item);
      }).toList();

    } catch (e) {
      log('❌ Erro ao buscar transações: $e');
      return [];
    }
  }

  /// 📊 RESUMO BÁSICO
  Future<Map<String, double>> fetchResumoPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final transacoes = await fetchTransacoes();
      
      double receitas = 0.0;
      double despesas = 0.0;
      
      for (final transacao in transacoes) {
        final data = transacao.data;
        if (data.isAfter(dataInicio) && data.isBefore(dataFim)) {
          if (transacao.tipo == 'receita') {
            receitas += transacao.valor;
          } else if (transacao.tipo == 'despesa') {
            despesas += transacao.valor;
          }
        }
      }
      
      return {
        'receitas': receitas,
        'despesas': despesas,
        'saldo': receitas - despesas,
      };
      
    } catch (e) {
      log('❌ Erro ao buscar resumo: $e');
      return {'receitas': 0.0, 'despesas': 0.0, 'saldo': 0.0};
    }
  }

  /// ➕ ADICIONAR TRANSAÇÃO
  Future<void> addTransacao({
    required String tipo,
    required String descricao,
    required double valor,
    required DateTime data,
    String? contaId,
    String? categoriaId,
    String? subcategoriaId,
    bool efetivado = true,
    String? observacoes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase.from('transacoes').insert({
        'usuario_id': userId,
        'tipo': tipo,
        'descricao': descricao,
        'valor': valor,
        'data': data.toIso8601String().split('T')[0],
        'conta_id': contaId,
        'categoria_id': categoriaId,
        'subcategoria_id': subcategoriaId,
        'efetivado': efetivado,
        'observacoes': observacoes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      log('✅ Transação criada com sucesso');

    } catch (e) {
      log('❌ Erro ao criar transação: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR TRANSAÇÃO
  Future<void> updateTransacao({
    required String transacaoId,
    String? descricao,
    double? valor,
    DateTime? data,
    String? contaId,
    String? categoriaId,
    String? subcategoriaId,
    bool? efetivado,
    String? observacoes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (descricao != null) updateData['descricao'] = descricao;
      if (valor != null) updateData['valor'] = valor;
      if (data != null) updateData['data'] = data.toIso8601String().split('T')[0];
      if (contaId != null) updateData['conta_id'] = contaId;
      if (categoriaId != null) updateData['categoria_id'] = categoriaId;
      if (subcategoriaId != null) updateData['subcategoria_id'] = subcategoriaId;
      if (efetivado != null) updateData['efetivado'] = efetivado;
      if (observacoes != null) updateData['observacoes'] = observacoes;

      await _supabase
          .from('transacoes')
          .update(updateData)
          .eq('id', transacaoId);

      log('✅ Transação atualizada com sucesso');

    } catch (e) {
      log('❌ Erro ao atualizar transação: $e');
      rethrow;
    }
  }

  /// 🗑️ DELETAR TRANSAÇÃO
  Future<void> deleteTransacao(String transacaoId) async {
    try {
      await _supabase
          .from('transacoes')
          .delete()
          .eq('id', transacaoId);

      log('✅ Transação deletada com sucesso');

    } catch (e) {
      log('❌ Erro ao deletar transação: $e');
      rethrow;
    }
  }

  /// 🔄 CRIAR TRANSFERÊNCIA
  Future<List<TransacaoModel>> criarTransferencia({
    required String contaOrigemId,
    required String contaDestinoId,
    required double valor,
    required DateTime data,
    required String descricao,
    String? observacoes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final agora = DateTime.now().toIso8601String();

      // Criar transação de débito (conta origem)
      final debito = await _supabase.from('transacoes').insert({
        'usuario_id': userId,
        'tipo': 'transferencia',
        'descricao': 'Transferência para: $descricao',
        'valor': -valor,
        'data': data.toIso8601String().split('T')[0],
        'conta_id': contaOrigemId,
        'conta_destino_id': contaDestinoId,
        'efetivado': true,
        'observacoes': observacoes,
        'created_at': agora,
        'updated_at': agora,
      }).select().single();

      // Criar transação de crédito (conta destino)
      final credito = await _supabase.from('transacoes').insert({
        'usuario_id': userId,
        'tipo': 'transferencia',
        'descricao': 'Transferência de: $descricao',
        'valor': valor,
        'data': data.toIso8601String().split('T')[0],
        'conta_id': contaDestinoId,
        'conta_origem_id': contaOrigemId,
        'efetivado': true,
        'observacoes': observacoes,
        'created_at': agora,
        'updated_at': agora,
      }).select().single();

      return [
        TransacaoModel.fromJson(debito),
        TransacaoModel.fromJson(credito),
      ];

    } catch (e) {
      log('❌ Erro ao criar transferência: $e');
      rethrow;
    }
  }
}