// 📂 Categoria Service CORRIGIDO - iPoupei Mobile
// 
// Versão 100% aderente à especificação React
// Implementa TODAS as regras de negócio
// 
// Baseado em: Especificação completa do React

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria_model.dart';

class CategoriaServiceCorrect {
  static CategoriaServiceCorrect? _instance;
  static CategoriaServiceCorrect get instance {
    _instance ??= CategoriaServiceCorrect._internal();
    return _instance!;
  }
  
  CategoriaServiceCorrect._internal();

  final _supabase = Supabase.instance.client;

  /// 🎨 ÍCONES SUGERIDOS BASEADOS NO NOME (igual ao React)
  static const Map<String, List<String>> _iconesSugeridos = {
    // Alimentação
    'alimenta': ['🍽️', '🍕', '🍔', '🥗'],
    'comida': ['🍽️', '🍕', '🍔', '🥗'],
    'mercado': ['🛒', '🛍️', '🏪'],
    'restaurante': ['🍽️', '🍴', '🥘'],
    
    // Transporte
    'transporte': ['🚗', '🚌', '🚇', '⛽'],
    'combustivel': ['⛽', '🚗'],
    'carro': ['🚗', '🚙'],
    'uber': ['🚕', '📱'],
    
    // Casa
    'casa': ['🏠', '🏡', '🏘️'],
    'aluguel': ['🏠', '🔑', '📋'],
    'luz': ['💡', '⚡', '🔆'],
    'agua': ['💧', '🚿', '🔧'],
    'internet': ['📶', '💻', '📡'],
    
    // Saúde
    'saude': ['🏥', '💊', '🩺', '❤️'],
    'medico': ['👩‍⚕️', '🩺', '🏥'],
    'farmacia': ['💊', '🏥'],
    
    // Trabalho/Receitas
    'salario': ['💰', '💵', '🏢', '💼'],
    'freelance': ['💻', '🎯', '📈'],
    'investimento': ['📈', '💎', '📊'],
    'bonus': ['🎁', '💰', '⭐'],
  };

  /// 📊 BUSCAR PRÓXIMA ORDEM (igual ao React)
  Future<int> _getProximaOrdem(String tipo) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 1;

      final response = await _supabase
          .rpc('get_max_ordem_categoria', params: {
            'p_usuario_id': userId,
            'p_tipo': tipo,
          });
      
