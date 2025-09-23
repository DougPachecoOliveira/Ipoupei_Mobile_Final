// 🔄 Sync Manager - iPoupei Mobile
// 
// Gerencia sincronização entre SQLite local e Supabase
// Funciona offline e sincroniza quando online
// 
// Baseado em: Offline-first pattern
// Arquitetura: Bidirectional sync + Conflict resolution

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/local_database.dart';
import '../services/grupos_metadados_service.dart';
import 'connectivity_helper.dart';

/// Status de sincronização
enum SyncStatus {
  idle,
  syncing,
  error,
  offline,
}

/// Gerenciador de sincronização entre local e remoto
class SyncManager {
  static SyncManager? _instance;
  static SyncManager get instance {
    _instance ??= SyncManager._internal();
    return _instance!;
  }
  
  /// 🔧 Converte boolean para INTEGER para compatibilidade SQLite
  static Map<String, dynamic> _prepareSQLiteData(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    // Field mapping from Supabase to SQLite for transactions
    final fieldMapping = <String, String>{
      'parcelaUnica': 'parcela_atual',
      'numeroTotalParcelas': 'total_parcelas',
      'numeroParcela': 'numero_parcelas',
    };

    for (final entry in data.entries) {
      final originalKey = entry.key;
      final value = entry.value;

      // Skip fields that don't exist in SQLite
      if (originalKey == 'fatura_id') {
        continue; // This field doesn't exist in SQLite schema
      }

      // Map field names from Supabase to SQLite
      final key = fieldMapping[originalKey] ?? originalKey;

      if (value is bool) {
        result[key] = value ? 1 : 0;  // Convert boolean to INTEGER
      } else {
        result[key] = value;
      }
    }

    return result;
  }
  
  SyncManager._internal();
  
  final LocalDatabase _localDB = LocalDatabase.instance;
  final ConnectivityHelper _connectivity = ConnectivityHelper.instance;
  final _supabase = Supabase.instance.client;
  SyncStatus _status = SyncStatus.idle;
  Timer? _periodicSync;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _initialized = false;
  bool _isOnline = false;
  
  /// 📊 TIMESTAMPS DE SYNC POR TABELA (para sync incremental)
  final Map<String, String> _lastSyncTimestamps = {};
  
  /// 📋 LISTA DE TABELAS PARA SYNC UNIVERSAL
  static const List<String> _syncTables = [
    'transacoes',
    'contas', 
    'cartoes',
    'categorias',
    'subcategorias',
  ];
  
  /// Controllers para streams
  final StreamController<SyncStatus> _statusController = 
    StreamController<SyncStatus>.broadcast();
  
  /// Getters públicos
  SyncStatus get status => _status;
  bool get isOnline => _isOnline;
  Stream<SyncStatus> get statusStream => _statusController.stream;
  
  /// 🚀 INICIALIZA SYNC MANAGER
  Future<void> initialize() async {
    if (_initialized) return;
    
    debugPrint('🔄 Inicializando Sync Manager...');
    
    try {
      // Carrega timestamps de sync salvos
      await _loadSyncTimestamps();
      
      // Verifica conectividade inicial
      await _checkConnectivity();
      
      // Escuta mudanças de conectividade
      _setupConnectivityListener();
      
      // Configura sync periódico inteligente
      _setupPeriodicSync();
      
      _initialized = true;
      debugPrint('✅ Sync Manager inicializado');
      
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Sync Manager: $e');
      rethrow;
    }
  }

