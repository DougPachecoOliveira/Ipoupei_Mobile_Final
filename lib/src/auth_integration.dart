// 🔗 Auth Integration - iPoupei Mobile
// 
// Integração entre SupabaseAuthService e Database Local
// Configura inicialização e sincronização automática
// 
// Baseado em: Enterprise patterns + Dependency Injection
// Arquitetura: Service Integration + Auto Setup

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'supabase_auth_service.dart';
import 'database/local_database.dart';
import 'sync/sync_manager.dart';
import 'services/app_lifecycle_manager.dart';
import 'shared/services/user_preferences_service.dart';

/// Configuração para inicialização do Supabase
class SupabaseConfig {
  /// URL do projeto Supabase - iPoupei (Project ID: ykifgrblmicoymavcqnu)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ykifgrblmicoymavcqnu.supabase.co',
  );
  
  /// Chave anônima do Supabase - iPoupei (atualizada 2025)
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY', 
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlraWZncmJsbWljb3ltYXZjcW51Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2MDc0ODAsImV4cCI6MjA2MzE4MzQ4MH0.mpRAktLtEGzVXvxjtY0pLqbuvI0nZS_On_UHbb4NuBo',
  );
  
  /// Deep Link para autenticação - Configuração Profissional iPoupei
  static const String authCallbackUrl = 'br.com.ipoupei.mobile://auth/callback';
  
  /// Verificações de configuração
  static bool get isConfigured => 
    url == 'https://ykifgrblmicoymavcqnu.supabase.co' && 
    anonKey.isNotEmpty && 
    anonKey.startsWith('eyJ');
}

/// Integração e inicialização dos services de autenticação
class AuthIntegration {
  static AuthIntegration? _instance;
  static AuthIntegration get instance {
    _instance ??= AuthIntegration._internal();
    return _instance!;
  }
  
  AuthIntegration._internal();
  
  bool _initialized = false;
  
  /// Services
  final SupabaseAuthService _authService = SupabaseAuthService.instance;
  final LocalDatabase _localDB = LocalDatabase.instance;
  
  /// Getters públicos
  SupabaseAuthService get authService => _authService;
  LocalDatabase get localDatabase => _localDB;
  bool get isInitialized => _initialized;
  
  /// 🚀 INICIALIZA TODA A INFRAESTRUTURA
  Future<void> initialize() async {
    if (_initialized) return;
    
    debugPrint('🔗 Inicializando integração Auth + Database...');
    
    try {
      // 1. Inicializa Supabase
      await _initializeSupabase();
      
      // 2. Inicializa Database Local
      await _localDB.initialize();
      
      // 3. Inicializa Auth Service
      await _authService.initialize();

      // 4. Inicializa UserPreferencesService
      try {
        debugPrint('🔧 Inicializando UserPreferencesService...');
        await UserPreferencesService.instance.initialize();
        debugPrint('✅ UserPreferencesService inicializado');
      } catch (e) {
        debugPrint('❌ Erro ao inicializar UserPreferencesService: $e (continuando...)');
      }

      // 5. Inicializa SyncManager
      await SyncManager.instance.initialize();

      // 6. Inicializa AppLifecycleManager
      AppLifecycleManager.instance.initialize();

      // 7. Configura listeners integrados
      _setupIntegrationListeners();
      
      _initialized = true;
      debugPrint('✅ Integração Auth + Database inicializada');
      
    } catch (e) {
      debugPrint('❌ Erro na inicialização da integração: $e');
      rethrow;
    }
  }
  
  /// 🌐 INICIALIZA SUPABASE
  Future<void> _initializeSupabase() async {
    try {
      // Verifica se já foi inicializado
      try {
        Supabase.instance.client;
        debugPrint('ℹ️ Supabase já inicializado');
        return;
      } catch (e) {
        // Não está inicializado, continua
      }
      
      debugPrint('🌐 Inicializando Supabase...');
      
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      
      debugPrint('✅ Supabase inicializado');
      
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Supabase: $e');
      rethrow;
    }
  }
  
