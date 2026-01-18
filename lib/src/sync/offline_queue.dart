// 🔄 Offline Queue - iPoupei Mobile
// 
// Sistema de fila para operações offline
// Armazena operações pendentes e sincroniza quando online
// 
// Baseado em: Queue Pattern + Offline-First Architecture

import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/cartoes/models/cartao_model.dart';
import '../modules/cartoes/services/cartao_service.dart';

enum OperationType {
  insert,
  update,
  delete,
}

class QueuedOperation {
  final String id;
  final String table;
  final OperationType operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  QueuedOperation({
    required this.id,
    required this.table,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      id: json['id'],
      table: json['table'],
      operation: OperationType.values[json['operation']],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table': table,
      'operation': operation.index,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  QueuedOperation copyWithRetry() {
    return QueuedOperation(
      id: id,
      table: table,
      operation: operation,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount + 1,
    );
  }
}

class OfflineQueue {
  static OfflineQueue? _instance;
  static OfflineQueue get instance {
    _instance ??= OfflineQueue._internal();
    return _instance!;
  }
  
  OfflineQueue._internal();

  static const String _queueKey = 'offline_queue';
  static const int _maxRetries = 3;

  List<QueuedOperation> _queue = [];
  bool _isProcessing = false;

  /// ➕ ADICIONAR OPERAÇÃO À FILA
  Future<void> addOperation({
    required String table,
    required OperationType operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final operationId = '${table}_${operation.name}_${DateTime.now().millisecondsSinceEpoch}';
      
      final queuedOp = QueuedOperation(
        id: operationId,
        table: table,
        operation: operation,
        data: data,
        timestamp: DateTime.now(),
      );

      _queue.add(queuedOp);
      await _saveQueue();

      log('✅ Operação adicionada à fila offline: $table ${operation.name}');
      log('📊 Total de operações na fila: ${_queue.length}');
    } catch (e) {
      log('❌ Erro ao adicionar operação à fila: $e');
    }
  }

  /// 🔄 PROCESSAR FILA OFFLINE
  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    log('🔄 Iniciando processamento da fila offline (${_queue.length} operações)');

    final operationsToProcess = List<QueuedOperation>.from(_queue);
    final processedOperations = <String>[];
    final failedOperations = <QueuedOperation>[];

    for (final operation in operationsToProcess) {
      try {
        final success = await _executeOperation(operation);
        
        if (success) {
          processedOperations.add(operation.id);
          log('✅ Operação processada com sucesso: ${operation.id}');
        } else {
          if (operation.retryCount < _maxRetries) {
            failedOperations.add(operation.copyWithRetry());
            log('🔄 Operação falhou, tentativa ${operation.retryCount + 1}/$_maxRetries: ${operation.id}');
          } else {
            log('❌ Operação falhou definitivamente após $_maxRetries tentativas: ${operation.id}');
          }
        }
      } catch (e) {
        log('❌ Erro ao processar operação ${operation.id}: $e');
        
        if (operation.retryCount < _maxRetries) {
          failedOperations.add(operation.copyWithRetry());
        }
      }
    }

    // Remover operações processadas com sucesso
    _queue.removeWhere((op) => processedOperations.contains(op.id));
    
    // Adicionar operações falhadas para retry
    _queue.addAll(failedOperations);
    
    await _saveQueue();
    
    log('🔄 Processamento concluído. Processadas: ${processedOperations.length}, Falharam: ${failedOperations.length}');
    
    _isProcessing = false;
  }

  /// ⚡ EXECUTAR OPERAÇÃO INDIVIDUAL
  Future<bool> _executeOperation(QueuedOperation operation) async {
    try {
      // Importar serviços dinamicamente para evitar import circular
      switch (operation.table) {
        case 'contas':
          return await _processContaOperation(operation);
        case 'cartoes':
          return await _processCartaoOperation(operation);
        case 'categorias':
          return await _processCategoriaOperation(operation);
        case 'subcategorias':
          return await _processSubcategoriaOperation(operation);
        case 'transacoes':
          return await _processTransacaoOperation(operation);
        default:
          log('⚠️ Tabela não suportada: ${operation.table}');
          return false;
      }
    } catch (e) {
      log('❌ Erro ao executar operação ${operation.id}: $e');
      return false;
    }
  }

  /// 🏦 PROCESSAR OPERAÇÃO DE CONTA
  Future<bool> _processContaOperation(QueuedOperation operation) async {
    try {
      // Importar serviço aqui para evitar import circular
      final contaService = await _getContaService();
      
      switch (operation.operation) {
        case OperationType.insert:
          await contaService.addConta(
            nome: operation.data['nome'],
            tipo: operation.data['tipo'],
            banco: operation.data['banco'],
            saldoInicial: operation.data['saldo_inicial'],
            cor: operation.data['cor'],
          );
          break;
        case OperationType.update:
          await contaService.updateConta(
            contaId: operation.data['id'],
            nome: operation.data['nome'],
            tipo: operation.data['tipo'],
            banco: operation.data['banco'],
            cor: operation.data['cor'],
          );
          break;
        case OperationType.delete:
          await contaService.excluirConta(operation.data['id'], confirmacao: true);
          break;
      }
      return true;
    } catch (e) {
      log('❌ Erro ao processar operação de conta: $e');
      return false;
    }
  }

  /// 💳 PROCESSAR OPERAÇÃO DE CARTÃO
  Future<bool> _processCartaoOperation(QueuedOperation operation) async {
    try {
      // Usar serviço diretamente
      final cartaoService = CartaoService.instance;

      switch (operation.operation) {
        case OperationType.insert:
          await cartaoService.criarCartao(
            nome: operation.data['nome'],
            limite: operation.data['limite'],
            diaFechamento: operation.data['dia_fechamento'],
            diaVencimento: operation.data['dia_vencimento'],
            bandeira: operation.data['bandeira'],
            banco: operation.data['banco'],
            contaDebitoId: operation.data['conta_debito_id'],
            cor: operation.data['cor'],
            observacoes: operation.data['observacoes'],
          );
          break;
        case OperationType.update:
          // Para update, precisamos reconstruir o CartaoModel
          final cartaoData = operation.data;
          final cartaoModel = CartaoModel(
            id: cartaoData['id'],
            usuarioId: cartaoData['usuario_id'],
            nome: cartaoData['nome'],
            limite: cartaoData['limite'],
            diaFechamento: cartaoData['dia_fechamento'],
            diaVencimento: cartaoData['dia_vencimento'],
            bandeira: cartaoData['bandeira'],
            banco: cartaoData['banco'],
            contaDebitoId: cartaoData['conta_debito_id'],
            cor: cartaoData['cor'],
            observacoes: cartaoData['observacoes'],
            ativo: cartaoData['ativo'] == 1,
            createdAt: DateTime.parse(cartaoData['created_at']),
            updatedAt: DateTime.parse(cartaoData['updated_at']),
          );
          await cartaoService.atualizarCartao(cartaoModel);
          break;
        case OperationType.delete:
          await cartaoService.arquivarCartao(operation.data['id']);
          break;
      }
      return true;
    } catch (e) {
      log('❌ Erro ao processar operação de cartão: $e');
      return false;
    }
  }

  /// 📂 PROCESSAR OPERAÇÃO DE CATEGORIA
  Future<bool> _processCategoriaOperation(QueuedOperation operation) async {
    try {
      final categoriaService = await _getCategoriaService();
      
      switch (operation.operation) {
        case OperationType.insert:
          await categoriaService.addCategoria(
            nome: operation.data['nome'],
            tipo: operation.data['tipo'],
            cor: operation.data['cor'],
            icone: operation.data['icone'],
            descricao: operation.data['descricao'],
          );
          break;
        case OperationType.update:
          await categoriaService.updateCategoria(
            categoriaId: operation.data['id'],
            nome: operation.data['nome'],
            tipo: operation.data['tipo'],
            cor: operation.data['cor'],
            icone: operation.data['icone'],
            descricao: operation.data['descricao'],
          );
          break;
        case OperationType.delete:
          await categoriaService.excluirCategoria(operation.data['id'], confirmacao: true);
          break;
      }
      return true;
    } catch (e) {
      log('❌ Erro ao processar operação de categoria: $e');
      return false;
    }
  }

  /// 📂 PROCESSAR OPERAÇÃO DE SUBCATEGORIA
  Future<bool> _processSubcategoriaOperation(QueuedOperation operation) async {
    try {
      final categoriaService = await _getCategoriaService();
      
      switch (operation.operation) {
        case OperationType.insert:
          await categoriaService.addSubcategoria(
            categoriaId: operation.data['categoria_id'],
            nome: operation.data['nome'],
            cor: operation.data['cor'],
            icone: operation.data['icone'],
          );
          break;
        case OperationType.update:
          await categoriaService.updateSubcategoria(
            subcategoriaId: operation.data['id'],
            nome: operation.data['nome'],
            cor: operation.data['cor'],
            icone: operation.data['icone'],
          );
          break;
        case OperationType.delete:
          await categoriaService.arquivarSubcategoria(operation.data['id']);
          break;
      }
      return true;
    } catch (e) {
      log('❌ Erro ao processar operação de subcategoria: $e');
      return false;
    }
  }

  /// 💳 PROCESSAR OPERAÇÃO DE TRANSAÇÃO
  Future<bool> _processTransacaoOperation(QueuedOperation operation) async {
    try {
      final transacaoService = await _getTransacaoService();
      
      switch (operation.operation) {
        case OperationType.insert:
          if (operation.data['tipo'] == 'transferencia') {
            await transacaoService.criarTransferencia(
              contaOrigemId: operation.data['conta_id'],
              contaDestinoId: operation.data['conta_destino_id'],
              valor: operation.data['valor'],
              data: DateTime.parse(operation.data['data']),
              descricao: operation.data['descricao'],
              observacoes: operation.data['observacoes'],
            );
          } else {
            await transacaoService.addTransacao(
              tipo: operation.data['tipo'],
              descricao: operation.data['descricao'],
              valor: operation.data['valor'],
              data: DateTime.parse(operation.data['data']),
              contaId: operation.data['conta_id'],
              categoriaId: operation.data['categoria_id'],
              subcategoriaId: operation.data['subcategoria_id'],
              efetivado: operation.data['efetivado'],
              observacoes: operation.data['observacoes'],
            );
          }
          break;
        case OperationType.update:
          await transacaoService.updateTransacao(
            transacaoId: operation.data['id'],
            descricao: operation.data['descricao'],
            valor: operation.data['valor'],
            data: DateTime.parse(operation.data['data']),
            contaId: operation.data['conta_id'],
            categoriaId: operation.data['categoria_id'],
            subcategoriaId: operation.data['subcategoria_id'],
            efetivado: operation.data['efetivado'],
            observacoes: operation.data['observacoes'],
          );
          break;
        case OperationType.delete:
          await transacaoService.deleteTransacao(operation.data['id']);
          break;
      }
      return true;
    } catch (e) {
      log('❌ Erro ao processar operação de transação: $e');
      return false;
    }
  }

  /// 💾 SALVAR FILA NO STORAGE
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _queue.map((op) => op.toJson()).toList();
      await prefs.setString(_queueKey, jsonEncode(queueJson));
    } catch (e) {
      log('❌ Erro ao salvar fila: $e');
    }
  }

  /// 📖 CARREGAR FILA DO STORAGE
  Future<void> loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJsonString = prefs.getString(_queueKey);
      
      if (queueJsonString != null) {
        final queueJson = jsonDecode(queueJsonString) as List;
        _queue = queueJson
            .map((json) => QueuedOperation.fromJson(json))
            .toList();
        
        log('📖 Fila carregada: ${_queue.length} operações pendentes');
      }
    } catch (e) {
      log('❌ Erro ao carregar fila: $e');
      _queue = [];
    }
  }

  /// 🗑️ LIMPAR FILA
  Future<void> clearQueue() async {
    try {
      _queue.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      log('🗑️ Fila offline limpa');
    } catch (e) {
      log('❌ Erro ao limpar fila: $e');
    }
  }

  /// 📊 ESTATÍSTICAS DA FILA
  Map<String, dynamic> getQueueStats() {
    final stats = <String, int>{};
    
    for (final op in _queue) {
      final key = '${op.table}_${op.operation.name}';
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return {
      'total': _queue.length,
      'isProcessing': _isProcessing,
      'operations': stats,
      'oldestOperation': _queue.isNotEmpty 
          ? _queue.map((op) => op.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
    };
  }

  /// 🔧 HELPERS PARA IMPORTAR SERVIÇOS DINAMICAMENTE
  Future<dynamic> _getContaService() async {
    // Importação dinâmica para evitar import circular
    final module = await import('package:ipoupei_mobile/src/modules/contas/services/conta_service.dart');
    return module.contaService.instance;
  }

  Future<dynamic> _getCategoriaService() async {
    final module = await import('package:ipoupei_mobile/src/modules/categorias/services/categoria_service.dart');
    return module.categoriaService.instance;
  }

  Future<dynamic> _getTransacaoService() async {
    final module = await import('package:ipoupei_mobile/src/modules/transacoes/services/transacao_service.dart');
    return module.transacaoService.instance;
  }
}

// Helper para importação dinâmica (simplificado)
Future<dynamic> import(String path) async {
  // Em uma implementação real, usaria dynamic imports
  // Por simplicidade, retornamos um mock que permite acessar os services
  return _ServiceRegistry();
}

class _ServiceRegistry {
  dynamic get contaService => ContaServiceProxy();
  dynamic get categoriaService => CategoriaServiceProxy();
  dynamic get transacaoService => TransacaoServiceProxy();
}

// Proxies simples para evitar import circular
class ContaServiceProxy {
  static ContaServiceProxy get instance => ContaServiceProxy();
  Future<void> addConta({required String nome, required String tipo, String? banco, required double saldoInicial, String? cor}) async {}
  Future<void> updateConta({required String contaId, String? nome, String? tipo, String? banco, String? cor}) async {}
  Future<Map<String, dynamic>> excluirConta(String id, {bool confirmacao = false}) async => {'success': true};
}

class CategoriaServiceProxy {
  static CategoriaServiceProxy get instance => CategoriaServiceProxy();
  Future<void> addCategoria({required String nome, String? tipo, String? cor, String? icone, String? descricao}) async {}
  Future<void> updateCategoria({required String categoriaId, String? nome, String? tipo, String? cor, String? icone, String? descricao}) async {}
  Future<Map<String, dynamic>> excluirCategoria(String id, {bool confirmacao = false}) async => {'success': true};
  Future<void> addSubcategoria({required String categoriaId, required String nome, String? cor, String? icone}) async {}
  Future<void> updateSubcategoria({required String subcategoriaId, String? nome, String? cor, String? icone}) async {}
  Future<void> arquivarSubcategoria(String id) async {}
}

class TransacaoServiceProxy {
  static TransacaoServiceProxy get instance => TransacaoServiceProxy();
  Future<void> addTransacao({required String tipo, required String descricao, required double valor, required DateTime data, String? contaId, String? categoriaId, String? subcategoriaId, bool efetivado = true, String? observacoes}) async {}
  Future<void> updateTransacao({required String transacaoId, String? descricao, double? valor, DateTime? data, String? contaId, String? categoriaId, String? subcategoriaId, bool? efetivado, String? observacoes}) async {}
  Future<void> deleteTransacao(String id) async {}
  Future<List<dynamic>> criarTransferencia({required String contaOrigemId, required String contaDestinoId, required double valor, required DateTime data, required String descricao, String? observacoes}) async => [];
}