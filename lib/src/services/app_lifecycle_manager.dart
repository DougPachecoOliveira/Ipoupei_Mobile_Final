// 🔄 App Lifecycle Manager - iPoupei Mobile
// 
// Gerencia ciclo de vida do app e sync automático
// Detecta quando app volta do background e força sync se necessário
// 
// Baseado em: Flutter WidgetsBindingObserver

import 'dart:async';
import 'package:flutter/widgets.dart';

import '../sync/sync_manager.dart';
import '../modules/contas/services/conta_service.dart';

/// Configurações de sync automático
class SyncConfig {
  /// Tempo mínimo de inatividade para forçar sync (em minutos)
  static const int minInactivityMinutes = 2;
  
  /// Tempo máximo de inatividade para forçar sync completo (em horas)  
  static const int maxInactivityHours = 4;
  
  /// Intervalo entre checks automáticos (em minutos)
  static const int autoCheckIntervalMinutes = 5;
}

/// Status do lifecycle
enum AppLifecycleStatus {
  active,
  paused,
  resumed,
  inactive,
}

/// Gerenciador do ciclo de vida do app
class AppLifecycleManager with WidgetsBindingObserver {
  static AppLifecycleManager? _instance;
  static AppLifecycleManager get instance {
    _instance ??= AppLifecycleManager._internal();
    return _instance!;
  }
  
  AppLifecycleManager._internal();
  
  bool _initialized = false;
  DateTime? _lastPauseTime;
  DateTime? _lastSyncTime;
  Timer? _periodicSyncTimer;
  
  final StreamController<AppLifecycleStatus> _statusController = 
      StreamController<AppLifecycleStatus>.broadcast();
  
  /// Stream do status do lifecycle
  Stream<AppLifecycleStatus> get statusStream => _statusController.stream;
  
  /// Status atual
  AppLifecycleStatus _currentStatus = AppLifecycleStatus.active;
  AppLifecycleStatus get currentStatus => _currentStatus;
  
  /// 🚀 INICIALIZA O GERENCIADOR
  void initialize() {
    if (_initialized) return;
    
    debugPrint('🔄 Inicializando AppLifecycleManager...');
    
    WidgetsBinding.instance.addObserver(this);
    _lastSyncTime = DateTime.now();
    
    // Inicia timer de sync periódico
    _startPeriodicSync();
    
    _initialized = true;
    debugPrint('✅ AppLifecycleManager inicializado');
  }
  
  /// 📱 LISTENER DE MUDANÇAS NO LIFECYCLE
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _handleAppPaused();
        break;
        
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
        
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
        
