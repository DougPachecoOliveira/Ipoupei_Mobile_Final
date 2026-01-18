// 🌟 User Preferences Service - iPoupei Mobile
//
// Service para gerenciar preferências locais do usuário
// Cartão favorito, configurações de UI, etc.
//
// Baseado em: Singleton + SharedPreferences Pattern

import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences_model.dart';
import '../../supabase_auth_service.dart';

class UserPreferencesService extends ChangeNotifier {
  static final UserPreferencesService _instance = UserPreferencesService._internal();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._internal();

  /// Instância singleton
  static UserPreferencesService get instance => _instance;

  UserPreferencesModel _preferences = UserPreferencesModel.empty();
  final SupabaseAuthService _authService = SupabaseAuthService.instance;
  bool _isInitialized = false;

  /// Preferências atuais
  UserPreferencesModel get preferences => _preferences;

  /// Verificar se está inicializado
  bool get isInitialized => _isInitialized;

  /// Chave para SharedPreferences (única por usuário)
  String get _preferencesKey {
    final userId = _authService.currentUser?.id;
    return 'user_preferences_${userId ?? 'default'}';
  }

  /// Inicializar service carregando preferências salvas
  Future<void> initialize() async {
    try {
      await _loadPreferences();
      _isInitialized = true;
      log('✅ UserPreferencesService inicializado');
    } catch (e) {
      log('❌ Erro ao inicializar UserPreferencesService: $e');
      _preferences = UserPreferencesModel.empty();
      _isInitialized = true;
    }
  }

  /// Carregar preferências do storage
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = prefs.getString(_preferencesKey);

    if (preferencesJson != null) {
      try {
        _preferences = UserPreferencesModel.fromJson(preferencesJson);
        log('📱 Preferências carregadas: ${_preferences.toString()}');
      } catch (e) {
        log('⚠️ Erro ao parsear preferências, usando padrão: $e');
        _preferences = UserPreferencesModel.empty();
      }
    } else {
      _preferences = UserPreferencesModel.empty();
      log('📱 Nenhuma preferência salva, usando padrão');
    }
  }

  /// Salvar preferências no storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferencesKey, _preferences.toJson());
      log('💾 Preferências salvas: ${_preferences.toString()}');
      notifyListeners();
    } catch (e) {
      log('❌ Erro ao salvar preferências: $e');
      throw Exception('Falha ao salvar preferências');
    }
  }

  /// ⭐ GERENCIAMENTO DO CARTÃO FAVORITO

  /// Obter ID do cartão favorito
  String? get cartaoFavoritoId => _preferences.cartaoFavoritoId;

  /// Verificar se há cartão favorito definido
  bool get hasCartaoFavorito => _preferences.hasCartaoFavorito;

  /// Verificar se um cartão específico é o favorito
  bool isCartaoFavorito(String? cartaoId) => _preferences.isCartaoFavorito(cartaoId);

  /// Definir cartão como favorito
  Future<void> setCartaoFavorito(String cartaoId) async {
    try {
      log('⭐ Definindo cartão favorito: $cartaoId');

      _preferences = UserPreferencesModel.withCartaoFavorito(cartaoId);
      await _savePreferences();

      log('✅ Cartão favorito definido com sucesso');
    } catch (e) {
      log('❌ Erro ao definir cartão favorito: $e');
      throw Exception('Falha ao definir cartão favorito');
    }
  }

  /// Remover cartão favorito
  Future<void> removeCartaoFavorito() async {
    try {
      log('🗑️ Removendo cartão favorito');

      _preferences = _preferences.removeCartaoFavorito();
      await _savePreferences();

      log('✅ Cartão favorito removido com sucesso');
    } catch (e) {
      log('❌ Erro ao remover cartão favorito: $e');
      throw Exception('Falha ao remover cartão favorito');
    }
  }

  /// Toggle do cartão favorito
  Future<void> toggleCartaoFavorito(String cartaoId) async {
    try {
      if (isCartaoFavorito(cartaoId)) {
        await removeCartaoFavorito();
      } else {
        await setCartaoFavorito(cartaoId);
      }
    } catch (e) {
      log('❌ Erro ao fazer toggle do cartão favorito: $e');
      rethrow;
    }
  }

  /// ⚙️ GERENCIAMENTO GERAL

  /// Limpar todas as preferências
  Future<void> clearPreferences() async {
    try {
      log('🗑️ Limpando todas as preferências');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_preferencesKey);
      _preferences = UserPreferencesModel.empty();

      notifyListeners();
      log('✅ Preferências limpas com sucesso');
    } catch (e) {
      log('❌ Erro ao limpar preferências: $e');
      throw Exception('Falha ao limpar preferências');
    }
  }

  /// Recarregar preferências do storage
  Future<void> reload() async {
    try {
      await _loadPreferences();
      notifyListeners();
      log('🔄 Preferências recarregadas');
    } catch (e) {
      log('❌ Erro ao recarregar preferências: $e');
      throw Exception('Falha ao recarregar preferências');
    }
  }

  /// Debug: Exportar preferências
  Map<String, dynamic> toDebugMap() {
    return {
      'initialized': _isInitialized,
      'userId': _authService.currentUser?.id,
      'preferences': _preferences.toMap(),
      'preferencesKey': _preferencesKey,
    };
  }
}