  /// 📊 CARREGA TIMESTAMPS DE SYNC SALVOS
  Future<void> _loadSyncTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final table in _syncTables) {
        final timestamp = prefs.getString('last_sync_$table');
        if (timestamp != null) {
          _lastSyncTimestamps[table] = timestamp;
          debugPrint('📅 $table: última sync em $timestamp');
        }
      }
      
      debugPrint('✅ Timestamps de sync carregados: ${_lastSyncTimestamps.length} tabelas');
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar timestamps: $e');
    }
  }
  
  /// 🌐 VERIFICA CONECTIVIDADE
  Future<void> _checkConnectivity() async {
    try {
      _isOnline = await _connectivity.isOnline();
      
      if (_isOnline) {
        _updateStatus(SyncStatus.idle);
      } else {
        _updateStatus(SyncStatus.offline);
      }
      
      debugPrint('🌐 Conectividade: ${_isOnline ? "Online" : "Offline"}');
      
    } catch (e) {
      debugPrint('❌ Erro ao verificar conectividade: $e');
      _isOnline = false;
      _updateStatus(SyncStatus.offline);
    }
  }
  
  /// 👂 CONFIGURA LISTENER DE CONECTIVIDADE
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged().listen(
      (bool isOnline) async {
        final wasOffline = !_isOnline;
        _isOnline = isOnline;
        
        debugPrint('🔄 Conectividade mudou: ${_isOnline ? "Online" : "Offline"}');
        
        if (_isOnline) {
          _updateStatus(SyncStatus.idle);
          
          // Se estava offline e agora está online, sincroniza
          if (wasOffline) {
            debugPrint('📡 Voltou online - iniciando sincronização...');
            await syncAll();
          }
        } else {
          _updateStatus(SyncStatus.offline);
        }
      },
    );
  }
  
  /// ⏰ CONFIGURA SYNC PERIÓDICO INTELIGENTE
  void _setupPeriodicSync() {
    // Sincroniza a cada 5 minutos quando online - mas só se necessário
    _periodicSync = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_isOnline && _status == SyncStatus.idle) {
        debugPrint('⏰ Verificação periódica iniciada');
        
        // 1️⃣ PRIMEIRO: Verificar se há mudanças para sincronizar
        final needsSync = await _checkWhatNeedsSync();
        
        if (needsSync.isEmpty) {
          debugPrint('✅ Tudo atualizado - pulando sync periódico');
          return;
        }
        
        debugPrint('📋 Tabelas com mudanças: ${needsSync.keys.join(', ')}');
        
        // 2️⃣ SEGUNDO: Executar sync inteligente apenas onde necessário
        await _performSmartSync(needsSync);
      }
    });
  }

  /// 🔍 VERIFICAÇÃO INTELIGENTE - Quais tabelas precisam de sync?
  Future<Map<String, bool>> _checkWhatNeedsSync() async {
    if (_localDB.currentUserId == null) return {};
    
    final needsSync = <String, bool>{};
    final userId = _localDB.currentUserId!;
    
    try {
      // Para cada tabela, verificar se há mudanças (query super leve)
      for (final table in _syncTables) {
        final hasChanges = await _tableHasChanges(table, userId);
        if (hasChanges) {
          needsSync[table] = true;
          debugPrint('📝 $table tem mudanças para sincronizar');
        }
      }
      
      return needsSync;
    } catch (e) {
      debugPrint('❌ Erro ao verificar mudanças: $e');
      return {};
    }
  }
  
  /// 🔍 VERIFICAR SE TABELA TEM MUDANÇAS (query COUNT super rápida)
  Future<bool> _tableHasChanges(String tableName, String userId) async {
    final lastSync = _lastSyncTimestamps[tableName] ?? 
      DateTime.now().subtract(const Duration(days: 90)).toIso8601String();
    
    try {
      // Query apenas para contar - super leve e rápida
      final result = await Supabase.instance.client
        .from(tableName)
        .select('id')
        .eq('usuario_id', userId)
        .gt('updated_at', lastSync)
        .limit(1); // Só precisa saber se existe pelo menos 1
      
      final hasChanges = result.isNotEmpty;
      debugPrint('🔍 $tableName: ${result.length} mudanças desde $lastSync');
      return hasChanges;
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar $tableName: $e');
      return false; // Em caso de erro, assume que não há mudanças
    }
  }
  
  /// 📥 SYNC INTELIGENTE - Baixa apenas o necessário
  Future<void> _performSmartSync(Map<String, bool> needsSync) async {
    if (needsSync.isEmpty) return;
    
    _updateStatus(SyncStatus.syncing);
    debugPrint('🔄 Iniciando sync inteligente para ${needsSync.length} tabelas');
    
    try {
      // 1. Upload mudanças locais primeiro
      await _uploadPendingChanges();
      
      // 2. Download apenas tabelas com mudanças
      for (final table in needsSync.keys) {
        await _downloadTableIncremental(table);
      }
      
      debugPrint('✅ Sync inteligente concluído');
      _updateStatus(SyncStatus.idle);
    } catch (e) {
      debugPrint('❌ Erro no sync inteligente: $e');
      _updateStatus(SyncStatus.error);
      rethrow;
    }
  }
  
  /// 📥 DOWNLOAD INCREMENTAL GENÉRICO (funciona para qualquer tabela)
  Future<void> _downloadTableIncremental(String tableName) async {
    if (_localDB.currentUserId == null) return;
    
    final userId = _localDB.currentUserId!;
    final lastSync = _lastSyncTimestamps[tableName] ?? 
      DateTime.now().subtract(const Duration(days: 90)).toIso8601String();
    
    debugPrint('📥 Sync incremental de $tableName desde $lastSync');
    
    try {
      // Buscar apenas registros novos/modificados
      final records = await Supabase.instance.client
        .from(tableName)
        .select()
        .eq('usuario_id', userId)
        .gt('updated_at', lastSync)
        .order('updated_at');
      
      debugPrint('📦 $tableName: ${records.length} registros para atualizar');
      
      // Processar cada registro
      for (final record in records) {
        await _processIncrementalRecord(tableName, record);
      }
      
      // Atualizar timestamp da tabela
      final now = DateTime.now().toIso8601String();
      _lastSyncTimestamps[tableName] = now;
      await _saveTimestamp(tableName, now);
      
      debugPrint('✅ $tableName sincronizada - novo timestamp: $now');
      
    } catch (e) {
      debugPrint('❌ Erro ao sincronizar $tableName: $e');
      rethrow;
    }
  }
  
  /// 🔄 PROCESSAR REGISTRO INCREMENTAL
  Future<void> _processIncrementalRecord(String tableName, Map<String, dynamic> record) async {
    try {
      // Adicionar campos de controle
      record['sync_status'] = 'synced';
      record['last_sync'] = DateTime.now().toIso8601String();
      
      // Verificar se já existe localmente
      final existing = await _localDB.select(
        tableName,
        where: 'id = ?',
        whereArgs: [record['id']],
      );
      
      // Preparar para SQLite (boolean → integer)
      final sqliteData = _prepareSQLiteData(record);
      
      if (existing.isEmpty) {
        // Inserir novo registro
        await _localDB.database!.insert(tableName, sqliteData);
        debugPrint('➕ $tableName: Novo registro ${record['id']}');
      } else {
        // Atualizar registro existente
        await _localDB.database!.update(
          tableName,
          sqliteData,
          where: 'id = ?',
          whereArgs: [record['id']],
        );
        debugPrint('🔄 $tableName: Atualizado registro ${record['id']}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar registro $tableName.${record['id']}: $e');
    }
  }
  
  /// 💾 SALVAR TIMESTAMP DE SYNC
  Future<void> _saveTimestamp(String tableName, String timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_$tableName', timestamp);
    } catch (e) {
      debugPrint('⚠️ Erro ao salvar timestamp de $tableName: $e');
    }
  }
  
  /// 🔄 SINCRONIZAÇÃO INICIAL (após login) - INTELIGENTE
  Future<void> syncInitial() async {
    if (!_isOnline || _localDB.currentUserId == null) {
      debugPrint('⚠️ Sync inicial cancelado - offline ou sem usuário');
      return;
    }
    
    debugPrint('🔄 Iniciando sincronização inicial...');
    _updateStatus(SyncStatus.syncing);
    
    try {
      final userId = _localDB.currentUserId!;
      
      // 🎯 DECISÃO INTELIGENTE: Sync completo ou incremental?
      final shouldDoFullSync = await _shouldDoFullSync();
      
      if (shouldDoFullSync) {
        debugPrint('📥 Executando SYNC COMPLETO (login/reabrir após dias)');
        await _performFullSync(userId);
      } else {
        debugPrint('📥 Executando SYNC INCREMENTAL (uso normal)');
        await _performIncrementalSync(userId);
      }
      
      debugPrint('✅ Sincronização inicial concluída');
      _updateStatus(SyncStatus.idle);
      
      // Salvar timestamp de último sync completo se foi feito
      if (shouldDoFullSync) {
        await _saveLastFullSyncDate();
      }
      
    } catch (e) {
      debugPrint('❌ Erro na sincronização inicial: $e');
      _updateStatus(SyncStatus.error);
    }
  }
  
  /// 🤔 VERIFICAR SE DEVE FAZER SYNC COMPLETO
  Future<bool> _shouldDoFullSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Primeira vez (sem timestamp) → Sync completo
      final lastFullSync = prefs.getString('last_full_sync');
      if (lastFullSync == null) {
        debugPrint('🔍 Primeira sincronização → Sync completo');
        return true;
      }
      
      // 2. Última sync > 7 dias → Sync completo
      final daysSinceSync = DateTime.now()
        .difference(DateTime.parse(lastFullSync))
        .inDays;
      
      if (daysSinceSync > 7) {
        debugPrint('🔍 Última sync há $daysSinceSync dias → Sync completo');
        return true;
      }
      
      // 3. App fechado > 24h → Sync completo
      final lastAppOpen = prefs.getString('last_app_open');
      if (lastAppOpen != null) {
        final hoursClosedApp = DateTime.now()
          .difference(DateTime.parse(lastAppOpen))
          .inHours;
          
        if (hoursClosedApp > 24) {
          debugPrint('🔍 App fechado por ${hoursClosedApp}h → Sync completo');
          return true;
        }
      }
      
      debugPrint('🔍 Condições normais → Sync incremental');
      return false;
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar tipo de sync, usando completo: $e');
      return true; // Em caso de erro, prefere sync completo
    }
  }
  
  /// 📥 SYNC COMPLETO (login/reabrir após dias)
  Future<void> _performFullSync(String userId) async {
    debugPrint('📦 Sync completo: Ano anterior + atual + 2 meses futuros');
    
    // Resetar todos os timestamps para forçar download completo
    _lastSyncTimestamps.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final table in _syncTables) {
      await prefs.remove('last_sync_$table');
    }
    
    // Download completo de todas as tabelas
    await _downloadUserData(userId);
    await _downloadUserSubcategories(userId);
    await _downloadUserAccounts(userId);
    await _downloadCartoes(userId);
    
    // Transações: ano anterior + atual + 2 meses futuros
    await _downloadTransactionsFullRange(userId);

    // Sincronizar metadados dos grupos após download das transações
    await _syncGruposMetadados(userId);

    // Atualizar timestamps de todas as tabelas
    final now = DateTime.now().toIso8601String();
    for (final table in _syncTables) {
      _lastSyncTimestamps[table] = now;
      await _saveTimestamp(table, now);
    }
  }
  
  /// 📥 SYNC INCREMENTAL (uso normal)
  Future<void> _performIncrementalSync(String userId) async {
    debugPrint('🔄 Sync incremental: Apenas mudanças desde última sync');
    
    // Verificar quais tabelas precisam de sync
    final needsSync = await _checkWhatNeedsSync();
    
    if (needsSync.isEmpty) {
      debugPrint('✅ Nenhuma mudança detectada');
      return;
    }
    
    // Executar sync apenas onde necessário
    await _performSmartSync(needsSync);
  }
  
  /// 📅 DOWNLOAD DE TRANSAÇÕES - RANGE COMPLETO
  Future<void> _downloadTransactionsFullRange(String userId) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, 1, 1); // Ano anterior
      final endDate = DateTime(now.year, now.month + 2, 0); // +2 meses futuros
      
      debugPrint('📅 Baixando transações: ${startDate.year}-01-01 até ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}');
      
      final transactions = await Supabase.instance.client
        .from('transacoes')
        .select()
        .eq('usuario_id', userId)
        .gte('data', startDate.toIso8601String().split('T')[0])
        .lte('data', endDate.toIso8601String().split('T')[0])
        .order('updated_at');
      
      debugPrint('📦 ${transactions.length} transações encontradas no range completo');
      
      // Processar todas as transações
      for (final transaction in transactions) {
        await _processIncrementalRecord('transacoes', transaction);
      }
      
    } catch (e) {
      debugPrint('❌ Erro no download completo de transações: $e');
    }
  }
  
  /// 💾 SALVAR DATA DO ÚLTIMO SYNC COMPLETO
  Future<void> _saveLastFullSyncDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_full_sync', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Erro ao salvar data do sync completo: $e');
    }
  }
  
  /// 🔄 SINCRONIZAÇÃO COMPLETA
  Future<void> syncAll() async {
    debugPrint('🔄 syncAll() CHAMADO');
    debugPrint('🌐 isOnline: $_isOnline');
    debugPrint('📊 status: $_status');
    debugPrint('👤 userId: ${_localDB.currentUserId}');
    
    if (!_isOnline || _status == SyncStatus.syncing || _localDB.currentUserId == null) {
      debugPrint('❌ SYNC CANCELADO - Condições não atendidas');
      return;
    }
    
    debugPrint('🔄 Iniciando sincronização completa...');
    _updateStatus(SyncStatus.syncing);
    
    try {
      // 1. Envia dados locais pendentes para o servidor
      await _uploadPendingChanges();
      
      // 2. Baixa mudanças do servidor
      await _downloadServerChanges();
      
      debugPrint('✅ Sincronização completa concluída');
      _updateStatus(SyncStatus.idle);
      
    } catch (e) {
      debugPrint('❌ Erro na sincronização completa: $e');
      _updateStatus(SyncStatus.error);
      
      // Tenta novamente em 1 minuto
      Timer(const Duration(minutes: 1), () async {
        if (_isOnline && _status == SyncStatus.error) {
          await syncAll();
        }
      });
    }
  }
  
  /// ⬆️ ENVIA DADOS PENDENTES PARA O SERVIDOR
  Future<void> _uploadPendingChanges() async {
    debugPrint('⬆️ Enviando dados pendentes...');
    
    try {
      final pendingItems = await _localDB.getPendingSyncItems();
      debugPrint('📦 Itens pendentes encontrados: ${pendingItems.length}');
      
      for (final item in pendingItems) {
        debugPrint('🔄 Processando: ${item['operation']} em ${item['table_name']}.${item['record_id']}');
        await _processSyncItem(item);
      }
      
      debugPrint('✅ ${pendingItems.length} itens enviados');
      
    } catch (e) {
      debugPrint('❌ Erro ao enviar dados pendentes: $e');
      rethrow;
    }
  }
  
  /// 📋 PROCESSA ITEM DA FILA DE SYNC COM DETECÇÃO DE READ-ONLY
  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    try {
      final tableName = item['table_name'] as String;
      final recordId = item['record_id'] as String;
      final operation = item['operation'] as String;
      final syncId = item['id'] as int?;
      
      debugPrint('🔄 Processando: $operation em $tableName.$recordId (sync_id: $syncId)');
      
      // 🔍 VERIFICAÇÃO PRÉ-OPERAÇÃO: Testa se Supabase está realmente online
      try {
        debugPrint('🌐 Testando conectividade Supabase...');
        await Supabase.instance.client.from('perfil_usuario').select('id').limit(1);
        debugPrint('✅ Supabase: Conectado');
      } catch (supabaseError) {
        debugPrint('❌ SUPABASE OFFLINE ou com erro: $supabaseError');
        throw Exception('Supabase inacessível: $supabaseError');
      }
      
      switch (operation.toUpperCase()) {
        case 'INSERT':
          await _uploadInsert(tableName, recordId);
          break;
        case 'UPDATE':
          await _uploadUpdate(tableName, recordId);
          break;
        case 'DELETE':
          await _uploadDelete(tableName, recordId);
          break;
        case 'ARCHIVE':
          await _uploadArchive(tableName, recordId);
          break;
        case 'UNARCHIVE':
          await _uploadUnarchive(tableName, recordId);
          break;
        case 'SOFT_DELETE':
          await _uploadSoftDelete(tableName, recordId);
          break;
        case 'SALDO_CORRECTION':
          await _uploadSaldoCorrection(tableName, recordId);
          break;
        default:
          debugPrint('⚠️ Operação não suportada: $operation para $tableName.$recordId');
          break;
      }
      
      // Remove da fila após sucesso
      await _localDB.removeSyncItem(item['id'] as int);
      debugPrint('✅ Item processado com sucesso: $operation em $tableName.$recordId');
      
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      debugPrint('❌ ERRO DETALHADO no processamento: $e');
      debugPrint('📊 Tabela: ${item['table_name']}, Operação: ${item['operation']}, RecordId: ${item['record_id']}');
      
      // ✅ DETECÇÃO ESPECÍFICA DE ERRO READ-ONLY
      if (errorMessage.contains('read-only') || 
          errorMessage.contains('unsupported operation') ||
          errorMessage.contains('database is locked') ||
          errorMessage.contains('readonly database')) {
        
        debugPrint('🚨 ERRO READ-ONLY DETECTADO: $e');
        debugPrint('🔧 Tentando corrigir problema read-only automaticamente...');
        
        // Estratégia 1: Limpar queue problemática
        await _handleReadOnlyError(item);
        return;
      }
      
      // ✅ DETECÇÃO DE ERRO SUPABASE
      if (errorMessage.contains('supabase') || 
          errorMessage.contains('postgresql') ||
          errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        
        debugPrint('🌐 ERRO DE CONECTIVIDADE SUPABASE: $e');
        // Não remove o item, mantém para retry
        await _handleSyncItemRetry(item);
        return;
      }
      
      debugPrint('❌ Erro genérico ao processar sync item: $e');
      
      // Para outros erros, incrementa tentativas
      await _handleSyncItemRetry(item);
    }
  }

  /// 🔧 TRATA ERRO READ-ONLY ESPECIFICAMENTE
  Future<void> _handleReadOnlyError(Map<String, dynamic> item) async {
    try {
      debugPrint('🔧 Tratando erro read-only para item: ${item['table_name']}.${item['record_id']}');
      
      // EXECUTA DIAGNÓSTICO COMPLETO QUANDO DETECTA READ-ONLY
      debugPrint('🔍 EXECUTANDO DIAGNÓSTICO COMPLETO DEVIDO A ERRO READ-ONLY...');
      final diagnostico = await diagnosticarECorrigirSQLite();
      
      // Log detalhado do diagnóstico
      debugPrint('📊 === RELATÓRIO COMPLETO DE DIAGNÓSTICO ===');
      debugPrint('❌ PROBLEMAS ENCONTRADOS:');
      for (final problema in diagnostico['problemas_encontrados']) {
        debugPrint('   • $problema');
      }
      debugPrint('✅ CORREÇÕES APLICADAS:');
      for (final correcao in diagnostico['correcoes_aplicadas']) {
        debugPrint('   • $correcao');
      }
      debugPrint('📋 DETALHES TÉCNICOS:');
      for (final detalhe in diagnostico['detalhes_tecnicos']) {
        debugPrint('   • $detalhe');
      }
      debugPrint('📊 === FIM DO RELATÓRIO ===');
      
      // 🔄 APÓS CORREÇÃO, TENTA REPROCESSAR O ITEM
      debugPrint('🔄 Tentando reprocessar item após correção read-only...');
      try {
        final tableName = item['table_name'] as String;
        final recordId = item['record_id'] as String;
        final operation = item['operation'] as String;
        
        debugPrint('🔍 REPROCESSAMENTO DETALHADO:');
        debugPrint('   Tabela: $tableName');
        debugPrint('   Operação: $operation');
        debugPrint('   Record ID: $recordId');
        
        // Tenta enviar novamente após correção
        switch (operation.toUpperCase()) {
          case 'INSERT':
            debugPrint('🔄 Reprocessando INSERT...');
            await _uploadInsert(tableName, recordId);
            break;
          case 'UPDATE':
            debugPrint('🔄 Reprocessando UPDATE...');
            await _uploadUpdate(tableName, recordId);
            break;
          case 'DELETE':
            debugPrint('🔄 Reprocessando DELETE...');
            await _uploadDelete(tableName, recordId);
            break;
          case 'ARCHIVE':
            debugPrint('🔄 Reprocessando ARCHIVE...');
            await _uploadArchive(tableName, recordId);
            break;
          case 'UNARCHIVE':
            debugPrint('🔄 Reprocessando UNARCHIVE...');
            await _uploadUnarchive(tableName, recordId);
            break;
          case 'SOFT_DELETE':
            debugPrint('🔄 Reprocessando SOFT_DELETE...');
            await _uploadSoftDelete(tableName, recordId);
            break;
          case 'SALDO_CORRECTION':
            debugPrint('🔄 Reprocessando SALDO_CORRECTION...');
            await _uploadSaldoCorrection(tableName, recordId);
            break;
          default:
            debugPrint('⚠️ Operação não suportada no reprocessamento: $operation');
            break;
        }
        
        // ✅ Remove apenas se o reprocessamento foi bem-sucedido
        await _localDB.removeSyncItem(item['id'] as int);
        debugPrint('✅ Item reprocessado e enviado com sucesso após correção');
        debugPrint('📊 Tabela: ${item['table_name']}, Operação: ${item['operation']}');
        
      } catch (reprocessError) {
        debugPrint('❌ Falha no reprocessamento após correção: $reprocessError');
        
        // Incrementa tentativas para retry posterior em vez de remover
        await _handleSyncItemRetry(item);
        debugPrint('📊 Item mantido na queue para nova tentativa');
      }
      
    } catch (e) {
      debugPrint('❌ Erro CRÍTICO ao tratar problema read-only: $e');
      
      // Fallback extremo: remove o item mesmo com erro
      try {
        await _localDB.removeSyncItem(item['id'] as int);
        debugPrint('🗑️ Item removido via fallback extremo');
      } catch (fallbackError) {
        debugPrint('❌ FALHA TOTAL: Não foi possível remover item: $fallbackError');
      }
    }
  }

  /// ♻️ TRATA RETRY DE ITENS COM ERRO
  Future<void> _handleSyncItemRetry(Map<String, dynamic> item) async {
    try {
      final attempts = (item['attempts'] as int?) ?? 0;
      const maxAttempts = 3;
      
      if (attempts >= maxAttempts) {
        debugPrint('🚫 Item removido após $maxAttempts tentativas: ${item['table_name']}.${item['record_id']}');
        await _localDB.removeSyncItem(item['id'] as int);
      } else {
        // Incrementa tentativas no banco
        await _localDB.database?.update(
          'sync_queue',
          {'attempts': attempts + 1},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        debugPrint('⏳ Item mantido na fila para retry (tentativa ${attempts + 1}/$maxAttempts)');
      }
    } catch (e) {
      debugPrint('❌ Erro ao tratar retry: $e');
    }
  }
  
  /// ⬆️ UPLOAD INSERT
  Future<void> _uploadInsert(String tableName, String recordId) async {
    debugPrint('📤 Iniciando UPLOAD INSERT para $tableName.$recordId');
    
    try {
      // 🔍 PASSO 1: Buscar dados locais
      debugPrint('🔍 Buscando dados locais...');
      final records = await _localDB.select(
        tableName,
        where: 'id = ?',
        whereArgs: [recordId],
      );
      
      if (records.isEmpty) {
        debugPrint('❌ Registro não encontrado localmente: $tableName.$recordId');
        return;
      }
      
      final record = records.first;
      debugPrint('✅ Dados locais encontrados: ${record.keys.join(', ')}');
      
      // 🔍 PASSO 2: Preparar dados para Supabase
      debugPrint('🔄 Preparando dados para Supabase...');
      final supabaseData = Map<String, dynamic>.from(record);
      
      debugPrint('🔄 Removendo campos de controle do INSERT...');
      supabaseData.remove('sync_status');
      supabaseData.remove('last_sync');
      debugPrint('✅ Campos de controle removidos do INSERT');
      
      // 🎯 LIMPA CAMPOS INVÁLIDOS PARA SUPABASE
      debugPrint('🧹 Iniciando limpeza de campos para INSERT...');
      final cleanData = _cleanRecordForSupabase(supabaseData, tableName);
      debugPrint('🧹 Limpeza do INSERT concluída');
      
      debugPrint('📊 Dados para inserir: ${cleanData.keys.join(', ')}');
      debugPrint('📋 ID do registro: ${cleanData['id']}');
      
      // 🔍 PASSO 3: Verificar se já existe no Supabase
      try {
        debugPrint('🔍 Verificando se já existe no Supabase...');
        final existing = await Supabase.instance.client
            .from(tableName)
            .select('id')
            .eq('id', recordId)
            .maybeSingle();
            
        if (existing != null) {
          debugPrint('⚠️ Registro já existe no Supabase, fazendo UPDATE em vez de INSERT');
          await _uploadUpdate(tableName, recordId);
          return;
        }
        debugPrint('✅ Registro não existe, prosseguindo com INSERT');
      } catch (checkError) {
        debugPrint('⚠️ Erro ao verificar existência (prosseguindo): $checkError');
      }
      
      // 🔍 PASSO 4: Executar INSERT no Supabase
      debugPrint('💾 Executando INSERT no Supabase...');
      final result = await Supabase.instance.client
          .from(tableName)
          .insert(cleanData)
          .select();
      
      debugPrint('✅ INSERT executado com sucesso: ${result.length} registros inseridos');
      
      // 🔍 PASSO 5: Marcar como sincronizado no SQLite
      debugPrint('🔄 Marcando como sincronizado no SQLite...');
      await _localDB.update(
        tableName,
        {
          'sync_status': 'synced',
          'last_sync': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [recordId],
      );
      
      debugPrint('✅ UPLOAD INSERT concluído com sucesso para $tableName.$recordId');
      
    } catch (e) {
      debugPrint('❌ FALHA no UPLOAD INSERT para $tableName.$recordId: $e');
      debugPrint('📊 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  /// ⬆️ UPLOAD UPDATE (filtrado para campos válidos do Supabase)
  Future<void> _uploadUpdate(String tableName, String recordId) async {
    final records = await _localDB.select(
      tableName,
      where: 'id = ?',
      whereArgs: [recordId],
    );
    
    if (records.isEmpty) return;
    
    final record = records.first;
    debugPrint('🔍 Campos locais encontrados: ${record.keys.toList()}');
    
    try {
      debugPrint('🔄 Criando cópia mutável do record...');
      // ⚡ CRIA CÓPIA MUTÁVEL - O record original pode ser readonly!
      final mutableRecord = Map<String, dynamic>.from(record);
      debugPrint('✅ Cópia mutável criada');
      
      debugPrint('🔄 Removendo campos de controle local...');
      // Remove campos de controle local
      mutableRecord.remove('sync_status');
      mutableRecord.remove('last_sync');
      mutableRecord.remove('created_at'); // Não atualiza created_at
      debugPrint('✅ Campos de controle removidos');
      
      // 🎯 LIMPA CAMPOS INVÁLIDOS PARA SUPABASE
      debugPrint('🧹 Iniciando limpeza de campos para Supabase...');
      final cleanRecord = _cleanRecordForSupabase(mutableRecord, tableName);
      debugPrint('🧹 Limpeza concluída');
      
      debugPrint('📤 Enviando UPDATE para $tableName.$recordId com campos: ${cleanRecord.keys.toList()}');
      
      await Supabase.instance.client
          .from(tableName)
          .update(cleanRecord)
          .eq('id', recordId);
      
      // Marca como sincronizado
      await _localDB.update(
        tableName,
        {
          'sync_status': 'synced',
          'last_sync': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [recordId],
      );
      
      debugPrint('✅ UPDATE processado com sucesso para $tableName.$recordId');
      
    } catch (e) {
      debugPrint('❌ Erro durante preparação/envio do UPDATE: $e');
      rethrow;
    }
  }
  
  /// ⬆️ UPLOAD DELETE
  Future<void> _uploadDelete(String tableName, String recordId) async {
    await Supabase.instance.client
        .from(tableName)
        .delete()
        .eq('id', recordId);
  }

  /// 📂 UPLOAD ARCHIVE (arquivar)
  Future<void> _uploadArchive(String tableName, String recordId) async {
    final records = await _localDB.select(
      tableName,
      where: 'id = ?',
      whereArgs: [recordId],
    );
    
    if (records.isEmpty) return;
    
    final record = records.first;
    final updateData = {
      'ativo': false,
      'updated_at': record['updated_at'] ?? DateTime.now().toIso8601String(),
    };
    
    // Inclui observações se for conta
    if (tableName == 'contas' && record['observacoes'] != null) {
      updateData['observacoes'] = record['observacoes'];
    }
    
    await Supabase.instance.client
        .from(tableName)
        .update(updateData)
        .eq('id', recordId);
        
    debugPrint('📂 $tableName.$recordId arquivado no Supabase');
  }

  /// 📤 UPLOAD UNARCHIVE (desarquivar)
  Future<void> _uploadUnarchive(String tableName, String recordId) async {
    final updateData = {
      'ativo': true,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await Supabase.instance.client
        .from(tableName)
        .update(updateData)
        .eq('id', recordId);
        
    debugPrint('📤 $tableName.$recordId desarquivado no Supabase');
  }

  /// 🗑️ UPLOAD SOFT DELETE (desativar)
  Future<void> _uploadSoftDelete(String tableName, String recordId) async {
    final updateData = {
      'ativo': false,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await Supabase.instance.client
        .from(tableName)
        .update(updateData)
        .eq('id', recordId);
        
    debugPrint('🗑️ $tableName.$recordId soft delete no Supabase');
  }

  /// 💰 UPLOAD SALDO CORRECTION (correção de saldo)
  Future<void> _uploadSaldoCorrection(String tableName, String recordId) async {
    final records = await _localDB.select(
      tableName,
      where: 'id = ?',
      whereArgs: [recordId],
    );
    
    if (records.isEmpty) return;
    
    final record = records.first;
    final updateData = {
      'saldo_inicial': record['saldo_inicial'],
      'updated_at': record['updated_at'] ?? DateTime.now().toIso8601String(),
    };
    
    await Supabase.instance.client
        .from(tableName)
        .update(updateData)
        .eq('id', recordId);
        
    debugPrint('💰 $tableName.$recordId saldo corrigido no Supabase');
  }
  
  /// ⬇️ BAIXA MUDANÇAS DO SERVIDOR (método legado - use _performSmartSync)
  Future<void> _downloadServerChanges() async {
    debugPrint('⬇️ Baixando mudanças do servidor (modo legado)...');
    
    if (_localDB.currentUserId != null) {
      final userId = _localDB.currentUserId!;
      
      // Usar sync incremental para todas as tabelas
      await _downloadUserData(userId);
      await _downloadUserSubcategories(userId);
      await _downloadUserAccounts(userId);
      await _downloadCartoes(userId);
      
      // ✅ ADICIONADO: Download de transações que estava faltando
      await _downloadRecentTransactions(userId);

      // Sincronizar metadados dos grupos após download das transações
      await _syncGruposMetadados(userId);
    }
  }

  /// ⬇️ BAIXA CARTÕES DO SERVIDOR
  Future<void> _downloadCartoes(String userId) async {
    try {
      debugPrint('📥 Baixando cartões do Supabase...');
      
      final cartoes = await Supabase.instance.client
          .from('cartoes')
          .select()
          .eq('usuario_id', userId)
          .order('created_at');
          
      debugPrint('📦 Cartões encontrados no Supabase: ${cartoes.length}');

      for (final cartaoData in cartoes) {
        debugPrint('🔍 Processando cartão do servidor: ${cartaoData['nome']}');
        
        // Verificar se já existe localmente
        final existing = await _localDB.database?.query(
          'cartoes',
          where: 'id = ?',
          whereArgs: [cartaoData['id']],
        );
        
        final cartaoDataForSQLite = {
          ...cartaoData,
          'ativo': cartaoData['ativo'] ? 1 : 0,
          'sync_status': 'synced',
          'last_sync': DateTime.now().toIso8601String(),
        };
        
        if (existing == null || existing.isEmpty) {
          // Inserir novo
          debugPrint('➕ Inserindo novo cartão: ${cartaoData['nome']}');
          await _localDB.database?.insert('cartoes', cartaoDataForSQLite);
        } else {
          // Atualizar existente
          debugPrint('🔄 Atualizando cartão existente: ${cartaoData['nome']}');
          await _localDB.database?.update(
            'cartoes',
            cartaoDataForSQLite,
            where: 'id = ?',
            whereArgs: [cartaoData['id']],
          );
        }
      }
      
      debugPrint('✅ Download de cartões concluído: ${cartoes.length} processados');
      
    } catch (e) {
      debugPrint('❌ Erro ao baixar cartões: $e');
    }
  }
  
  /// ⬇️ BAIXA DADOS DO USUÁRIO
  Future<void> _downloadUserData(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('perfil_usuario')
          .select()
          .eq('id', userId)
          .single();
      
      // Atualiza ou insere no banco local
      final existing = await _localDB.select(
        'perfil_usuario',
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      response['sync_status'] = 'synced';
      response['last_sync'] = DateTime.now().toIso8601String();
      
      final sqliteData = _prepareSQLiteData(response);
      if (existing.isEmpty) {
        await _localDB.database!.insert('perfil_usuario', sqliteData);
      } else {
        await _localDB.database!.update(
          'perfil_usuario',
          sqliteData,
          where: 'id = ?',
          whereArgs: [userId],
        );
      }
      
    } catch (e) {
      debugPrint('⚠️ Erro ao baixar dados do usuário: $e');
    }
  }
  
  // Cache para evitar sync desnecessário
  DateTime? _lastCategoriaSync;
  DateTime? _lastSubcategoriaSync;
  static const _syncCooldown = Duration(minutes: 5); // 5 minutos de cooldown

  /// ⬇️ BAIXA CATEGORIAS DO USUÁRIO (método público para uso sob demanda)
  Future<void> syncCategorias({bool force = false}) async {
    if (_localDB.currentUserId == null) return;
    
    // Verificar se já fez sync recentemente (apenas se não for forçado)
    final now = DateTime.now();
    if (!force && _lastCategoriaSync != null && 
        now.difference(_lastCategoriaSync!) < _syncCooldown) {
      debugPrint('⏰ Sync de categorias pulado - feito há ${now.difference(_lastCategoriaSync!).inMinutes} min');
      return;
    }
    
    debugPrint(force ? '🔄 FORÇANDO sync de categorias...' : '🔄 Sync normal de categorias...');
    await _downloadUserCategories(_localDB.currentUserId!);
    _lastCategoriaSync = now;
  }

  /// ⬇️ BAIXA CATEGORIAS DO USUÁRIO
  Future<void> _downloadUserCategories(String userId) async {
    try {
      debugPrint('📂 Baixando categorias do Supabase...');
      final categories = await Supabase.instance.client
          .from('categorias')
          .select()
          .eq('usuario_id', userId);
      
      debugPrint('📦 Categorias encontradas no Supabase: ${categories.length}');
      
      for (final category in categories) {
        debugPrint('🔄 Processando categoria do servidor: ${category['nome']}');
        debugPrint('🔍 Categoria ${category['nome']} - ID: ${category['id']}');
        debugPrint('🔍 Ativo original (Supabase): ${category['ativo']} (${category['ativo'].runtimeType})');
        
        category['sync_status'] = 'synced';
        category['last_sync'] = DateTime.now().toIso8601String();
        
        final existing = await _localDB.select(
          'categorias',
          where: 'id = ?',
          whereArgs: [category['id']],
        );
        
        final sqliteData = _prepareSQLiteData(category);
        debugPrint('🔍 Ativo convertido (SQLite): ${sqliteData['ativo']}');
        
        if (existing.isEmpty) {
          await _localDB.database!.insert('categorias', sqliteData);
          debugPrint('✅ Categoria ${category['nome']} inserida no SQLite');
        } else {
          await _localDB.database!.update(
            'categorias',
            sqliteData,
            where: 'id = ?',
            whereArgs: [category['id']],
          );
          debugPrint('🔄 Categoria ${category['nome']} atualizada no SQLite');
        }
      }
      
      debugPrint('✅ Download de categorias concluído: ${categories.length} processadas');
    } catch (e) {
      debugPrint('⚠️ Erro ao baixar categorias: $e');
    }
  }
  
  /// ⬇️ BAIXA SUBCATEGORIAS DO USUÁRIO (método público para uso sob demanda)
  Future<void> syncSubcategorias({bool force = false}) async {
    if (_localDB.currentUserId == null) return;
    
    // Verificar se já fez sync recentemente (apenas se não for forçado)
    final now = DateTime.now();
    if (!force && _lastSubcategoriaSync != null && 
        now.difference(_lastSubcategoriaSync!) < _syncCooldown) {
      debugPrint('⏰ Sync de subcategorias pulado - feito há ${now.difference(_lastSubcategoriaSync!).inMinutes} min');
      return;
    }
    
    debugPrint(force ? '🔄 FORÇANDO sync de subcategorias...' : '🔄 Sync normal de subcategorias...');
    await _downloadUserSubcategories(_localDB.currentUserId!);
    _lastSubcategoriaSync = now;
  }

  /// ⬇️ BAIXA SUBCATEGORIAS DO USUÁRIO
  Future<void> _downloadUserSubcategories(String userId) async {
    try {
      debugPrint('📂 Baixando subcategorias do Supabase...');
      
      final subcategories = await Supabase.instance.client
          .from('subcategorias')
          .select()
          .eq('usuario_id', userId);
      
      debugPrint('📦 Subcategorias encontradas no Supabase: ${subcategories.length}');
      
      for (final subcategory in subcategories) {
        subcategory['sync_status'] = 'synced';
        subcategory['last_sync'] = DateTime.now().toIso8601String();
        
        final existing = await _localDB.select(
          'subcategorias',
          where: 'id = ?',
          whereArgs: [subcategory['id']],
        );
        
        final sqliteData = _prepareSQLiteData(subcategory);
        if (existing.isEmpty) {
          debugPrint('➕ Inserindo nova subcategoria: ${subcategory['nome']}');
          await _localDB.database!.insert('subcategorias', sqliteData);
        } else {
          debugPrint('🔄 Atualizando subcategoria existente: ${subcategory['nome']}');
          await _localDB.database!.update(
            'subcategorias',
            sqliteData,
            where: 'id = ?',
            whereArgs: [subcategory['id']],
          );
        }
      }
      
      debugPrint('✅ Download de subcategorias concluído: ${subcategories.length} processadas');
    } catch (e) {
      debugPrint('⚠️ Erro ao baixar subcategorias: $e');
    }
  }
  
  /// ⬇️ BAIXA CONTAS DO USUÁRIO
  Future<void> _downloadUserAccounts(String userId) async {
    try {
      debugPrint('🏦 SyncManager: Baixando contas com RPC...');
      
      // ✅ USA A MESMA RPC QUE O REACT E CONTASERVICE
      final response = await Supabase.instance.client.rpc(
        'ip_prod_obter_saldos_por_conta',
        params: {
          'p_usuario_id': userId,
          'p_incluir_inativas': true,
        },
      );
      
      if (response is List) {
        debugPrint('🏦 SyncManager: Processando ${response.length} contas da RPC...');
        
        for (final item in response) {
          // Converte dados da RPC para formato SQLite
          final account = {
            'id': item['conta_id'],
            'usuario_id': userId,
            'nome': item['conta_nome'],
            'tipo': item['conta_tipo'],
            'saldo_inicial': item['saldo_inicial'],
            'saldo': item['saldo_atual'], // ✅ SALDO CORRETO DA RPC!
            'cor': item['cor'],
            'banco': item['banco'],
            'icone': item['icone'],
            'ativo': item['ativa'] == true ? 1 : 0,
            'incluir_soma_total': item['incluir_soma'] == true ? 1 : 0,
            'observacoes': item['observacoes'],
            'created_at': item['created_at'],
            'updated_at': item['updated_at'],
            'sync_status': 'synced',
            'last_sync': DateTime.now().toIso8601String(),
          };
          
          debugPrint('🏦 SyncManager: ${item['conta_nome']} - Saldo: R\$ ${item['saldo_atual']}');
          
          final existing = await _localDB.select(
            'contas',
            where: 'id = ?',
            whereArgs: [account['id']],
          );
          
          final sqliteData = _prepareSQLiteData(account);
          if (existing.isEmpty) {
            await _localDB.database!.insert('contas', sqliteData);
          } else {
            await _localDB.database!.update(
              'contas',
              sqliteData,
              where: 'id = ?',
              whereArgs: [account['id']],
            );
          }
        }
        
        debugPrint('✅ SyncManager: ${response.length} contas sincronizadas com saldos corretos da RPC');
      } else {
        debugPrint('⚠️ SyncManager: RPC não retornou dados válidos');
      }
      
    } catch (e) {
      debugPrint('❌ SyncManager: Erro ao baixar contas: $e');
    }
  }
  
  /// ⬇️ BAIXA CARTÕES DO USUÁRIO
  Future<void> _downloadUserCards(String userId) async {
    try {
      final cards = await Supabase.instance.client
          .from('cartoes')
          .select()
          .eq('usuario_id', userId);
      
      for (final card in cards) {
        card['sync_status'] = 'synced';
        card['last_sync'] = DateTime.now().toIso8601String();
        
        final existing = await _localDB.select(
          'cartoes',
          where: 'id = ?',
          whereArgs: [card['id']],
        );
        
        final sqliteData = _prepareSQLiteData(card);
        if (existing.isEmpty) {
          await _localDB.database!.insert('cartoes', sqliteData);
        } else {
          await _localDB.database!.update(
            'cartoes',
            sqliteData,
            where: 'id = ?',
            whereArgs: [card['id']],
          );
        }
      }
      
    } catch (e) {
      debugPrint('⚠️ Erro ao baixar cartões: $e');
    }
  }
  
  /// ⬇️ BAIXA TRANSAÇÕES RECENTES E FUTURAS
  Future<void> _downloadRecentTransactions(String userId) async {
    try {
      // ✅ EXPANDIDO: 12 meses atrás até 12 meses à frente para cobrir todos os cenários
      final twelveMonthsAgo = DateTime.now().subtract(const Duration(days: 365));
      final twelveMonthsAhead = DateTime.now().add(const Duration(days: 365));
      
      debugPrint('📅 Buscando transações de ${twelveMonthsAgo.toIso8601String().split('T')[0]} até ${twelveMonthsAhead.toIso8601String().split('T')[0]}');
      
      final transactions = await Supabase.instance.client
          .from('transacoes')
          .select()
          .eq('usuario_id', userId)
          .gte('data', twelveMonthsAgo.toIso8601String().split('T')[0])
          .lte('data', twelveMonthsAhead.toIso8601String().split('T')[0])
          .limit(2000); // Aumentado limite para cobrir mais dados
      
      debugPrint('💰 ${transactions.length} transações encontradas no período de ${twelveMonthsAgo.toIso8601String().split('T')[0]} até ${twelveMonthsAhead.toIso8601String().split('T')[0]}');
      
      for (final transaction in transactions) {
        transaction['sync_status'] = 'synced';
        transaction['last_sync'] = DateTime.now().toIso8601String();
        
        final existing = await _localDB.select(
          'transacoes',
          where: 'id = ?',
          whereArgs: [transaction['id']],
        );
        
        final sqliteData = _prepareSQLiteData(transaction);
        if (existing.isEmpty) {
          await _localDB.database!.insert('transacoes', sqliteData);
        } else {
          await _localDB.database!.update(
            'transacoes',
            sqliteData,
            where: 'id = ?',
            whereArgs: [transaction['id']],
          );
        }
      }
      
    } catch (e) {
      debugPrint('⚠️ Erro ao baixar transações: $e');
    }
  }
  
  /// 📅 BAIXA TRANSAÇÕES DE UM PERÍODO ESPECÍFICO (para navegação de mês)
  Future<void> syncTransactionsForPeriod(DateTime targetMonth) async {
    if (!_isOnline || _localDB.currentUserId == null) return;
    
    try {
      final userId = _localDB.currentUserId!;
      
      // Período: mês inteiro + 2 meses antes e depois para cobrir parcelamentos
      final startDate = DateTime(targetMonth.year, targetMonth.month - 2, 1);
      final endDate = DateTime(targetMonth.year, targetMonth.month + 3, 0);
      
      debugPrint('🔄 Sincronizando transações para período específico: ${startDate.toIso8601String().split('T')[0]} até ${endDate.toIso8601String().split('T')[0]}');
      
      final transactions = await Supabase.instance.client
          .from('transacoes')
          .select()
          .eq('usuario_id', userId)
          .gte('data', startDate.toIso8601String().split('T')[0])
          .lte('data', endDate.toIso8601String().split('T')[0])
          .limit(500);
      
      debugPrint('💰 ${transactions.length} transações encontradas para o período');
      
      for (final transaction in transactions) {
        transaction['sync_status'] = 'synced';
        transaction['last_sync'] = DateTime.now().toIso8601String();
        
        final existing = await _localDB.select(
          'transacoes',
          where: 'id = ?',
          whereArgs: [transaction['id']],
        );
        
        final sqliteData = _prepareSQLiteData(transaction);
        if (existing.isEmpty) {
          await _localDB.database!.insert('transacoes', sqliteData);
          debugPrint('➕ Nova transação inserida: ${transaction['descricao']}');
        } else {
          await _localDB.database!.update(
            'transacoes',
            sqliteData,
            where: 'id = ?',
            whereArgs: [transaction['id']],
          );
        }
      }
      
      debugPrint('✅ Sincronização do período concluída');

    } catch (e) {
      debugPrint('❌ Erro ao sincronizar período: $e');
    }
  }

  /// 📊 SINCRONIZA METADADOS DOS GRUPOS DE TRANSAÇÕES
  Future<void> _syncGruposMetadados(String userId) async {
    try {
      print('🚀 [SYNC] === INICIANDO SYNC DOS METADADOS ===');
      debugPrint('📊 Sincronizando metadados dos grupos de transações...');

      // ✅ BUSCAR METADADOS AGREGADOS DO SUPABASE (dados completos)
      final metadados = await _downloadGruposMetadados(userId);

      // Salvar no banco local
      final service = GruposMetadadosService.instance;
      int processados = 0;

      for (final metadata in metadados) {
        await service.salvarMetadadosSupabase(metadata);
        processados++;
      }

      debugPrint('✅ $processados grupos de metadados sincronizados do Supabase');
      print('🏁 [SYNC] === SYNC DOS METADADOS FINALIZADO ===');

    } catch (e) {
      print('❌ [SYNC] ERRO NO SYNC DOS METADADOS: $e');
      debugPrint('❌ Erro ao sincronizar metadados dos grupos: $e');
    }
  }

  /// 📥 DOWNLOAD DOS METADADOS AGREGADOS DO SUPABASE
  Future<List<Map<String, dynamic>>> _downloadGruposMetadados(String userId) async {
    try {
      print('🔽 [DOWNLOAD] Iniciando download dos metadados do Supabase...');
      debugPrint('📥 Baixando metadados agregados do Supabase...');

      // Query agregada para buscar metadados de todos os grupos
      final response = await Supabase.instance.client
        .from('transacoes')
        .select('''
          grupo_recorrencia,
          grupo_parcelamento,
          descricao,
          valor,
          data,
          efetivado,
          tipo_recorrencia
        ''')
        .eq('usuario_id', userId)
        .or('grupo_recorrencia.not.is.null,grupo_parcelamento.not.is.null');

      print('📦 ${response.length} transações de grupos encontradas no Supabase');
      print('🔍 Query utilizada: SELECT grupo_recorrencia, grupo_parcelamento, descricao, valor, data, efetivado, tipo_recorrencia FROM transacoes WHERE usuario_id = $userId AND (grupo_recorrencia IS NOT NULL OR grupo_parcelamento IS NOT NULL)');

      // Debug: verificar se encontrou o grupo específico
      final grupoEspecifico = '255434f4-05be-4bea-b1fe-125757683fde';
      final transacoesDoGrupo = response.where((t) =>
        t['grupo_recorrencia'] == grupoEspecifico || t['grupo_parcelamento'] == grupoEspecifico
      ).toList();
      print('🎯 Grupo $grupoEspecifico: ${transacoesDoGrupo.length} transações encontradas');

      debugPrint('📦 ${response.length} transações de grupos encontradas no Supabase');

      // Processar e agregar por grupo
      Map<String, Map<String, dynamic>> grupos = {};

      for (final transacao in response) {
        final grupoId = (transacao['grupo_recorrencia'] ?? transacao['grupo_parcelamento']) as String?;
        if (grupoId == null) continue;

        final tipoGrupo = transacao['grupo_recorrencia'] != null ? 'recorrencia' : 'parcelamento';
        final isEfetivado = transacao['efetivado'] == true;
        final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
        final data = DateTime.parse(transacao['data']);

        if (!grupos.containsKey(grupoId)) {
          grupos[grupoId] = {
            'grupo_id': grupoId,
            'tipo_grupo': tipoGrupo,
            'descricao': transacao['descricao'],
            'valor_unitario': valor,
            'data_primeira': data,
            'data_ultima': data,
            'total_items': 0,
            'items_efetivados': 0,
            'items_pendentes': 0,
            'valor_total': 0.0,
            'valor_efetivado': 0.0,
            'valor_pendente': 0.0,
            'tipo_recorrencia': transacao['tipo_recorrencia'],
          };
        }

        final grupo = grupos[grupoId]!;
        grupo['total_items'] = grupo['total_items'] + 1;
        grupo['valor_total'] = grupo['valor_total'] + valor;

        if (isEfetivado) {
          grupo['items_efetivados'] = grupo['items_efetivados'] + 1;
          grupo['valor_efetivado'] = grupo['valor_efetivado'] + valor;
        } else {
          grupo['items_pendentes'] = grupo['items_pendentes'] + 1;
          grupo['valor_pendente'] = grupo['valor_pendente'] + valor;
        }

        // Atualizar datas extremas
        if (data.isBefore(grupo['data_primeira'])) {
          grupo['data_primeira'] = data;
        }
        if (data.isAfter(grupo['data_ultima'])) {
          grupo['data_ultima'] = data;
        }
      }

      debugPrint('✅ ${grupos.length} grupos processados');
      return grupos.values.toList();

    } catch (e) {
      debugPrint('❌ Erro ao baixar metadados do Supabase: $e');
      return [];
    }
  }

  /// Atualiza status e notifica listeners
  void _updateStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
      debugPrint('📊 Sync status: $_status');
    }
  }
  
  /// 🧹 LIMPA QUEUE DE SYNC (para resolver problemas de read-only)
  Future<void> clearSyncQueue() async {
    try {
      await _localDB.clearSyncQueue();
      debugPrint('✅ Queue de sync limpa com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao limpar queue de sync: $e');
    }
  }

  /// 🔧 DIAGNÓSTICO COMPLETO E CORREÇÃO DE TODOS OS PROBLEMAS READ-ONLY
  Future<Map<String, dynamic>> diagnosticarECorrigirSQLite() async {
    debugPrint('🔍 Iniciando diagnóstico COMPLETO do SQLite...');
    
    Map<String, dynamic> resultado = {
      'problemas_encontrados': <String>[],
      'correcoes_aplicadas': <String>[],
      'detalhes_tecnicos': <String>[],
      'sucesso': false,
    };

    try {
      // === DIAGNÓSTICO 1: ESTADO DO DATABASE ===
      await _diagnosticarEstadoDatabase(resultado);
      
      // === DIAGNÓSTICO 2: PERMISSÕES E ARQUIVO ===  
      await _diagnosticarPermissoes(resultado);
      
      // === DIAGNÓSTICO 3: OPERAÇÕES BÁSICAS ===
      await _diagnosticarOperacoesBasicas(resultado);
      
      // === DIAGNÓSTICO 4: CONCORRÊNCIA E LOCKS ===
      await _diagnosticarConcorrencia(resultado);
      
      // === DIAGNÓSTICO 5: SYNC QUEUE ESPECÍFICO ===
      await _diagnosticarSyncQueue(resultado);
      
      // === DIAGNÓSTICO 6: SCHEMA E INTEGRIDADE ===
      await _diagnosticarSchema(resultado);
      
      // === DIAGNÓSTICO 7: RECURSOS DO SISTEMA ===
      await _diagnosticarRecursos(resultado);
      
      // === DIAGNÓSTICO 8: DADOS CORROMPIDOS ===
      await _diagnosticarDados(resultado);

      resultado['sucesso'] = resultado['problemas_encontrados'].isEmpty;
      
      if (resultado['sucesso']) {
        debugPrint('✅ Diagnóstico COMPLETO: Tudo funcionando corretamente');
      } else {
        debugPrint('❌ PROBLEMAS ENCONTRADOS: ${resultado['problemas_encontrados']}');
        debugPrint('🔧 CORREÇÕES APLICADAS: ${resultado['correcoes_aplicadas']}');  
        debugPrint('📋 DETALHES TÉCNICOS: ${resultado['detalhes_tecnicos']}');
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('Erro geral no diagnóstico: $e');
      debugPrint('❌ Erro durante diagnóstico SQLite: $e');
    }

    return resultado;
  }

  // === MÉTODOS DE DIAGNÓSTICO ESPECÍFICOS ===
  
  /// 🔍 DIAGNÓSTICO 1: Estado do Database
  Future<void> _diagnosticarEstadoDatabase(Map<String, dynamic> resultado) async {
    try {
      // Verifica inicialização
      if (_localDB.database == null || !_localDB.isInitialized) {
        resultado['problemas_encontrados'].add('❌ Database não inicializado');
        
        try {
          await _localDB.initialize();
          resultado['correcoes_aplicadas'].add('✅ Database reinicializado');
        } catch (e) {
          resultado['problemas_encontrados'].add('❌ CRÍTICO: Falha ao reinicializar database: $e');
          return;
        }
      } else {
        resultado['detalhes_tecnicos'].add('✅ Database inicializado corretamente');
      }

      // Verifica se database está aberto
      final db = _localDB.database;
      if (db == null) {
        resultado['problemas_encontrados'].add('❌ CRÍTICO: Database é null após inicialização');
        return;
      }

      // Verifica se database está fechado
      try {
        await db.rawQuery('SELECT sqlite_version()');
        resultado['detalhes_tecnicos'].add('✅ Conexão SQLite ativa');
      } catch (e) {
        resultado['problemas_encontrados'].add('❌ Database fechado ou inacessível: $e');
        await _corrigirProblemaReadOnly();
        resultado['correcoes_aplicadas'].add('✅ Tentativa de reconexão aplicada');
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico do estado: $e');
    }
  }

  /// 🔍 DIAGNÓSTICO 2: Permissões e Arquivo
  Future<void> _diagnosticarPermissoes(Map<String, dynamic> resultado) async {
    try {
      final db = _localDB.database;
      if (db == null) return;

      // Verifica path do database
      final path = db.path;
      resultado['detalhes_tecnicos'].add('📂 Path do database: $path');

      // Testa modo read-only explícito
      try {
        final readOnlyCheck = await db.rawQuery("PRAGMA query_only");
        if (readOnlyCheck.isNotEmpty && readOnlyCheck[0]['query_only'] == 1) {
          resultado['problemas_encontrados'].add('❌ CRÍTICO: Database aberto em modo READ-ONLY');
          
          // Tenta reabrir em modo write
          await _corrigirProblemaReadOnly();
          resultado['correcoes_aplicadas'].add('✅ Database reaberto em modo WRITE');
        }
      } catch (e) {
        resultado['detalhes_tecnicos'].add('⚠️ Não foi possível verificar modo read-only: $e');
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico de permissões: $e');
    }
  }

  /// 🔍 DIAGNÓSTICO 3: Operações Básicas
  Future<void> _diagnosticarOperacoesBasicas(Map<String, dynamic> resultado) async {
    try {
      final db = _localDB.database;
      if (db == null) return;

      // TESTE 1: Operação de leitura
      try {
        final versionResult = await db.rawQuery('SELECT sqlite_version() as version');
        final version = versionResult.first['version'];
        resultado['detalhes_tecnicos'].add('✅ SQLite versão: $version');
      } catch (e) {
        resultado['problemas_encontrados'].add('❌ CRÍTICO: Falha na leitura básica: $e');
        return;
      }

      // TESTE 2: Criar tabela temporária
      try {
        await db.execute('CREATE TEMP TABLE IF NOT EXISTS test_write_${DateTime.now().millisecondsSinceEpoch} (id INTEGER)');
        resultado['detalhes_tecnicos'].add('✅ Teste CREATE TABLE: OK');
      } catch (e) {
        if (e.toString().toLowerCase().contains('read-only') || 
            e.toString().toLowerCase().contains('unsupported operation')) {
          resultado['problemas_encontrados'].add('❌ CRÍTICO: Erro READ-ONLY detectado no CREATE: $e');
          await _corrigirProblemaReadOnly();
          resultado['correcoes_aplicadas'].add('✅ Correção READ-ONLY aplicada após CREATE');
        } else {
          resultado['problemas_encontrados'].add('❌ Erro na criação de tabela: $e');
        }
      }

      // TESTE 3: Operação INSERT
      try {
        await db.rawInsert('INSERT INTO sync_queue (table_name, record_id, operation, data, created_at, attempts) VALUES (?, ?, ?, ?, ?, ?)', 
                          ['test_table', 'test_id', 'TEST', '{}', DateTime.now().toIso8601String(), 0]);
        
        // Remove o teste
        await db.delete('sync_queue', where: 'table_name = ? AND record_id = ?', whereArgs: ['test_table', 'test_id']);
        resultado['detalhes_tecnicos'].add('✅ Teste INSERT/DELETE: OK');
      } catch (e) {
        if (e.toString().toLowerCase().contains('read-only') || 
            e.toString().toLowerCase().contains('unsupported operation')) {
          resultado['problemas_encontrados'].add('❌ CRÍTICO: Erro READ-ONLY detectado no INSERT: $e');
          await _corrigirProblemaReadOnly();
          resultado['correcoes_aplicadas'].add('✅ Correção READ-ONLY aplicada após INSERT');
        } else {
          resultado['problemas_encontrados'].add('❌ Erro no teste de inserção: $e');
        }
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico de operações básicas: $e');
    }
  }

  /// 🔍 DIAGNÓSTICO 4: Concorrência e Locks
  Future<void> _diagnosticarConcorrencia(Map<String, dynamic> resultado) async {
    try {
      final db = _localDB.database;
      if (db == null) return;

      // Verifica locks ativos
      try {
        await db.rawQuery('BEGIN IMMEDIATE');
        await db.rawQuery('ROLLBACK');
        resultado['detalhes_tecnicos'].add('✅ Teste de lock: Sem deadlocks detectados');
      } catch (e) {
        if (e.toString().toLowerCase().contains('database is locked') || 
            e.toString().toLowerCase().contains('busy')) {
          resultado['problemas_encontrados'].add('❌ Database LOCKED detectado: $e');
          
          // Força unlock
          try {
            await db.rawQuery('ROLLBACK');
            await _corrigirProblemaReadOnly();
            resultado['correcoes_aplicadas'].add('✅ Database desbloqueado');
          } catch (unlockError) {
            resultado['problemas_encontrados'].add('❌ CRÍTICO: Não foi possível desbloquear: $unlockError');
          }
        } else {
          resultado['problemas_encontrados'].add('❌ Erro no teste de concorrência: $e');
        }
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico de concorrência: $e');
    }
  }

  /// 🔍 DIAGNÓSTICO 5: Sync Queue Específico
  Future<void> _diagnosticarSyncQueue(Map<String, dynamic> resultado) async {
    try {
      // Verifica itens na queue
      final pendingItems = await _localDB.getPendingSyncItems();
      resultado['detalhes_tecnicos'].add('📊 Itens pendentes na sync queue: ${pendingItems.length}');

      if (pendingItems.length > 50) {
        resultado['problemas_encontrados'].add('⚠️ Sync queue sobrecarregada: ${pendingItems.length} itens');
        
        // Analisa itens antigos
        final oldItems = pendingItems.where((item) {
          final createdAt = DateTime.tryParse(item['created_at'] as String? ?? '');
          if (createdAt == null) return false;
          return DateTime.now().difference(createdAt).inDays > 1;
        }).length;

        if (oldItems > 0) {
          resultado['problemas_encontrados'].add('⚠️ $oldItems itens antigos na queue (>24h)');
          
          // Remove itens muito antigos
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          try {
            final removed = await _localDB.database?.delete(
              'sync_queue',
              where: 'created_at < ?',
              whereArgs: [sevenDaysAgo.toIso8601String()],
            );
            if (removed != null && removed > 0) {
              resultado['correcoes_aplicadas'].add('✅ $removed itens antigos removidos da queue');
            }
          } catch (e) {
            resultado['problemas_encontrados'].add('❌ Erro ao limpar itens antigos: $e');
          }
        }
      }

      // Verifica itens com muitas tentativas
      final failedItems = pendingItems.where((item) => (item['attempts'] as int? ?? 0) >= 3).length;
      if (failedItems > 0) {
        resultado['problemas_encontrados'].add('⚠️ $failedItems itens falharam múltiplas vezes');
        
        try {
          final removed = await _localDB.database?.delete(
            'sync_queue',
            where: 'attempts >= ?',
            whereArgs: [3],
          );
          if (removed != null && removed > 0) {
            resultado['correcoes_aplicadas'].add('✅ $removed itens com falha removidos');
          }
        } catch (e) {
          resultado['problemas_encontrados'].add('❌ Erro ao remover itens falhados: $e');
        }
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico da sync queue: $e');
    }
  }

  /// 🔍 DIAGNÓSTICO 6: Schema e Integridade
  Future<void> _diagnosticarSchema(Map<String, dynamic> resultado) async {
    try {
      final db = _localDB.database;
      if (db == null) return;

      // Verifica integridade do database
      try {
        final integrityResult = await db.rawQuery('PRAGMA integrity_check');
        final integrity = integrityResult.first.values.first as String;
        if (integrity.toLowerCase() != 'ok') {
          resultado['problemas_encontrados'].add('❌ CRÍTICO: Database corrompido - integrity_check: $integrity');
          
          // Tenta reparar
          try {
            await db.rawQuery('VACUUM');
            resultado['correcoes_aplicadas'].add('✅ VACUUM executado para reparar database');
          } catch (vacuumError) {
            resultado['problemas_encontrados'].add('❌ CRÍTICO: Falha ao executar VACUUM: $vacuumError');
          }
        } else {
          resultado['detalhes_tecnicos'].add('✅ Integridade do database: OK');
        }
      } catch (e) {
        resultado['problemas_encontrados'].add('❌ Não foi possível verificar integridade: $e');
      }

      // Verifica se tabela sync_queue existe
      try {
        await db.rawQuery('SELECT COUNT(*) FROM sync_queue LIMIT 1');
        resultado['detalhes_tecnicos'].add('✅ Tabela sync_queue: Existe e acessível');
      } catch (e) {
        resultado['problemas_encontrados'].add('❌ CRÍTICO: Tabela sync_queue não existe ou inacessível: $e');
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico do schema: $e');
    }
  }

  /// 🔍 DIAGNÓSTICO 7: Recursos do Sistema
  Future<void> _diagnosticarRecursos(Map<String, dynamic> resultado) async {
    try {
      final db = _localDB.database;
      if (db == null) return;

      // Verifica tamanho do database
      try {
        final sizeResult = await db.rawQuery('PRAGMA page_count; PRAGMA page_size');
        if (sizeResult.length >= 2) {
          final pageCount = sizeResult[0]['page_count'] as int? ?? 0;
          final pageSize = sizeResult[1]['page_size'] as int? ?? 0;
          final dbSizeBytes = pageCount * pageSize;
          final dbSizeMB = dbSizeBytes / (1024 * 1024);
          
          resultado['detalhes_tecnicos'].add('📊 Tamanho do database: ${dbSizeMB.toStringAsFixed(2)} MB');
          
          if (dbSizeMB > 100) {
            resultado['problemas_encontrados'].add('⚠️ Database muito grande: ${dbSizeMB.toStringAsFixed(2)} MB');
          }
        }
      } catch (e) {
        resultado['detalhes_tecnicos'].add('⚠️ Não foi possível verificar tamanho: $e');
      }

      // Verifica journal mode
      try {
        final journalResult = await db.rawQuery('PRAGMA journal_mode');
        final journalMode = journalResult.first.values.first as String;
        resultado['detalhes_tecnicos'].add('📝 Journal mode: $journalMode');
      } catch (e) {
        resultado['detalhes_tecnicos'].add('⚠️ Não foi possível verificar journal mode: $e');
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico de recursos: $e');
    }
  }

  /// 🔍 DIAGNÓSTICO 8: Dados Corrompidos
  Future<void> _diagnosticarDados(Map<String, dynamic> resultado) async {
    try {
      // Verifica registros com dados nulos em campos obrigatórios
      final db = _localDB.database;
      if (db == null) return;

      try {
        final nullRecords = await db.rawQuery('''
          SELECT COUNT(*) as count FROM sync_queue 
          WHERE table_name IS NULL OR record_id IS NULL OR operation IS NULL
        ''');
        
        final nullCount = nullRecords.first['count'] as int? ?? 0;
        if (nullCount > 0) {
          resultado['problemas_encontrados'].add('❌ $nullCount registros com campos NULL obrigatórios na sync_queue');
          
          // Remove registros corrompidos
          try {
            final deleted = await db.delete(
              'sync_queue',
              where: 'table_name IS NULL OR record_id IS NULL OR operation IS NULL',
            );
            if (deleted > 0) {
              resultado['correcoes_aplicadas'].add('✅ $deleted registros corrompidos removidos');
            }
          } catch (e) {
            resultado['problemas_encontrados'].add('❌ Erro ao remover registros corrompidos: $e');
          }
        } else {
          resultado['detalhes_tecnicos'].add('✅ Dados da sync_queue: Sem campos NULL detectados');
        }
      } catch (e) {
        resultado['problemas_encontrados'].add('❌ Erro ao verificar dados corrompidos: $e');
      }

    } catch (e) {
      resultado['problemas_encontrados'].add('❌ Erro no diagnóstico de dados: $e');
    }
  }

  /// 🔧 CORRIGE PROBLEMAS READ-ONLY ESPECÍFICOS
  Future<void> _corrigirProblemaReadOnly() async {
    try {
      debugPrint('🔧 Aplicando correções DRÁSTICAS para problema read-only...');
      
      // Estratégia 1: Salvar estado atual
      final currentUserId = _localDB.currentUserId;
      
      // Estratégia 2: Dispose COMPLETO com força
      debugPrint('🔄 Fazendo dispose FORÇADO do SQLite...');
      try {
        await _localDB.database?.close();
      } catch (e) {
        debugPrint('⚠️ Erro ao fechar database: $e');
      }
      
      await _localDB.dispose();
      
      // Estratégia 3: Aguardar mais tempo + GC
      debugPrint('⏳ Aguardando limpeza completa + GC...');
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Força garbage collection se possível
      debugPrint('🗑️ Forçando garbage collection...');
      
      // Estratégia 4: Reinicialização com verificação múltipla
      debugPrint('🔄 Reinicializando SQLite com verificação...');
      await _localDB.initialize();
      
      if (currentUserId != null) {
        await _localDB.setCurrentUser(currentUserId);
      }
      
      // Estratégia 5: Teste múltiplo de funcionamento
      for (int i = 0; i < 3; i++) {
        try {
          await _localDB.database?.rawQuery('SELECT 1');
          debugPrint('✅ Teste SQLite $i: OK');
          break;
        } catch (e) {
          debugPrint('❌ Teste SQLite $i: $e');
          if (i == 2) rethrow; // Falha após 3 tentativas
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      debugPrint('✅ Correções DRÁSTICAS read-only aplicadas');
      
    } catch (e) {
      debugPrint('❌ FALHA CRÍTICA na correção read-only: $e');
      // Como último recurso, marca os itens para skip
      throw Exception('Correção read-only falhou completamente: $e');
    }
  }

  /// 🧹 LIMPA CAMPOS INVÁLIDOS PARA SUPABASE
  Map<String, dynamic> _cleanRecordForSupabase(Map<String, dynamic> record, String tableName) {
    debugPrint('🧹 _cleanRecordForSupabase chamado para tabela: $tableName');
    debugPrint('🔍 Campos de entrada: ${record.keys.toList()}');
    
    final cleanRecord = Map<String, dynamic>.from(record);
    
    if (tableName == 'contas') {
      debugPrint('🎯 Processando tabela CONTAS - aplicando filtros...');
      
      // 🎯 CAMPOS QUE EXISTEM NO SQLITE LOCAL MAS NÃO NO SUPABASE:
      final camposInvalidos = [
        // ✅ CORREÇÃO: conta_principal EXISTE NO SUPABASE! Removido da lista
        // 'conta_principal', // Campo válido, não deve ser removido
      ];
      
      int camposRemovidos = 0;
      for (final campo in camposInvalidos) {
        if (cleanRecord.containsKey(campo)) {
          final valorRemovido = cleanRecord.remove(campo);
          camposRemovidos++;
          debugPrint('🚫 Campo "$campo" removido (valor: $valorRemovido) - não existe no Supabase');
        } else {
          debugPrint('ℹ️ Campo "$campo" não encontrado nos dados');
        }
      }
      
      debugPrint('📊 Total de campos removidos: $camposRemovidos');
      debugPrint('✅ Campos válidos para Supabase: ${cleanRecord.keys.toList()}');
      
    } else {
      debugPrint('ℹ️ Tabela $tableName não requer limpeza especial');
    }
    
    return cleanRecord;
  }

  // ===== DOWNLOAD ON-DEMAND PARA GRUPOS =====

  /// Baixa todas as transações de um grupo específico para SQLite local
  /// Usado quando grupo ultrapassa janela local de ±12 meses
  Future<int> baixarTransacoesGrupo({
    required String grupoId,
    required String tipoGrupo, // 'recorrencia' ou 'parcelamento'
    String? usuarioId,
  }) async {
    try {
      debugPrint('🔄 Baixando grupo $grupoId ($tipoGrupo)...');

      // Usar usuário atual se não fornecido
      final userId = usuarioId ?? _localDB.currentUserId;
      if (userId == null) {
        debugPrint('❌ Usuário não identificado para download');
        return 0;
      }

      // Verificar conectividade
      if (!await _connectivity.isOnline()) {
        debugPrint('❌ Sem conexão para baixar grupo');
        return 0;
      }

      final campo = tipoGrupo == 'recorrencia'
        ? 'grupo_recorrencia'
        : 'grupo_parcelamento';

      // Baixar todas as transações do grupo do Supabase
      final response = await _supabase
        .from('transacoes')
        .select()
        .eq(campo, grupoId)
        .eq('usuario_id', userId)
        .order('data', ascending: true);

      int transacoesBaixadas = 0;

      // Salvar cada transação no SQLite local
      for (final transacaoData in response) {
        try {
          // Preparar dados para SQLite
          final transacaoLocal = _prepareSQLiteData(transacaoData);

          // Inserir ou atualizar no SQLite (usando colunas que existem no schema local)
          await _localDB.rawQuery('''
            INSERT OR REPLACE INTO transacoes (
              id, usuario_id, tipo, categoria_id, subcategoria_id,
              descricao, valor, data, efetivado, data_efetivacao,
              conta_id, cartao_id, observacoes,
              grupo_recorrencia, grupo_parcelamento, parcela_atual,
              total_parcelas, numero_parcelas, created_at, updated_at,
              sync_status, last_sync
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            transacaoLocal['id'],
            transacaoLocal['usuario_id'],
            transacaoLocal['tipo'],
            transacaoLocal['categoria_id'],
            transacaoLocal['subcategoria_id'],
            transacaoLocal['descricao'],
            transacaoLocal['valor'],
            transacaoLocal['data'],
            transacaoLocal['efetivado'],
            transacaoLocal['data_efetivacao'],
            transacaoLocal['conta_id'],
            transacaoLocal['cartao_id'],
            transacaoLocal['observacoes'],
            transacaoLocal['grupo_recorrencia'],
            transacaoLocal['grupo_parcelamento'],
            transacaoLocal['parcela_atual'],
            transacaoLocal['total_parcelas'],
            transacaoLocal['numero_parcelas'],
            transacaoLocal['created_at'],
            transacaoLocal['updated_at'],
            'synced',
            DateTime.now().toIso8601String(),
          ]);

          transacoesBaixadas++;

        } catch (e) {
          debugPrint('❌ Erro ao salvar transação ${transacaoData['id']}: $e');
        }
      }

      debugPrint('✅ Download completo: $transacoesBaixadas transações do grupo $grupoId');
      return transacoesBaixadas;

    } catch (e) {
      debugPrint('❌ Erro no download do grupo $grupoId: $e');
      return 0;
    }
  }

  /// Verifica se um grupo precisa de download (ultrapassa janela local)
  Future<bool> grupoPrecisaDownload({
    required String grupoId,
    required String tipoGrupo,
  }) async {
    try {
      final userId = _localDB.currentUserId;
      if (userId == null) return false;

      // Buscar metadados do grupo
      final metadados = await _localDB.rawQuery('''
        SELECT data_ultima FROM grupos_metadados
        WHERE grupo_id = ? AND usuario_id = ? AND tipo_grupo = ?
      ''', [grupoId, userId, tipoGrupo]);

      if (metadados.isEmpty) return false;

      final dataUltima = DateTime.parse(metadados.first['data_ultima'] as String);
      final janelaMaxima = DateTime.now().add(const Duration(days: 365));

      // Se última data > 12 meses à frente, precisa baixar
      return dataUltima.isAfter(janelaMaxima);

    } catch (e) {
      debugPrint('❌ Erro ao verificar se grupo precisa download: $e');
      return false;
    }
  }

  /// 🧹 DISPOSE
  void dispose() {
    _periodicSync?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
    debugPrint('🧹 Sync Manager disposed');
  }
}

/// 🎯 Singleton global para acesso fácil
final syncManager = SyncManager.instance;