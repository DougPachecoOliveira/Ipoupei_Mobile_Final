import 'dart:async';

import 'package:flutter/material.dart';

import '../../../sync/sync_manager.dart';

/// Feedback discreto: salvar nunca espera a nuvem, mas o usuário sempre sabe
/// se a alteração ainda está viajando ou ficou guardada no aparelho.
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  StreamSubscription<SyncStatus>? _subscription;
  late SyncStatus _status;

  @override
  void initState() {
    super.initState();
    _status = SyncManager.instance.status;
    _subscription = SyncManager.instance.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == SyncStatus.idle) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final foreground = _status == SyncStatus.error ? colors.onErrorContainer : colors.onSecondaryContainer;
    final background = _status == SyncStatus.error ? colors.errorContainer : colors.secondaryContainer;

    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Material(
          key: ValueKey(_status),
          color: background,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_status == SyncStatus.syncing)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                  )
                else
                  Icon(_icon, size: 16, color: foreground),
                const SizedBox(width: 7),
                Text(_message, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (_status) {
      case SyncStatus.error:
        return Icons.cloud_off_outlined;
      case SyncStatus.offline:
        return Icons.offline_bolt_outlined;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.idle:
        return Icons.cloud_done_outlined;
    }
  }

  String get _message {
    switch (_status) {
      case SyncStatus.syncing:
        return 'Salvando na nuvem';
      case SyncStatus.error:
        return 'Salvo no aparelho';
      case SyncStatus.offline:
        return 'Modo offline';
      case SyncStatus.idle:
        return 'Atualizado';
    }
  }
}
