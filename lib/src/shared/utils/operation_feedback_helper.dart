// 🔄 Operation Feedback Helper - iPoupei Mobile
// 
// Sistema universal de feedback para todas as operações CRUD
// Garante experiência consistente em transações, contas, cartões, etc.
// 
// Baseado em: UX Pattern + Offline-First + Auto-Refresh

import 'package:flutter/material.dart';

/// Tipos de operação suportadas
enum OperationType {
  create,
  update, 
  delete,
  archive,
  unarchive,
  saldoCorrection,
  payment,
  transfer,
}

/// Helper universal para feedback pós-operação
class OperationFeedbackHelper {
  static const Map<OperationType, Map<String, String>> _messages = {
    OperationType.create: {
      'immediate': 'Criado com sucesso!',
    },
    OperationType.update: {
      'immediate': 'Atualizado com sucesso!', 
    },
    OperationType.delete: {
      'immediate': 'Excluído com sucesso!',
    },
    OperationType.archive: {
      'immediate': 'Arquivado com sucesso!',
    },
    OperationType.unarchive: {
      'immediate': 'Desarquivado com sucesso!',
    },
    OperationType.saldoCorrection: {
      'immediate': 'Saldo corrigido com sucesso!',
    },
    OperationType.payment: {
      'immediate': 'Pagamento registrado!',
    },
    OperationType.transfer: {
      'immediate': 'Transferência realizada!',
    },
  };

  /// Confirma apenas o que realmente aconteceu: a escrita local terminou.
  /// O status global de sincronização cuida da nuvem sem prender a navegação
  /// e sem exibir um falso "sincronizado" baseado em temporizador.
  static Future<void> executeOperationFeedback({
    required BuildContext context,
    required OperationType operation,
    required String entityName, // Ex: "transação", "conta", "cartão"
    VoidCallback? onRefreshComplete,
  }) async {
    _showImmediateFeedback(context, operation, entityName);
    onRefreshComplete?.call();
  }
  
  /// ✅ FEEDBACK IMEDIATO (0s)
  static void _showImmediateFeedback(
    BuildContext context, 
    OperationType operation,
    String entityName,
  ) {
    final message = _messages[operation]?['immediate'] ?? 'Operação realizada!';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// 🎯 VERSÕES ESPECÍFICAS PARA FACILITAR USO
  
  static Future<void> transactionCreated(BuildContext context, {VoidCallback? onRefreshComplete}) {
    return executeOperationFeedback(
      context: context,
      operation: OperationType.create,
      entityName: 'transação',
      onRefreshComplete: onRefreshComplete,
    );
  }
  
  static Future<void> cardCreated(BuildContext context, {VoidCallback? onRefreshComplete}) {
    return executeOperationFeedback(
      context: context,
      operation: OperationType.create,
      entityName: 'cartão',
      onRefreshComplete: onRefreshComplete,
    );
  }
  
  static Future<void> accountUpdated(BuildContext context, {VoidCallback? onRefreshComplete}) {
    return executeOperationFeedback(
      context: context,
      operation: OperationType.update,
      entityName: 'conta',
      onRefreshComplete: onRefreshComplete,
    );
  }
  
  static Future<void> paymentRegistered(BuildContext context, {VoidCallback? onRefreshComplete}) {
    return executeOperationFeedback(
      context: context,
      operation: OperationType.payment,
      entityName: 'pagamento',
      onRefreshComplete: onRefreshComplete,
    );
  }
  
  static Future<void> transferCompleted(BuildContext context, {VoidCallback? onRefreshComplete}) {
    return executeOperationFeedback(
      context: context,
      operation: OperationType.transfer,
      entityName: 'transferência',
      onRefreshComplete: onRefreshComplete,
    );
  }
  
  /// 🔧 HELPER PARA OPERAÇÕES COM NAVEGAÇÃO
  static Future<void> executeWithNavigation({
    required BuildContext context,
    required OperationType operation,
    required String entityName,
    required Future<bool> Function() operationFunction,
    bool popOnSuccess = true,
    VoidCallback? onRefreshComplete,
  }) async {
    try {
      // Executa operação
      final success = await operationFunction();
      
      if (success && context.mounted) {
        // Executa feedback
        await executeOperationFeedback(
          context: context,
          operation: operation,
          entityName: entityName,
          onRefreshComplete: onRefreshComplete,
        );
        
        // Navega de volta se solicitado
        if (popOnSuccess) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
