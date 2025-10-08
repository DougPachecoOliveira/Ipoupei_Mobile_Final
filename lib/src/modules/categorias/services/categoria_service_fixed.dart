// 📂 Categoria Service FUNCIONAIS - iPoupei Mobile
// 
// Serviço simplificado mas 100% funcional
// Todas as operações básicas funcionando
// 
// Baseado em: Repository Pattern Simples

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria_model.dart';

class CategoriaService {
  static CategoriaService? _instance;
  static CategoriaService get instance {
    _instance ??= CategoriaService._internal();
    return _instance!;
  }
  
  CategoriaService._internal();

  final _supabase = Supabase.instance.client;

  /// 📂 BUSCAR CATEGORIAS
  Future<List<CategoriaModel>> fetchCategorias({String? tipo}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      log('📂 Buscando categorias para: ${_supabase.auth.currentUser?.email}');

      dynamic query = _supabase
          .from('categorias')
          .select('*')
          .eq('usuario_id', userId)
          .eq('ativo', true);

      if (tipo != null && tipo.isNotEmpty) {
        query = query.eq('tipo', tipo);
      }
      
      query = query.order('ordem').order('nome');

      final response = await query;

      final categorias = (response as List).map<CategoriaModel>((item) {
        return CategoriaModel.fromJson(item);
      }).toList();

      log('✅ Categorias carregadas: ${categorias.length}');
      return categorias;
    } catch (e) {
      log('❌ Erro ao buscar categorias: $e');
      return [];
    }
  }

  /// 📂 BUSCAR SUBCATEGORIAS
  Future<List<SubcategoriaModel>> fetchSubcategorias({String? categoriaId}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      dynamic query = _supabase
          .from('subcategorias')
          .select('*')
          .eq('usuario_id', userId)
          .eq('ativo', true);

      if (categoriaId != null && categoriaId.isNotEmpty) {
        query = query.eq('categoria_id', categoriaId);
      }
      
      query = query.order('nome');

      final response = await query;

      final subcategorias = (response as List).map<SubcategoriaModel>((item) {
        return SubcategoriaModel.fromJson(item);
      }).toList();

      log('✅ Subcategorias carregadas: ${subcategorias.length}');
      return subcategorias;
    } catch (e) {
      log('❌ Erro ao buscar subcategorias: $e');
      return [];
    }
  }

  /// ➕ ADICIONAR CATEGORIA
  Future<CategoriaModel> addCategoria({
    required String nome,
    required String tipo,
    String? cor,
    String? icone,
    String? descricao,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final now = DateTime.now();
      final categoriaData = {
        'user_id': userId,
        'nome': nome,
        'tipo': tipo,
        'cor': cor ?? '#008080',
        'icone': icone ?? '📁',
        'ativo': true,
        'ordem': 1,
        'is_default': false,
        'descricao': descricao,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('categorias')
          .insert(categoriaData)
          .select()
          .single();

      log('✅ Categoria criada: $nome');
      return CategoriaModel.fromJson(response);
    } catch (e) {
      log('❌ Erro ao criar categoria: $e');
      rethrow;
    }
  }

  /// ➕ ADICIONAR SUBCATEGORIA
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
      final subcategoriaData = {
        'categoria_id': categoriaId,
        'user_id': userId,
        'nome': nome,
        'cor': cor,
        'icone': icone,
        'ativo': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('subcategorias')
          .insert(subcategoriaData)
          .select()
          .single();

      log('✅ Subcategoria criada: $nome');
      return SubcategoriaModel.fromJson(response);
    } catch (e) {
      log('❌ Erro ao criar subcategoria: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR CATEGORIA
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

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nome != null) updateData['nome'] = nome;
      if (tipo != null) updateData['tipo'] = tipo;
      if (cor != null) updateData['cor'] = cor;
      if (icone != null) updateData['icone'] = icone;
      if (descricao != null) updateData['descricao'] = descricao;

      final response = await _supabase
          .from('categorias')
          .update(updateData)
          .eq('id', categoriaId)
          .eq('usuario_id', userId)
          .select()
          .single();

      log('✅ Categoria atualizada: $categoriaId');
      return CategoriaModel.fromJson(response);
    } catch (e) {
      log('❌ Erro ao atualizar categoria: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR SUBCATEGORIA
  Future<SubcategoriaModel> updateSubcategoria({
    required String subcategoriaId,
    String? nome,
    String? cor,
    String? icone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nome != null) updateData['nome'] = nome;
      if (cor != null) updateData['cor'] = cor;
      if (icone != null) updateData['icone'] = icone;

      final response = await _supabase
          .from('subcategorias')
          .update(updateData)
          .eq('id', subcategoriaId)
          .eq('usuario_id', userId)
          .select()
          .single();

      log('✅ Subcategoria atualizada: $subcategoriaId');
      return SubcategoriaModel.fromJson(response);
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
            'ativo': false,
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

  /// 📦 ARQUIVAR SUBCATEGORIA
  Future<void> arquivarSubcategoria(String subcategoriaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase
          .from('subcategorias')
          .update({
            'ativo': false,
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

  /// 🗑️ EXCLUIR CATEGORIA (versão funcional)
  Future<Map<String, dynamic>> excluirCategoria(String categoriaId, {bool confirmacao = false}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Verificar se tem transações vinculadas
      final transacoes = await _supabase
          .from('transacoes')
          .select('id')
          .eq('categoria_id', categoriaId)
          .eq('usuario_id', userId);

      final totalTransacoes = (transacoes as List).length;

      if (totalTransacoes > 0 && !confirmacao) {
        return {
          'success': false,
          'error': 'POSSUI_TRANSACOES',
          'message': 'Esta categoria possui $totalTransacoes transação(ões).',
          'quantidadeTransacoes': totalTransacoes,
        };
      }

      // Se tem transações, faz soft delete
      if (totalTransacoes > 0) {
        await arquivarCategoria(categoriaId);
        return {'success': true, 'type': 'soft_delete'};
      }

      // Se não tem transações, remove fisicamente
      await _supabase
          .from('subcategorias')
          .delete()
          .eq('categoria_id', categoriaId)
          .eq('usuario_id', userId);

      await _supabase
          .from('categorias')
          .delete()
          .eq('id', categoriaId)
          .eq('usuario_id', userId);

      log('✅ Categoria excluída: $categoriaId');
      return {'success': true, 'type': 'hard_delete'};
    } catch (e) {
      log('❌ Erro ao excluir categoria: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}