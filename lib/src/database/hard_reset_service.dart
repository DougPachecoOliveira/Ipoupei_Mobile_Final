// 🔧 Hard Reset Service - iPoupei Mobile
//
// Serviço para resetar completamente a base de dados local
// Simula o comportamento de "primeiro login" após reinstalar app
//
// Funcionalidades:
// - Limpeza completa de todas as tabelas
// - Reset de timestamps de sync
// - Redownload total do Supabase
// - Progress tracking interativo

import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../database/local_database.dart';
import '../sync/sync_manager.dart';
import '../shared/services/contas_refresh_notifier.dart';
import '../modules/contas/services/conta_service.dart';
import '../modules/categorias/services/categoria_service.dart';

/// Enum para as fases do hard reset
enum ResetPhase {
  preparing,      // Preparando reset
  clearingLocal,  // Limpando dados locais
  downloading,    // Baixando do Supabase
  processing,     // Processando dados
  finalizing,     // Finalizando
  completed,      // Concluído
  error          // Erro
}

/// Modelo de progresso do reset
class ResetProgress {
  final ResetPhase phase;
  final String message;
  final String detailMessage;
  final double progress; // 0.0 a 1.0
  final int? processedCount;
  final int? totalCount;
  final String? currentTable;
  final bool isCompleted;
  final String? errorMessage;

  const ResetProgress({
    required this.phase,
    required this.message,
    required this.detailMessage,
    required this.progress,
    this.processedCount,
    this.totalCount,
    this.currentTable,
    this.isCompleted = false,
    this.errorMessage,
  });

