import 'dart:developer';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cartao_model.dart';
import '../../../database/local_database.dart';
import '../../../sync/sync_manager.dart';
import '../../../auth_integration.dart';

class CartaoService {
  static final CartaoService _instance = CartaoService._internal();
  static CartaoService get instance => _instance;
  CartaoService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;
  final SyncManager _syncManager = SyncManager.instance;
  static const Uuid _uuid = Uuid();

  /// ✅ 1. CRIAR CARTÃO
  Future<CartaoModel> criarCartao({
    required String nome,
    required double limite,
    required int diaFechamento,
    required int diaVencimento,
    String? bandeira,
    String? banco,
    String? contaDebitoId,
    String? cor,
    String? observacoes,
  }) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não logado');

      final agora = DateTime.now();
      final cartaoData = {
        'id': _uuid.v4(),
        'usuario_id': userId,
        'nome': nome.trim(),
        'limite': limite,
        'dia_fechamento': diaFechamento,
        'dia_vencimento': diaVencimento,
        'bandeira': bandeira,
        'banco': banco,
        'conta_debito_id': contaDebitoId,
        'cor': cor,
        'observacoes': observacoes,
        'ativo': 1, // true
        'created_at': agora.toIso8601String(),
        'updated_at': agora.toIso8601String(),
        'sync_status': 'pending', // pendente sync
      };

      // ✅ SALVAR NO SQLITE PRIMEIRO (OFFLINE-FIRST)
      await _localDb.database?.insert('cartoes', cartaoData);
      await _localDb.addToSyncQueue('cartoes', cartaoData['id'] as String, 'INSERT', cartaoData);

      // 🚀 ENVIO DIRETO AO SUPABASE (temporário até sync_queue funcionar)
      try {
        await Supabase.instance.client
          .from('cartoes')
          .insert({
            'id': cartaoData['id'],
            'usuario_id': cartaoData['usuario_id'],
            'nome': cartaoData['nome'],
            'bandeira': cartaoData['bandeira'],
            'banco': cartaoData['banco'],
            'limite': cartaoData['limite'],
            'dia_fechamento': cartaoData['dia_fechamento'],
            'dia_vencimento': cartaoData['dia_vencimento'],
            'conta_debito_id': cartaoData['conta_debito_id'], // ✅ CAMPO IMPORTANTE!
            'cor': cartaoData['cor'],
            'observacoes': cartaoData['observacoes'],
            'ativo': cartaoData['ativo'] == 1,
            'created_at': cartaoData['created_at'],
            'updated_at': cartaoData['updated_at'],
          });

        log('🚀 Cartão criado enviado para Supabase: ${cartaoData['nome']}');
      } catch (supabaseError) {
        log('⚠️ Erro ao criar no Supabase (continua funcionando offline): $supabaseError');
      }

      final cartao = CartaoModel.fromJson(cartaoData);
      log('✅ Cartão criado: ${cartao.nome} - Limite: ${cartao.limiteFormatado}');

