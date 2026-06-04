// 💳 Transacao Service Complete - iPoupei Mobile
// 
// Serviço COMPLETO para transações idêntico ao React
// Implementa TODOS os campos e lógicas do projeto original
// 
// Baseado em: ReceitasModal.jsx e DespesasModal.jsx

import 'dart:async';
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transacao_model.dart';
import '../../../database/local_database.dart';
import '../../../sync/connectivity_helper.dart';
import '../../../sync/sync_manager.dart';
import '../../categorias/services/categoria_service.dart';
import '../../contas/services/conta_service.dart';
import '../../../shared/services/contas_refresh_notifier.dart';

class TransacaoService {
  static TransacaoService? _instance;
  static TransacaoService get instance {
    _instance ??= TransacaoService._internal();
    return _instance!;
  }
  
  TransacaoService._internal();

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// 💰 CRIAR RECEITA (OFFLINE-FIRST - FUNCIONA SEM INTERNET)
  Future<List<TransacaoModel>> criarReceita({
    required String descricao,
    required double valor,
    required DateTime data,
    required String contaId,
    required String categoriaId,
    String? subcategoriaId,
    required String tipoReceita, // 'extra', 'parcelada', 'previsivel'
    bool efetivado = true,
    String? observacoes,
    int? numeroParcelas,
    String? frequenciaParcelada = 'mensal',
    String? frequenciaPrevisivel = 'mensal',
    int? numeroRepeticoes, // ✅ NOVO PARÂMETRO
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('💰 Criando receita OFFLINE-FIRST: $descricao ($tipoReceita)');

      // 🔍 VERIFICA CONECTIVIDADE PRIMEIRO
      final isOnline = await ConnectivityHelper.instance.isOnline();
      log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

      final now = DateTime.now();
      final dadosBase = {
        'usuario_id': userId,
        'descricao': descricao.trim(),
        'categoria_id': categoriaId,
        'subcategoria_id': subcategoriaId,
        'conta_id': contaId,
        'valor': valor,
        'tipo': 'receita',
        'tipo_receita': tipoReceita,
        'observacoes': observacoes?.trim(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'efetivado': efetivado,
        'recorrente': false,
        'eh_recorrente': false,
        'transferencia': false,
        'ajuste_manual': false,
        'sincronizado': isOnline, // TRUE se online, FALSE se offline
        'numero_parcelas': 1,
      };

      List<Map<String, dynamic>> receitasCriadas = [];

      switch (tipoReceita) {
        case 'extra':
          receitasCriadas = [{
            ...dadosBase,
            'id': _uuid.v4(),
            'data': data.toIso8601String().split('T')[0],
          }];
          break;

        case 'parcelada':
          final grupoId = _uuid.v4();
          final totalParcelas = numeroParcelas ?? 12;
          final dataBase = data;
          
          // 💰 CÁLCULO CORRETO DAS PARCELAS (corrigindo bug do React)
          final valoresParcelas = _calcularValoresParcelas(valor, totalParcelas);
          
          for (int i = 0; i < totalParcelas; i++) {
            final dataReceita = _calcularDataParcela(dataBase, i, frequenciaParcelada!);
            final efetivoStatus = i == 0 ? efetivado : false;
            final sufixo = ' (${i + 1}/$totalParcelas)';
            
            receitasCriadas.add({
              ...dadosBase,
              'id': _uuid.v4(),
              'data': dataReceita.toIso8601String().split('T')[0],
              'descricao': (dadosBase['descricao'] as String) + sufixo,
              'valor': valoresParcelas[i], // ✅ VALOR CORRETO POR PARCELA
              'efetivado': efetivoStatus,
              'recorrente': true,
              'grupo_parcelamento': grupoId,
              'parcela_atual': i + 1,
              'total_parcelas': totalParcelas,
              'numero_parcelas': totalParcelas,
            });
          }
          break;

        case 'previsivel':
          final grupoId = _uuid.v4();
          final totalRecorrencias = numeroRepeticoes ?? _calcularTotalRecorrencias(frequenciaPrevisivel!);
          final dataBase = data;
          
          for (int i = 0; i < totalRecorrencias; i++) {
            final dataReceita = _calcularDataParcela(dataBase, i, frequenciaPrevisivel!);
            final efetivoStatus = i == 0 ? efetivado : false;
            
            receitasCriadas.add({
              ...dadosBase,
              'id': _uuid.v4(),
              'data': dataReceita.toIso8601String().split('T')[0],
              'efetivado': efetivoStatus,
              'recorrente': true,
              'eh_recorrente': true,
              'grupo_recorrencia': grupoId,
              'numero_recorrencia': i + 1,
              'total_recorrencias': totalRecorrencias,
              'tipo_recorrencia': frequenciaPrevisivel,
            });
          }
          break;
      }

      // ✅ SEMPRE SALVA NO SQLITE LOCAL PRIMEIRO (OFFLINE-FIRST)
      final receitasModels = <TransacaoModel>[];
      for (final receita in receitasCriadas) {
        // Converte para formato SQLite
        final receitaSQL = _prepararDadosSQLite(receita);

        // Salva no SQLite local
        await LocalDatabase.instance.addTransacaoLocal(receitaSQL);

        // ⚡ Recalcula saldo da conta antes de notificar a UI (determinístico)
        if (efetivado) {
          await LocalDatabase.instance.recalcularSaldoConta(contaId);
        }

        // Cria modelo para retorno
        receitasModels.add(TransacaoModel.fromJson(receita));

        log('💾 Receita salva no SQLite: ${receita['id']}');
      }

      // ✅ SE ESTIVER ONLINE, TENTA SALVAR NO SUPABASE TAMBÉM
      if (isOnline) {
        try {
          final response = await _supabase
              .from('transacoes')
              .insert(receitasCriadas)
              .select();

          log('☁️ ${response.length} receita(s) sincronizada(s) com Supabase');
        } catch (onlineError) {
          log('⚠️ Erro ao sincronizar online (dados salvos offline): $onlineError');
          
          // Marca como não sincronizado para tentar depois
          for (final receita in receitasCriadas) {
            await LocalDatabase.instance.updateTransacaoLocal(
              receita['id'],
              {'sincronizado': 0} // FALSE em SQLite
            );
          }
        }
      } else {
        log('📱 Modo OFFLINE: ${receitasCriadas.length} receita(s) salva(s) localmente para sincronizar depois');
      }

      log('✅ ${receitasModels.length} receita(s) criada(s): $descricao ${isOnline ? "(online + offline)" : "(somente offline)"}');

      // 🔔 NOTIFICA MUDANÇA PARA CACHE DE CATEGORIAS
      CategoriaService.instance.notificarMudancaTransacoes();

      // 🔔 Notificar mudança nos saldos das contas
      ContasRefreshNotifier.instance.notificarMudancaContas();

      return receitasModels;
    } catch (e) {
      log('❌ Erro ao criar receita: $e');
      rethrow;
    }
  }

  /// 💸 CRIAR DESPESA (OFFLINE-FIRST - FUNCIONA SEM INTERNET)
  Future<List<TransacaoModel>> criarDespesa({
    required String descricao,
    required double valor,
    required DateTime data,
    required String contaId,
    required String categoriaId,
    String? subcategoriaId,
    required String tipoDespesa, // 'extra', 'parcelada', 'previsivel'
    bool efetivado = true,
    String? observacoes,
    int? numeroParcelas,
    String? frequenciaParcelada = 'mensal',
    String? frequenciaPrevisivel = 'mensal',
    int? numeroRepeticoes, // ✅ NOVO PARÂMETRO
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('💸 Criando despesa OFFLINE-FIRST: $descricao ($tipoDespesa)');

      // 🔍 VERIFICA CONECTIVIDADE PRIMEIRO
      final isOnline = await ConnectivityHelper.instance.isOnline();
      log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

      final now = DateTime.now();
      final dadosBase = {
        'usuario_id': userId,
        'descricao': descricao.trim(),
        'categoria_id': categoriaId,
        'subcategoria_id': subcategoriaId,
        'conta_id': contaId,
        'valor': valor,
        'tipo': 'despesa',
        'tipo_despesa': tipoDespesa,
        'observacoes': observacoes?.trim(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'efetivado': efetivado,
        'recorrente': false,
        'eh_recorrente': false,
        'transferencia': false,
        'ajuste_manual': false,
        'sincronizado': isOnline, // TRUE se online, FALSE se offline
        'numero_parcelas': 1,
      };

      List<Map<String, dynamic>> despesasCriadas = [];

      switch (tipoDespesa) {
        case 'extra':
          despesasCriadas = [{
            ...dadosBase,
            'id': _uuid.v4(),
            'data': data.toIso8601String().split('T')[0],
          }];
          break;

        case 'parcelada':
          final grupoId = _uuid.v4();
          final totalParcelas = numeroParcelas ?? 12;
          final dataBase = data;
          
          // 💰 CÁLCULO CORRETO DAS PARCELAS (corrigindo bug do React)
          final valoresParcelas = _calcularValoresParcelas(valor, totalParcelas);
          
          for (int i = 0; i < totalParcelas; i++) {
            final dataDespesa = _calcularDataParcela(dataBase, i, frequenciaParcelada!);
            final efetivoStatus = i == 0 ? efetivado : false;
            final sufixo = ' (${i + 1}/$totalParcelas)';
            
            despesasCriadas.add({
              ...dadosBase,
              'id': _uuid.v4(),
              'data': dataDespesa.toIso8601String().split('T')[0],
              'descricao': (dadosBase['descricao'] as String) + sufixo,
              'valor': valoresParcelas[i], // ✅ VALOR CORRETO POR PARCELA
              'efetivado': efetivoStatus,
              'recorrente': true,
              'grupo_parcelamento': grupoId,
              'parcela_atual': i + 1,
              'total_parcelas': totalParcelas,
              'numero_parcelas': totalParcelas,
            });
          }
          break;

        case 'previsivel':
          final grupoId = _uuid.v4();
          final totalRecorrencias = numeroRepeticoes ?? _calcularTotalRecorrencias(frequenciaPrevisivel!);
          final dataBase = data;
          
          for (int i = 0; i < totalRecorrencias; i++) {
            final dataDespesa = _calcularDataParcela(dataBase, i, frequenciaPrevisivel!);
            final efetivoStatus = i == 0 ? efetivado : false;
            
            despesasCriadas.add({
              ...dadosBase,
              'id': _uuid.v4(),
              'data': dataDespesa.toIso8601String().split('T')[0],
              'efetivado': efetivoStatus,
              'recorrente': true,
              'eh_recorrente': true,
              'grupo_recorrencia': grupoId,
              'numero_recorrencia': i + 1,
              'total_recorrencias': totalRecorrencias,
              'tipo_recorrencia': frequenciaPrevisivel,
            });
          }
          break;
      }

      // ✅ SEMPRE SALVA NO SQLITE LOCAL PRIMEIRO (OFFLINE-FIRST)
      final despesasModels = <TransacaoModel>[];
      for (final despesa in despesasCriadas) {
        // Converte para formato SQLite
        final despesaSQL = _prepararDadosSQLite(despesa);

        // Salva no SQLite local
        await LocalDatabase.instance.addTransacaoLocal(despesaSQL);

        // ⚡ Recalcula saldo da conta antes de notificar a UI (determinístico)
        if (efetivado) {
          await LocalDatabase.instance.recalcularSaldoConta(contaId);
        }

        // Cria modelo para retorno
        despesasModels.add(TransacaoModel.fromJson(despesa));

        log('💾 Despesa salva no SQLite: ${despesa['id']}');
      }

      // ✅ SE ESTIVER ONLINE, TENTA SALVAR NO SUPABASE TAMBÉM
      if (isOnline) {
        try {
          final response = await _supabase
              .from('transacoes')
              .insert(despesasCriadas)
              .select();

          log('☁️ ${response.length} despesa(s) sincronizada(s) com Supabase');
        } catch (onlineError) {
          log('⚠️ Erro ao sincronizar online (dados salvos offline): $onlineError');
          
          // Marca como não sincronizado para tentar depois
          for (final despesa in despesasCriadas) {
            await LocalDatabase.instance.updateTransacaoLocal(
              despesa['id'],
              {'sincronizado': 0} // FALSE em SQLite
            );
          }
        }
      } else {
        log('📱 Modo OFFLINE: ${despesasCriadas.length} despesa(s) salva(s) localmente para sincronizar depois');
      }

      log('✅ ${despesasModels.length} despesa(s) criada(s): $descricao ${isOnline ? "(online + offline)" : "(somente offline)"}');

      // 🔔 NOTIFICA MUDANÇA PARA CACHE DE CATEGORIAS
      CategoriaService.instance.notificarMudancaTransacoes();

      // 🔔 Notificar mudança nos saldos das contas
      ContasRefreshNotifier.instance.notificarMudancaContas();

      return despesasModels;
    } catch (e) {
      log('❌ Erro ao criar despesa: $e');
      rethrow;
    }
  }

  /// 💱 CRIAR TRANSFERÊNCIA (OFFLINE-FIRST - FUNCIONA SEM INTERNET)
  Future<List<TransacaoModel>> criarTransferencia({
    required String descricao,
    required double valor,
    required DateTime data,
    required String contaOrigemId,
    required String contaDestinoId,
    String? observacoes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('💱 Criando transferência OFFLINE-FIRST: $descricao');

      // 🔍 VERIFICA CONECTIVIDADE PRIMEIRO
      final isOnline = await ConnectivityHelper.instance.isOnline();
      log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

      final now = DateTime.now();
      final grupoId = _uuid.v4();

      // ✅ CRIAR SAÍDA (DESPESA NA CONTA ORIGEM)
      final transacaoSaida = {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'descricao': 'Transferência enviada: $descricao',
        'conta_id': contaOrigemId,
        'conta_destino_id': contaDestinoId,
        'valor': valor,
        'tipo': 'despesa',
        'tipo_despesa': 'extra',
        'data': data.toIso8601String().split('T')[0],
        'efetivado': true,
        'observacoes': observacoes?.trim(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'transferencia': true,
        'grupo_parcelamento': grupoId,
        'recorrente': false,
        'eh_recorrente': false,
        'numero_parcelas': 1,
        'ajuste_manual': false,
        'sincronizado': isOnline,
      };

      // ✅ CRIAR ENTRADA (RECEITA NA CONTA DESTINO)
      final transacaoEntrada = {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'descricao': 'Transferência recebida: $descricao',
        'conta_id': contaDestinoId,
        'conta_destino_id': contaOrigemId,
        'valor': valor,
        'tipo': 'receita',
        'tipo_receita': 'extra',
        'data': data.toIso8601String().split('T')[0],
        'efetivado': true,
        'observacoes': observacoes?.trim(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'transferencia': true,
        'grupo_parcelamento': grupoId,
        'recorrente': false,
        'eh_recorrente': false,
        'numero_parcelas': 1,
        'ajuste_manual': false,
        'sincronizado': isOnline,
      };

      // ✅ SEMPRE SALVA NO SQLITE LOCAL PRIMEIRO (OFFLINE-FIRST)
      await LocalDatabase.instance.addTransacaoLocal(transacaoSaida);
      log('💾 Saída salva no SQLite: ${transacaoSaida['id']}');

      await LocalDatabase.instance.addTransacaoLocal(transacaoEntrada);
      log('💾 Entrada salva no SQLite: ${transacaoEntrada['id']}');

      // ⚡ Recalcula saldo das 2 contas em paralelo antes de notificar a UI
      await Future.wait([
        LocalDatabase.instance.recalcularSaldoConta(contaOrigemId),
        LocalDatabase.instance.recalcularSaldoConta(contaDestinoId),
      ]);

      final transferenciasModels = [
        TransacaoModel.fromJson(transacaoSaida),
        TransacaoModel.fromJson(transacaoEntrada),
      ];

      // ✅ SE ESTIVER ONLINE, TENTA SALVAR NO SUPABASE TAMBÉM
      if (isOnline) {
        try {
          await _supabase
              .from('transacoes')
              .insert([transacaoSaida, transacaoEntrada]);

          log('☁️ Transferência sincronizada com Supabase');
        } catch (onlineError) {
          log('⚠️ Erro ao sincronizar online (dados salvos offline): $onlineError');

          // Marca como não sincronizado para tentar depois
          await LocalDatabase.instance.updateTransacaoLocal(
            transacaoSaida['id'] as String,
            {'sincronizado': 0}
          );
          await LocalDatabase.instance.updateTransacaoLocal(
            transacaoEntrada['id'] as String,
            {'sincronizado': 0}
          );
        }
      } else {
        log('📱 Modo OFFLINE: Transferência salva localmente para sincronizar depois');
      }

      log('✅ Transferência criada: $descricao ${isOnline ? "(online + offline)" : "(somente offline)"}');

      // 🔔 Notificar mudança nos saldos das contas
      ContasRefreshNotifier.instance.notificarMudancaContas();

      return transferenciasModels;
    } catch (e) {
      log('❌ Erro ao criar transferência: $e');
      rethrow;
    }
  }


  /// ✅ CALCULAR TOTAL DE RECORRÊNCIAS (IGUAL AO REACT)
  int _calcularTotalRecorrencias(String frequencia) {
    switch (frequencia) {
      case 'semanal': return 20 * 52; // 20 anos
      case 'quinzenal': return 20 * 26; // 20 anos
      case 'mensal': return 20 * 12; // 20 anos
      case 'anual': return 20; // 20 anos
      default: return 20 * 12;
    }
  }

  /// ✅ VALIDAR DADOS DE TRANSAÇÃO
  Map<String, String> validarTransacao({
    required String descricao,
    required double valor,
    required String contaId,
    required String categoriaId,
  }) {
    Map<String, String> erros = {};

    if (descricao.trim().isEmpty) {
      erros['descricao'] = 'Descrição é obrigatória';
    }

    if (valor <= 0) {
      erros['valor'] = 'Valor deve ser maior que zero';
    }

    if (contaId.isEmpty) {
      erros['conta'] = 'Conta é obrigatória';
    }

    if (categoriaId.isEmpty) {
      erros['categoria'] = 'Categoria é obrigatória';
    }

    return erros;
  }

  /// ✅ CRIAR CATEGORIA AUTOMATICAMENTE (SE NÃO EXISTIR)
  Future<String> criarCategoriaSeNecessario(String nomeCategoria, String tipo) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('🔍 Verificando categoria: $nomeCategoria ($tipo) para usuário: $userId');

      // 1. Tentar buscar categoria existente PRIMEIRO
      final existing = await _supabase
          .from('categorias')
          .select('id, nome')
          .eq('usuario_id', userId)
          .eq('tipo', tipo)
          .eq('ativo', true)
          .limit(1);

      if (existing.isNotEmpty) {
        log('✅ Usando categoria existente: ${existing[0]['nome']} (${existing[0]['id']})');
        return existing[0]['id'];
      }

      log('📂 Nenhuma categoria encontrada, criando: $nomeCategoria');

      // 2. Criar nova categoria se não existe nenhuma
      final novaCategoria = await _supabase
          .from('categorias')
          .insert({
            'id': _uuid.v4(),
            'usuario_id': userId,
            'nome': nomeCategoria,
            'tipo': tipo,
            'icone': tipo == 'receita' ? 'trending-up' : 'trending-down',
            'cor': tipo == 'receita' ? '#10b981' : '#ef4444',
            'ativo': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id, nome')
          .single();

      log('✅ Categoria criada: ${novaCategoria['nome']} (${novaCategoria['id']})');
      return novaCategoria['id'];
    } catch (e) {
      log('❌ Erro ao criar/buscar categoria: $e');
      
      // 3. FALLBACK: Tentar buscar QUALQUER categoria do tipo para o usuário
      try {
        final fallbackUserId = _supabase.auth.currentUser?.id;
        if (fallbackUserId == null) throw Exception('Usuário não autenticado no fallback');
        
        log('🔄 Tentando fallback: buscar qualquer categoria do tipo $tipo');
        final fallback = await _supabase
            .from('categorias')
            .select('id, nome')
            .eq('usuario_id', fallbackUserId)
            .eq('tipo', tipo)
            .limit(1)
            .single();
        
        log('✅ Usando categoria fallback: ${fallback['nome']} (${fallback['id']})');
        return fallback['id'];
      } catch (fallbackError) {
        log('❌ Erro no fallback: $fallbackError');
        rethrow;
      }
    }
  }

  /// 💳 BUSCAR TRANSAÇÕES COM FILTROS (OFFLINE-FIRST - FUNCIONA SEM INTERNET)
  Future<List<TransacaoModel>> fetchTransacoes({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
    String? contaId,
    String? categoriaId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('💳 Buscando transações OFFLINE-FIRST para: ${_supabase.auth.currentUser?.email}');

      // 🔄 OFFLINE-FIRST: Busca do SQLite local
      final db = LocalDatabase.instance.database;
      if (db == null) {
        log('⚠️ Database não inicializado');
        return [];
      }

      // Construir WHERE clause
      final whereConditions = <String>['usuario_id = ?'];
      final whereArgs = <dynamic>[userId];

      if (dataInicio != null) {
        whereConditions.add('data >= ?');
        whereArgs.add(dataInicio.toIso8601String().split('T')[0]);
      }
      if (dataFim != null) {
        whereConditions.add('data <= ?');
        whereArgs.add(dataFim.toIso8601String());
      }
      if (tipo != null && tipo.isNotEmpty) {
        if (tipo == 'transferencia') {
          // Para transferências, usar o campo transferencia = true
          whereConditions.add('transferencia = ?');
          whereArgs.add(1); // SQLite boolean = 1
          print('🔍 DEBUG QUERY: Buscando transferências com WHERE transferencia = 1');
        } else {
          // Para outros tipos, usar campo tipo normalmente
          whereConditions.add('tipo = ?');
          whereArgs.add(tipo);
          print('🔍 DEBUG QUERY: Buscando tipo "$tipo" com WHERE tipo = $tipo');
        }
      }
      if (contaId != null && contaId.isNotEmpty) {
        whereConditions.add('conta_id = ?');
        whereArgs.add(contaId);
      }
      if (categoriaId != null && categoriaId.isNotEmpty) {
        whereConditions.add('categoria_id = ?');
        whereArgs.add(categoriaId);
      }

      final where = whereConditions.join(' AND ');

      log('🔍 Query SQLite: WHERE $where');
      log('🔍 Args: $whereArgs');

      // Buscar do SQLite
      final result = await db.query(
        'transacoes',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'data DESC, created_at DESC',
        limit: limit,
        offset: offset,
      );

      // Debug: verificar se existem transferências no banco quando buscamos transferências
      if (tipo == 'transferencia') {
        final debugQuery = await db.rawQuery('SELECT COUNT(*) as total FROM transacoes WHERE transferencia = 1');
        final totalTransferencias = debugQuery.isNotEmpty ? debugQuery.first['total'] ?? 0 : 0;
        log('🔍 DEBUG: Total de transferências no banco: $totalTransferencias');

        // Também verificar algumas transferências de exemplo
        final exemploQuery = await db.rawQuery('SELECT id, descricao, tipo, transferencia FROM transacoes WHERE transferencia = 1 LIMIT 3');
        log('🔍 DEBUG: Exemplos de transferências: $exemploQuery');
      }

      log('💾 ${result.length} transações encontradas no SQLite');

      final transacoes = result.map<TransacaoModel>((item) {
        return TransacaoModel.fromJson(item);
      }).toList();

      log('✅ Transações carregadas (offline-first): ${transacoes.length}');
      return transacoes;
    } catch (e) {
      log('❌ Erro ao buscar transações: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR TRANSAÇÃO (OFFLINE-FIRST - FUNCIONA SEM INTERNET)
  Future<TransacaoModel> updateTransacao({
    required String transacaoId,
    String? descricao,
    double? valor,
    DateTime? data,
    String? contaId,
    String? contaDestinoId,
    String? cartaoId,
    String? categoriaId,
    String? subcategoriaId,
    bool? efetivado,
    String? observacoes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('✏️ Atualizando transação OFFLINE-FIRST: $transacaoId');

      // 🔍 VERIFICA CONECTIVIDADE
      final isOnline = await ConnectivityHelper.instance.isOnline();
      log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

      // ✅ BUSCAR DADOS ATUAIS DO SQLITE LOCAL
      final db = LocalDatabase.instance.database;
      if (db == null) throw Exception('Database não inicializado');

      final result = await db.query(
        'transacoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [transacaoId, userId],
      );

      if (result.isEmpty) {
        throw Exception('Transação não encontrada');
      }

      final transacaoAtual = result.first;
      final isCartaoEfetivado = transacaoAtual['cartao_id'] != null &&
                                transacaoAtual['efetivado'] == 1;

      // ❌ VALIDAÇÕES PARA CARTÕES EFETIVADOS
      if (isCartaoEfetivado) {
        if (valor != null) {
          throw Exception('Não é possível alterar valor de despesa de cartão já efetivada (fatura paga)');
        }
        if (contaId != null || cartaoId != null) {
          throw Exception('Não é possível alterar conta/cartão de despesa efetivada');
        }
        if (data != null) {
          throw Exception('Não é possível alterar data de despesa de cartão efetivada');
        }
        if (efetivado == false) {
          throw Exception('Despesas de cartão efetivadas não podem ser tornadas pendentes (fatura já paga)');
        }

        log('💳 Editando cartão efetivado - apenas descrição, categoria, subcategoria e observações permitidas');
      }

      // ✅ VALIDAÇÕES PARA TRANSAÇÕES EFETIVADAS NORMAIS
      if (transacaoAtual['efetivado'] == 1 && transacaoAtual['cartao_id'] == null) {
        if (valor != null) {
          throw Exception('Não é possível alterar valor de transação efetivada');
        }
        if (contaId != null || contaDestinoId != null) {
          throw Exception('Não é possível alterar contas de transação efetivada');
        }
        if (data != null) {
          throw Exception('Não é possível alterar data de transação efetivada');
        }
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (descricao != null) updateData['descricao'] = descricao;
      if (valor != null) updateData['valor'] = valor;
      if (data != null) updateData['data'] = data.toIso8601String().split('T')[0];
      if (contaId != null) updateData['conta_id'] = contaId;
      if (contaDestinoId != null) updateData['conta_destino_id'] = contaDestinoId;
      if (cartaoId != null) updateData['cartao_id'] = cartaoId;
      if (categoriaId != null) updateData['categoria_id'] = categoriaId;
      if (subcategoriaId != null) updateData['subcategoria_id'] = subcategoriaId;
      if (efetivado != null) updateData['efetivado'] = efetivado ? 1 : 0; // SQLite boolean
      if (observacoes != null) updateData['observacoes'] = observacoes;

      // ✅ SEMPRE ATUALIZA SQLITE LOCAL PRIMEIRO
      await LocalDatabase.instance.updateTransacaoLocal(transacaoId, updateData);
      log('💾 Transação atualizada no SQLite: $transacaoId');

      // ⚡ Recalcular saldo se efetivado mudou
      final mudouEfetivado = efetivado != null && efetivado != (transacaoAtual['efetivado'] == 1);
      if (mudouEfetivado && transacaoAtual['conta_id'] != null) {
        final contaAfetada = transacaoAtual['conta_id'] as String;
        await LocalDatabase.instance.recalcularSaldoConta(contaAfetada);
        log('⚡ Saldo recalculado da conta $contaAfetada');
      }

      // ✅ SE ONLINE, TENTA SINCRONIZAR COM SUPABASE
      if (isOnline) {
        try {
          // Converter boolean para Supabase
          final updateDataSupabase = Map<String, dynamic>.from(updateData);
          if (efetivado != null) updateDataSupabase['efetivado'] = efetivado; // Boolean para Supabase

          await _supabase
              .from('transacoes')
              .update(updateDataSupabase)
              .eq('id', transacaoId)
              .eq('usuario_id', userId);

          log('☁️ Transação sincronizada com Supabase: $transacaoId');
        } catch (onlineError) {
          log('⚠️ Erro ao sincronizar com Supabase: $onlineError');
          // Marca como não sincronizado
          await LocalDatabase.instance.updateTransacaoLocal(
            transacaoId,
            {'sincronizado': 0}
          );
        }
      } else {
        log('📱 Offline: Atualização será sincronizada quando voltar online');
      }

      // 🔔 NOTIFICA MUDANÇA PARA CACHE DE CATEGORIAS
      CategoriaService.instance.notificarMudancaTransacoes();

      // Buscar transação atualizada do SQLite para retornar
      final updated = await db.query(
        'transacoes',
        where: 'id = ?',
        whereArgs: [transacaoId],
      );

      log('✅ Transação atualizada: $transacaoId ${isOnline ? "(online + offline)" : "(somente offline)"}');
      return TransacaoModel.fromJson(updated.first);
    } catch (e) {
      log('❌ Erro ao atualizar transação: $e');
      rethrow;
    }
  }

  /// 🗑️ EXCLUIR TRANSAÇÃO (OFFLINE-FIRST)
  Future<void> deleteTransacao(String transacaoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('🗑️ Excluindo transação OFFLINE-FIRST: $transacaoId');

      // 🔍 VERIFICA CONECTIVIDADE
      final isOnline = await ConnectivityHelper.instance.isOnline();
      log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

      // ⚡ BUSCAR conta_id ANTES de deletar (para recalcular depois)
      final db = LocalDatabase.instance.database;
      String? contaAfetada;
      bool transacaoEfetivada = false;

      if (db != null) {
        final result = await db.query(
          'transacoes',
          columns: ['conta_id', 'efetivado'],
          where: 'id = ?',
          whereArgs: [transacaoId],
        );

        if (result.isNotEmpty) {
          contaAfetada = result.first['conta_id'] as String?;
          transacaoEfetivada = result.first['efetivado'] == 1;
        }
      }

      // ✅ SEMPRE EXCLUI DO SQLite LOCAL PRIMEIRO (OFFLINE-FIRST)
      await LocalDatabase.instance.deleteTransacaoLocal(transacaoId);
      log('💾 Transação excluída do SQLite local: $transacaoId');

      // ⚡ Recalcula saldo da conta afetada (se existir e estava efetivada)
      if (contaAfetada != null && transacaoEfetivada) {
        await LocalDatabase.instance.recalcularSaldoConta(contaAfetada);
        log('⚡ Saldo recalculado da conta $contaAfetada');
      }

      // 🌐 TENTA SINCRONIZAR COM SUPABASE SE ONLINE
      if (isOnline) {
        try {
          await _supabase
              .from('transacoes')
              .delete()
              .eq('id', transacaoId)
              .eq('usuario_id', userId);
          log('☁️ Transação excluída do Supabase: $transacaoId');
        } catch (e) {
          log('⚠️ Falha na exclusão no Supabase: $e');
          // Não falha - dados já foram excluídos localmente
          // Sync automático tentará novamente em background
        }
      } else {
        log('📱 Offline: Exclusão será sincronizada quando voltar online');
      }

      // 🔔 NOTIFICA MUDANÇA PARA CACHE DE CATEGORIAS
      CategoriaService.instance.notificarMudancaTransacoes();

      log('✅ Transação excluída com sucesso: $transacaoId ${isOnline ? "(online + offline)" : "(somente offline)"}');
    } catch (e) {
      log('❌ Erro ao excluir transação: $e');
      rethrow;
    }
  }

  /// 🔍 BUSCAR TRANSAÇÃO POR ID
  Future<TransacaoModel?> fetchTransacaoPorId(String transacaoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('transacoes')
          .select('*')
          .eq('id', transacaoId)
          .eq('usuario_id', userId)
          .single();

      return TransacaoModel.fromJson(response);
    } catch (e) {
      log('❌ Erro ao buscar transação por ID: $e');
      return null;
    }
  }

  /// 📊 BUSCAR RESUMO DO PERÍODO
  Future<Map<String, double>> fetchResumoPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'receitas': 0.0, 'despesas': 0.0, 'saldo': 0.0};

      // Buscar receitas
      final receitasResponse = await _supabase
          .from('transacoes')
          .select('valor')
          .eq('usuario_id', userId)
          .eq('tipo', 'receita')
          .eq('efetivado', true)
          .gte('data', dataInicio.toIso8601String().split('T')[0])
          .lte('data', dataFim.toIso8601String().split('T')[0]);

      // Buscar despesas
      final despesasResponse = await _supabase
          .from('transacoes')
          .select('valor')
          .eq('usuario_id', userId)
          .eq('tipo', 'despesa')
          .eq('efetivado', true)
          .gte('data', dataInicio.toIso8601String().split('T')[0])
          .lte('data', dataFim.toIso8601String().split('T')[0]);

      double totalReceitas = 0.0;
      for (final item in receitasResponse as List) {
        totalReceitas += (item['valor'] as num).toDouble();
      }

      double totalDespesas = 0.0;
      for (final item in despesasResponse as List) {
        totalDespesas += (item['valor'] as num).toDouble();
      }

      final saldo = totalReceitas - totalDespesas;

      return {
        'receitas': totalReceitas,
        'despesas': totalDespesas,
        'saldo': saldo,
      };
    } catch (e) {
      log('❌ Erro ao buscar resumo do período: $e');
      return {'receitas': 0.0, 'despesas': 0.0, 'saldo': 0.0};
    }
  }


  /// 🔄 CONVERTE DADOS PARA FORMATO SQLITE
  Map<String, dynamic> _prepararDadosSQLite(Map<String, dynamic> dados) {
    final dadosSQL = <String, dynamic>{};
    
    for (final entry in dados.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Converte boolean para INTEGER para SQLite
      if (value is bool) {
        dadosSQL[key] = value ? 1 : 0;
      } else {
        dadosSQL[key] = value;
      }
    }
    
    return dadosSQL;
  }

  /// 💰 CÁLCULO CORRETO DE PARCELAS - CORRIGE BUG DO REACT
  List<double> _calcularValoresParcelas(double valorTotal, int numeroParcelas) {
    if (numeroParcelas <= 0) return [valorTotal];
    if (numeroParcelas == 1) return [valorTotal];
    
    log('💰 Calculando $numeroParcelas parcelas de R\$ ${valorTotal.toStringAsFixed(2)}');
    
    // 1️⃣ VALOR BASE: Arredonda para baixo (Math.floor equivalente)
    final valorBaseCentavos = (valorTotal * 100).floor() ~/ numeroParcelas;
    final valorBase = valorBaseCentavos / 100;
    
    // 2️⃣ TOTAL DAS PRIMEIRAS (N-1) PARCELAS
    final totalPrimeiras = valorBase * (numeroParcelas - 1);
    
    // 3️⃣ ÚLTIMA PARCELA RECEBE A DIFERENÇA EXATA
    final ultimaParcela = valorTotal - totalPrimeiras;
    
    // 4️⃣ MONTA LISTA DE PARCELAS
    final parcelas = <double>[];
    for (int i = 0; i < numeroParcelas; i++) {
      if (i == numeroParcelas - 1) {
        parcelas.add(ultimaParcela); // Última parcela com diferença
      } else {
        parcelas.add(valorBase); // Primeiras parcelas
      }
    }
    
    // ✅ VALIDAÇÃO: Soma deve ser igual ao valor original
    final somaTotal = parcelas.reduce((a, b) => a + b);
    log('✅ Parcelas: ${parcelas.map((v) => 'R\$ ${v.toStringAsFixed(2)}').join(' + ')} = R\$ ${somaTotal.toStringAsFixed(2)}');
    
    if ((somaTotal - valorTotal).abs() > 0.01) {
      log('⚠️ AVISO: Diferença na soma das parcelas: ${(somaTotal - valorTotal).toStringAsFixed(2)}');
    }
    
    return parcelas;
  }

  /// 🗓️ CÁLCULO DE DATA COM REGRAS CORRETAS PARA DATAS EXTREMAS
  DateTime _calcularDataParcela(DateTime dataBase, int incremento, String frequencia) {
    switch (frequencia) {
      case 'semanal':
        return dataBase.add(Duration(days: 7 * incremento));
        
      case 'quinzenal':
        return dataBase.add(Duration(days: 14 * incremento));
        
      case 'mensal':
        return _calcularDataMensal(dataBase, incremento);
        
      case 'anual':
        return DateTime(
          dataBase.year + incremento,
          dataBase.month,
          _ajustarDiaMes(dataBase.day, dataBase.month, dataBase.year + incremento)
        );
        
      default:
        return dataBase.add(Duration(days: 30 * incremento));
    }
  }

  /// 📅 CÁLCULO MENSAL COM REGRAS CORRETAS PARA DATAS EXTREMAS
  DateTime _calcularDataMensal(DateTime dataBase, int incrementoMeses) {
    if (incrementoMeses == 0) return dataBase;
    
    final diaOriginal = dataBase.day;
    
    // Calcula o novo mês e ano
    var novoMes = dataBase.month + incrementoMeses;
    var novoAno = dataBase.year;
    
    // Ajusta ano se necessário
    while (novoMes > 12) {
      novoMes -= 12;
      novoAno += 1;
    }
    while (novoMes < 1) {
      novoMes += 12;
      novoAno -= 1;
    }
    
    // Ajusta o dia de acordo com as regras
    final diaAjustado = _ajustarDiaMes(diaOriginal, novoMes, novoAno);
    
    final novaData = DateTime(novoAno, novoMes, diaAjustado);
    log('📅 Data: ${dataBase.day}/${dataBase.month}/${dataBase.year} + ${incrementoMeses}m → $diaAjustado/$novoMes/$novoAno');
    
    return novaData;
  }

  /// 🔧 AJUSTA DIA DO MÊS PARA DATAS EXTREMAS
  int _ajustarDiaMes(int diaDesejado, int mes, int ano) {
    // Descobre último dia do mês
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    
    // REGRAS DE DATAS EXTREMAS:
    if (diaDesejado == 1) {
      return 1; // Dia 1 sempre mantém dia 1
    }
    
    if (diaDesejado >= 28) {
      // Dias extremos (28, 29, 30, 31) sempre vão para o último dia
      log('🗓️ Dia extremo $diaDesejado → último dia do mês ($ultimoDia)');
      return ultimoDia;
    }
    
    // Dias normais: usa o menor entre o desejado e o último disponível
    return diaDesejado <= ultimoDia ? diaDesejado : ultimoDia;
  }

  /// 🔢 CONTAGEM RÁPIDA PARA DIAGNÓSTICO

  /// Conta receitas recorrentes - OFFLINE FIRST
  Future<int> countReceitasRecorrentes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final db = LocalDatabase.instance.database;
      if (db == null) {
        log('⚠️ Database não inicializado para contagem de receitas');
        return 0;
      }

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM transacoes
        WHERE usuario_id = ? AND tipo = 'receita' AND recorrente = 1
          AND (transferencia IS NULL OR transferencia = 0)
      ''', [userId]);

      final count = result.first['count'] as int;
      log('📊 Receitas recorrentes (SQLite): $count');
      return count;
    } catch (e) {
      log('⚠️ Erro ao contar receitas, usando fallback: $e');
      return 0;
    }
  }

  /// Conta despesas fixas (recorrentes) - OFFLINE FIRST
  Future<int> countDespesasFixas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final db = LocalDatabase.instance.database;
      if (db == null) {
        log('⚠️ Database não inicializado para contagem de despesas fixas');
        return 0;
      }

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM transacoes
        WHERE usuario_id = ? AND tipo = 'despesa' AND recorrente = 1
          AND (transferencia IS NULL OR transferencia = 0)
      ''', [userId]);

      final count = result.first['count'] as int;
      log('📊 Despesas fixas (SQLite): $count');
      return count;
    } catch (e) {
      log('⚠️ Erro ao contar despesas fixas, usando fallback: $e');
      return 0;
    }
  }

