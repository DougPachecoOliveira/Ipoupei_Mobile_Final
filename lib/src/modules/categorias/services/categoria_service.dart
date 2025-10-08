// 📂 Categoria Service - iPoupei Mobile
// 
// Serviço para operações de categorias com Supabase
// Idêntico ao hook React useCategorias
// 
// Baseado em: Repository Pattern

import 'dart:developer';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../models/categoria_model.dart';
import '../../../database/local_database.dart';
import '../../../sync/sync_manager.dart';
import '../../../sync/connectivity_helper.dart';
import 'package:uuid/uuid.dart';

class CategoriaService {
  static CategoriaService? _instance;
  static CategoriaService get instance {
    _instance ??= CategoriaService._internal();
    return _instance!;
  }
  
  CategoriaService._internal() {
    // Inicializa automaticamente quando o serviço é criado
    inicializar();
  }

  final _supabase = Supabase.instance.client;
  final _localDb = LocalDatabase.instance;
  final _uuid = const Uuid();
  
  // Mock temporário para testes
  final List<CategoriaModel> _categoriasMock = [
    CategoriaModel(
      id: '1',
      usuarioId: 'user1',
      nome: 'Alimentação',
      cor: '#FF5722',
      icone: 'restaurant',
      tipo: 'despesa',
      ativo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CategoriaModel(
      id: '2',
      usuarioId: 'user1',
      nome: 'Transporte',
      cor: '#2196F3',
      icone: 'directions_car',
      tipo: 'despesa',
      ativo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CategoriaModel(
      id: '3',
      usuarioId: 'user1',
      nome: 'Saúde',
      cor: '#4CAF50',
      icone: 'local_hospital',
      tipo: 'despesa',
      ativo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final Map<String, List<CategoriaModel>> _subcategoriasMock = {
    '1': [
      CategoriaModel(
        id: '11',
        usuarioId: 'user1',
        nome: 'Supermercado',
        cor: '#FF5722',
        icone: 'store',
        tipo: 'despesa',
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    '3': [
      CategoriaModel(
        id: '31',
        usuarioId: 'user1',
        nome: 'Consultas e exames',
        cor: '#4CAF50',
        icone: 'medical_services',
        tipo: 'despesa',
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
  };

  /// 📂 BUSCAR CATEGORIAS (OFFLINE-FIRST)
  Future<List<CategoriaModel>> fetchCategorias({String? tipo}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('📂 Buscando categorias OFFLINE-FIRST para: ${_supabase.auth.currentUser?.email}');
      
      // 🔄 OFFLINE-FIRST: Busca local primeiro
      await _localDb.setCurrentUser(userId);
      final localData = await _localDb.fetchCategoriasLocal(tipo: tipo);
      
      // Se SQLite está vazio, faz sync inicial do Supabase
      if (localData.isEmpty) {
        log('🔄 SQLite vazio - fazendo sync inicial do Supabase...');
        try {
          await _syncInitialFromSupabase(userId);
          // Tenta buscar novamente após sync
          final localDataAfterSync = await _localDb.fetchCategoriasLocal(tipo: tipo);
          final categorias = localDataAfterSync.map<CategoriaModel>((item) {
            return CategoriaModel.fromJson(item);
          }).toList();
          log('✅ Categorias após sync inicial: ${categorias.length}');
          
          // Se ainda está vazio, criar categorias básicas
          if (categorias.isEmpty) {
            log('🔧 Criando categorias básicas...');
            await _criarCategoriasBasicas(userId);
            final categoriasBasicas = await _localDb.fetchCategoriasLocal(tipo: tipo);
            return categoriasBasicas.map<CategoriaModel>((item) {
              return CategoriaModel.fromJson(item);
            }).toList();
          }
          
          return categorias;
        } catch (syncError) {
          log('⚠️ Sync inicial falhou, criando categorias básicas: $syncError');
          // Fallback: criar categorias básicas localmente
          await _criarCategoriasBasicas(userId);
          final categoriasBasicas = await _localDb.fetchCategoriasLocal(tipo: tipo);
          return categoriasBasicas.map<CategoriaModel>((item) {
            return CategoriaModel.fromJson(item);
          }).toList();
        }
      }
      
      final categorias = localData.map<CategoriaModel>((item) {
        return CategoriaModel.fromJson(item);
      }).toList();

      log('✅ Categorias carregadas do SQLite: ${categorias.length}');
      return categorias;
    } catch (e) {
      log('❌ Erro ao buscar categorias: $e');
      // Se falhar, retorna lista vazia em vez de dar crash
      return [];
    }
  }
  
  /// 🔄 SYNC INICIAL DO SUPABASE PARA SQLITE
  Future<void> _syncInitialFromSupabase(String userId) async {
    log('🔄 Iniciando sync inicial de categorias...');
    
    // Busca categorias do Supabase
    dynamic query = _supabase
        .from('categorias')
        .select('id, usuario_id, nome, tipo, cor, icone, descricao, ativo, ordem, created_at, updated_at')
        .eq('usuario_id', userId);
    
    final response = await query;
    
    if (response is List && response.isNotEmpty) {
      for (final item in response) {
        // Converte para formato SQLite
        final categoriaData = Map<String, dynamic>.from(item);
        categoriaData['ativo'] = categoriaData['ativo'] == true ? 1 : 0; // Boolean → INTEGER
        categoriaData['sync_status'] = 'synced';
        categoriaData['last_sync'] = DateTime.now().toIso8601String();
        
        // Insere no SQLite
        await _localDb.database!.insert(
          'categorias',
          categoriaData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      log('✅ Sync inicial concluído: ${response.length} categorias');
    }
    
    // Busca subcategorias do Supabase
    final subResponse = await _supabase
        .from('subcategorias')
        .select('*')
        .eq('usuario_id', userId);
    
    if (subResponse is List && subResponse.isNotEmpty) {
      for (final item in subResponse) {
        final subcategoriaData = Map<String, dynamic>.from(item);
        subcategoriaData['ativo'] = subcategoriaData['ativo'] == true ? 1 : 0;
        subcategoriaData['sync_status'] = 'synced';
        subcategoriaData['last_sync'] = DateTime.now().toIso8601String();
        
        await _localDb.database!.insert(
          'subcategorias',
          subcategoriaData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      log('✅ Sync inicial subcategorias: ${subResponse.length} itens');
    }
  }
  
  /// 📡 FALLBACK: BUSCA DIRETO DO SUPABASE
  Future<List<CategoriaModel>> _fetchFromSupabaseDirect(String userId, String? tipo) async {
    log('📡 Buscando direto do Supabase como fallback...');
    
    dynamic query = _supabase
        .from('categorias')
        .select('id, usuario_id, nome, tipo, cor, icone, descricao, ativo, ordem, created_at, updated_at')
        .eq('usuario_id', userId);

    if (tipo != null && tipo.isNotEmpty) {
      query = query.eq('tipo', tipo);
    }
    
    query = query.order('created_at', ascending: false);
    
    final response = await query;
    
    final categorias = (response as List).map<CategoriaModel>((item) {
      return CategoriaModel.fromJson(item);
    }).toList();
    
    log('✅ Fallback Supabase: ${categorias.length} categorias');
    return categorias;
  }

  /// 📂 BUSCAR SUBCATEGORIAS (OFFLINE-FIRST)
  Future<List<SubcategoriaModel>> fetchSubcategorias({String? categoriaId}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('📂 Buscando subcategorias OFFLINE-FIRST');
      
      // 🔄 OFFLINE-FIRST: Busca local com JOIN
      await _localDb.setCurrentUser(userId);
      final localData = await _localDb.fetchSubcategoriasLocal(categoriaId: categoriaId);

      final subcategorias = localData.map<SubcategoriaModel>((item) {
        return SubcategoriaModel.fromJson(item);
      }).toList();

      log('✅ Subcategorias carregadas do SQLite: ${subcategorias.length}');
      return subcategorias;
    } catch (e) {
      log('❌ Erro ao buscar subcategorias: $e');
      return [];
    }
  }

  /// ➕ ADICIONAR CATEGORIA (OFFLINE-FIRST)
  Future<CategoriaModel> addCategoria({
    required String nome,
    String? tipo,
    String? cor,
    String? icone,
    String? descricao,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final now = DateTime.now();
      final categoriaId = _uuid.v4();
      
      final categoriaData = {
        'id': categoriaId,                 // ✅ UUID gerado
        'usuario_id': userId,              // ✅ Existe na tabela
        'nome': nome,                      // ✅ Existe na tabela  
        'tipo': tipo ?? 'despesa',         // ✅ Default para despesa
        'cor': cor ?? '#008080',           // ✅ Default React
        'icone': icone ?? '📁',            // ✅ Default React
        'ativo': 1,                        // ✅ SQLite usa INTEGER para boolean
        'ordem': 1,                        // ✅ Existe na tabela
        'descricao': descricao,            // ✅ Existe na tabela
        'created_at': now.toIso8601String(), // ✅ Timestamp
        'updated_at': now.toIso8601String(), // ✅ Timestamp
      };

      // 🔄 OFFLINE-FIRST: Salva local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      await _localDb.addCategoriaLocal(categoriaData);

      // 🧹 LIMPAR CACHE - Importante para mostrar dados atualizados
      limparCache();
      
      // 🔄 REFRESH INTELIGENTE: Recarrega períodos afetados
      _refreshInteligentePorMudanca();

      log('✅ Categoria criada OFFLINE: $nome');
      
      // Converte de volta para Supabase format (ativo: true)
      final responseData = Map<String, dynamic>.from(categoriaData);
      responseData['ativo'] = true;
      
      return CategoriaModel.fromJson(responseData);
    } catch (e) {
      log('❌ Erro ao criar categoria: $e');
      rethrow;
    }
  }

  /// ➕ ADICIONAR SUBCATEGORIA (OFFLINE-FIRST)
  Future<SubcategoriaModel> addSubcategoria({
    required String categoriaId,
    required String nome,
    String? cor,
    String? icone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final now = DateTime.now();
      final subcategoriaId = _uuid.v4();
      
      final subcategoriaData = {
        'id': subcategoriaId,              // ✅ UUID gerado
        'categoria_id': categoriaId,       // ✅ Obrigatório
        'usuario_id': userId,              // ✅ Obrigatório
        'nome': nome,                      // ✅ Obrigatório
        'descricao': null,                 // ✅ Opcional
        'ativo': 1,                        // ✅ SQLite INTEGER
        'created_at': now.toIso8601String(), // ✅ Timestamp
        'updated_at': now.toIso8601String(), // ✅ Timestamp
      };

      // 🔄 OFFLINE-FIRST: Salva local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      await _localDb.addSubcategoriaLocal(subcategoriaData);

      log('✅ Subcategoria criada OFFLINE: $nome');
      
      // Converte para Supabase format
      final responseData = Map<String, dynamic>.from(subcategoriaData);
      responseData['ativo'] = true;
      
      return SubcategoriaModel.fromJson(responseData);
    } catch (e) {
      log('❌ Erro ao criar subcategoria: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR CATEGORIA (OFFLINE-FIRST)
  Future<CategoriaModel> updateCategoria({
    required String categoriaId,
    String? nome,
    String? tipo,
    String? cor,
    String? icone,
    String? descricao,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Monta dados de atualização (só campos fornecidos)
      final updateData = <String, dynamic>{};
      if (nome != null) updateData['nome'] = nome;
      if (tipo != null) updateData['tipo'] = tipo;
      if (cor != null) updateData['cor'] = cor;
      if (icone != null) updateData['icone'] = icone;
      if (descricao != null) updateData['descricao'] = descricao;

      // 🔄 OFFLINE-FIRST: Atualiza local e enfileira para sync
      await _localDb.setCurrentUser(userId);
      await _localDb.updateCategoriaLocal(categoriaId, updateData);

      // 🧹 LIMPAR CACHE - Importante para mostrar dados atualizados
      limparCache();
      
      // 🔄 REFRESH INTELIGENTE: Recarrega períodos afetados
      _refreshInteligentePorMudanca();

      log('✅ Categoria atualizada OFFLINE: $categoriaId');
      
      // Busca dados atualizados para retornar
      final categorias = await fetchCategorias();
      final categoriaAtualizada = categorias.where((c) => c.id == categoriaId).firstOrNull;
      
      if (categoriaAtualizada != null) {
        return categoriaAtualizada;
      } else {
        throw Exception('Categoria não encontrada após atualização');
      }
    } catch (e) {
      log('❌ Erro ao atualizar categoria: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR SUBCATEGORIA (OFFLINE-FIRST)
  Future<SubcategoriaModel> updateSubcategoria({
    required String categoriaId,  // Precisa do categoriaId para validação
    required String subcategoriaId,
    String? nome,
    String? cor,
    String? icone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Monta dados de atualização (só campos fornecidos)
      final updateData = <String, dynamic>{};
      if (nome != null) updateData['nome'] = nome;
      // Nota: cor e icone não são usados em subcategorias (herdam da categoria pai)

      // 🔄 OFFLINE-FIRST: Atualiza local e enfileira para sync  
      await _localDb.setCurrentUser(userId);
      await _localDb.updateSubcategoriaLocal(subcategoriaId, categoriaId, updateData);

      log('✅ Subcategoria atualizada OFFLINE: $subcategoriaId');
      
      // Busca dados atualizados para retornar
      final subcategorias = await fetchSubcategorias();
      final subcategoriaAtualizada = subcategorias.where((s) => s.id == subcategoriaId).firstOrNull;
      
      if (subcategoriaAtualizada != null) {
        return subcategoriaAtualizada;
      } else {
        throw Exception('Subcategoria não encontrada após atualização');
      }
    } catch (e) {
      log('❌ Erro ao atualizar subcategoria: $e');
      rethrow;
    }
  }

  /// 📦 ARQUIVAR CATEGORIA
  Future<void> arquivarCategoria(String categoriaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase
          .from('categorias')
          .update({
            'ativo': 0, // false = 0 para compatibilidade SQLite
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoriaId)
          .eq('usuario_id', userId);

      log('✅ Categoria arquivada: $categoriaId');
    } catch (e) {
      log('❌ Erro ao arquivar categoria: $e');
      rethrow;
    }
  }

  /// 📤 DESARQUIVAR CATEGORIA
  Future<void> desarquivarCategoria(String categoriaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase
          .from('categorias')
          .update({
            'ativo': 1, // true = 1 para compatibilidade SQLite
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoriaId)
          .eq('usuario_id', userId);

      log('✅ Categoria desarquivada: $categoriaId');
    } catch (e) {
      log('❌ Erro ao desarquivar categoria: $e');
      rethrow;
    }
  }

  /// 📦 ARQUIVAR SUBCATEGORIA
  Future<void> arquivarSubcategoria(String subcategoriaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase
          .from('subcategorias')
          .update({
            'ativo': 0, // false = 0 para compatibilidade SQLite
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subcategoriaId)
          .eq('usuario_id', userId);

      log('✅ Subcategoria arquivada: $subcategoriaId');
    } catch (e) {
      log('❌ Erro ao arquivar subcategoria: $e');
      rethrow;
    }
  }

  /// 📊 VERIFICAR DEPENDÊNCIAS DA CATEGORIA
  Future<Map<String, dynamic>> verificarDependenciasCategoria(String categoriaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _localDb.setCurrentUser(userId);
      
      // Buscar transações vinculadas à categoria
      final transacoes = await _supabase
          .from('transacoes')
          .select('id')
          .eq('categoria_id', categoriaId)
          .eq('usuario_id', userId);
      
      // Buscar subcategorias vinculadas à categoria
      final subcategorias = await _supabase
          .from('subcategorias')
          .select('id')
          .eq('categoria_id', categoriaId)
          .eq('usuario_id', userId);
      
      final qtdTransacoes = transacoes.length;
      final qtdSubcategorias = subcategorias.length;
      final temDependencias = qtdTransacoes > 0 || qtdSubcategorias > 0;
      
      log('📊 Dependências categoria $categoriaId: $qtdTransacoes transações, $qtdSubcategorias subcategorias');
      
      return {
        'success': true,
        'temDependencias': temDependencias,
        'qtdTransacoes': qtdTransacoes,
        'qtdSubcategorias': qtdSubcategorias,
      };
    } catch (e) {
      log('❌ Erro ao verificar dependências: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🔄 MIGRAR CATEGORIA COM TODAS AS DEPENDÊNCIAS
  Future<Map<String, dynamic>> migrarCategoria({
    required String categoriaOrigemId,
    required String categoriaDestinoId,
  }) async {
    try {
      
      // Verificar conectividade antes de tentar migração
      final isOnline = await ConnectivityHelper.instance.isOnline();
      if (!isOnline) {
        return {
          'success': false,
          'error': 'Migração requer conexão com a internet. Verifique sua conexão e tente novamente.',
        };
      }
      
      
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      await _localDb.setCurrentUser(userId);
      
      
      // Validar se as categorias existem e são do mesmo tipo
      final categoriaOrigem = await _supabase
          .from('categorias')
          .select('tipo, nome')
          .eq('id', categoriaOrigemId)
          .eq('usuario_id', userId)
          .maybeSingle();
          
          
      final categoriaDestino = await _supabase
          .from('categorias')
          .select('tipo, nome')
          .eq('id', categoriaDestinoId)
          .eq('usuario_id', userId)
          .maybeSingle();
      
      
      if (categoriaOrigem == null) {
        throw Exception('Categoria origem não encontrada');
      }
      
      if (categoriaDestino == null) {
        throw Exception('Categoria destino não encontrada');
      }
      
      if (categoriaOrigem['tipo'] != categoriaDestino['tipo']) {
        throw Exception('Categorias devem ser do mesmo tipo (receita/despesa)');
      }
      
      if (categoriaOrigemId == categoriaDestinoId) {
        throw Exception('Não é possível migrar uma categoria para ela mesma');
      }
      
      log('🔄 Iniciando migração: ${categoriaOrigem['nome']} → ${categoriaDestino['nome']}');
      
      // Iniciar transação (batch updates)
      int transacoesMigradas = 0;
      int subcategoriasMigradas = 0;
      
      
      // 1. Migrar todas as transações
      final resultadoTransacoes = await _supabase
          .from('transacoes')
          .update({'categoria_id': categoriaDestinoId})
          .eq('categoria_id', categoriaOrigemId)
          .eq('usuario_id', userId)
          .select('id');
      
      transacoesMigradas = resultadoTransacoes.length;
      
      
      // 2. Migrar todas as subcategorias
      final resultadoSubcategorias = await _supabase
          .from('subcategorias')
          .update({'categoria_id': categoriaDestinoId})
          .eq('categoria_id', categoriaOrigemId)
          .eq('usuario_id', userId)
          .select('id');
      
      subcategoriasMigradas = resultadoSubcategorias.length;
      
      // 3. Atualizar dados locais (SQLite) para refletir mudanças imediatamente
      
      try {
        // Atualizar transações no SQLite local
        if (transacoesMigradas > 0) {
          await _localDb.database?.execute('''
            UPDATE transacoes 
            SET categoria_id = ? 
            WHERE categoria_id = ? AND usuario_id = ?
          ''', [categoriaDestinoId, categoriaOrigemId, userId]);
        }
        
        // Atualizar subcategorias no SQLite local
        if (subcategoriasMigradas > 0) {
          await _localDb.database?.execute('''
            UPDATE subcategorias 
            SET categoria_id = ? 
            WHERE categoria_id = ? AND usuario_id = ?
          ''', [categoriaDestinoId, categoriaOrigemId, userId]);
        }
        
        // Limpar caches para forçar refresh
        _cacheValoresCategorias.clear();
        _cacheValoresSubcategorias.clear();
        
      } catch (e) {
        // Não falha a migração por causa disso, apenas log
      }
      
      // 4. Forçar sincronização completa das categorias e subcategorias
      
      try {
        // Baixar dados atualizados do Supabase (forçado, ignorando cooldown)
        await SyncManager.instance.syncCategorias(force: true);
        await SyncManager.instance.syncSubcategorias(force: true);
        
        // Limpar TODOS os caches
        _cacheValoresCategorias.clear();
        _cacheValoresSubcategorias.clear();
        _preCacheUltimos12Meses.clear();
        _preCacheSubcategoriasUltimos12Meses.clear();
        
      } catch (e) {
        // Não falha a migração por causa disso, apenas log
      }
      
      log('✅ Migração concluída - dados atualizados no Supabase e SQLite');
      log('✅ Migração concluída: $transacoesMigradas transações, $subcategoriasMigradas subcategorias');
      
      return {
        'success': true,
        'transacoesMigradas': transacoesMigradas,
        'subcategoriasMigradas': subcategoriasMigradas,
        'message': 'Migração realizada com sucesso',
      };
    } catch (e) {
      log('❌ Erro na migração de categoria: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🗑️ EXCLUIR CATEGORIA COM VALIDAÇÃO SEGURA
  Future<Map<String, dynamic>> excluirCategoriaSeguro({
    required String categoriaId,
    String? categoriaDestinoId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _localDb.setCurrentUser(userId);
      
      // 1. Verificar dependências
      final dependencias = await verificarDependenciasCategoria(categoriaId);
      if (!dependencias['success']) {
        return dependencias;
      }
      
      final temDependencias = dependencias['temDependencias'] as bool;
      
      // 2. Se tem dependências mas não tem categoria destino, erro
      if (temDependencias && categoriaDestinoId == null) {
        return {
          'success': false,
          'requiresMigration': true,
          'qtdTransacoes': dependencias['qtdTransacoes'],
          'qtdSubcategorias': dependencias['qtdSubcategorias'],
          'error': 'Esta categoria possui dados vinculados. Selecione uma categoria destino para migrar os dados.',
        };
      }
      
      // 3. Se tem dependências, migrar primeiro
      if (temDependencias && categoriaDestinoId != null) {
        final migracao = await migrarCategoria(
          categoriaOrigemId: categoriaId,
          categoriaDestinoId: categoriaDestinoId,
        );
        
        if (!migracao['success']) {
          return migracao;
        }
        
        log('✅ Dados migrados, prosseguindo com exclusão');
      }
      
      // 4. Excluir categoria (agora sem dependências)
      final resultado = await deleteCategoria(categoriaId);
      
      if (resultado['success']) {
        log('✅ Categoria excluída com sucesso: $categoriaId');
        return {
          'success': true,
          'message': temDependencias 
              ? 'Categoria excluída após migração dos dados'
              : 'Categoria excluída com sucesso',
          'dadosMigrados': temDependencias,
        };
      }
      
      return resultado;
    } catch (e) {
      log('❌ Erro na exclusão segura de categoria: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🗑️ DELETE CATEGORIA (OFFLINE-FIRST COM SOFT/HARD DELETE) - MÉTODO ORIGINAL
  Future<Map<String, dynamic>> deleteCategoria(String categoriaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 🔄 OFFLINE-FIRST: Delete local com lógica inteligente
      await _localDb.setCurrentUser(userId);
      final resultado = await _localDb.deleteCategoriaLocal(categoriaId);

      log('✅ ${resultado['message']}: $categoriaId');
      return resultado;
    } catch (e) {
      log('❌ Erro ao deletar categoria: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🗑️ DELETE SUBCATEGORIA (OFFLINE-FIRST COM SOFT/HARD DELETE)  
  Future<Map<String, dynamic>> deleteSubcategoria(String categoriaId, String subcategoriaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 🔄 OFFLINE-FIRST: Delete local com lógica inteligente
      await _localDb.setCurrentUser(userId);
      final resultado = await _localDb.deleteSubcategoriaLocal(subcategoriaId, categoriaId);

      log('✅ ${resultado['message']}: $subcategoriaId');
      return resultado;
    } catch (e) {
      log('❌ Erro ao deletar subcategoria: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🔍 GET CATEGORIA BY ID (EM MEMÓRIA - IGUAL REACT)
  CategoriaModel? getCategoriaById(String categoriaId, List<CategoriaModel> categorias) {
    try {
      return categorias.where((categoria) => categoria.id == categoriaId).firstOrNull;
    } catch (e) {
      log('❌ Erro ao buscar categoria por ID em memória: $e');
      return null;
    }
  }

  /// 🔍 GET SUBCATEGORIA BY ID (EM MEMÓRIA - IGUAL REACT)
  SubcategoriaModel? getSubcategoriaById(String subcategoriaId, List<SubcategoriaModel> subcategorias) {
    try {
      return subcategorias.where((subcategoria) => subcategoria.id == subcategoriaId).firstOrNull;
    } catch (e) {
      log('❌ Erro ao buscar subcategoria por ID em memória: $e');
      return null;
    }
  }

  /// 📈 BUSCAR CATEGORIAS COM VALORES PRÉ-CALCULADOS (OFFLINE-FIRST)
  /// Prioriza SQLite local, depois tenta Supabase se necessário
  Future<List<Map<String, dynamic>>> fetchCategoriasComValores({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('📊 Buscando categorias com valores OFFLINE-FIRST...');

      // 🏠 PRIORIDADE 1: Tentar SQLite local primeiro (OFFLINE-FIRST)
      try {
        await _localDb.setCurrentUser(userId);

        // Primeiro tenta método otimizado do LocalDatabase
        try {
          final dadosOffline = await _localDb.fetchCategoriasComValoresLocal(
            tipo: tipo,
            dataInicio: dataInicio,
            dataFim: dataFim,
          );

          if (dadosOffline.isNotEmpty) {
            log('✅ Dados offline otimizados encontrados: ${dadosOffline.length} categorias');
            return dadosOffline;
          }
        } catch (e) {
          log('⚠️ Método otimizado falhou, calculando manualmente: $e');
        }

        // FALLBACK: Calcular valores manualmente do SQLite
        log('🔄 Calculando valores offline manualmente...');
        final categorias = await fetchCategorias(tipo: tipo);

        if (categorias.isEmpty) {
          log('⚠️ Nenhuma categoria no SQLite, tentando online...');
        } else {
          final resultado = <Map<String, dynamic>>[];

          // Calcular valores para cada categoria
          for (final categoria in categorias) {
            double valorTotal = 0.0;
            int quantidadeTransacoes = 0;

            try {
              // Query direta no SQLite para SUM dos valores
              final db = _localDb.database;
              if (db != null) {
                String query = '''
                  SELECT COALESCE(SUM(valor), 0) as total, COUNT(*) as qtd
                  FROM transacoes
                  WHERE categoria_id = ? AND usuario_id = ? AND efetivado = 1
                ''';

                List<dynamic> params = [categoria.id, userId];

                // Adicionar filtros de data se fornecidos
                if (dataInicio != null) {
                  query += ' AND data >= ?';
                  params.add(dataInicio.toIso8601String().split('T')[0]);
                }
                if (dataFim != null) {
                  query += ' AND data <= ?';
                  params.add(dataFim.toIso8601String().split('T')[0]);
                }

                final result = await db.rawQuery(query, params);

                if (result.isNotEmpty) {
                  valorTotal = (result.first['total'] as num?)?.toDouble() ?? 0.0;
                  quantidadeTransacoes = (result.first['qtd'] as int?) ?? 0;
                }
              }
            } catch (e) {
              log('⚠️ Erro ao calcular valores para ${categoria.nome}: $e');
            }

            resultado.add({
              'id': categoria.id,
              'usuario_id': userId,
              'nome': categoria.nome,
              'cor': categoria.cor,
              'icone': categoria.icone,
              'tipo': categoria.tipo,
              'valor_total': valorTotal,
              'quantidade_transacoes': quantidadeTransacoes,
              'ativo': categoria.ativo,
              'created_at': categoria.createdAt.toIso8601String(),
              'updated_at': categoria.updatedAt.toIso8601String(),
            });
          }

          log('✅ Valores calculados offline: ${resultado.length} categorias');
          return resultado;
        }
      } catch (offlineError) {
        log('⚠️ Erro ao buscar offline: $offlineError');
      }

      // 📡 PRIORIDADE 2: Tentar RPC do Supabase (requer internet)
      try {
        final response = await _supabase.rpc(
          'get_categorias_com_valores',
          params: {
            'p_usuario_id': userId,
            'p_data_inicio': dataInicio?.toIso8601String().split('T')[0],
            'p_data_fim': dataFim?.toIso8601String().split('T')[0],
            'p_tipo': tipo,
          },
        );

        if (response is List && response.isNotEmpty) {
          log('✅ Categorias com valores do RPC: ${response.length}');
          return response.map<Map<String, dynamic>>((item) {
            return Map<String, dynamic>.from(item);
          }).toList();
        }
      } catch (rpcError) {
        log('⚠️ Erro no RPC (pode estar offline): $rpcError');
      }

      // 🔄 PRIORIDADE 3: Fallback calculando manualmente (requer internet)
      log('⚠️ Tentando fallback manual...');
      return await _fetchCategoriasComValoresFallback(
        dataInicio: dataInicio,
        dataFim: dataFim,
        tipo: tipo,
      );
    } catch (e) {
      log('❌ Erro geral em fetchCategoriasComValores: $e');
      // Última tentativa: retornar categorias básicas sem valores
      return await _retornarCategoriasBasicasSemValores(tipo: tipo);
    }
  }

  /// 🔖 BUSCAR SUBCATEGORIAS COM VALORES PRÉ-CALCULADOS (OFFLINE-FIRST)
  /// Prioriza SQLite local, depois tenta Supabase se necessário
  Future<List<Map<String, dynamic>>> fetchSubcategoriasComValores({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? categoriaId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('🔖 Buscando subcategorias com valores OFFLINE-FIRST...');

      // 🏠 PRIORIDADE 1: Tentar SQLite local primeiro (OFFLINE-FIRST)
      try {
        await _localDb.setCurrentUser(userId);
        final subcategoriasBasicas = await _localDb.fetchSubcategoriasLocal(categoriaId: categoriaId);

        if (subcategoriasBasicas.isNotEmpty) {
          // Retorna subcategorias do SQLite (com valores zerados por enquanto)
          final dadosOffline = subcategoriasBasicas.map((sub) => {
            ...sub,
            'valor_total': 0.0,
            'quantidade_transacoes': 0,
          }).toList();

          log('✅ Subcategorias offline encontradas: ${dadosOffline.length}');
          return dadosOffline;
        }

        log('⚠️ SQLite vazio de subcategorias, tentando online...');
      } catch (offlineError) {
        log('⚠️ Erro ao buscar subcategorias offline: $offlineError');
      }

      // 📡 PRIORIDADE 2: Tentar RPC do Supabase (requer internet)
      try {
        final response = await _supabase.rpc(
          'get_subcategorias_com_valores',
          params: {
            'p_usuario_id': userId,
            'p_data_inicio': dataInicio?.toIso8601String().split('T')[0],
            'p_data_fim': dataFim?.toIso8601String().split('T')[0],
            'p_categoria_id': categoriaId,
          },
        );

        if (response is List && response.isNotEmpty) {
          log('✅ Subcategorias com valores do RPC: ${response.length}');
          return response.map<Map<String, dynamic>>((item) {
            return Map<String, dynamic>.from(item);
          }).toList();
        }
      } catch (rpcError) {
        log('⚠️ Erro no RPC subcategorias (pode estar offline): $rpcError');
      }

      // 🔄 PRIORIDADE 3: Fallback calculando manualmente (requer internet)
      log('⚠️ Tentando fallback manual para subcategorias...');
      return await _fetchSubcategoriasComValoresFallback(
        dataInicio: dataInicio,
        dataFim: dataFim,
        categoriaId: categoriaId,
      );
    } catch (e) {
      log('❌ Erro geral em fetchSubcategoriasComValores: $e');
      return [];
    }
  }

  /// 🆘 FALLBACK FINAL: Retornar categorias básicas sem valores quando tudo falhar
  Future<List<Map<String, dynamic>>> _retornarCategoriasBasicasSemValores({String? tipo}) async {
    try {
      log('🆘 Usando fallback final: categorias básicas sem valores');

      // Busca categorias básicas do SQLite
      final categorias = await fetchCategorias(tipo: tipo);

      return categorias.map((cat) => {
        'id': cat.id,
        'nome': cat.nome,
        'cor': cat.cor,
        'icone': cat.icone,
        'tipo': cat.tipo,
        'valor_total': 0.0,
        'quantidade_transacoes': 0,
        'ativo': cat.ativo,
      }).toList();
    } catch (e) {
      log('❌ Erro no fallback final: $e');
      return [];
    }
  }

  /// 🚀 OFFLINE OTIMIZADO: BUSCAR CATEGORIAS COM VALORES (PRIMEIRA TENTATIVA)
  /// Usa SQLite otimizado como primeira opção de fallback
  Future<List<Map<String, dynamic>>> _fetchCategoriasComValoresOffline({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('🚀 Tentando offline otimizado...');
      
      await _localDb.setCurrentUser(userId);
      final dadosOffline = await _localDb.fetchCategoriasComValoresLocal(
        tipo: tipo,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      if (dadosOffline.isNotEmpty) {
        log('✅ Dados offline encontrados: ${dadosOffline.length}');
        return dadosOffline;
      }
      
      log('⚠️ Sem dados offline, usando fallback de rede...');
      return await _fetchCategoriasComValoresFallback(
        dataInicio: dataInicio,
        dataFim: dataFim,
        tipo: tipo,
      );
    } catch (e) {
      log('⚠️ Erro offline, usando fallback de rede: $e');
      return await _fetchCategoriasComValoresFallback(
        dataInicio: dataInicio,
        dataFim: dataFim,
        tipo: tipo,
      );
    }
  }

  /// 🔖 OFFLINE OTIMIZADO: BUSCAR SUBCATEGORIAS COM VALORES (PRIMEIRA TENTATIVA)
  /// Usa SQLite otimizado como primeira opção de fallback
  Future<List<Map<String, dynamic>>> _fetchSubcategoriasComValoresOffline({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? categoriaId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('🔖 Tentando offline otimizado para subcategorias...');
      
      await _localDb.setCurrentUser(userId);
      // Usa o método básico de subcategorias por enquanto
      // TODO: Implementar fetchSubcategoriasComValoresLocal na LocalDatabase  
      final subcategoriasBasicas = await _localDb.fetchSubcategoriasLocal(categoriaId: categoriaId);
      final dadosOffline = subcategoriasBasicas.map((sub) => {
        ...sub,
        'valor_total': 0.0,
        'quantidade_transacoes': 0,
      }).toList();

      if (dadosOffline.isNotEmpty) {
        log('✅ Dados offline subcategorias encontrados: ${dadosOffline.length}');
        return dadosOffline;
      }
      
      log('⚠️ Sem dados offline subcategorias, usando fallback de rede...');
      return await _fetchSubcategoriasComValoresFallback(
        dataInicio: dataInicio,
        dataFim: dataFim,
        categoriaId: categoriaId,
      );
    } catch (e) {
      log('⚠️ Erro offline subcategorias, usando fallback de rede: $e');
      return await _fetchSubcategoriasComValoresFallback(
        dataInicio: dataInicio,
        dataFim: dataFim,
        categoriaId: categoriaId,
      );
    }
  }

  /// 📈 FALLBACK: BUSCAR CATEGORIAS COM ESTATÍSTICAS (MÉTODO ORIGINAL)
  Future<List<Map<String, dynamic>>> _fetchCategoriasComValoresFallback({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('📊 Usando fallback para categorias com valores...');
      
      // Buscar categorias
      final categorias = await fetchCategorias(tipo: tipo);
      final resultado = <Map<String, dynamic>>[];

      // Calcular valores para cada categoria
      for (final categoria in categorias) {
        var query = _supabase
            .from('transacoes')
            .select('valor')
            .eq('categoria_id', categoria.id)
            .eq('usuario_id', userId)
            .eq('efetivado', true);

        if (dataInicio != null) {
          query = query.gte('data', dataInicio.toIso8601String().split('T')[0]);
        }
        if (dataFim != null) {
          query = query.lte('data', dataFim.toIso8601String().split('T')[0]);
        }

        final transacoes = await query;

        double total = 0.0;
        int quantidade = 0;

        for (final t in transacoes as List) {
          total += (t['valor'] as num).toDouble();
          quantidade++;
        }

        resultado.add({
          'id': categoria.id,
          'nome': categoria.nome,
          'cor': categoria.cor,
          'icone': categoria.icone,
          'tipo': categoria.tipo,
          'valor_total': total,
          'quantidade_transacoes': quantidade,
          'ativo': categoria.ativo,
        });
      }

      return resultado;
    } catch (e) {
      log('❌ Erro no fallback de categorias: $e');
      return [];
    }
  }

  /// 🔖 FALLBACK: BUSCAR SUBCATEGORIAS COM ESTATÍSTICAS (MÉTODO ORIGINAL)
  Future<List<Map<String, dynamic>>> _fetchSubcategoriasComValoresFallback({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? categoriaId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('🔖 Usando fallback para subcategorias com valores...');
      
      // Buscar subcategorias
      final subcategorias = await fetchSubcategorias(categoriaId: categoriaId);
      final resultado = <Map<String, dynamic>>[];

      // Calcular valores para cada subcategoria
      for (final subcategoria in subcategorias) {
        var query = _supabase
            .from('transacoes')
            .select('valor')
            .eq('subcategoria_id', subcategoria.id)
            .eq('usuario_id', userId)
            .eq('efetivado', true);

        if (dataInicio != null) {
          query = query.gte('data', dataInicio.toIso8601String().split('T')[0]);
        }
        if (dataFim != null) {
          query = query.lte('data', dataFim.toIso8601String().split('T')[0]);
        }

        final transacoes = await query;

        double total = 0.0;
        int quantidade = 0;

        for (final t in transacoes as List) {
          total += (t['valor'] as num).toDouble();
          quantidade++;
        }

        resultado.add({
          'id': subcategoria.id,
          'categoria_id': subcategoria.categoriaId,
          'nome': subcategoria.nome,
          'cor': subcategoria.cor,
          'icone': subcategoria.icone,
          'valor_total': total,
          'quantidade_transacoes': quantidade,
          'ativo': subcategoria.ativo,
        });
      }

      return resultado;
    } catch (e) {
      log('❌ Erro no fallback de subcategorias: $e');
      return [];
    }
  }

  /// 📈 MÉTODO DE COMPATIBILIDADE (MANTÉM INTERFACE ORIGINAL)
  Future<Map<String, dynamic>> fetchCategoriasComEstatisticas({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final categoriasComValores = await fetchCategoriasComValores(
      dataInicio: dataInicio,
      dataFim: dataFim,
    );
    
    final categorias = <CategoriaModel>[];
    final estatisticas = <String, Map<String, double>>{};
    
    for (final item in categoriasComValores) {
      categorias.add(CategoriaModel(
        id: item['id'],
        usuarioId: item['usuario_id'] ?? '',
        nome: item['nome'],
        cor: item['cor'],
        icone: item['icone'],
        tipo: item['tipo'],
        ativo: item['ativo'] == true || item['ativo'] == 1,
        createdAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now(),
      ));
      
      estatisticas[item['id']] = {
        'total': (item['valor_total'] as num?)?.toDouble() ?? 0.0,
        'quantidade': (item['quantidade_transacoes'] as num?)?.toDouble() ?? 0.0,
      };
    }
    
    return {
      'categorias': categorias,
      'estatisticas': estatisticas,
    };
  }

  /// 💾 PRÉ-CACHE DOS ÚLTIMOS 12 MESES (PERFORMANCE MÁXIMA)
  final Map<String, Map<String, dynamic>> _cacheValoresCategorias = {};
  final Map<String, List<Map<String, dynamic>>> _preCacheUltimos12Meses = {};
  DateTime? _ultimoUpdateCache;
  DateTime? _ultimoPreCarregamento;
  bool _preCarregamentoIniciado = false;

  /// 🔖 CACHE DE SUBCATEGORIAS - ESPELHANDO O SISTEMA DE CATEGORIAS
  final Map<String, Map<String, dynamic>> _cacheValoresSubcategorias = {};
  final Map<String, List<Map<String, dynamic>>> _preCacheSubcategoriasUltimos12Meses = {};
  DateTime? _ultimoUpdateCacheSubcategorias;
  DateTime? _ultimoPreCarregamentoSubcategorias;
  bool _preCarregamentoSubcategoriasIniciado = false;

  /// ⏰ ATUALIZAÇÃO AUTOMÁTICA A CADA 5 MINUTOS
  Timer? _timerAtualizacaoAutomatica;
  bool _atualizacaoAutomaticaAtiva = false;
  
  /// 🚀 BUSCAR CATEGORIAS COM CACHE LOCAL (MÁXIMA PERFORMANCE)
  Future<List<Map<String, dynamic>>> fetchCategoriasComValoresCache({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
    bool forceRefresh = false,
  }) async {
    // Verifica se pode usar pré-cache dos últimos 12 meses
    if (!forceRefresh && dataInicio != null && dataFim != null) {
      final dadosPreCache = _buscarNoPreCache(dataInicio, dataFim, tipo);
      if (dadosPreCache != null) {
        log('⚡ Usando PRÉ-CACHE dos últimos 12 meses!');
        return dadosPreCache;
      }
    }
    
    final cacheKey = '${dataInicio?.toIso8601String() ?? ''}-${dataFim?.toIso8601String() ?? ''}-${tipo ?? ''}';
    final agora = DateTime.now();
    
    // Verifica cache normal (5 minutos)
    if (!forceRefresh && 
        _cacheValoresCategorias.containsKey(cacheKey)) {
      final cacheData = _cacheValoresCategorias[cacheKey]!;
      final timestampCache = DateTime.tryParse(cacheData['timestamp'] as String);
      
      if (timestampCache != null && agora.difference(timestampCache).inMinutes < 5) {
        log('⚡ Usando cache local de categorias');
        return cacheData['dados'] as List<Map<String, dynamic>>;
      }
    }
    
    // Busca dados frescos
    final dados = await fetchCategoriasComValores(
      dataInicio: dataInicio,
      dataFim: dataFim,
      tipo: tipo,
    );
    
    // Atualiza cache normal
    _cacheValoresCategorias[cacheKey] = {
      'dados': dados,
      'timestamp': agora.toIso8601String(),
    };
    _ultimoUpdateCache = agora;
    
    log('💾 Cache de categorias atualizado');
    return dados;
  }

  /// 🔖 BUSCAR SUBCATEGORIAS COM CACHE LOCAL (MÁXIMA PERFORMANCE)
  Future<List<Map<String, dynamic>>> fetchSubcategoriasComValoresCache({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? categoriaId,
    bool forceRefresh = false,
  }) async {
    // Verifica se pode usar pré-cache dos últimos 12 meses
    if (!forceRefresh && dataInicio != null && dataFim != null) {
      final dadosPreCache = _buscarSubcategoriasNoPreCache(dataInicio, dataFim, categoriaId);
      if (dadosPreCache != null) {
        log('⚡ Usando PRÉ-CACHE de subcategorias dos últimos 12 meses!');
        return dadosPreCache;
      }
    }
    
    final cacheKey = '${dataInicio?.toIso8601String() ?? ''}-${dataFim?.toIso8601String() ?? ''}-${categoriaId ?? ''}';
    final agora = DateTime.now();
    
    // Verifica cache normal (5 minutos)
    if (!forceRefresh && 
        _cacheValoresSubcategorias.containsKey(cacheKey)) {
      final cacheData = _cacheValoresSubcategorias[cacheKey]!;
      final timestampCache = DateTime.tryParse(cacheData['timestamp'] as String);
      
      if (timestampCache != null && agora.difference(timestampCache).inMinutes < 5) {
        log('⚡ Usando cache local de subcategorias');
        return cacheData['dados'] as List<Map<String, dynamic>>;
      }
    }
    
    // Busca dados frescos
    final dados = await fetchSubcategoriasComValores(
      dataInicio: dataInicio,
      dataFim: dataFim,
      categoriaId: categoriaId,
    );
    
    // Atualiza cache normal
    _cacheValoresSubcategorias[cacheKey] = {
      'dados': dados,
      'timestamp': agora.toIso8601String(),
    };
    _ultimoUpdateCacheSubcategorias = agora;
    
    log('💾 Cache de subcategorias atualizado');
    return dados;
  }

  /// 🔍 BUSCAR NO PRÉ-CACHE DOS ÚLTIMOS 12 MESES
  List<Map<String, dynamic>>? _buscarNoPreCache(DateTime dataInicio, DateTime dataFim, String? tipo) {
    final chaveInicio = '${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}';
    final chaveFim = '${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}';
    
    // Se é período de um mês exato, busca direto
    if (chaveInicio == chaveFim) {
      final chaveFinal = '${chaveInicio}-${tipo ?? 'all'}';
      if (_preCacheUltimos12Meses.containsKey(chaveFinal)) {
        return List<Map<String, dynamic>>.from(_preCacheUltimos12Meses[chaveFinal]!);
      }
    }
    
    // TODO: Implementar agregação para períodos múltiplos se necessário
    return null;
  }

  /// 🔖 BUSCAR SUBCATEGORIAS NO PRÉ-CACHE DOS ÚLTIMOS 12 MESES
  List<Map<String, dynamic>>? _buscarSubcategoriasNoPreCache(DateTime dataInicio, DateTime dataFim, String? categoriaId) {
    final chaveInicio = '${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}';
    final chaveFim = '${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}';
    
    // Se é período de um mês exato, busca direto
    if (chaveInicio == chaveFim) {
      final chaveFinal = '${chaveInicio}-${categoriaId ?? 'all'}';
      if (_preCacheSubcategoriasUltimos12Meses.containsKey(chaveFinal)) {
        return List<Map<String, dynamic>>.from(_preCacheSubcategoriasUltimos12Meses[chaveFinal]!);
      }
    }
    
    // TODO: Implementar agregação para períodos múltiplos se necessário
    return null;
  }
  
  /// 🚀 PRÉ-CARREGAR DADOS DOS ÚLTIMOS 12 MESES + ANO ATUAL
  Future<void> preCarregarUltimos12Meses({bool forceRefresh = false}) async {
    if (_preCarregamentoIniciado && !forceRefresh) return;
    
    _preCarregamentoIniciado = true;
    final agora = DateTime.now();
    
    // Verifica se precisa recarregar (1 vez por dia)
    if (!forceRefresh && _ultimoPreCarregamento != null) {
      final diffDias = agora.difference(_ultimoPreCarregamento!).inDays;
      if (diffDias < 1) {
        log('⚡ Pré-cache ainda válido (${diffDias} dias)');
        return;
      }
    }
    
    log('🚀 Iniciando pré-carregamento dos últimos 12 meses + ano atual...');
    
    try {
      // Lista de períodos para pré-carregar
      final periodosParaCarregar = <Map<String, dynamic>>[];
      
      // 1. ÚLTIMOS 12 MESES (histórico)
      for (int i = 1; i <= 12; i++) {
        final dataBase = DateTime(agora.year, agora.month - i, 1);
        final dataInicio = DateTime(dataBase.year, dataBase.month, 1);
        final dataFim = DateTime(dataBase.year, dataBase.month + 1, 0);
        
        periodosParaCarregar.add({
          'dataInicio': dataInicio,
          'dataFim': dataFim,
          'chave': '${dataBase.year}-${dataBase.month.toString().padLeft(2, '0')}',
          'descricao': '${_getNomeMes(dataBase.month)}/${dataBase.year}',
        });
      }
      
      // 2. TODOS OS MESES DO ANO ATUAL
      for (int mes = 1; mes <= 12; mes++) {
        final dataInicio = DateTime(agora.year, mes, 1);
        final dataFim = DateTime(agora.year, mes + 1, 0);
        
        periodosParaCarregar.add({
          'dataInicio': dataInicio,
          'dataFim': dataFim,
          'chave': '${agora.year}-${mes.toString().padLeft(2, '0')}',
          'descricao': '${_getNomeMes(mes)}/${agora.year}',
        });
      }
      
      // Remove duplicatas
      final periodosUnicos = <String, Map<String, dynamic>>{};
      for (final periodo in periodosParaCarregar) {
        periodosUnicos[periodo['chave']] = periodo;
      }
      
      log('📅 Carregando ${periodosUnicos.length} períodos únicos...');
      
      // Pré-carrega cada período (todas as categorias e por tipo)
      int contador = 0;
      for (final periodo in periodosUnicos.values) {
        contador++;
        final dataInicio = periodo['dataInicio'] as DateTime;
        final dataFim = periodo['dataFim'] as DateTime;
        final chave = periodo['chave'] as String;
        final descricao = periodo['descricao'] as String;
        
        log('📈 Pré-carregando ($contador/${periodosUnicos.length}): $descricao');
        
        // Carrega: todas, receitas, despesas
        for (final tipo in [null, 'receita', 'despesa']) {
          try {
            final dados = await fetchCategoriasComValores(
              dataInicio: dataInicio,
              dataFim: dataFim,
              tipo: tipo,
            );
            
            final chaveCompleta = '$chave-${tipo ?? 'all'}';
            _preCacheUltimos12Meses[chaveCompleta] = dados;
            
            log('  ✅ ${tipo ?? 'todas'}: ${dados.length} categorias');
          } catch (e) {
            log('  ❌ Erro ao carregar ${tipo ?? 'todas'}: $e');
          }
        }
        
        // Pequena pausa para não sobrecarregar
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      _ultimoPreCarregamento = agora;
      
      final totalChaves = _preCacheUltimos12Meses.keys.length;
      log('🎯 Pré-carregamento concluído! $totalChaves períodos em cache');
      log('📊 Uso de memória: ~${(totalChaves * 50)} KB estimados');
      
      // 🔖 INICIAR PRÉ-CARREGAMENTO DE SUBCATEGORIAS EM PARALELO
      preCarregarSubcategoriasUltimos12Meses(forceRefresh: forceRefresh).catchError((e) {
        log('⚠️ Erro no pré-carregamento de subcategorias: $e');
      });
      
    } catch (e) {
      log('❌ Erro no pré-carregamento: $e');
    } finally {
      _preCarregamentoIniciado = false;
    }
  }

  /// 🔖 PRÉ-CARREGAR SUBCATEGORIAS DOS ÚLTIMOS 12 MESES + ANO ATUAL
  Future<void> preCarregarSubcategoriasUltimos12Meses({bool forceRefresh = false}) async {
    if (_preCarregamentoSubcategoriasIniciado && !forceRefresh) return;
    
    _preCarregamentoSubcategoriasIniciado = true;
    final agora = DateTime.now();
    
    // Verifica se precisa recarregar (1 vez por dia)
    if (!forceRefresh && _ultimoPreCarregamentoSubcategorias != null) {
      final diffDias = agora.difference(_ultimoPreCarregamentoSubcategorias!).inDays;
      if (diffDias < 1) {
        log('⚡ Pré-cache de subcategorias ainda válido (${diffDias} dias)');
        return;
      }
    }
    
    log('🔖 Iniciando pré-carregamento de subcategorias dos últimos 12 meses + ano atual...');
    
    try {
      // Buscar todas as categorias ativas para pré-carregar suas subcategorias
      final categorias = await fetchCategorias();
      if (categorias.isEmpty) {
        log('⚠️ Nenhuma categoria encontrada para pré-carregar subcategorias');
        return;
      }
      
      // Lista de períodos para pré-carregar
      final periodosParaCarregar = <Map<String, dynamic>>[];
      
      // 1. ÚLTIMOS 12 MESES (histórico)
      for (int i = 1; i <= 12; i++) {
        final dataBase = DateTime(agora.year, agora.month - i, 1);
        final dataInicio = DateTime(dataBase.year, dataBase.month, 1);
        final dataFim = DateTime(dataBase.year, dataBase.month + 1, 0);
        
        periodosParaCarregar.add({
          'dataInicio': dataInicio,
          'dataFim': dataFim,
          'chave': '${dataBase.year}-${dataBase.month.toString().padLeft(2, '0')}',
          'descricao': '${_getNomeMes(dataBase.month)}/${dataBase.year}',
        });
      }
      
      // 2. TODOS OS MESES DO ANO ATUAL
      for (int mes = 1; mes <= 12; mes++) {
        final dataInicio = DateTime(agora.year, mes, 1);
        final dataFim = DateTime(agora.year, mes + 1, 0);
        
        periodosParaCarregar.add({
          'dataInicio': dataInicio,
          'dataFim': dataFim,
          'chave': '${agora.year}-${mes.toString().padLeft(2, '0')}',
          'descricao': '${_getNomeMes(mes)}/${agora.year}',
        });
      }
      
      // Remove duplicatas
      final periodosUnicos = <String, Map<String, dynamic>>{};
      for (final periodo in periodosParaCarregar) {
        periodosUnicos[periodo['chave']] = periodo;
      }
      
      log('📅 Carregando subcategorias de ${periodosUnicos.length} períodos únicos...');
      
      // Pré-carrega cada período para todas as categorias
      int contador = 0;
      for (final periodo in periodosUnicos.values) {
        contador++;
        final dataInicio = periodo['dataInicio'] as DateTime;
        final dataFim = periodo['dataFim'] as DateTime;
        final chave = periodo['chave'] as String;
        final descricao = periodo['descricao'] as String;
        
        log('🔖 Pré-carregando subcategorias ($contador/${periodosUnicos.length}): $descricao');
        
        // Carrega: todas as subcategorias e por categoria específica
        final categoriasParaCache = [null, ...categorias.map((c) => c.id)];
        
        for (final categoriaId in categoriasParaCache) {
          try {
            final dados = await fetchSubcategoriasComValores(
              dataInicio: dataInicio,
              dataFim: dataFim,
              categoriaId: categoriaId,
            );
            
            final chaveCompleta = '$chave-${categoriaId ?? 'all'}';
            _preCacheSubcategoriasUltimos12Meses[chaveCompleta] = dados;
            
            final categoriaDesc = categoriaId != null 
                ? categorias.where((c) => c.id == categoriaId).firstOrNull?.nome ?? 'categoria'
                : 'todas';
            log('  ✅ $categoriaDesc: ${dados.length} subcategorias');
          } catch (e) {
            log('  ❌ Erro ao carregar subcategorias de ${categoriaId ?? 'todas'}: $e');
          }
        }
        
        // Pequena pausa para não sobrecarregar
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _ultimoPreCarregamentoSubcategorias = agora;
      
      final totalChaves = _preCacheSubcategoriasUltimos12Meses.keys.length;
      log('🎯 Pré-carregamento de subcategorias concluído! $totalChaves períodos em cache');
      log('📊 Uso de memória subcategorias: ~${(totalChaves * 30)} KB estimados');
      
    } catch (e) {
      log('❌ Erro no pré-carregamento de subcategorias: $e');
    } finally {
      _preCarregamentoSubcategoriasIniciado = false;
    }
  }
  
  /// 📅 HELPER: Nome do mês
  String _getNomeMes(int mes) {
    const nomes = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return nomes[mes] ?? mes.toString();
  }
  
  /// 🔄 INICIALIZAÇÃO DO SERVIÇO (CHAMA AUTOMATICAMENTE)
  Future<void> inicializar() async {
    log('🚀 Inicializando CategoriaService...');
    
    // Pré-carrega em background (não bloqueia a UI)
    preCarregarUltimos12Meses().catchError((e) {
      log('⚠️ Erro no pré-carregamento inicial: $e');
    });
    
    // ⏰ Iniciar atualização automática a cada 5 minutos
    iniciarAtualizacaoAutomatica();
  }

  /// ⏰ INICIAR ATUALIZAÇÃO AUTOMÁTICA A CADA 5 MINUTOS
  void iniciarAtualizacaoAutomatica() {
    if (_atualizacaoAutomaticaAtiva) return;
    
    log('⏰ Iniciando atualização automática do cache a cada 5 minutos...');
    _atualizacaoAutomaticaAtiva = true;
    
    _timerAtualizacaoAutomatica = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _executarAtualizacaoAutomatica(),
    );
  }

  /// ⏰ PARAR ATUALIZAÇÃO AUTOMÁTICA
  void pararAtualizacaoAutomatica() {
    if (!_atualizacaoAutomaticaAtiva) return;
    
    log('⏰ Parando atualização automática do cache...');
    _timerAtualizacaoAutomatica?.cancel();
    _timerAtualizacaoAutomatica = null;
    _atualizacaoAutomaticaAtiva = false;
  }

  /// ⏰ EXECUTAR ATUALIZAÇÃO AUTOMÁTICA (CHAMADO PELO TIMER)
  Future<void> _executarAtualizacaoAutomatica() async {
    try {
      final agora = DateTime.now();
      log('⏰ Executando atualização automática do cache em: ${agora.toString()}');
      
      // Atualizar apenas os períodos mais recentes para ser eficiente
      final periodosParaAtualizar = <String>[];
      
      // Mês atual
      final mesAtual = '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
      periodosParaAtualizar.add(mesAtual);
      
      // Mês anterior (para capturar transações tardias)
      final mesAnterior = DateTime(agora.year, agora.month - 1, 1);
      final chaveMesAnterior = '${mesAnterior.year}-${mesAnterior.month.toString().padLeft(2, '0')}';
      periodosParaAtualizar.add(chaveMesAnterior);
      
      log('⏰ Atualizando ${periodosParaAtualizar.length} períodos mais recentes...');
      
      // Executar em paralelo para ser mais rápido
      await Future.wait([
        _recarregarPeriodosEspecificos(periodosParaAtualizar),
        _recarregarSubcategoriasPeriodosEspecificos(periodosParaAtualizar),
      ]);
      
      log('✅ Atualização automática concluída com sucesso');
    } catch (e) {
      log('❌ Erro na atualização automática: $e');
    }
  }

  /// 🗑️ LIMPAR CACHE (USAR APÓS MUDANÇAS)
  void limparCache() {
    // Limpar cache de categorias
    _cacheValoresCategorias.clear();
    _preCacheUltimos12Meses.clear();
    _ultimoUpdateCache = null;
    _ultimoPreCarregamento = null;
    
    // 🔖 Limpar cache de subcategorias
    _cacheValoresSubcategorias.clear();
    _preCacheSubcategoriasUltimos12Meses.clear();
    _ultimoUpdateCacheSubcategorias = null;
    _ultimoPreCarregamentoSubcategorias = null;
    
    log('🧹 Cache completo de categorias e subcategorias limpo');
    
    // ⏰ Reiniciar atualização automática após limpeza
    if (_atualizacaoAutomaticaAtiva) {
      pararAtualizacaoAutomatica();
      iniciarAtualizacaoAutomatica();
    }
  }
  
  /// 🔄 REFRESH INTELIGENTE POR MUDANÇA
  void _refreshInteligentePorMudanca() {
    // Agenda refresh para não bloquear a operação atual
    Future.delayed(const Duration(milliseconds: 500), () {
      final agora = DateTime.now();
      
      // Recarrega apenas os períodos mais recentes (últimos 3 meses)
      final periodosParaRefresh = <String>[];
      
      // Mês atual
      final mesAtual = '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
      periodosParaRefresh.add(mesAtual);
      
      // 2 meses anteriores
      for (int i = 1; i <= 2; i++) {
        final dataAnterior = DateTime(agora.year, agora.month - i, 1);
        final chave = '${dataAnterior.year}-${dataAnterior.month.toString().padLeft(2, '0')}';
        periodosParaRefresh.add(chave);
      }
      
      log('🔄 Refresh inteligente: ${periodosParaRefresh.length} períodos recentes');
      
      // Recarrega os períodos em background (categorias e subcategorias)
      _recarregarPeriodosEspecificos(periodosParaRefresh);
      _recarregarSubcategoriasPeriodosEspecificos(periodosParaRefresh);
    });
  }
  
  /// 🔄 RECARREGAR PERÍODOS ESPECÍFICOS
  Future<void> _recarregarPeriodosEspecificos(List<String> chavesPeriodos) async {
    for (final chavePeriodo in chavesPeriodos) {
      try {
        final parts = chavePeriodo.split('-');
        if (parts.length != 2) continue;
        
        final ano = int.tryParse(parts[0]);
        final mes = int.tryParse(parts[1]);
        if (ano == null || mes == null) continue;
        
        final dataInicio = DateTime(ano, mes, 1);
        final dataFim = DateTime(ano, mes + 1, 0);
        
        // Recarrega para todos os tipos
        for (final tipo in [null, 'receita', 'despesa']) {
          try {
            final dados = await fetchCategoriasComValores(
              dataInicio: dataInicio,
              dataFim: dataFim,
              tipo: tipo,
            );
            
            final chaveCompleta = '$chavePeriodo-${tipo ?? 'all'}';
            _preCacheUltimos12Meses[chaveCompleta] = dados;
            
          } catch (e) {
            log('⚠️ Erro ao recarregar $chavePeriodo-${tipo ?? 'all'}: $e');
          }
        }
        
        // Pequena pausa
        await Future.delayed(const Duration(milliseconds: 100));
        
      } catch (e) {
        log('⚠️ Erro ao processar período $chavePeriodo: $e');
      }
    }
    
    log('✅ Refresh inteligente de categorias concluído');
  }

  /// 🔖 RECARREGAR SUBCATEGORIAS PERÍODOS ESPECÍFICOS
  Future<void> _recarregarSubcategoriasPeriodosEspecificos(List<String> chavesPeriodos) async {
    // Buscar categorias para recarregar suas subcategorias
    final categorias = await fetchCategorias();
    if (categorias.isEmpty) return;
    
    for (final chavePeriodo in chavesPeriodos) {
      try {
        final parts = chavePeriodo.split('-');
        if (parts.length != 2) continue;
        
        final ano = int.tryParse(parts[0]);
        final mes = int.tryParse(parts[1]);
        if (ano == null || mes == null) continue;
        
        final dataInicio = DateTime(ano, mes, 1);
        final dataFim = DateTime(ano, mes + 1, 0);
        
        // Recarrega para todas as categorias
        final categoriasParaCache = [null, ...categorias.map((c) => c.id)];
        
        for (final categoriaId in categoriasParaCache) {
          try {
            final dados = await fetchSubcategoriasComValores(
              dataInicio: dataInicio,
              dataFim: dataFim,
              categoriaId: categoriaId,
            );
            
            final chaveCompleta = '$chavePeriodo-${categoriaId ?? 'all'}';
            _preCacheSubcategoriasUltimos12Meses[chaveCompleta] = dados;
            
          } catch (e) {
            log('⚠️ Erro ao recarregar subcategorias $chavePeriodo-${categoriaId ?? 'all'}: $e');
          }
        }
        
        // Pequena pausa
        await Future.delayed(const Duration(milliseconds: 150));
        
      } catch (e) {
        log('⚠️ Erro ao processar período de subcategorias $chavePeriodo: $e');
      }
    }
    
    log('✅ Refresh inteligente de subcategorias concluído');
  }
  
  /// 🔄 FORÇAR REFRESH COMPLETO (USAR QUANDO NECESSÁRIO)
  Future<void> forcarRefreshCompleto() async {
    log('🔄 Forçando refresh completo do pré-cache...');
    _ultimoPreCarregamento = null;
    _ultimoPreCarregamentoSubcategorias = null;
    await preCarregarUltimos12Meses(forceRefresh: true);
    // As subcategorias são carregadas automaticamente pelo preCarregarUltimos12Meses
  }
  
  /// 🎯 MÉTODO PÚBLICO PARA OUTROS SERVIÇOS NOTIFICAREM MUDANÇAS
  /// Chame quando houver mudanças em transações que afetam categorias
  void notificarMudancaTransacoes() {
    log('🔔 Notificação de mudança em transações recebida');
    _refreshInteligentePorMudanca();
  }

  /// 📊 STATUS DO PRÉ-CACHE (PARA DEBUG)
  Map<String, dynamic> getStatusPreCache() {
    return {
      // Cache de categorias
      'categorias_periodos_carregados': _preCacheUltimos12Meses.keys.length,
      'categorias_ultimo_precarregamento': _ultimoPreCarregamento?.toString(),
      'categorias_precarregamento_em_andamento': _preCarregamentoIniciado,
      'categorias_cache_normal_size': _cacheValoresCategorias.keys.length,
      'categorias_chaves_precache': _preCacheUltimos12Meses.keys.toList(),
      
      // 🔖 Cache de subcategorias
      'subcategorias_periodos_carregados': _preCacheSubcategoriasUltimos12Meses.keys.length,
      'subcategorias_ultimo_precarregamento': _ultimoPreCarregamentoSubcategorias?.toString(),
      'subcategorias_precarregamento_em_andamento': _preCarregamentoSubcategoriasIniciado,
      'subcategorias_cache_normal_size': _cacheValoresSubcategorias.keys.length,
      'subcategorias_chaves_precache': _preCacheSubcategoriasUltimos12Meses.keys.toList(),
      
      // ⏰ Atualização automática
      'atualizacao_automatica_ativa': _atualizacaoAutomaticaAtiva,
      'timer_ativo': _timerAtualizacaoAutomatica != null,
      
      // Totais combinados
      'total_chaves_cache': _preCacheUltimos12Meses.keys.length + _preCacheSubcategoriasUltimos12Meses.keys.length,
      'memoria_estimada_kb': (_preCacheUltimos12Meses.keys.length * 50) + (_preCacheSubcategoriasUltimos12Meses.keys.length * 30),
    };
  }

  /// 🧹 DISPOSE - LIMPAR RECURSOS QUANDO O SERVICE FOR DESCARTADO
  void dispose() {
    pararAtualizacaoAutomatica();
    log('🧹 CategoriaService resources cleaned up');
  }

  /// 🔧 CRIA CATEGORIAS BÁSICAS LOCALMENTE
  Future<void> _criarCategoriasBasicas(String userId) async {
    final now = DateTime.now();
    final categorias = [
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Alimentação',
        'tipo': 'despesa',
        'cor': '#FF5722',
        'icone': 'restaurant',
        'ativo': 1,
        'ordem': 1,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Transporte',
        'tipo': 'despesa',
        'cor': '#2196F3',
        'icone': 'directions_car',
        'ativo': 1,
        'ordem': 2,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Saúde',
        'tipo': 'despesa',
        'cor': '#4CAF50',
        'icone': 'medical_services',
        'ativo': 1,
        'ordem': 3,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Compras',
        'tipo': 'despesa',
        'cor': '#FF9800',
        'icone': 'shopping_bag',
        'ativo': 1,
        'ordem': 4,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Lazer',
        'tipo': 'despesa',
        'cor': '#9C27B0',
        'icone': 'movie',
        'ativo': 1,
        'ordem': 5,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      // ===== RECEITAS =====
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Salário',
        'tipo': 'receita',
        'cor': '#4CAF50',
        'icone': 'work',
        'ativo': 1,
        'ordem': 6,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Freelance',
        'tipo': 'receita',
        'cor': '#2196F3',
        'icone': 'business_center',
        'ativo': 1,
        'ordem': 7,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Investimentos',
        'tipo': 'receita',
        'cor': '#FF9800',
        'icone': 'trending_up',
        'ativo': 1,
        'ordem': 8,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': 'Vendas',
        'tipo': 'receita',
        'cor': '#9C27B0',
        'icone': 'sell',
        'ativo': 1,
        'ordem': 9,
        'is_default': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'pending',
        'last_sync': now.toIso8601String(),
      },
    ];

    await _localDb.setCurrentUser(userId);
    
    for (final categoria in categorias) {
      await _localDb.addCategoriaLocal(categoria);
    }
    
    log('✅ ${categorias.length} categorias básicas criadas (5 despesas + 4 receitas)');
  }

  // ===== MÉTODOS PARA COMPATIBILIDADE =====
  
  /// Listar categorias principais (usa dados reais)
  Future<List<CategoriaModel>> listarCategorias() async {
    return await fetchCategorias(tipo: 'despesa');
  }

  /// Listar subcategorias de uma categoria (usa dados reais)
  Future<List<CategoriaModel>> listarSubcategorias(String categoriaId) async {
    final subcategorias = await fetchSubcategorias(categoriaId: categoriaId);
    return subcategorias.map((sub) => CategoriaModel(
      id: sub.id,
      usuarioId: sub.usuarioId,
      nome: sub.nome,
      cor: sub.cor ?? '#6B7280',
      icone: sub.icone ?? 'help',
      tipo: 'despesa',
      ativo: sub.ativo,
      createdAt: sub.createdAt,
      updatedAt: sub.updatedAt,
    )).toList();
  }

  /// 🔢 CONTAGEM RÁPIDA PARA DIAGNÓSTICO

  /// Conta categorias por tipo (despesa/receita) - OFFLINE FIRST
  Future<int> countCategoriasByTipo(String tipo) async {
    try {
      // Tenta SQLite primeiro para velocidade
      final db = await _localDb.database;
      if (db == null) {
        log('⚠️ Database não inicializado, usando fallback');
        throw Exception('Database não disponível');
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM categorias WHERE tipo = ? AND ativo = 1',
        [tipo]
      );

      final count = result.first['count'] as int;
      log('📊 Categorias $tipo (SQLite): $count');
      return count;
    } catch (e) {
      log('⚠️ Erro SQLite, usando fallback: $e');
      // Fallback: usar dados mock
      if (tipo == 'despesa') return 5;
      if (tipo == 'receita') return 4;
      return 0;
    }
  }

  /// Conta total de categorias ativas - OFFLINE FIRST
  Future<int> countTotalCategorias() async {
    try {
      final db = await _localDb.database;
      if (db == null) {
        log('⚠️ Database não inicializado, usando fallback');
        throw Exception('Database não disponível');
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM categorias WHERE ativo = 1'
      );

      final count = result.first['count'] as int;
      log('📊 Total categorias (SQLite): $count');
      return count;
    } catch (e) {
      log('⚠️ Erro SQLite, usando fallback: $e');
      return 9; // Fallback (5 despesas + 4 receitas)
    }
  }

  /// Verifica se tem pelo menos X categorias configuradas
  Future<bool> temCategoriasConfiguradas({int minimo = 3}) async {
    final total = await countTotalCategorias();
    return total >= minimo;
  }

}