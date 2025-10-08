// 🔄 Operation Feedback Helper - iPoupei Mobile
// 
// Sistema universal de feedback para todas as operações CRUD
// Garante experiência consistente em transações, contas, cartões, etc.
// 
// Baseado em: UX Pattern + Offline-First + Auto-Refresh

import 'package:flutter/material.dart';
import '../../modules/shared/theme/app_colors.dart';

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
      'syncing': 'Sincronizando criação...',
      'synced': '✅ Criação sincronizada',
    },
    OperationType.update: {
      'immediate': 'Atualizado com sucesso!', 
      'syncing': 'Sincronizando alterações...',
      'synced': '✅ Alterações sincronizadas',
    },
    OperationType.delete: {
      'immediate': 'Excluído com sucesso!',
      'syncing': 'Sincronizando exclusão...',
      'synced': '✅ Exclusão sincronizada',
    },
    OperationType.archive: {
      'immediate': 'Arquivado com sucesso!',
      'syncing': 'Sincronizando arquivamento...',
      'synced': '✅ Arquivamento sincronizado',
    },
    OperationType.unarchive: {
      'immediate': 'Desarquivado com sucesso!',
      'syncing': 'Sincronizando desarquivamento...',
      'synced': '✅ Desarquivamento sincronizado',
    },
    OperationType.saldoCorrection: {
      'immediate': 'Saldo corrigido com sucesso!',
      'syncing': 'Sincronizando correção...',
      'synced': '✅ Correção sincronizada',
    },
    OperationType.payment: {
      'immediate': 'Pagamento registrado!',
      'syncing': 'Sincronizando pagamento...',
      'synced': '✅ Pagamento sincronizado',
    },
    OperationType.transfer: {
      'immediate': 'Transferência realizada!',
      'syncing': 'Sincronizando transferência...',
      'synced': '✅ Transferência sincronizada',
    },
  };

  /// 🎯 EXECUTA FEEDBACK COMPLETO PARA QUALQUER OPERAÇÃO
  static Future<void> executeOperationFeedback({
    required BuildContext context,
    required OperationType operation,
    required String entityName, // Ex: "transação", "conta", "cartão"
    VoidCallback? onRefreshComplete,
    Duration refreshDelay = const Duration(seconds: 3),
  }) async {
    
    // 1️⃣ FEEDBACK IMEDIATO
    _showImmediateFeedback(context, operation, entityName);
    
    // 2️⃣ FEEDBACK DE SINCRONIZAÇÃO  
    _showSyncingFeedback(context, operation);
    
    // 3️⃣ AGENDA REFRESH INTELIGENTE
    _scheduleIntelligentRefresh(
      context: context,
      operation: operation,
      delay: refreshDelay,
      onComplete: onRefreshComplete,
    );
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
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// 🔄 FEEDBACK DE SINCRONIZAÇÃO (1s depois)
  static void _showSyncingFeedback(BuildContext context, OperationType operation) {
    Future.delayed(const Duration(seconds: 1), () {
      final message = _messages[operation]?['syncing'] ?? 'Sincronizando...';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.tealPrimary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
  
  /// 📡 AGENDA REFRESH INTELIGENTE (3s depois)
  static void _scheduleIntelligentRefresh({
    required BuildContext context,
    required OperationType operation,
    required Duration delay,
    VoidCallback? onComplete,
  }) {
    Future.delayed(delay, () {
      if (context.mounted) {
        final message = _messages[operation]?['synced'] ?? '✅ Dados sincronizados';
        
        // Feedback final sutil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Callback personalizado
        onComplete?.call();
      }
    });
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
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}