      return cartao;
    } catch (e) {
      log('❌ Erro ao criar cartão: $e');
      rethrow;
    }
  }

  /// ✅ 2. LISTAR CARTÕES ATIVOS
  Future<List<CartaoModel>> listarCartoesAtivos() async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'cartoes',
        where: 'usuario_id = ? AND ativo = 1',
        whereArgs: [userId],
        orderBy: 'nome ASC',
      ) ?? [];

      final cartoes = result.map((data) => CartaoModel.fromJson(data)).toList();
      log('✅ Cartões ativos encontrados: ${cartoes.length}');
      
      return cartoes;
    } catch (e) {
      log('❌ Erro ao listar cartões: $e');
      return [];
    }
  }

  /// ✅ 3. ALIAS PARA COMPATIBILIDADE - fetchCartoes()
  Future<List<CartaoModel>> fetchCartoes() async {
    return await listarCartoesAtivos();
  }

  /// ✅ 4. LISTAR TODOS OS CARTÕES
  Future<List<CartaoModel>> listarTodosCartoes() async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'cartoes',
        where: 'usuario_id = ?',
        whereArgs: [userId],
        orderBy: 'ativo DESC, nome ASC',
      ) ?? [];

      return result.map((data) => CartaoModel.fromJson(data)).toList();
    } catch (e) {
      log('❌ Erro ao listar todos cartões: $e');
      return [];
    }
  }

  /// ✅ 5. LISTAR CARTÕES ARQUIVADOS
  Future<List<CartaoModel>> listarCartoesArquivados() async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'cartoes',
        where: 'usuario_id = ? AND ativo = 0',
        whereArgs: [userId],
        orderBy: 'nome ASC',
      ) ?? [];

      return result.map((data) => CartaoModel.fromJson(data)).toList();
    } catch (e) {
      log('❌ Erro ao listar cartões arquivados: $e');
      return [];
    }
  }

  /// ✅ 6. BUSCAR CARTÃO POR ID
  Future<CartaoModel?> buscarCartaoPorId(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return null;

      final result = await _localDb.database?.query(
        'cartoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
        limit: 1,
      ) ?? [];

      if (result.isEmpty) return null;
      
      return CartaoModel.fromJson(result.first);
    } catch (e) {
      log('❌ Erro ao buscar cartão: $e');
      return null;
    }
  }

  /// ✅ 5. ATUALIZAR CARTÃO
  Future<bool> atualizarCartao(CartaoModel cartao) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      final cartaoAtualizado = cartao.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      // Criar mapa sem campo 'icone' para o update local
      final dadosParaUpdate = Map<String, dynamic>.from(cartaoAtualizado.toJson());
      dadosParaUpdate.remove('icone'); // Remove campo que não existe na tabela local

      await _localDb.database?.update(
        'cartoes',
        dadosParaUpdate,
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartao.id, userId],
      );

      await _localDb.addToSyncQueue('cartoes', cartao.id, 'UPDATE', cartaoAtualizado.toJson());

      // 🚀 ENVIO DIRETO AO SUPABASE (temporário até sync_queue funcionar)
      try {
        log('🔄 Enviando cartão UPDATE para Supabase: ${cartao.nome}');

        await Supabase.instance.client
          .from('cartoes')
          .update({
            'nome': cartaoAtualizado.nome,
            'bandeira': cartaoAtualizado.bandeira,
            'banco': cartaoAtualizado.banco,
            'limite': cartaoAtualizado.limite,
            'dia_fechamento': cartaoAtualizado.diaFechamento,
            'dia_vencimento': cartaoAtualizado.diaVencimento,
            'conta_debito_id': cartaoAtualizado.contaDebitoId, // ✅ CAMPO IMPORTANTE!
            'cor': cartaoAtualizado.cor,
            'observacoes': cartaoAtualizado.observacoes,
            'ativo': cartaoAtualizado.ativo,
            'updated_at': cartaoAtualizado.updatedAt.toIso8601String(),
          })
          .eq('id', cartao.id)
          .eq('usuario_id', userId);

        log('✅ Cartão atualizado no Supabase: ${cartao.nome}');
      } catch (supabaseError) {
        log('⚠️ Erro ao enviar UPDATE para Supabase: $supabaseError');
        log('📱 Continuando funcionando offline...');
      }

      log('✅ Cartão atualizado: ${cartao.nome}');

      return true;
    } catch (e) {
      log('❌ Erro ao atualizar cartão: $e');
      return false;
    }
  }

  /// ✅ 6. ARQUIVAR CARTÃO (SOFT DELETE)
  Future<bool> arquivarCartao(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      await _localDb.database?.update(
        'cartoes',
        {
          'ativo': 0, // false
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      );

      await _localDb.addToSyncQueue('cartoes', cartaoId, 'UPDATE', {});
      log('✅ Cartão arquivado: $cartaoId');
      
      return true;
    } catch (e) {
      log('❌ Erro ao arquivar cartão: $e');
      return false;
    }
  }

  /// ✅ 7. REATIVAR CARTÃO
  Future<bool> reativarCartao(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      await _localDb.database?.update(
        'cartoes',
        {
          'ativo': 1, // true
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      );

      await _localDb.addToSyncQueue('cartoes', cartaoId, 'UPDATE', {});
      log('✅ Cartão reativado: $cartaoId');
      
      return true;
    } catch (e) {
      log('❌ Erro ao reativar cartão: $e');
      return false;
    }
  }

  /// ✅ 8. EXCLUIR CARTÃO PERMANENTEMENTE
  Future<bool> excluirCartao(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      // ⚠️ VERIFICAR SE HÁ DESPESAS VINCULADAS
      final despesasVinculadas = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND is_cartao_credito = 1 AND (observacoes LIKE ? OR observacoes LIKE ?)',
        whereArgs: [userId, '%$cartaoId%', '%cartao:$cartaoId%'],
        limit: 1,
      ) ?? [];

      if (despesasVinculadas.isNotEmpty) {
        throw Exception('Não é possível excluir cartão com despesas vinculadas');
      }

      await _localDb.database?.delete(
        'cartoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      );

      await _localDb.addToSyncQueue('cartoes', cartaoId, 'DELETE', {});
      log('✅ Cartão excluído permanentemente: $cartaoId');
      
      return true;
    } catch (e) {
      log('❌ Erro ao excluir cartão: $e');
      rethrow;
    }
  }

  /// ✅ 9. VALIDAR DADOS DO CARTÃO
  Map<String, String> validarCartao({
    required String nome,
    required double limite,
    required int diaFechamento,
    required int diaVencimento,
  }) {
    final erros = <String, String>{};

    if (nome.trim().isEmpty) {
      erros['nome'] = 'Nome é obrigatório';
    } else if (nome.trim().length < 2) {
      erros['nome'] = 'Nome deve ter pelo menos 2 caracteres';
    }

    if (limite <= 0) {
      erros['limite'] = 'Limite deve ser maior que zero';
    } else if (limite > 999999.99) {
      erros['limite'] = 'Limite muito alto (máx: R\$ 999.999,99)';
    }

    if (diaFechamento < 1 || diaFechamento > 31) {
      erros['diaFechamento'] = 'Dia de fechamento deve ser entre 1 e 31';
    }

    if (diaVencimento < 1 || diaVencimento > 31) {
      erros['diaVencimento'] = 'Dia de vencimento deve ser entre 1 e 31';
    }

    if (diaFechamento == diaVencimento) {
      erros['dias'] = 'Dias de fechamento e vencimento devem ser diferentes';
    }

    return erros;
  }

  /// ✅ 9.5. GERAR NOME ÚNICO COM SUFIXOS (2), (3), etc.
  Future<String> gerarNomeUnico(String nomeBase, {String? cartaoIdExcluir}) async {
    String nomeTestado = nomeBase;
    int sufixo = 1;

    // Testar nome original primeiro
    bool duplicado = await verificarNomeDuplicado(nomeTestado, cartaoIdExcluir: cartaoIdExcluir);

    // Se não há duplicata, retorna nome original
    if (!duplicado) {
      return nomeTestado;
    }

    // Se há duplicata, tentar com sufixos
    while (duplicado && sufixo <= 99) { // Limite de 99 sufixos
      sufixo++;
      nomeTestado = '$nomeBase ($sufixo)';
      duplicado = await verificarNomeDuplicado(nomeTestado, cartaoIdExcluir: cartaoIdExcluir);
      log('🔄 Testando nome: "$nomeTestado" - Duplicado: $duplicado');
    }

    log('✅ Nome único gerado: "$nomeTestado"');
    return nomeTestado;
  }

  /// ✅ 10. VERIFICAR NOME DUPLICADO
  Future<bool> verificarNomeDuplicado(String nome, {String? cartaoIdExcluir}) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      String where = 'usuario_id = ? AND LOWER(nome) = ? AND ativo = 1';
      List<dynamic> whereArgs = [userId, nome.toLowerCase()];

      if (cartaoIdExcluir != null) {
        where += ' AND id != ?';
        whereArgs.add(cartaoIdExcluir);
      }

      log('🔍 Verificando nome duplicado: "$nome"');

      final result = await _localDb.database?.query(
        'cartoes',
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      ) ?? [];

      if (result.isNotEmpty) {
        log('📝 Nome duplicado encontrado: ${result.first['nome']}');
      }

      return result.isNotEmpty;
    } catch (e) {
      log('❌ Erro ao verificar nome duplicado: $e');
      return false;
    }
  }

  /// ✅ 11. BUSCAR CARTÃO POR NOME
  Future<CartaoModel?> buscarCartaoPorNome(String nome) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return null;

      final result = await _localDb.database?.query(
        'cartoes',
        where: 'usuario_id = ? AND LOWER(nome) = ? AND ativo = 1',
        whereArgs: [userId, nome.toLowerCase()],
        limit: 1,
      ) ?? [];

      if (result.isEmpty) return null;
      
      return CartaoModel.fromJson(result.first);
    } catch (e) {
      log('❌ Erro ao buscar cartão por nome: $e');
      return null;
    }
  }

  /// ✅ 12. CONTAR CARTÕES ATIVOS
  Future<int> contarCartoesAtivos() async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return 0;

      final result = await _localDb.database?.rawQuery(
        'SELECT COUNT(*) as total FROM cartoes WHERE usuario_id = ? AND ativo = 1',
        [userId],
      ) ?? [];

      if (result.isEmpty) return 0;
      
      return result.first['total'] as int;
    } catch (e) {
      log('❌ Erro ao contar cartões: $e');
      return 0;
    }
  }

  /// ✅ 13. LISTAR CARTÕES POR BANDEIRA
  Future<List<CartaoModel>> listarCartoesPorBandeira(String bandeira) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'cartoes',
        where: 'usuario_id = ? AND bandeira = ? AND ativo = 1',
        whereArgs: [userId, bandeira],
        orderBy: 'nome ASC',
      ) ?? [];

      return result.map((data) => CartaoModel.fromJson(data)).toList();
    } catch (e) {
      log('❌ Erro ao listar cartões por bandeira: $e');
      return [];
    }
  }

  /// ✅ 14. CALCULAR LIMITE TOTAL
  Future<double> calcularLimiteTotal() async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return 0.0;

      final result = await _localDb.database?.rawQuery(
        'SELECT SUM(limite) as total FROM cartoes WHERE usuario_id = ? AND ativo = 1',
        [userId],
      ) ?? [];

      if (result.isEmpty || result.first['total'] == null) return 0.0;
      
      return (result.first['total'] as num).toDouble();
    } catch (e) {
      log('❌ Erro ao calcular limite total: $e');
      return 0.0;
    }
  }

  /// ✅ 15. ATUALIZAR LIMITE DO CARTÃO
  Future<bool> atualizarLimite(String cartaoId, double novoLimite) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      if (novoLimite <= 0) {
        throw Exception('Limite deve ser maior que zero');
      }

      await _localDb.database?.update(
        'cartoes',
        {
          'limite': novoLimite,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      );

      await _localDb.addToSyncQueue('cartoes', cartaoId, 'UPDATE', {});
      log('✅ Limite atualizado para R\$ ${novoLimite.toStringAsFixed(2)}');
      
      return true;
    } catch (e) {
      log('❌ Erro ao atualizar limite: $e');
      return false;
    }
  }

  /// ✅ 16. ATUALIZAR DIAS FATURA
  Future<bool> atualizarDiasFatura(String cartaoId, int diaFechamento, int diaVencimento) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      if (diaFechamento < 1 || diaFechamento > 31) {
        throw Exception('Dia de fechamento inválido');
      }

      if (diaVencimento < 1 || diaVencimento > 31) {
        throw Exception('Dia de vencimento inválido');
      }

      if (diaFechamento == diaVencimento) {
        throw Exception('Dias de fechamento e vencimento devem ser diferentes');
      }

      await _localDb.database?.update(
        'cartoes',
        {
          'dia_fechamento': diaFechamento,
          'dia_vencimento': diaVencimento,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      );

      await _localDb.addToSyncQueue('cartoes', cartaoId, 'UPDATE', {});
      log('✅ Dias da fatura atualizados: $diaFechamento/$diaVencimento');
      
      return true;
    } catch (e) {
      log('❌ Erro ao atualizar dias: $e');
      return false;
    }
  }

  /// ✅ 17. DEFINIR CONTA DÉBITO AUTOMÁTICO
  Future<bool> definirContaDebito(String cartaoId, String? contaId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      await _localDb.database?.update(
        'cartoes',
        {
          'conta_debito_id': contaId,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
      );

      await _localDb.addToSyncQueue('cartoes', cartaoId, 'UPDATE', {});
      log('✅ Conta débito ${contaId != null ? 'definida' : 'removida'}');
      
      return true;
    } catch (e) {
      log('❌ Erro ao definir conta débito: $e');
      return false;
    }
  }

  /// ✅ 18. EXPORTAR CARTÕES PARA JSON
  Future<List<Map<String, dynamic>>> exportarCartoes() async {
    try {
      final cartoes = await listarTodosCartoes();
      return cartoes.map((cartao) => cartao.toSupabaseJson()).toList();
    } catch (e) {
      log('❌ Erro ao exportar cartões: $e');
      return [];
    }
  }

  /// ✅ 19. IMPORTAR CARTÕES DO JSON
  Future<bool> importarCartoes(List<Map<String, dynamic>> dadosCartoes) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      int importados = 0;
      for (final dadosCartao in dadosCartoes) {
        try {
          // ✅ VERIFICAR SE JÁ EXISTE
          final cartaoExistente = await buscarCartaoPorId(dadosCartao['id']);
          if (cartaoExistente != null) continue;

          // ✅ VALIDAR DADOS
          final erros = validarCartao(
            nome: dadosCartao['nome'],
            limite: dadosCartao['limite'],
            diaFechamento: dadosCartao['dia_fechamento'],
            diaVencimento: dadosCartao['dia_vencimento'],
          );

          if (erros.isNotEmpty) continue;

          // ✅ GARANTIR USUÁRIO CORRETO
          dadosCartao['usuario_id'] = userId;
          dadosCartao['sync_status'] = 'pending'; // Marcar para sync

          await _localDb.database?.insert('cartoes', dadosCartao);
          await _localDb.addToSyncQueue('cartoes', dadosCartao['id'], 'INSERT', dadosCartao);
          importados++;
        } catch (e) {
          log('⚠️ Erro ao importar cartão ${dadosCartao['nome']}: $e');
          continue;
        }
      }

      log('✅ Cartões importados: $importados/${dadosCartoes.length}');
      return importados > 0;
    } catch (e) {
      log('❌ Erro na importação de cartões: $e');
      return false;
    }
  }

  /// ✅ 20. LIMPAR CARTÕES ARQUIVADOS
  Future<int> limparCartoesArquivados() async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return 0;

      // ✅ BUSCAR CARTÕES ARQUIVADOS SEM DESPESAS VINCULADAS
      final cartoesArquivados = await _localDb.database?.query(
        'cartoes',
        columns: ['id'],
        where: 'usuario_id = ? AND ativo = 0',
        whereArgs: [userId],
      ) ?? [];

      int removidos = 0;
      for (final cartao in cartoesArquivados) {
        final cartaoId = cartao['id'] as String;
        
        // ✅ VERIFICAR SE HÁ DESPESAS VINCULADAS
        final despesasVinculadas = await _localDb.database?.query(
          'transacoes',
          where: 'usuario_id = ? AND is_cartao_credito = 1 AND (observacoes LIKE ? OR observacoes LIKE ?)',
          whereArgs: [userId, '%$cartaoId%', '%cartao:$cartaoId%'],
          limit: 1,
        ) ?? [];

        if (despesasVinculadas.isEmpty) {
          await _localDb.database?.delete(
            'cartoes',
            where: 'id = ?',
            whereArgs: [cartaoId],
          );
          
          await _localDb.addToSyncQueue('cartoes', cartaoId, 'DELETE', {});
          removidos++;
        }
      }

      log('✅ Cartões arquivados removidos: $removidos');
      return removidos;
    } catch (e) {
      log('❌ Erro ao limpar cartões arquivados: $e');
      return 0;
    }
  }

  /// ✅ 21. SINCRONIZAR CARTÕES
  Future<bool> sincronizarCartoes() async {
    try {
      log('🔔 sincronizarCartoes() CHAMADO');
      
      final isOnline = _syncManager.isOnline;
      log('🌐 isOnline: $isOnline');
      if (!isOnline) {
        log('📡 Offline - sincronização adiada');
        return false;
      }

      final userId = _authIntegration.authService.currentUser?.id;
      log('👤 userId: $userId');
      if (userId == null) return false;

      // ✅ SYNC CHANGES PRIMEIRO (PENDÊNCIAS LOCAIS)
      log('⬆️ Enviando mudanças locais para Supabase...');
      await _syncManager.syncAll();

      // ✅ BAIXAR CARTÕES DO SUPABASE
      log('⬇️ Baixando cartões do Supabase...');
      final cartoesSupabase = await Supabase.instance.client
          .from('cartoes')
          .select()
          .eq('usuario_id', userId)
          .order('created_at');
          
      log('📦 Cartões encontrados no Supabase: ${cartoesSupabase.length}');

      // ✅ ATUALIZAR DADOS LOCAIS
      for (final cartaoData in cartoesSupabase) {
        log('🔍 Processando cartão: ${cartaoData['nome']} (${cartaoData['id']})');
        final cartaoLocal = await buscarCartaoPorId(cartaoData['id']);
        
        if (cartaoLocal == null) {
          // ✅ CARTÃO NOVO - INSERIR
          log('➕ Inserindo cartão novo: ${cartaoData['nome']}');
          await _localDb.database?.insert('cartoes', {
            ...cartaoData,
            'ativo': cartaoData['ativo'] ? 1 : 0,
            'sync_status': 'synced',
          });
          log('✅ Cartão inserido no SQLite: ${cartaoData['nome']}');
        } else if (cartaoLocal.syncStatus != 'synced') {
          // ✅ CARTÃO DESATUALIZADO - ATUALIZAR
          log('🔄 Atualizando cartão existente: ${cartaoData['nome']}');
          await _localDb.database?.update(
            'cartoes',
            {
              ...cartaoData,
              'ativo': cartaoData['ativo'] ? 1 : 0,
              'sync_status': 'synced',
            },
            where: 'id = ?',
            whereArgs: [cartaoData['id']],
          );
          log('✅ Cartão atualizado no SQLite: ${cartaoData['nome']}');
        } else {
          log('⭐ Cartão já sincronizado: ${cartaoData['nome']}');
        }
      }

      log('✅ Sincronização de cartões concluída');
      log('📊 DEBUG: ${cartoesSupabase.length} cartões baixados do Supabase');
      return true;
    } catch (e) {
      log('❌ Erro na sincronização: $e');
      return false;
    }
  }

  /// ✅ 22. IMPORTAR CARTÕES SUGERIDOS
  Future<bool> importarCartoesSugeridos(List<Map<String, dynamic>> cartoesSelecionados) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      log('📝 Importando ${cartoesSelecionados.length} cartões sugeridos...');
      
      int sucessos = 0;
      int falhas = 0;

      for (final cartaoSugerido in cartoesSelecionados) {
        try {
          // ✅ VERIFICAR SE CARTÃO JÁ EXISTE (por nome)
          final nomeCartao = cartaoSugerido['nome'] as String;
          final cartaoExistente = await _localDb.database?.query(
            'cartoes',
            where: 'usuario_id = ? AND LOWER(nome) = ? AND ativo = 1',
            whereArgs: [userId, nomeCartao.toLowerCase()],
            limit: 1,
          );

          if (cartaoExistente != null && cartaoExistente.isNotEmpty) {
            log('⚠️ Cartão "${nomeCartao}" já existe - pulando');
            continue;
          }

          // ✅ USAR O MÉTODO EXISTENTE criarCartao() - OFFLINE-FIRST
          await criarCartao(
            nome: cartaoSugerido['nome'],
            limite: (cartaoSugerido['limite'] as num).toDouble(),
            diaFechamento: cartaoSugerido['dia_fechamento'],
            diaVencimento: cartaoSugerido['dia_vencimento'],
            bandeira: cartaoSugerido['bandeira'],
            cor: cartaoSugerido['cor'],
          );

          sucessos++;
          log('✅ Cartão "${nomeCartao}" importado com sucesso');
          
        } catch (e) {
          falhas++;
          log('❌ Erro ao importar cartão "${cartaoSugerido['nome']}": $e');
        }
      }

      log('📊 Importação concluída: $sucessos sucessos, $falhas falhas');

      // ✅ FORÇAR SINCRONIZAÇÃO BIDIRECIONAL (upload + download)
      if (sucessos > 0) {
        log('🔄 Forçando sincronização bidirecional...');
        await _syncManager.syncAll();
        log('✅ Sincronização bidirecional concluída - dados do Supabase baixados para SQLite');
      }

      return sucessos > 0;

    } catch (e) {
      log('❌ Erro na importação de cartões sugeridos: $e');
      return false;
    }
  }

  /// 🔢 CONTAGEM RÁPIDA PARA DIAGNÓSTICO

  /// Verifica se tem cartões configurados (usa método existente)
  Future<bool> temCartoesConfigurados({int minimo = 1}) async {
    final total = await contarCartoesAtivos();
    return total >= minimo;
  }
}