  /// Conta despesas variáveis (não recorrentes) - OFFLINE FIRST
  Future<int> countDespesasVariaveis() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final db = LocalDatabase.instance.database;
      if (db == null) {
        log('⚠️ Database não inicializado para contagem de despesas variáveis');
        return 0;
      }

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM transacoes
        WHERE usuario_id = ? AND tipo = 'despesa' AND (recorrente = 0 OR recorrente IS NULL)
          AND (transferencia IS NULL OR transferencia = 0)
      ''', [userId]);

      final count = result.first['count'] as int;
      log('📊 Despesas variáveis (SQLite): $count');
      return count;
    } catch (e) {
      log('⚠️ Erro ao contar despesas variáveis, usando fallback: $e');
      return 0;
    }
  }

  /// Verifica se tem receitas configuradas
  Future<bool> temReceitasConfiguradas({int minimo = 1}) async {
    final count = await countReceitasRecorrentes();
    return count >= minimo;
  }

  /// Verifica se tem despesas fixas configuradas
  Future<bool> temDespesasFixasConfiguradas({int minimo = 1}) async {
    final count = await countDespesasFixas();
    return count >= minimo;
  }

  /// Verifica se tem despesas variáveis configuradas
  Future<bool> temDespesasVariaveisConfiguradas({int minimo = 1}) async {
    final count = await countDespesasVariaveis();
    return count >= minimo;
  }

}