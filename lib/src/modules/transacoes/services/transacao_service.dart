// 💳 Transacao Service Complete - iPoupei Mobile
// 
// Serviço COMPLETO para transações idêntico ao React
// Implementa TODOS os campos e lógicas do projeto original
// 
// Baseado em: ReceitasModal.jsx e DespesasModal.jsx

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transacao_model.dart';
import '../../../database/local_database.dart';
import '../../../sync/connectivity_helper.dart';
import '../../categorias/services/categoria_service.dart';

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
      
      return despesasModels;
    } catch (e) {
      log('❌ Erro ao criar despesa: $e');
      rethrow;
    }
  }

  /// 💱 CRIAR TRANSFERÊNCIA
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

      log('💱 Criando transferência: $descricao');

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
        'sincronizado': true,
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
        'sincronizado': true,
      };

      // ✅ INSERIR AMBAS NO SUPABASE
      final response = await _supabase
          .from('transacoes')
          .insert([transacaoSaida, transacaoEntrada])
          .select();

      final transferenciasModels = response.map<TransacaoModel>((data) => TransacaoModel.fromJson(data)).toList();
      
      log('✅ Transferência criada: $descricao');
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

  /// 💳 BUSCAR TRANSAÇÕES COM FILTROS (MANTIDO DO SERVIÇO ORIGINAL)
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

      log('💳 Buscando transações para: ${_supabase.auth.currentUser?.email}');

      dynamic query = _supabase
          .from('transacoes')
          .select('''
            id, usuario_id, conta_id, conta_destino_id, cartao_id,
            categoria_id, subcategoria_id, tipo, descricao, valor,
            data, efetivado, observacoes, created_at, updated_at,
            tipo_receita, tipo_despesa, grupo_recorrencia, grupo_parcelamento,
            parcela_atual, total_parcelas, numero_recorrencia, total_recorrencias,
            eh_recorrente, transferencia, recorrente, tipo_recorrencia,
            valor_parcela, numero_parcelas, fatura_vencimento,
            data_proxima_recorrencia, ajuste_manual, motivo_ajuste,
            data_efetivacao, tags, localizacao, origem_diagnostico, sincronizado
          ''')
          .eq('usuario_id', userId);

      // Aplicar filtros
      if (dataInicio != null) {
        query = query.gte('data', dataInicio.toIso8601String().split('T')[0]);
      }
      if (dataFim != null) {
        query = query.lte('data', dataFim.toIso8601String().split('T')[0]);
      }
      if (tipo != null && tipo.isNotEmpty) {
        query = query.eq('tipo', tipo);
      }
      if (contaId != null && contaId.isNotEmpty) {
        query = query.eq('conta_id', contaId);
      }
      if (categoriaId != null && categoriaId.isNotEmpty) {
        query = query.eq('categoria_id', categoriaId);
      }
      
      query = query
          .order('data', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      final transacoes = (response as List).map<TransacaoModel>((item) {
        return TransacaoModel.fromJson(item);
      }).toList();

      log('✅ Transações carregadas: ${transacoes.length}');
      return transacoes;
    } catch (e) {
      log('❌ Erro ao buscar transações: $e');
      rethrow;
    }
  }

  /// ✏️ ATUALIZAR TRANSAÇÃO
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

      // ✅ BUSCAR DADOS ATUAIS DA TRANSAÇÃO PARA VALIDAÇÕES
      final transacaoAtual = await _supabase
          .from('transacoes')
          .select('*')
          .eq('id', transacaoId)
          .eq('usuario_id', userId)
          .single();

      final isCartaoEfetivado = transacaoAtual['cartao_id'] != null && 
                                transacaoAtual['efetivado'] == true;

      // ❌ VALIDAÇÕES PARA CARTÕES EFETIVADOS
      if (isCartaoEfetivado) {
        // Campos proibidos para cartões efetivados
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
      if (transacaoAtual['efetivado'] == true && transacaoAtual['cartao_id'] == null) {
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
      if (efetivado != null) updateData['efetivado'] = efetivado;
      if (observacoes != null) updateData['observacoes'] = observacoes;

      final response = await _supabase
          .from('transacoes')
          .update(updateData)
          .eq('id', transacaoId)
          .eq('usuario_id', userId)
          .select()
          .single();

      log('✅ Transação atualizada: $transacaoId');
      
      // 🔔 NOTIFICA MUDANÇA PARA CACHE DE CATEGORIAS
      CategoriaService.instance.notificarMudancaTransacoes();
      
      return TransacaoModel.fromJson(response);
    } catch (e) {
      log('❌ Erro ao atualizar transação: $e');
      rethrow;
    }
  }

  /// 🗑️ EXCLUIR TRANSAÇÃO
  Future<void> deleteTransacao(String transacaoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase
          .from('transacoes')
          .delete()
          .eq('id', transacaoId)
          .eq('usuario_id', userId);

      log('✅ Transação excluída: $transacaoId');
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