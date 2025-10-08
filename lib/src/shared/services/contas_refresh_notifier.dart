// 🔔 Notificador de Refresh de Contas - iPoupei Mobile
//
// Serviço singleton para notificar páginas de contas quando há mudanças
// Usado quando transações são efetivadas/desefetivadas e afetam saldos
//
// Pattern: Observer/Publisher-Subscriber

import 'package:flutter/foundation.dart';

/// Notificador singleton para refresh de contas
/// Quando uma transação é efetivada/desefetivada, notifica páginas de contas
class ContasRefreshNotifier {
  static ContasRefreshNotifier? _instance;
  static ContasRefreshNotifier get instance {
    _instance ??= ContasRefreshNotifier._internal();
    return _instance!;
  }

  ContasRefreshNotifier._internal();

  /// Notificador que incrementa quando contas precisam refresh
  /// Páginas escutam e recarregam dados do SQLite (rápido)
  final ValueNotifier<int> refreshTrigger = ValueNotifier<int>(0);

  /// 🔔 Notifica que houve mudança em transações que afeta saldos de contas
  /// Chamado após efetivar/desefetivar transações
  void notificarMudancaContas() {
    refreshTrigger.value++;
    debugPrint('🔔 Contas precisam refresh (trigger: ${refreshTrigger.value})');
  }

  /// 🧹 Dispose (apenas para testes)
  void dispose() {
    refreshTrigger.dispose();
  }
}
