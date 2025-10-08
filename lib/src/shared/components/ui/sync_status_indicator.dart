// 🔄 Sync Status Indicator - iPoupei Mobile
// 
// Indicador visual do status de sincronização
// Mostra quando o app está fazendo sync automático
// 
// Baseado em: Material Design + App Colors

import 'package:flutter/material.dart';
import '../../../services/app_lifecycle_manager.dart';
import '../../../sync/sync_manager.dart';

/// Indicador de status de sincronização
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  SyncStatus _syncStatus = SyncStatus.idle;
  AppLifecycleStatus _lifecycleStatus = AppLifecycleStatus.active;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _setupListeners();
  }
  
  void _setupListeners() {
    // Escuta mudanças no status de sync
    SyncManager.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
        
        if (status == SyncStatus.syncing) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
          _animationController.value = 1.0;
        }
      }
    });
    
    // Escuta mudanças no lifecycle
    AppLifecycleManager.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _lifecycleStatus = status;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Só mostra o indicador quando está sincronizando
    if (_syncStatus != SyncStatus.syncing) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getSyncColor().withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getSyncColor().withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getIconColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getSyncMessage(),
                  style: TextStyle(
                    color: _getIconColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getSyncColor() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.orange;
      case SyncStatus.idle:
        return Colors.green;
    }
  }
  
  Color _getIconColor() {
    return Colors.white;
  }
  
  String _getSyncMessage() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        if (_lifecycleStatus == AppLifecycleStatus.resumed) {
          return 'Atualizando dados...';
        }
        return 'Sincronizando...';
      case SyncStatus.error:
        return 'Erro na sincronização';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.idle:
        return 'Sincronizado';
    }
  }
}