  /// 👂 CONFIGURA LISTENERS INTEGRADOS
  void _setupIntegrationListeners() {
    debugPrint('👂 Configurando listeners integrados...');
    
    // Escuta mudanças no status de autenticação
    _authService.statusStream.listen((status) {
      debugPrint('🔄 Auth status changed: $status');
      _handleAuthStatusChange(status);
    });
    
    // Escuta mudanças do usuário
    _authService.userStream.listen((user) {
      if (user != null) {
        debugPrint('👤 Usuário logado: ${user.email}');
        _handleUserLogin(user);
      } else {
        debugPrint('🚪 Usuário deslogado');
        _handleUserLogout();
      }
    });
  }
  
  /// 🔄 MANIPULA MUDANÇA DE STATUS DE AUTH
  void _handleAuthStatusChange(AuthStatus status) async {
    switch (status) {
      case AuthStatus.authenticated:
        debugPrint('🔐 Sistema autenticado - preparando dados locais');
        break;
        
      case AuthStatus.unauthenticated:
        debugPrint('🔓 Sistema desautenticado - limpando dados locais');
        break;
        
      case AuthStatus.loading:
        debugPrint('⏳ Sistema carregando...');
        break;
        
      case AuthStatus.error:
        debugPrint('❌ Erro no sistema de autenticação');
        break;
    }
  }
  
  /// 👤 MANIPULA LOGIN DO USUÁRIO
  void _handleUserLogin(AuthUser user) async {
    try {
      debugPrint('🔄 Configurando dados locais para usuário: ${user.id}');

      // Configura database local para o usuário
      await _localDB.setCurrentUser(user.id);

      // Inicializa preferências do usuário específico
      try {
        debugPrint('👤 Reinicializando UserPreferencesService para usuário: ${user.id}');
        await UserPreferencesService.instance.initialize();
        debugPrint('✅ Preferências do usuário ${user.id} carregadas');
      } catch (e) {
        debugPrint('❌ Erro ao reinicializar UserPreferencesService: $e (continuando...)');
      }

      // Inicia sincronização inicial
      await SyncManager.instance.syncInitial();

      debugPrint('✅ Dados do usuário configurados');

    } catch (e) {
      debugPrint('❌ Erro ao configurar dados do usuário: $e');
    }
  }
  
  /// 🚪 MANIPULA LOGOUT DO USUÁRIO
  void _handleUserLogout() async {
    try {
      debugPrint('🧹 Limpando dados locais...');

      // Limpa preferências do usuário
      try {
        debugPrint('🧹 Limpando UserPreferencesService...');
        await UserPreferencesService.instance.clearPreferences();
        debugPrint('✅ Preferências do usuário limpas');
      } catch (e) {
        debugPrint('❌ Erro ao limpar UserPreferencesService: $e (continuando...)');
      }

      // Limpa dados do usuário no database local
      await _localDB.clearCurrentUser();

      debugPrint('✅ Dados locais limpos');

    } catch (e) {
      debugPrint('❌ Erro ao limpar dados locais: $e');
    }
  }
  
  /// 📊 STATUS DA INTEGRAÇÃO
  Map<String, dynamic> getIntegrationStatus() {
    return {
      'integration_initialized': _initialized,
      'supabase_initialized': _isSupabaseInitialized(),
      'auth_service_initialized': true,
      'local_db_initialized': _localDB.isInitialized,
      'current_user': _authService.currentUser?.toMap(),
      'auth_status': _authService.status.toString(),
    };
  }
  
  /// 🧪 VERIFICA SE SUPABASE ESTÁ INICIALIZADO
  bool _isSupabaseInitialized() {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 🧹 DISPOSE
  void dispose() {
    AppLifecycleManager.instance.dispose();
    debugPrint('🧹 AuthIntegration disposed');
  }
}

/// 🎯 Singleton global para acesso fácil
final authIntegration = AuthIntegration.instance;