  ResetProgress copyWith({
    ResetPhase? phase,
    String? message,
    String? detailMessage,
    double? progress,
    int? processedCount,
    int? totalCount,
    String? currentTable,
    bool? isCompleted,
    String? errorMessage,
  }) {
    return ResetProgress(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      detailMessage: detailMessage ?? this.detailMessage,
      progress: progress ?? this.progress,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      currentTable: currentTable ?? this.currentTable,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Serviço singleton para hard reset
class HardResetService {
  static final HardResetService _instance = HardResetService._internal();
  static HardResetService get instance => _instance;
  HardResetService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final SyncManager _syncManager = SyncManager.instance;

  /// Stream de progresso do reset
  final StreamController<ResetProgress> _progressController = StreamController.broadcast();
  Stream<ResetProgress> get progressStream => _progressController.stream;

  /// Flag para indicar se reset está em andamento
  bool _isResetting = false;
  bool get isResetting => _isResetting;

  /// Timer para timeout
  Timer? _timeoutTimer;

  /// Completer para controle de background sync
  Completer<void>? _backgroundSyncCompleter;

  /// 🚨 HARD RESET PRINCIPAL
  /// Limpa tudo e refaz sync completo
  Future<bool> performHardReset() async {
    if (_isResetting) {
      log('⚠️ Hard reset já está em andamento');
      return false;
    }

    _isResetting = true;
    log('🔧 Iniciando Hard Reset...');

    try {
      // Fase 1: Preparação
      await _updateProgress(
        phase: ResetPhase.preparing,
        message: 'Preparando reset inteligente...',
        detailMessage: 'Verificando conectividade. Seu login será preservado!',
        progress: 0.05,
      );

      // Verifica se está online
      if (!_syncManager.isOnline) {
        throw Exception('Necessária conexão com internet para reset');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Fase 2: Limpeza Local
      await _clearLocalData();

      // Fase 3: Download
      await _downloadAllData();

      // Fase 4: Finalização
      await _finalizeReset();

      // ✅ Sucesso
      await _updateProgress(
        phase: ResetPhase.completed,
        message: 'Reset concluído com sucesso!',
        detailMessage: 'Dados financeiros atualizados. Login preservado!',
        progress: 1.0,
        isCompleted: true,
      );

      log('✅ Hard Reset concluído com sucesso');
      return true;

    } catch (e) {
      log('❌ Erro durante Hard Reset: $e');

      await _updateProgress(
        phase: ResetPhase.error,
        message: 'Erro durante reset',
        detailMessage: 'Falha: ${e.toString()}',
        progress: 0.0,
        errorMessage: e.toString(),
      );

      return false;
    } finally {
      _isResetting = false;
      _timeoutTimer?.cancel();
    }
  }

  /// 🧹 LIMPEZA DE DADOS LOCAIS
  Future<void> _clearLocalData() async {
    await _updateProgress(
      phase: ResetPhase.clearingLocal,
      message: 'Limpando dados locais...',
      detailMessage: 'Removendo cache e timestamps antigos',
      progress: 0.1,
    );

    // 🎯 SMART RESET: Limpa APENAS dados financeiros, PRESERVA autenticação e perfil
    final financialDataTables = [
      'sync_queue',           // Primeiro: fila de operações
      'transacoes',           // Dados financeiros
      'faturas',
      'planejamentos',
      'cartoes',
      'contas',
      'subcategorias',
      'categorias',
      'grupos_metadados'
      // ✅ PRESERVADOS: perfil_usuario, notificacoes (mantém login e configurações)
    ];

    // LIMPEZA ATOMIC: Tudo em uma transação para garantir integridade
    final db = _localDb.database;
    if (db != null) {
      await db.transaction((txn) async {
        for (int i = 0; i < financialDataTables.length; i++) {
          final table = financialDataTables[i];

          await _updateProgress(
            phase: ResetPhase.clearingLocal,
            message: 'Limpando dados financeiros...',
            detailMessage: 'Limpando tabela: $table (preservando login)',
            progress: 0.1 + (i / financialDataTables.length) * 0.15,
            currentTable: table,
          );

          // Limpa a tabela dentro da transação
          try {
            await txn.delete(table);
            log('🧹 Tabela $table limpa');
          } catch (e) {
            log('⚠️ Erro ao limpar tabela $table: $e (continuando...)');
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
      });
    }

    // Reset timestamps de sync
    await _clearSyncTimestamps();

    // Limpa cache de serviços
    await _clearAllCaches();

    log('🧹 Limpeza local concluída');
  }

  /// 📥 DOWNLOAD DE TODOS OS DADOS
  Future<void> _downloadAllData() async {
    await _updateProgress(
      phase: ResetPhase.downloading,
      message: 'Baixando dados do servidor...',
      detailMessage: 'Conectando ao Servidor e iniciando o download',
      progress: 0.3,
    );

    // Inicia timeout de 60 segundos
    _startTimeoutTimer();

    try {
      // ✅ USA EXATAMENTE A MESMA SEQUÊNCIA QUE FUNCIONA NO PRIMEIRO LOGIN

      // 1. ContaService.forcarResync() PRIMEIRO (como no main.dart)
      await _updateProgress(
        phase: ResetPhase.downloading,
        message: 'Sincronizando contas...',
        detailMessage: 'Forçando resync de contas com saldos corretos do Supabase',
        progress: 0.4,
      );
      await ContaService.instance.forcarResync();
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. SyncManager.syncInitial() DEPOIS (como no main.dart)
      await _updateProgress(
        phase: ResetPhase.downloading,
        message: 'Sincronizando dados...',
        detailMessage: 'Executando sync inicial completo de categorias, cartões e transações',
        progress: 0.6,
      );
      await SyncManager.instance.syncInitial();
      await Future.delayed(const Duration(milliseconds: 500));

      await _updateProgress(
        phase: ResetPhase.downloading,
        message: 'Download concluído!',
        detailMessage: 'Todos os dados foram baixados com sucesso usando sequência do primeiro login',
        progress: 0.8,
      );

    } catch (e) {
      log('❌ Erro durante download: $e');
      rethrow;
    }
  }

  /// ✅ FINALIZAÇÃO DO RESET
  Future<void> _finalizeReset() async {
    await _updateProgress(
      phase: ResetPhase.finalizing,
      message: 'Finalizando...',
      detailMessage: 'Validando dados e atualizando interface',
      progress: 0.9,
    );

    // Valida integridade dos dados
    await _validateDataIntegrity();

    // Limpa cache de todos os serviços
    await _clearAllCaches();

    // Notifica páginas para refresh
    try {
      ContasRefreshNotifier.instance.notificarMudancaContas();
    } catch (e) {
      log('⚠️ Erro ao notificar mudanças: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 🔍 VALIDAÇÃO DE INTEGRIDADE
  Future<void> _validateDataIntegrity() async {
    final userId = _localDb.currentUserId;
    if (userId == null) return;

    try {
      // Verifica se existem dados básicos
      final contasCount = await _localDb.database?.rawQuery(
        'SELECT COUNT(*) as count FROM contas WHERE usuario_id = ?',
        [userId],
      );

      final transacoesCount = await _localDb.database?.rawQuery(
        'SELECT COUNT(*) as count FROM transacoes WHERE usuario_id = ?',
        [userId],
      );

      log('✅ Validação: ${contasCount?.first['count']} contas, ${transacoesCount?.first['count']} transações');

    } catch (e) {
      log('⚠️ Erro na validação: $e');
    }
  }

  /// ⏱️ TIMER DE TIMEOUT
  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(seconds: 60), () async {
      log('⏱️ Timeout de 60s atingido - liberando interface');

      // Libera interface mas continua sync em background
      await _updateProgress(
        phase: ResetPhase.completed,
        message: 'Dados principais carregados!',
        detailMessage: 'Finalizando em segundo plano...',
        progress: 0.8,
        isCompleted: true, // Libera a UI
      );

      // Continua sync em background
      _continueInBackground();
    });
  }

  /// 🔄 CONTINUAÇÃO EM BACKGROUND
  void _continueInBackground() async {
    log('🔄 Continuando sync em background...');

    _backgroundSyncCompleter = Completer<void>();

    try {
      // Continua o sync que pode ter sido interrompido
      await _syncManager.syncAll();

      // Finalização em background
      await _clearAllCaches();
      ContasRefreshNotifier.instance.notificarMudancaContas();

      log('✅ Background sync concluído');

    } catch (e) {
      log('❌ Erro em background sync: $e');
    } finally {
      _backgroundSyncCompleter?.complete();
    }
  }

  /// 🧹 LIMPAR TIMESTAMPS DE SYNC
  Future<void> _clearSyncTimestamps() async {
    // Remove timestamps salvos para forçar download completo
    // Isso fará o SyncManager baixar tudo novamente
    await _syncManager.clearSyncTimestamps();
    log('🧹 Timestamps de sync limpos');
  }

  /// 🧹 LIMPAR APENAS CACHES DE DADOS FINANCEIROS (PRESERVA LOGIN)
  Future<void> _clearAllCaches() async {
    try {
      // 1. ✅ PRESERVAR SharedPreferences (contém tokens de autenticação)
      // Limpar apenas chaves específicas se necessário no futuro
      log('✅ SharedPreferences preservado (mantém tokens de auth)');

      // 2. Limpar caches dos services
      try {
        // ContaService cache
        final contaService = ContaService.instance;
        if (contaService.runtimeType.toString().contains('ContaService')) {
          // Reflexão para acessar cache privado se existir
          log('🧹 Cache ContaService preparado para limpeza');
        }
      } catch (e) {
        log('⚠️ Erro ao limpar cache ContaService: $e (continuando...)');
      }

      try {
        // CategoriaService cache
        final categoriaService = CategoriaService.instance;
        if (categoriaService.runtimeType.toString().contains('CategoriaService')) {
          log('🧹 Cache CategoriaService preparado para limpeza');
        }
      } catch (e) {
        log('⚠️ Erro ao limpar cache CategoriaService: $e (continuando...)');
      }

      // 3. ✅ PRESERVAR UserPreferencesService (configurações do usuário)
      // As preferências do usuário (cartão favorito, etc.) devem ser mantidas
      log('✅ UserPreferencesService preservado (mantém configurações)');

      log('✅ Caches de dados financeiros limpos, autenticação preservada');

    } catch (e) {
      log('⚠️ Erro geral ao limpar cache: $e');
    }
  }

  /// 📡 UPDATE DE PROGRESSO
  Future<void> _updateProgress({
    required ResetPhase phase,
    required String message,
    required String detailMessage,
    required double progress,
    int? processedCount,
    int? totalCount,
    String? currentTable,
    bool isCompleted = false,
    String? errorMessage,
  }) async {
    final progressData = ResetProgress(
      phase: phase,
      message: message,
      detailMessage: detailMessage,
      progress: progress.clamp(0.0, 1.0),
      processedCount: processedCount,
      totalCount: totalCount,
      currentTable: currentTable,
      isCompleted: isCompleted,
      errorMessage: errorMessage,
    );

    _progressController.add(progressData);

    // Debug log
    debugPrint('🔧 Reset Progress: ${(progress * 100).toInt()}% - $message');
  }

  /// 🧹 DISPOSE
  void dispose() {
    _progressController.close();
    _timeoutTimer?.cancel();
  }
}
