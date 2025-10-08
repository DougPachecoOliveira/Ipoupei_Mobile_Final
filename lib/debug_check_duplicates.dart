// 🔍 Script de Diagnóstico - Detectar Transações Duplicadas no SQLite
//
// Este script analisa o banco SQLite local para identificar:
// 1. Transações duplicadas (mesmo ID)
// 2. Transações "gêmeas" (mesma data, valor, descrição, conta)
// 3. Soma total por conta para comparar com Supabase

import 'dart:developer';
import 'package:ipoupei_mobile/src/database/local_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DuplicateChecker {
  final _localDb = LocalDatabase.instance;
  final _supabase = Supabase.instance.client;

  /// 🔍 Verificar duplicatas na conta específica
  Future<void> checkDuplicatesForAccount(String contaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        log('❌ Usuário não autenticado');
        return;
      }

      await _localDb.setCurrentUser(userId);
      final db = _localDb.database;
      if (db == null) {
        log('❌ Database não inicializado');
        return;
      }

      log('🔍 ===== DIAGNÓSTICO DE DUPLICATAS =====');
      log('🏦 Conta ID: $contaId');
      log('👤 Usuário ID: $userId');
      log('');

      // 1️⃣ BUSCAR TODAS AS TRANSAÇÕES DA CONTA
      final todasTransacoes = await db.query(
        'transacoes',
        where: 'conta_id = ? AND usuario_id = ?',
        whereArgs: [contaId, userId],
        orderBy: 'data DESC, created_at DESC',
      );

      log('📊 Total de transações encontradas: ${todasTransacoes.length}');
      log('');

      // 2️⃣ VERIFICAR IDs DUPLICADOS
      final idsContados = <String, int>{};
      for (final t in todasTransacoes) {
        final id = t['id'] as String;
        idsContados[id] = (idsContados[id] ?? 0) + 1;
      }

      final idsDuplicados = idsContados.entries.where((e) => e.value > 1).toList();
      if (idsDuplicados.isNotEmpty) {
        log('⚠️ IDs DUPLICADOS ENCONTRADOS:');
        for (final entry in idsDuplicados) {
          log('   ID: ${entry.key} - Aparece ${entry.value}x');
        }
        log('');
      } else {
        log('✅ Nenhum ID duplicado encontrado');
        log('');
      }

      // 3️⃣ VERIFICAR TRANSAÇÕES "GÊMEAS" (mesma data, valor, descrição)
      final chaves = <String, List<Map<String, dynamic>>>{};
      for (final t in todasTransacoes) {
        final chave = '${t['data']}_${t['valor']}_${t['descricao']}_${t['tipo']}';
        chaves[chave] ??= [];
        chaves[chave]!.add(t);
      }

      final gemeas = chaves.entries.where((e) => e.value.length > 1).toList();
      if (gemeas.isNotEmpty) {
        log('⚠️ TRANSAÇÕES GÊMEAS ENCONTRADAS (mesma data/valor/descrição):');
        for (final entry in gemeas) {
          log('   Grupo: ${entry.value.length} transações idênticas');
          for (final t in entry.value) {
            log('      - ID: ${t['id']}, Data: ${t['data']}, Valor: R\$ ${t['valor']}, Desc: "${t['descricao']}", Efetivado: ${t['efetivado']}');
          }
        }
        log('');
      } else {
        log('✅ Nenhuma transação gêmea encontrada');
        log('');
      }

      // 4️⃣ SOMAS POR TIPO (APENAS EFETIVADAS)
      final efetivadas = todasTransacoes.where((t) => t['efetivado'] == 1).toList();
      log('📊 SOMAS (apenas efetivadas = ${efetivadas.length} transações):');

      double totalReceitas = 0;
      double totalDespesas = 0;
      double totalTransfRecebidas = 0;
      double totalTransfEnviadas = 0;
      int countReceitas = 0;
      int countDespesas = 0;
      int countTransfRecebidas = 0;
      int countTransfEnviadas = 0;

      for (final t in efetivadas) {
        final tipo = t['tipo'] as String;
        final valor = (t['valor'] as num).toDouble();

        if (tipo == 'receita') {
          totalReceitas += valor;
          countReceitas++;
        } else if (tipo == 'despesa') {
          totalDespesas += valor;
          countDespesas++;
        } else if (tipo == 'transferencia') {
          if (valor > 0) {
            totalTransfRecebidas += valor;
            countTransfRecebidas++;
          } else {
            totalTransfEnviadas += valor.abs();
            countTransfEnviadas++;
          }
        }
      }

      log('   💰 Receitas: R\$ ${totalReceitas.toStringAsFixed(2)} ($countReceitas transações)');
      log('   💸 Despesas: R\$ ${totalDespesas.toStringAsFixed(2)} ($countDespesas transações)');
      log('   ➡️  Transf Recebidas: R\$ ${totalTransfRecebidas.toStringAsFixed(2)} ($countTransfRecebidas transações)');
      log('   ⬅️  Transf Enviadas: R\$ ${totalTransfEnviadas.toStringAsFixed(2)} ($countTransfEnviadas transações)');
      log('');

      // 5️⃣ LISTAR TODAS AS RECEITAS EFETIVADAS (para debug)
      log('📋 LISTA DE TODAS AS RECEITAS EFETIVADAS:');
      final receitasEfetivadas = efetivadas.where((t) => t['tipo'] == 'receita').toList();
      for (int i = 0; i < receitasEfetivadas.length; i++) {
        final t = receitasEfetivadas[i];
        log('   ${i + 1}. R\$ ${(t['valor'] as num).toStringAsFixed(2)} - ${t['data']} - "${t['descricao']}" (ID: ${t['id']})');
      }
      log('');

      // 6️⃣ VERIFICAR SYNC QUEUE
      final syncQueue = await db.query('sync_queue', orderBy: 'created_at DESC');
      log('📤 SYNC QUEUE: ${syncQueue.length} itens pendentes');
      if (syncQueue.isNotEmpty) {
        final porOperacao = <String, int>{};
        for (final item in syncQueue) {
          final op = item['operation'] as String;
          porOperacao[op] = (porOperacao[op] ?? 0) + 1;
        }
        for (final entry in porOperacao.entries) {
          log('   - ${entry.key}: ${entry.value} itens');
        }
      }
      log('');

      log('🔍 ===== FIM DO DIAGNÓSTICO =====');

    } catch (e, stack) {
      log('❌ Erro no diagnóstico: $e');
      log('Stack: $stack');
    }
  }

  /// 🔍 Verificar duplicatas em TODAS as contas
  Future<void> checkAllAccounts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        log('❌ Usuário não autenticado');
        return;
      }

      await _localDb.setCurrentUser(userId);
      final db = _localDb.database;
      if (db == null) {
        log('❌ Database não inicializado');
        return;
      }

      // Buscar todas as contas
      final contas = await db.query('contas', where: 'usuario_id = ?', whereArgs: [userId]);

      log('🔍 ===== VERIFICANDO TODAS AS CONTAS =====');
      log('Total de contas: ${contas.length}');
      log('');

      for (final conta in contas) {
        final contaId = conta['id'] as String;
        final nome = conta['nome'] as String;
        log('🏦 Verificando conta: $nome');
        await checkDuplicatesForAccount(contaId);
        log('');
      }

    } catch (e, stack) {
      log('❌ Erro ao verificar todas as contas: $e');
      log('Stack: $stack');
    }
  }
}