      return (response as int? ?? 0) + 1;
    } catch (e) {
      log('⚠️ Erro ao buscar ordem, usando 1: $e');
      return 1;
    }
  }

  /// 🎨 OBTER ÍCONES SUGERIDOS PARA NOME
  List<String> getSuggestedIcons(String nome) {
    final nomeMinusculo = nome.toLowerCase();
    
    for (final entry in _iconesSugeridos.entries) {
      if (nomeMinusculo.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return ['📁', '📂', '📋', '🏷️']; // Ícones padrão
  }

  /// 🔍 BUSCAR ÍCONES POR TERMO
  List<String> searchIcons(String termo) {
    final termoMinusculo = termo.toLowerCase();
    List<String> resultados = [];
    
    for (final entry in _iconesSugeridos.entries) {
      if (entry.key.contains(termoMinusculo)) {
        resultados.addAll(entry.value);
      }
    }
    
    return resultados.isEmpty ? ['📁', '📂', '🏷️'] : resultados.take(12).toList();
  }

  /// 🎨 CORES PREDEFINIDAS (igual ao React - 20 cores)
  static const List<String> coresPredefinidas = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FECA57',
    '#FF9FF3', '#54A0FF', '#5F27CD', '#00D2D3', '#FF9F43',
    '#A55EEA', '#26DE81', '#FD79A8', '#FDCB6E', '#6C5CE7',
    '#FDA7DF', '#F97F51', '#BDC3C7', '#2C2C54', '#40407A'
  ];

  /// ➕ CRIAR CATEGORIA (100% aderente)
  Future<CategoriaModel> addCategoria({
    required String nome,
    required String tipo, // Obrigatório na spec
    String? cor,
    String? icone,
    String? descricao,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Validações da spec
      if (nome.trim().isEmpty) {
        throw Exception('Nome não pode estar vazio');
      }
      
      if (!['despesa', 'receita'].contains(tipo)) {
        throw Exception('Tipo deve ser "despesa" ou "receita"');
      }

      // Buscar próxima ordem corretamente
      final proximaOrdem = await _getProximaOrdem(tipo);
      
      final categoriaData = {
        'user_id': userId,
        'nome': nome.trim(),
        'tipo': tipo,
        'cor': cor ?? '#008080',        // Default da spec
        'icone': icone ?? '📁',         // Default da spec
        'ativo': true,
        'ordem': proximaOrdem,          // ✅ CORRIGIDO: ordem automática
        'is_default': false,
        'descricao': descricao?.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('categorias')
          .insert(categoriaData)
          .select()
          .single();

      log('✅ Categoria criada: $nome (ordem: $proximaOrdem)');
      return CategoriaModel.fromJson(response);
    } catch (e) {
      log('❌ Erro ao criar categoria: $e');
      rethrow;
    }
  }

  /// 🗑️ EXCLUIR CATEGORIA (100% aderente - soft delete inteligente)
  Future<Map<String, dynamic>> excluirCategoria(String categoriaId, {bool confirmacao = false}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // 1. Verificar transações vinculadas
      final transacoesResponse = await _supabase
          .from('transacoes')
          .select('id')
          .eq('categoria_id', categoriaId)
          .eq('usuario_id', userId);

      final totalTransacoes = (transacoesResponse as List).length;

      // 2. Se tem transações e não confirmou, retorna aviso
      if (totalTransacoes > 0 && !confirmacao) {
        return {
          'success': false,
          'error': 'POSSUI_TRANSACOES',
          'message': 'Esta categoria possui $totalTransacoes transação(ões). Recomendamos soft delete.',
          'quantidadeTransacoes': totalTransacoes,
        };
      }

      // 3. SOFT DELETE se tem transações (preserva histórico)
      if (totalTransacoes > 0) {
        // Soft delete da categoria
        await _supabase
            .from('categorias')
            .update({
              'ativo': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', categoriaId)
            .eq('usuario_id', userId);

        // Soft delete das subcategorias (cascata)
        await _supabase
            .from('subcategorias')
            .update({
              'ativo': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('categoria_id', categoriaId)
            .eq('usuario_id', userId);

        log('✅ Categoria soft deleted (preservou histórico)');
        return {'success': true, 'type': 'soft_delete'};
      }

      // 4. HARD DELETE se não tem transações
      // Remover subcategorias primeiro
      await _supabase
          .from('subcategorias')
          .delete()
          .eq('categoria_id', categoriaId)
          .eq('usuario_id', userId);

      // Remover categoria
      await _supabase
          .from('categorias')
          .delete()
          .eq('id', categoriaId)
          .eq('usuario_id', userId);

      log('✅ Categoria hard deleted (sem transações)');
      return {'success': true, 'type': 'hard_delete'};

    } catch (e) {
      log('❌ Erro ao excluir categoria: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ✏️ ATUALIZAR CATEGORIA (restrições da spec)
  Future<CategoriaModel> updateCategoria({
    required String categoriaId,
    String? nome,
    String? tipo,      // ⚠️ Na spec tipo NÃO pode ser alterado
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

      // Campos editáveis conforme spec
      if (nome != null && nome.trim().isNotEmpty) {
        updateData['nome'] = nome.trim();
      }
      if (cor != null) updateData['cor'] = cor;
      if (icone != null) updateData['icone'] = icone;
      if (descricao != null) updateData['descricao'] = descricao.trim();
      
      // ⚠️ TIPO NÃO É EDITÁVEL conforme spec React
      // "Tipo NÃO pode ser alterado (despesa não vira receita)"

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

  /// 📋 BUSCAR CATEGORIAS (com filtros da spec)
  Future<List<CategoriaModel>> fetchCategorias({
    String? tipo,
    bool incluirArquivadas = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      dynamic query = _supabase
          .from('categorias')
          .select('*')
          .eq('usuario_id', userId);

      // Filtro por tipo
      if (tipo != null && tipo.isNotEmpty) {
        query = query.eq('tipo', tipo);
      }

      // Filtro de arquivadas (padrão: só ativas)
      if (!incluirArquivadas) {
        query = query.eq('ativo', true);
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
}