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

class TransacaoServiceComplete {
  static TransacaoServiceComplete? _instance;
  static TransacaoServiceComplete get instance {
    _instance ??= TransacaoServiceComplete._internal();
    return _instance!;
  }
  
  TransacaoServiceComplete._internal();

  final _supabase = Supabase.instance.client;
  final _localDb = LocalDatabase.instance;
  final _uuid = const Uuid();

  /// 💰 CRIAR RECEITA (MÉTODO COMPLETO IGUAL AO REACT)
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
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('💰 Criando receita: $descricao ($tipoReceita)');

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
        'efetivado': true, // Default para Supabase
        'recorrente': false, // Default
        'grupo_recorrencia': null,
        'grupo_parcelamento': null,
        'parcela_atual': null,
        'total_parcelas': null,
        'numero_recorrencia': null,
        'total_recorrencias': null,
        'eh_recorrente': false,
        'data_efetivacao': null,
        'transferencia': false,
        'parcela_unica': true,
        'ajuste_manual': false,
      };

      List<Map<String, dynamic>> receitasCriadas = [];

      switch (tipoReceita) {
        case 'extra':
          receitasCriadas = [{
            ...dadosBase,
            'id': _uuid.v4(),
            'data': data.toIso8601String().split('T')[0],
            'efetivado': efetivado,
            'recorrente': false,
            'grupo_recorrencia': null,
            'grupo_parcelamento': null,
            'data_efetivacao': efetivado ? now.toIso8601String() : null,
          }];
          break;

        case 'parcelada':
          final grupoId = _uuid.v4();
          final totalParcelas = numeroParcelas ?? 12;
          final dataBase = data;
          
          for (int i = 0; i < totalParcelas; i++) {
            final dataReceita = _calcularDataParcela(dataBase, i, frequenciaParcelada!);
            final efetivoStatus = i == 0 ? efetivado : false;
            final sufixo = ' (${i + 1}/$totalParcelas)';
            
            receitasCriadas.add({
              ...dadosBase,
              'id': _uuid.v4(),
              'data': dataReceita.toIso8601String().split('T')[0],
              'descricao': '${dadosBase['descricao']}$sufixo',
              'efetivado': efetivoStatus,
              'recorrente': true,
              'grupo_parcelamento': grupoId,
              'parcela_atual': i + 1,
              'total_parcelas': totalParcelas,
              'grupo_recorrencia': null,
              'numero_recorrencia': null,
              'total_recorrencias': null,
              'eh_recorrente': false,
              'data_efetivacao': efetivoStatus ? now.toIso8601String() : null,
            });
          }
          break;

        case 'previsivel':
          final grupoId = _uuid.v4();
          final totalRecorrencias = _calcularTotalRecorrencias(frequenciaPrevisivel!);
          final dataBase = data;
          
          for (int i = 0; i < totalRecorrencias; i++) {
            final dataReceita = _calcularDataParcela(dataBase, i, frequenciaPrevisivel);
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
              'grupo_parcelamento': null,
              'parcela_atual': null,
              'total_parcelas': null,
              'data_efetivacao': efetivoStatus ? now.toIso8601String() : null,
            });
          }
          break;
      }

      // ✅ INSERIR NO SUPABASE (dados já limpos)
      final response = await _supabase
          .from('transacoes')
          .insert(receitasCriadas)
          .select();

      final receitasModels = response.map<TransacaoModel>((data) => TransacaoModel.fromJson(data)).toList();
      
      log('✅ ${receitasModels.length} receita(s) criada(s): $descricao');
      return receitasModels;
    } catch (e) {
      log('❌ Erro ao criar receita: $e');
      rethrow;
    }
  }

  /// 💸 CRIAR DESPESA (MÉTODO COMPLETO IGUAL AO REACT)
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
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('💸 Criando despesa: $descricao ($tipoDespesa)');

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
        'efetivado': true, // Default para Supabase
        'recorrente': false, // Default
        'grupo_recorrencia': null,
        'grupo_parcelamento': null,
        'parcela_atual': null,
        'total_parcelas': null,
        'numero_recorrencia': null,
        'total_recorrencias': null,
        'eh_recorrente': false,
        'data_efetivacao': null,
        'transferencia': false,
        'parcela_unica': true,
        'ajuste_manual': false,
      };

      List<Map<String, dynamic>> despesasCriadas = [];

      switch (tipoDespesa) {
        case 'extra':
          despesasCriadas = [{
            ...dadosBase,
            'id': _uuid.v4(),
            'data': data.toIso8601String().split('T')[0],
            'efetivado': efetivado,
            'recorrente': false,
            'grupo_recorrencia': null,
            'grupo_parcelamento': null,
            'data_efetivacao': efetivado ? now.toIso8601String() : null,
          }];
          break;

        case 'parcelada':
          final grupoId = _uuid.v4();
          final totalParcelas = numeroParcelas ?? 12;
          final dataBase = data;
          
          for (int i = 0; i < totalParcelas; i++) {
            final dataDespesa = _calcularDataParcela(dataBase, i, frequenciaParcelada!);
            final efetivoStatus = i == 0 ? efetivado : false;
            final sufixo = ' (${i + 1}/$totalParcelas)';
            
            despesasCriadas.add({
              ...dadosBase,
              'id': _uuid.v4(),
              'data': dataDespesa.toIso8601String().split('T')[0],
              'descricao': '${dadosBase['descricao']}$sufixo',
              'efetivado': efetivoStatus,
              'recorrente': true,
              'grupo_parcelamento': grupoId,
              'parcela_atual': i + 1,
              'total_parcelas': totalParcelas,
              'grupo_recorrencia': null,
              'numero_recorrencia': null,
              'total_recorrencias': null,
              'eh_recorrente': false,
              'data_efetivacao': efetivoStatus ? now.toIso8601String() : null,
            });
          }
          break;

        case 'previsivel':
          final grupoId = _uuid.v4();
          final totalRecorrencias = _calcularTotalRecorrencias(frequenciaPrevisivel!);
          final dataBase = data;
          
          for (int i = 0; i < totalRecorrencias; i++) {
            final dataDespesa = _calcularDataParcela(dataBase, i, frequenciaPrevisivel);
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
              'grupo_parcelamento': null,
              'parcela_atual': null,
              'total_parcelas': null,
              'data_efetivacao': efetivoStatus ? now.toIso8601String() : null,
            });
          }
          break;
      }

      // ✅ INSERIR NO SUPABASE (dados já limpos)
      final response = await _supabase
          .from('transacoes')
          .insert(despesasCriadas)
          .select();

      final despesasModels = response.map<TransacaoModel>((data) => TransacaoModel.fromJson(data)).toList();
      
      log('✅ ${despesasModels.length} despesa(s) criada(s): $descricao');
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
        'parcela_unica': true,
        'ajuste_manual': false,
        'data_efetivacao': now.toIso8601String(),
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
        'parcela_unica': true,
        'ajuste_manual': false,
        'data_efetivacao': now.toIso8601String(),
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

  /// ✅ CALCULAR DATA DA PARCELA/RECORRÊNCIA (IGUAL AO REACT)
  DateTime _calcularDataParcela(DateTime dataBase, int indice, String frequencia) {
    final dataReceita = DateTime(dataBase.year, dataBase.month, dataBase.day);
    
    switch (frequencia) {
      case 'semanal':
        return dataReceita.add(Duration(days: 7 * indice));
      case 'quinzenal':
        return dataReceita.add(Duration(days: 14 * indice));
      case 'mensal':
        return DateTime(dataReceita.year, dataReceita.month + indice, dataReceita.day);
      case 'anual':
        return DateTime(dataReceita.year + indice, dataReceita.month, dataReceita.day);
      default:
        return DateTime(dataReceita.year, dataReceita.month + indice, dataReceita.day);
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

      // Verificar se categoria já existe
      final existing = await _supabase
          .from('categorias')
          .select('id')
          .eq('usuario_id', userId)
          .eq('nome', nomeCategoria)
          .eq('tipo', tipo)
          .maybeSingle();

      if (existing != null) {
        return existing['id'];
      }

      // Criar nova categoria
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
          .select('id')
          .single();

      log('✅ Categoria criada: $nomeCategoria');
      return novaCategoria['id'];
    } catch (e) {
      log('❌ Erro ao criar categoria: $e');
      rethrow;
    }
  }
}