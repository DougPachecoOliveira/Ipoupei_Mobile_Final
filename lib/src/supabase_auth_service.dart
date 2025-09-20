// 🔐 Supabase Auth Service - iPoupei Mobile
// 
// Service de autenticação híbrida com Supabase
// Gerencia login, logout, sessões e sincronização inicial
// 
// Baseado em: Enterprise patterns + Supabase Auth
// Arquitetura: Singleton + Stream reactive + Auto sync

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync/connectivity_helper.dart';

/// Estados de autenticação
enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Dados do usuário autenticado
class AuthUser {
  final String id;
  final String email;
  final String? nome;
  final String? avatarUrl;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AuthUser({
    required this.id,
    required this.email,
    this.nome,
    this.avatarUrl,
    required this.createdAt,
    this.metadata = const {},
  });

  factory AuthUser.fromSupabaseUser(User user) {
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      nome: user.userMetadata?['nome'] ?? user.userMetadata?['name'],
      avatarUrl: user.userMetadata?['avatar_url'],
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      metadata: user.userMetadata ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Supabase Auth Service - Gerencia autenticação híbrida
class SupabaseAuthService {
  static SupabaseAuthService? _instance;
  static SupabaseAuthService get instance {
    _instance ??= SupabaseAuthService._internal();
    return _instance!;
  }
  
  SupabaseAuthService._internal();
  
  /// Estado interno
  AuthStatus _status = AuthStatus.loading;
  AuthUser? _currentUser;
  StreamSubscription<AuthState>? _authSubscription;
  
  /// Controllers para streams
  final StreamController<AuthStatus> _statusController = 
    StreamController<AuthStatus>.broadcast();
  final StreamController<AuthUser?> _userController = 
    StreamController<AuthUser?>.broadcast();
    
  /// Configurações
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();
  
  /// Getters públicos
  AuthStatus get status => _status;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _status == AuthStatus.loading;
  
  /// Streams públicos
  Stream<AuthStatus> get statusStream => _statusController.stream;
  Stream<AuthUser?> get userStream => _userController.stream;
  
  /// 🚀 INICIALIZA O SERVICE
  Future<void> initialize() async {
    if (_initialized) return await _initCompleter.future;
    
    debugPrint('🔐 Inicializando SupabaseAuthService...');
    
    try {
      // Verifica se Supabase já está inicializado
      try {
        Supabase.instance.client;
      } catch (e) {
        throw Exception('Supabase não está inicializado. Chame Supabase.initialize() primeiro.');
      }
      
      // Escuta mudanças de autenticação
      _setupAuthListener();
      
      // Verifica sessão atual
      await _checkCurrentSession();
      
      _initialized = true;
      _initCompleter.complete();
      
      debugPrint('✅ SupabaseAuthService inicializado');
      
    } catch (e) {
      debugPrint('❌ Erro ao inicializar SupabaseAuthService: $e');
      _updateStatus(AuthStatus.error);
      _initCompleter.completeError(e);
      rethrow;
    }
  }
  
  /// 👂 CONFIGURA LISTENER DE AUTH
  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState state) async {
        debugPrint('🔄 Auth state changed: ${state.event}');
        
        switch (state.event) {
          case AuthChangeEvent.signedIn:
            await _handleSignedIn(state.session?.user);
            break;
            
          case AuthChangeEvent.signedOut:
            await _handleSignedOut();
            break;
            
          case AuthChangeEvent.userUpdated:
            await _handleUserUpdated(state.session?.user);
            break;
            
          default:
            debugPrint('🔄 Auth event não tratado: ${state.event}');
        }
      },
      onError: (error) async {
        // 🔍 VERIFICA SE É ERRO DE CONECTIVIDADE
        final isConnectivityError = _isConnectivityError(error);
        final isOnline = await ConnectivityHelper.instance.isOnline();
        
        if (isConnectivityError && !isOnline) {
          // 📱 MODO OFFLINE: Silencia erros de conectividade
          debugPrint('📱 Auth offline: Ignorando erro de conectividade (${error.runtimeType})');
        } else {
          // 🚨 ERRO REAL: Loga normalmente
          debugPrint('❌ Erro no auth listener: $error');
          _updateStatus(AuthStatus.error);
        }
      },
    );
  }
  
  /// 🔍 VERIFICA SESSÃO ATUAL
  Future<void> _checkCurrentSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = session?.user;
      
      if (user != null && session != null) {
        debugPrint('✅ Sessão ativa encontrada: ${user.email}');
        await _handleSignedIn(user);
      } else {
        debugPrint('ℹ️ Nenhuma sessão ativa');
        _updateStatus(AuthStatus.unauthenticated);
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao verificar sessão: $e');
      _updateStatus(AuthStatus.error);
    }
  }
  
  /// 📧 LOGIN COM EMAIL E SENHA
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _waitForInitialization();
    
    debugPrint('📧 Tentando login com email: $email');
    _updateStatus(AuthStatus.loading);
    
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Erro no login: usuário não encontrado');
      }
      
      debugPrint('✅ Login realizado: ${response.user!.email}');
      
      return AuthUser.fromSupabaseUser(response.user!);
      
    } catch (e) {
      debugPrint('❌ Erro no login: $e');
      _updateStatus(AuthStatus.unauthenticated);
      
      // Mapeia erros comuns para mensagens amigáveis
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Email ou senha incorretos');
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception('Email não confirmado. Verifique sua caixa de entrada.');
      } else if (e.toString().contains('Too many requests')) {
        throw Exception('Muitas tentativas. Tente novamente em alguns minutos.');
      }
      
      rethrow;
    }
  }
  
  /// 👤 CADASTRO COM EMAIL E SENHA
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String nome,
  }) async {
    await _waitForInitialization();
    
    debugPrint('👤 Tentando cadastro: $email');
    _updateStatus(AuthStatus.loading);
    
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nome': nome.trim(),
          'email': email.trim(),
        },
      );
      
      if (response.user == null) {
        throw Exception('Erro no cadastro: usuário não criado');
      }
      
      debugPrint('✅ Cadastro realizado: ${response.user!.email}');
      
      // Se precisar confirmar email, não autentica automaticamente
      if (response.session == null) {
        debugPrint('📨 Email de confirmação enviado');
        _updateStatus(AuthStatus.unauthenticated);
        throw Exception('Cadastro realizado! Confirme seu email antes de fazer login.');
      }
      
      return AuthUser.fromSupabaseUser(response.user!);
      
    } catch (e) {
      debugPrint('❌ Erro no cadastro: $e');
      _updateStatus(AuthStatus.unauthenticated);
      
      // Mapeia erros comuns
      if (e.toString().contains('User already registered')) {
        throw Exception('Este email já está cadastrado');
      } else if (e.toString().contains('Password should be at least 6 characters')) {
        throw Exception('A senha deve ter pelo menos 6 caracteres');
      }
      
      rethrow;
    }
  }
  
  /// 🚪 LOGOUT
  Future<void> signOut() async {
    await _waitForInitialization();
    
    debugPrint('🚪 Fazendo logout...');
    
    try {
      await Supabase.instance.client.auth.signOut();
      debugPrint('✅ Logout realizado');
      
    } catch (e) {
      debugPrint('❌ Erro no logout: $e');
      // Força logout local mesmo com erro
      await _handleSignedOut();
      rethrow;
    }
  }
  
  /// 🔧 HANDLERS INTERNOS
  
  /// Manipula evento de login
  Future<void> _handleSignedIn(User? user) async {
    if (user == null) return;
    
    debugPrint('🔐 Usuário logado: ${user.email}');
    
    _currentUser = AuthUser.fromSupabaseUser(user);
    _updateStatus(AuthStatus.authenticated);
    _userController.add(_currentUser);
  }
  
  /// Manipula evento de logout
  Future<void> _handleSignedOut() async {
    debugPrint('🔓 Usuário deslogado');
    
    _currentUser = null;
    _updateStatus(AuthStatus.unauthenticated);
    _userController.add(null);
  }
  
  /// Manipula atualização do usuário
  Future<void> _handleUserUpdated(User? user) async {
    if (user == null || !isAuthenticated) return;
    
    debugPrint('🔄 Dados do usuário atualizados');
    
    _currentUser = AuthUser.fromSupabaseUser(user);
    _userController.add(_currentUser);
  }
  
  /// Atualiza status e notifica listeners
  void _updateStatus(AuthStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
      debugPrint('📊 Auth status: $_status');
    }
  }
  
  /// Aguarda inicialização
  Future<void> _waitForInitialization() async {
    if (!_initialized) {
      await _initCompleter.future;
    }
  }

  /// 🔍 DETECTA ERROS DE CONECTIVIDADE PARA SILENCIAR EM MODO OFFLINE
  bool _isConnectivityError(dynamic error) {
    if (error == null) return false;
    
    final errorString = error.toString().toLowerCase();
    final errorType = error.runtimeType.toString().toLowerCase();
    
    // Lista de padrões que indicam problemas de conectividade
    final connectivityPatterns = [
      'failed host lookup',
      'no address associated with hostname',
      'network is unreachable',
      'connection refused',
      'connection timed out',
      'socket exception',
      'clientexception',
      'authretryablefetchexception',
      'os error',
      'errno = 7',
      'no internet connection',
      'network error',
      'connection error',
    ];
    
    // Verifica se o erro corresponde a algum padrão de conectividade
    for (final pattern in connectivityPatterns) {
      if (errorString.contains(pattern) || errorType.contains(pattern)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 🧹 DISPOSE
  void dispose() {
    _authSubscription?.cancel();
    _statusController.close();
    _userController.close();
    debugPrint('🧹 SupabaseAuthService disposed');
  }
}

/// 🎯 Singleton global para acesso fácil
final supabaseAuth = SupabaseAuthService.instance;