      case AppLifecycleState.hidden:
        // App oculto mas rodando
        break;
    }
  }
  
  /// ⏸️ APP PAUSADO/FECHADO
  void _handleAppPaused() {
    _lastPauseTime = DateTime.now();
    _currentStatus = AppLifecycleStatus.paused;
    _statusController.add(_currentStatus);
    
    debugPrint('📱 App pausado às: $_lastPauseTime');
    
    // Para o timer periódico quando app está pausado
    _stopPeriodicSync();
  }
  
  /// ▶️ APP RETOMADO
  void _handleAppResumed() async {
    _currentStatus = AppLifecycleStatus.resumed;
    _statusController.add(_currentStatus);
    
    debugPrint('📱 App retomado do background');
    
    // Reinicia timer periódico
    _startPeriodicSync();
    
    if (_lastPauseTime != null) {
      final pauseDuration = DateTime.now().difference(_lastPauseTime!);
      debugPrint('⏰ App ficou inativo por: ${pauseDuration.inMinutes} minutos');
      
      await _evaluateNeedForSync(pauseDuration);
    }
    
    _lastPauseTime = null;
    _currentStatus = AppLifecycleStatus.active;
    _statusController.add(_currentStatus);
  }
  
  /// 💤 APP INATIVO
  void _handleAppInactive() {
    _currentStatus = AppLifecycleStatus.inactive;
    _statusController.add(_currentStatus);
    debugPrint('📱 App inativo (chamada, notificação, etc)');
  }
  
  /// 🤔 AVALIA NECESSIDADE DE SYNC BASEADO NO TEMPO DE INATIVIDADE
  Future<void> _evaluateNeedForSync(Duration inactivityDuration) async {
    try {
      final inactivityMinutes = inactivityDuration.inMinutes;
      final inactivityHours = inactivityDuration.inHours;
      
      if (inactivityHours >= SyncConfig.maxInactivityHours) {
        debugPrint('🔄 Inatividade longa (${inactivityHours}h) - Sync completo obrigatório');
        await _performFullSync('Sincronização após ${inactivityHours}h offline');
        
      } else if (inactivityMinutes >= SyncConfig.minInactivityMinutes) {
        debugPrint('🔄 Inatividade moderada (${inactivityMinutes}min) - Sync incremental');
        await _performIncrementalSync();
        
      } else {
        debugPrint('✅ Inatividade curta, sync não necessário');
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao avaliar necessidade de sync: $e');
    }
  }
  
  /// 🔄 SYNC COMPLETO
  Future<void> _performFullSync(String reason) async {
    try {
      debugPrint('🔄 Iniciando sync completo: $reason');
      
      // Força resync completo de contas
      await ContaService.instance.forcarResync();
      
      // Sync completo via SyncManager
      await SyncManager.instance.syncInitial();
      
      _lastSyncTime = DateTime.now();
      debugPrint('✅ Sync completo concluído');
      
    } catch (e) {
      debugPrint('❌ Erro no sync completo: $e');
    }
  }
  
  /// ⚡ SYNC INCREMENTAL
  Future<void> _performIncrementalSync() async {
    try {
      debugPrint('⚡ Iniciando sync incremental...');
      
      // Sync incremental mais leve
      await SyncManager.instance.syncAll();
      
      _lastSyncTime = DateTime.now();
      debugPrint('✅ Sync incremental concluído');
      
    } catch (e) {
      debugPrint('❌ Erro no sync incremental: $e');
    }
  }
  
  /// ⏰ INICIA SYNC PERIÓDICO AUTOMÁTICO
  void _startPeriodicSync() {
    _stopPeriodicSync(); // Para o timer anterior se existir
    
    _periodicSyncTimer = Timer.periodic(
      Duration(minutes: SyncConfig.autoCheckIntervalMinutes),
      (timer) => _performPeriodicSync(),
    );
    
    debugPrint('⏰ Sync periódico iniciado (${SyncConfig.autoCheckIntervalMinutes}min)');
  }
  
  /// 🛑 PARA SYNC PERIÓDICO
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }
  
  /// 🔄 SYNC PERIÓDICO AUTOMÁTICO
  Future<void> _performPeriodicSync() async {
    if (_currentStatus != AppLifecycleStatus.active) return;
    
    try {
      debugPrint('⏰ Executando sync periódico automático...');
      await SyncManager.instance.syncAll();
      _lastSyncTime = DateTime.now();
      debugPrint('✅ Sync periódico concluído');
      
    } catch (e) {
      debugPrint('❌ Erro no sync periódico: $e');
    }
  }
  
  /// 🔧 FORÇA SYNC MANUAL
  Future<void> forceSyncNow({bool fullSync = false}) async {
    if (fullSync) {
      await _performFullSync('Sync manual solicitado');
    } else {
      await _performIncrementalSync();
    }
  }
  
  /// 📊 STATUS DO LIFECYCLE
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'current_status': _currentStatus.toString(),
      'last_pause_time': _lastPauseTime?.toIso8601String(),
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'periodic_sync_active': _periodicSyncTimer?.isActive ?? false,
    };
  }
  
  /// 🧹 DISPOSE
  void dispose() {
    _stopPeriodicSync();
    WidgetsBinding.instance.removeObserver(this);
    _statusController.close();
    _initialized = false;
    debugPrint('🧹 AppLifecycleManager disposed');
  }
}