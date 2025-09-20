// 🏦 Conta Service - iPoupei Mobile
// 
// Serviço OFFLINE-FIRST para operações de contas  
// Idêntico ao hook React useContas com LocalDatabase
// 
// Baseado em: Repository Pattern + Offline-First

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../models/conta_model.dart';
import '../../../database/local_database.dart';

class ContaService {
  static ContaService? _instance;
  static ContaService get instance {
    _instance ??= ContaService._internal();
    return _instance!;
  }
  
  ContaService._internal();

  final _supabase = Supabase.instance.client;
  final _localDb = LocalDatabase.instance;
  final _uuid = const Uuid();

  /// 🎯 GERENCIA EXCLUSIVIDADE DE CONTA PRINCIPAL (LOCAL + SUPABASE SINCRONIZADOS)
  Future<void> _gerenciarContaPrincipalExclusiva(String userId, String novaContaPrincipalId, bool isContaPrincipal) async {
    if (!isContaPrincipal) return;
    
    try {
      log('🎯 Gerenciando exclusividade de conta principal...');
      
      // 1. PRIMEIRO: ATUALIZAR TODAS NO SQLite LOCAL (MAIS RÁPIDO)
      await _localDb.setCurrentUser(userId);
      
      // Remove flag de TODAS as outras contas locais
      await _localDb.database!.update(
        'contas',
        {
          'conta_principal': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending', // Marca para sincronizar
        },
        where: 'usuario_id = ? AND conta_principal = 1 AND ativo = 1',
        whereArgs: [userId],
      );
      
      // Define a nova como principal no local
      await _localDb.database!.update(
        'contas',
        {
          'conta_principal': 1,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending', // Marca para sincronizar
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [novaContaPrincipalId, userId],
      );
      
      log('✅ Atualização local concluída');
      
      // 2. DEPOIS: SINCRONIZAR COM SUPABASE EM PARALELO
      _sincronizarContaPrincipalComSupabase(userId, novaContaPrincipalId);
      
    } catch (e) {
      log('❌ Erro ao gerenciar conta principal: $e');
      rethrow;
    }
  }

  /// 🚀 SINCRONIZAÇÃO ASSÍNCRONA COM SUPABASE (NÃO BLOQUEIA A UI)
  Future<void> _sincronizarContaPrincipalComSupabase(String userId, String novaContaPrincipalId) async {
    try {
      log('🚀 Sincronizando conta principal com Supabase...');
      
      // Buscar TODAS as contas no Supabase para atualizar
      final contasSupabase = await _supabase
          .from('contas')
          .select('id, conta_principal')
          .eq('usuario_id', userId)
          .eq('ativo', true);
      
      // Atualizar cada conta no Supabase
      final futures = contasSupabase.map((conta) async {
        final contaId = conta['id'] as String;
        final deveSerPrincipal = contaId == novaContaPrincipalId;
        
        try {
          await _supabase.from('contas').update({
            'conta_principal': deveSerPrincipal,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', contaId).eq('usuario_id', userId);
          
          // Marca como sincronizado no local
          await _localDb.database!.update(
            'contas',
            {'sync_status': 'synced'},
            where: 'id = ? AND usuario_id = ?',
            whereArgs: [contaId, userId],
          );
          
        } catch (e) {
          log('❌ Erro ao sincronizar conta $contaId: $e');
        }
      });
      
      await Future.wait(futures);
      log('✅ Sincronização com Supabase concluída');
      
    } catch (e) {
      log('❌ Erro na sincronização com Supabase: $e');
      // Não faz throw para não quebrar a experiência do usuário
    }
  }


  /// 🏦 BUSCAR CONTAS (OFFLINE-FIRST)
  Future<List<ContaModel>> fetchContas({bool incluirArquivadas = false}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('🏦 Buscando contas OFFLINE-FIRST para: ${_supabase.auth.currentUser?.email}');

      // 🔄 OFFLINE-FIRST: Busca local com cálculo de saldos
      await _localDb.setCurrentUser(userId);
      final localData = await _localDb.fetchContasLocal(incluirArquivadas: incluirArquivadas);

      // Se SQLite está vazio, faz sync inicial do Supabase
      if (localData.isEmpty) {
        log('🔄 SQLite vazio - fazendo sync inicial de contas do Supabase...');
        try {
          await _syncInitialContasFromSupabase(userId);
          // Tenta buscar novamente após sync
          final localDataAfterSync = await _localDb.fetchContasLocal(incluirArquivadas: incluirArquivadas);
          final contas = localDataAfterSync.map<ContaModel>((item) {
            return ContaModel.fromJson(item);
          }).toList();
          return contas;
        } catch (syncError) {
          log('⚠️ Sync inicial falhou, tentando Supabase direto: $syncError');
          // Fallback para Supabase direto
          return await _fetchContasFromSupabaseDirect(userId, incluirArquivadas);
        }
      }

      log('🔄 Convertendo ${localData.length} itens para ContaModel...');
      
      final contas = <ContaModel>[];
      for (int i = 0; i < localData.length; i++) {
        try {
          final item = localData[i];
          log('📝 Item $i: ${item['id']} - ${item['nome']}');
          final conta = ContaModel.fromJson(item);
          contas.add(conta);
        } catch (e) {
          log('❌ Erro ao converter item $i: $e');
        }
      }

      return contas;
    } catch (e) {
      log('❌ Erro ao buscar contas: $e');
      return [];
    }
  }
  
  /// 🔄 SYNC INICIAL DE CONTAS DO SUPABASE PARA SQLITE
  Future<void> _syncInitialContasFromSupabase(String userId) async {
    log('🔄 Iniciando sync inicial de contas...');
    
    // ✅ Busca contas usando RPC (mesma do React)
    log('🔍 Chamando RPC ip_prod_obter_saldos_por_conta para sync inicial...');
    final response = await _supabase.rpc(
      'ip_prod_obter_saldos_por_conta',
      params: {
        'p_usuario_id': userId,
        'p_incluir_inativas': true, // Inclui todas para sync inicial
      },
    );
    log('🔍 RPC response type: ${response.runtimeType}');
    log('🔍 RPC response length: ${response is List ? response.length : 'não é lista'}');
    
    if (response is List && response.isNotEmpty) {
      log('🔍 RPC retornou ${response.length} contas');
      for (final item in response) {
        log('🔍 Processando conta: ${item['conta_nome']} - Saldo: ${item['saldo_atual']}');
        
        // Converte dados RPC para formato SQLite
        final contaData = {
          'id': item['conta_id'],
          'usuario_id': userId,
          'nome': item['conta_nome'],
          'tipo': item['conta_tipo'],
          'saldo_inicial': item['saldo_inicial'],
          'saldo': item['saldo_atual'], // ✅ Saldo já calculado pela RPC!
          'cor': item['cor'],
          'banco': item['banco'],
          'icone': item['icone'],
          'ativo': item['ativa'] == true ? 1 : 0, // Boolean → INTEGER
          'incluir_soma_total': item['incluir_soma'] == true ? 1 : 0,
          'conta_principal': item['conta_principal'] == true ? 1 : 0, // ✅ CAMPO FALTANTE!
          'observacoes': item['observacoes'],
          'created_at': item['created_at'],
          'updated_at': item['updated_at'],
          'sync_status': 'synced',
          'last_sync': DateTime.now().toIso8601String(),
        };
        
        // Insere no SQLite
        await _localDb.database!.insert(
          'contas',
          contaData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } else {
      log('⚠️ RPC não retornou dados ou retornou vazio');
    }
  }
  
  /// 📡 FALLBACK: BUSCA CONTAS DIRETO DO SUPABASE
  Future<List<ContaModel>> _fetchContasFromSupabaseDirect(String userId, bool incluirArquivadas) async {
    log('📡 Buscando contas direto do Supabase como fallback...');
    
    // ✅ Usa a MESMA função RPC que o React usa
    log('🔍 Fallback: Chamando RPC ip_prod_obter_saldos_por_conta...');
    final response = await _supabase.rpc(
      'ip_prod_obter_saldos_por_conta',
      params: {
        'p_usuario_id': userId,
        'p_incluir_inativas': incluirArquivadas,
      },
    );
    log('🔍 Fallback RPC response: ${response?.runtimeType}, length: ${response is List ? response.length : 'não é lista'}');
    
    if (response == null) {
      log('⚠️ Função RPC retornou null, usando fallback direto');
      // Fallback para query direta se RPC falhar
      dynamic query = _supabase
          .from('contas')
          .select('*')
          .eq('usuario_id', userId);
      
      if (!incluirArquivadas) {
        query = query.eq('ativo', true);
      }
      
      final directResponse = await query;
      return _convertSupabaseDataToModel(directResponse, fromRpc: false);
    }
    
    // ✅ Converte dados da RPC para modelo
    return _convertSupabaseDataToModel(response, fromRpc: true);
  }

  /// 🔄 CONVERTE DADOS DO SUPABASE PARA MODELO
  List<ContaModel> _convertSupabaseDataToModel(dynamic data, {required bool fromRpc}) {
    if (data == null) return [];
    
    final contas = (data as List).map<ContaModel>((item) {
      Map<String, dynamic> contaData;
      
      if (fromRpc) {
        // ✅ Dados da RPC ip_prod_obter_saldos_por_conta
        contaData = {
          'id': item['conta_id'],
          'usuario_id': item['usuario_id'] ?? _supabase.auth.currentUser?.id,
          'nome': item['conta_nome'],
          'tipo': item['conta_tipo'],
          'saldo_inicial': item['saldo_inicial'],
          'saldo': item['saldo_atual'], // ✅ RPC retorna saldo_atual
          'cor': item['cor'],
          'banco': item['banco'],
          'icone': item['icone'],
          'ativo': item['ativa'],
          'incluir_soma_total': item['incluir_soma'],
          'conta_principal': item['conta_principal'], // ✅ CAMPO FALTANTE NO FALLBACK!
          'observacoes': item['observacoes'],
          'created_at': item['created_at'],
          'updated_at': item['updated_at'],
        };
      } else {
        // ✅ Dados diretos da tabela contas
        contaData = Map<String, dynamic>.from(item);
      }
      
      return ContaModel.fromJson(contaData);
    }).toList();
    
    return contas;
  }

  /// 💰 CALCULAR SALDO TOTAL (OFFLINE-FIRST)
  Future<double> getSaldoTotal() async {
    log('💰 Calculando saldo total...');
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        log('❌ Usuário não autenticado');
        return 0.0;
      }

      // 🔄 OFFLINE-FIRST: Calcula local
      await _localDb.setCurrentUser(userId);
      final saldoTotal = await _localDb.calcularSaldoTotalLocal();

      log('✅ Saldo total calculado OFFLINE: R\$ ${saldoTotal.toStringAsFixed(2)}');
      return saldoTotal;
    } catch (e) {
      log('❌ Erro ao calcular saldo total: $e');
      return 0.0;
    }
  }

  /// ➕ ADICIONAR NOVA CONTA (OFFLINE-FIRST)
  Future<ContaModel> addConta({
    required String nome,
    required String tipo,
    String? banco,
    String? agencia,
    String? conta,
    double? saldo,
    double? saldoInicial,
    String? cor,
    String? icone,
    bool? contaPrincipal,
    int? ordem,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final now = DateTime.now();
      final contaId = _uuid.v4();
      
      // Usa saldo ou saldoInicial (flexibilidade igual React)
      final saldoFinal = saldoInicial ?? saldo ?? 0.0;
      
      final contaData = {
        'id': contaId,                        // ✅ UUID gerado
        'usuario_id': userId,                 // ✅ User ID
        'nome': nome,                         // ✅ Nome obrigatório
        'tipo': tipo,                         // ✅ Tipo obrigatório
        'banco': banco,                       // ✅ Opcional (nullable)
        'agencia': agencia,                   // ✅ Campo Supabase
        'conta': conta,                       // ✅ Campo Supabase
        'saldo_inicial': saldoFinal,          // ✅ Saldo inicial
        'saldo': saldoFinal,                  // ✅ Saldo atual (igual inicial)
        'cor': cor ?? '#3B82F6',             // ✅ Default React
        'icone': icone ?? 'bank',            // ✅ Campo Supabase
        'ativo': 1,                          // ✅ SQLite INTEGER
        'incluir_soma_total': 1,             // ✅ Default true
        'conta_principal': contaPrincipal == true ? 1 : 0, // ✅ Campo Supabase
        'ordem': ordem ?? 1,                 // ✅ Parametrizado
        'observacoes': null,                 // ✅ Opcional
        'origem_diagnostico': 0,             // ✅ Campo Supabase (default false)
        'created_at': now.toIso8601String(), // ✅ Timestamp
        'updated_at': now.toIso8601String(), // ✅ Timestamp
      };

      // 🔄 OFFLINE-FIRST: Salva local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      
      // 🎯 EXCLUSIVIDADE: Se é conta principal, remove flag das outras
      if (contaPrincipal == true) {
        await _gerenciarContaPrincipalExclusiva(userId, contaId, true);
      }
      
      await _localDb.addContaLocal(contaData);

      log('✅ Conta criada OFFLINE: $nome');

      // Converte para formato Supabase para retorno
      final responseData = Map<String, dynamic>.from(contaData);
      responseData['ativo'] = true;
      responseData['incluir_soma_total'] = true;

      return ContaModel.fromJson(responseData);
    } catch (e) {
      log('❌ Erro ao criar conta: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR CONTA (OFFLINE-FIRST)
  Future<ContaModel> updateConta({
    required String contaId,
    String? nome,
    String? tipo,
    String? banco,
    String? agencia,
    String? conta,
    String? cor,
    String? icone,
    bool? contaPrincipal,
    int? ordem,
    double? saldo,
    double? saldoInicial,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Monta dados de atualização
      final updateData = <String, dynamic>{};
      if (nome != null) updateData['nome'] = nome;
      if (tipo != null) updateData['tipo'] = tipo;
      if (banco != null) updateData['banco'] = banco;
      if (agencia != null) updateData['agencia'] = agencia;
      if (conta != null) updateData['conta'] = conta;
      if (cor != null) updateData['cor'] = cor;
      if (icone != null) updateData['icone'] = icone;
      if (contaPrincipal != null) {
        updateData['conta_principal'] = contaPrincipal ? 1 : 0;
      }
      if (ordem != null) updateData['ordem'] = ordem;
      
      // Conversão saldo → saldo_inicial (igual React)
      if (saldo != null) updateData['saldo_inicial'] = saldo;
      if (saldoInicial != null) updateData['saldo_inicial'] = saldoInicial;

      // 🔄 OFFLINE-FIRST: Atualiza local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      
      // 🎯 EXCLUSIVIDADE: Se definiu como conta principal, remove flag das outras ANTES
      if (contaPrincipal == true) {
        await _gerenciarContaPrincipalExclusiva(userId, contaId, true);
        
        // ⚡ FORÇA SINCRONIZAÇÃO LOCAL IMEDIATA PARA GARANTIR CONSISTÊNCIA
        await Future.delayed(const Duration(milliseconds: 500)); // Aguarda sincronização
        await forcarSincronizacaoLocal();
      }
      
      // Atualiza a conta atual DEPOIS da exclusividade
      await _localDb.updateContaLocal(contaId, updateData);


      // Busca dados atualizados para retornar
      final contas = await fetchContas();
      final contaAtualizada = contas.where((c) => c.id == contaId).firstOrNull;

      if (contaAtualizada != null) {
        return contaAtualizada;
      } else {
        throw Exception('Conta não encontrada após atualização');
      }
    } catch (e) {
      log('❌ Erro ao atualizar conta: $e');
      rethrow;
    }
  }

  /// 📦 ARQUIVAR CONTA (OFFLINE-FIRST)
  Future<void> arquivarConta(String contaId, {String? motivo}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 🔄 OFFLINE-FIRST: Arquiva local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      await _localDb.arquivarContaLocal(contaId, motivo);

    } catch (e) {
      log('❌ Erro ao arquivar conta: $e');
      rethrow;
    }
  }

  /// 📤 DESARQUIVAR CONTA (OFFLINE-FIRST)
  Future<void> desarquivarConta(String contaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 🔄 OFFLINE-FIRST: Desarquiva local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      await _localDb.desarquivarContaLocal(contaId);

    } catch (e) {
      log('❌ Erro ao desarquivar conta: $e');
      rethrow;
    }
  }

  /// 🗑️ EXCLUIR CONTA (OFFLINE-FIRST) 
  Future<Map<String, dynamic>> excluirConta(String contaId, {bool confirmacao = false}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 🔄 OFFLINE-FIRST: Exclui local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      final resultado = await _localDb.excluirContaLocal(contaId, confirmacao: confirmacao);

      return resultado;
    } catch (e) {
      log('❌ Erro ao excluir conta: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🔧 CORRIGIR SALDO DA CONTA (OFFLINE-FIRST)
  Future<Map<String, dynamic>> corrigirSaldoConta({
    required String contaId,
    required double novoSaldo,
    required String metodo,  // 'ajuste' ou 'saldo_inicial'
    required String motivo,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 🔄 OFFLINE-FIRST: Corrige saldo local com os dois métodos
      await _localDb.setCurrentUser(userId);
      final resultado = await _localDb.corrigirSaldoContaLocal(
        contaId,
        novoSaldo,
        metodo,
        motivo,
      );

      return resultado;
    } catch (e) {
      log('❌ Erro ao corrigir saldo: $e');
      return {
        'success': false,
        'error': 'Erro ao corrigir saldo: $e',
      };
    }
  }

  /// 🔍 GET CONTA BY ID (EM MEMÓRIA - IGUAL REACT)
  ContaModel? getContaById(String contaId, List<ContaModel> contas) {
    try {
      return contas.where((conta) => conta.id == contaId).firstOrNull;
    } catch (e) {
      log('❌ Erro ao buscar conta por ID em memória: $e');
      return null;
    }
  }

  /// 🔍 BUSCAR CONTAS ATIVAS (HELPER)
  Future<List<ContaModel>> getContasAtivas() async {
    return await fetchContas(incluirArquivadas: false);
  }

  /// 🔍 BUSCAR CONTAS ARQUIVADAS (HELPER)
  Future<List<ContaModel>> getContasArquivadas() async {
    final todasContas = await fetchContas(incluirArquivadas: true);
    return todasContas.where((conta) => !conta.ativo).toList();
  }

  /// 📊 RESUMO FINANCEIRO
  Future<Map<String, dynamic>> getResumoContas() async {
    try {
      final contas = await fetchContas();
      final saldoTotal = await getSaldoTotal();
      
      final contasAtivas = contas.where((c) => c.ativo).length;
      final contasArquivadas = contas.where((c) => !c.ativo).length;
      
      return {
        'saldoTotal': saldoTotal,
        'totalContas': contas.length,
        'contasAtivas': contasAtivas,
        'contasArquivadas': contasArquivadas,
        'contas': contas,
      };
    } catch (e) {
      log('❌ Erro ao gerar resumo de contas: $e');
      return {
        'saldoTotal': 0.0,
        'totalContas': 0,
        'contasAtivas': 0,
        'contasArquivadas': 0,
        'contas': <ContaModel>[],
      };
    }
  }

  /// ✅ VALIDAR DADOS DA CONTA
  Map<String, String> validarDadosConta({
    required String nome,
    required String tipo,
    String? banco,
    double? saldo,
  }) {
    final erros = <String, String>{};

    // Valida nome
    if (nome.trim().isEmpty) {
      erros['nome'] = 'Nome é obrigatório';
    } else if (nome.trim().length < 2) {
      erros['nome'] = 'Nome deve ter pelo menos 2 caracteres';
    } else if (nome.trim().length > 50) {
      erros['nome'] = 'Nome deve ter no máximo 50 caracteres';
    }

    // Valida tipo
    const tiposValidos = ['corrente', 'poupanca', 'investimento', 'carteira'];
    if (!tiposValidos.contains(tipo)) {
      erros['tipo'] = 'Tipo deve ser: corrente, poupanca, investimento ou carteira';
    }

    // Valida banco (opcional)
    if (banco != null && banco.trim().length > 30) {
      erros['banco'] = 'Nome do banco deve ter no máximo 30 caracteres';
    }

    // Valida saldo (opcional, pode ser negativo)
    if (saldo != null && (saldo.isNaN || saldo.isInfinite)) {
      erros['saldo'] = 'Saldo deve ser um número válido';
    }

    return erros;
  }

  /// 🔍 VERIFICAR NOME ÚNICO
  Future<bool> verificarNomeUnico(String nome, {String? contaIdExcluir}) async {
    try {
      final contas = await fetchContas(incluirArquivadas: true);
      
      for (final conta in contas) {
        if (conta.nome.toLowerCase() == nome.toLowerCase()) {
          // Se é atualização, ignora a própria conta
          if (contaIdExcluir != null && conta.id == contaIdExcluir) {
            continue;
          }
          return false; // Nome já existe
        }
      }
      
      return true; // Nome é único
    } catch (e) {
      log('❌ Erro ao verificar nome único: $e');
      return false; // Por segurança, considera como não único
    }
  }

  /// 🔄 FORÇAR RESYNC COMPLETO DE CONTAS
  Future<void> forcarResync() async {
    log('🔄 Forçando resync completo de contas...');
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 1. Limpar dados locais
      await _localDb.database!.delete('contas', where: 'usuario_id = ?', whereArgs: [userId]);
      log('🗑️ Dados locais limpos');
      
      // 2. Forçar sync inicial
      await _syncInitialContasFromSupabase(userId);
      log('✅ Resync completo concluído');
      
    } catch (e) {
      log('❌ Erro no resync: $e');
    }
  }

  /// 🧪 TESTE: EXECUTAR LIMPEZA DE DUPLAS CONTAS PRINCIPAIS
  Future<void> testarLimpezaContaPrincipal() async {
    log('🧪 TESTE: Executando limpeza de duplas contas principais...');
    try {
      final resultado = await limparDuplaContaPrincipal();
      log('🧪 RESULTADO DA LIMPEZA: $resultado');
    } catch (e) {
      log('🧪 Erro no teste de limpeza: $e');
    }
  }

  /// 🧪 TESTE: FORÇAR BUSCA POR RPC
  Future<void> testarRPC() async {
    log('🧪 TESTE: Forçando busca por RPC...');
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final response = await _supabase.rpc(
        'ip_prod_obter_saldos_por_conta',
        params: {
          'p_usuario_id': userId,
          'p_incluir_inativas': true,
        },
      );
      
      if (response is List && response.isNotEmpty) {
        double saldoTotalRPC = 0.0;
        log('🧪 === DADOS DA RPC ===');
        for (final item in response) {
          final nome = item['conta_nome'];
          final saldoAtual = (item['saldo_atual'] as num?)?.toDouble() ?? 0.0;
          saldoTotalRPC += saldoAtual;
          log('🧪 $nome: R\$ ${saldoAtual.toStringAsFixed(2)}');
        }
        log('🧪 TOTAL RPC: R\$ ${saldoTotalRPC.toStringAsFixed(2)}');
        
        // Comparar com SQLite local
        final saldoLocal = await getSaldoTotal();
        log('🧪 TOTAL LOCAL: R\$ ${saldoLocal.toStringAsFixed(2)}');
        log('🧪 DIFERENÇA: R\$ ${(saldoTotalRPC - saldoLocal).toStringAsFixed(2)}');
      }
    } catch (e) {
      log('🧪 Erro no teste RPC: $e');
    }
  }

  /// ⚡ FORÇAR SINCRONIZAÇÃO IMEDIATA LOCAL (EMERGENCIAL)
  Future<void> forcarSincronizacaoLocal() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('⚡ Forçando sincronização local...');

      // Busca dados atuais do Supabase
      final contasSupabase = await _supabase
          .from('contas')
          .select('*')
          .eq('usuario_id', userId)
          .eq('ativo', true);

      await _localDb.setCurrentUser(userId);

      // Atualiza cada conta no SQLite local
      for (final contaData in contasSupabase) {
        await _localDb.database!.update(
          'contas',
          {
            'conta_principal': contaData['conta_principal'] == true ? 1 : 0,
            'nome': contaData['nome'],
            'saldo': contaData['saldo'],
            'updated_at': contaData['updated_at'],
            'sync_status': 'synced',
            'last_sync': DateTime.now().toIso8601String(),
          },
          where: 'id = ? AND usuario_id = ?',
          whereArgs: [contaData['id'], userId],
        );
      }

      log('✅ Sincronização local forçada concluída');

    } catch (e) {
      log('❌ Erro na sincronização forçada: $e');
    }
  }

  /// 🧹 LIMPAR DUPLAS CONTAS PRINCIPAIS (CORREÇÃO EMERGENCIAL)
  Future<Map<String, dynamic>> limparDuplaContaPrincipal() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('🧹 Iniciando limpeza de duplas contas principais...');

      // 1. Buscar todas as contas principais no Supabase
      final contasPrincipais = await _supabase
          .from('contas')
          .select('id, nome, created_at')
          .eq('usuario_id', userId)
          .eq('conta_principal', true)
          .eq('ativo', true)
          .order('created_at', ascending: true); // Mais antiga primeiro

      log('🔍 Encontradas ${contasPrincipais.length} contas principais');

      if (contasPrincipais.length <= 1) {
        return {
          'success': true,
          'message': 'Nenhuma duplicação encontrada',
          'contasProcessadas': contasPrincipais.length,
          'contasCorrigidas': 0,
        };
      }

      // 2. Manter apenas a PRIMEIRA (mais antiga) como principal
      final contaParaManter = contasPrincipais.first;
      final contasParaRemover = contasPrincipais.skip(1).toList();

      log('✅ Mantendo como principal: ${contaParaManter['nome']} (${contaParaManter['id']})');

      int contasCorrigidas = 0;
      
      // 3. Remover flag principal das outras contas
      for (final conta in contasParaRemover) {
        final contaId = conta['id'] as String;
        final contaNome = conta['nome'] as String;

        try {
          // Atualiza no Supabase
          await _supabase.from('contas').update({
            'conta_principal': false,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', contaId).eq('usuario_id', userId);

          // Atualiza no SQLite local
          await _localDb.database!.update(
            'contas',
            {
              'conta_principal': 0,
              'updated_at': DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            },
            where: 'id = ? AND usuario_id = ?',
            whereArgs: [contaId, userId],
          );

          contasCorrigidas++;
          log('✅ Corrigida: $contaNome ($contaId)');
          
        } catch (e) {
          log('❌ Erro ao corrigir $contaNome: $e');
        }
      }

      // 4. Garantir que a conta mantida está correta no local
      try {
        await _localDb.database!.update(
          'contas',
          {
            'conta_principal': 1,
            'updated_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'id = ? AND usuario_id = ?',
          whereArgs: [contaParaManter['id'], userId],
        );
      } catch (e) {
        log('⚠️ Erro ao sincronizar conta mantida no local: $e');
      }

      final resultado = {
        'success': true,
        'message': 'Duplas contas principais corrigidas com sucesso',
        'contasProcessadas': contasPrincipais.length,
        'contasCorrigidas': contasCorrigidas,
        'contaMantida': '${contaParaManter['nome']} (${contaParaManter['id']})',
        'contasRemovidas': contasParaRemover.map((c) => '${c['nome']} (${c['id']})').toList(),
      };

      log('🎉 Limpeza concluída: $resultado');
      return resultado;

    } catch (e) {
      log('❌ Erro na limpeza de duplas contas principais: $e');
      return {
        'success': false,
        'error': 'Erro na limpeza: $e',
        'contasProcessadas': 0,
        'contasCorrigidas': 0,
      };
    }
  }

  /// 🔄 RECALCULAR SALDOS (OFFLINE-FIRST)
  Future<Map<String, dynamic>> recalcularSaldos() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('🔄 Recalculando saldos OFFLINE...');

      // Busca todas as contas
      final contas = await fetchContas(incluirArquivadas: true);
      int contasCorrigidas = 0;

      // Para cada conta, recalcula o saldo atual
      for (final conta in contas) {
        try {
          await _localDb.setCurrentUser(userId);
          
          // Busca saldo_inicial atual
          final contasLocal = await _localDb.database!.query(
            'contas',
            where: 'id = ? AND usuario_id = ?',
            whereArgs: [conta.id, userId],
          );

          if (contasLocal.isNotEmpty) {
            final saldoInicial = (contasLocal.first['saldo_inicial'] as num?)?.toDouble() ?? 0.0;
            
            // Recalcula saldo atual usando as transações
            final saldoAtual = await _localDb.calcularSaldoContaLocal(conta.id, saldoInicial);
            
            // Força update do saldo na tabela (não é sync, só local)
            await _localDb.database!.update(
              'contas',
              {'saldo': saldoAtual},
              where: 'id = ? AND usuario_id = ?',
              whereArgs: [conta.id, userId],
            );
            
            contasCorrigidas++;
          }
        } catch (e) {
          log('❌ Erro ao recalcular saldo da conta ${conta.nome}: $e');
        }
      }

      final resultado = {
        'success': true,
        'message': 'Saldos recalculados com sucesso',
        'contasProcessadas': contas.length,
        'contasCorrigidas': contasCorrigidas,
      };

      return resultado;
    } catch (e) {
      log('❌ Erro ao recalcular saldos: $e');
      return {
        'success': false,
        'error': 'Erro ao recalcular saldos: $e',
        'contasProcessadas': 0,
        'contasCorrigidas': 0,
      };
    }
  }

  /// 🔢 CONTAGEM RÁPIDA PARA DIAGNÓSTICO

  /// Conta contas ativas - OFFLINE FIRST
  Future<int> contarContasAtivas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final db = await _localDb.database;
      if (db == null) {
        log('⚠️ Database não inicializado, usando fallback');
        return 2; // Fallback
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM contas WHERE usuario_id = ? AND ativo = 1',
        [userId],
      );

      if (result.isEmpty) return 0;

      final count = result.first['count'] as int;
      log('📊 Contas ativas (SQLite): $count');
      return count;
    } catch (e) {
      log('⚠️ Erro SQLite, usando fallback: $e');
      return 2; // Fallback
    }
  }

  /// Verifica se tem contas configuradas
  Future<bool> temContasConfiguradas({int minimo = 1}) async {
    final total = await contarContasAtivas();
    return total >= minimo;
  }
}