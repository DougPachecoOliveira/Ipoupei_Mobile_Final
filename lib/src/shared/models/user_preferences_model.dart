// 🌟 User Preferences Model - iPoupei Mobile
//
// Modelo para gerenciar preferências locais do usuário
// Inclui cartão favorito e outras preferências futuras
//
// Baseado em: Local Storage Pattern

import 'dart:convert';

class UserPreferencesModel {
  final String? cartaoFavoritoId;
  final DateTime? updatedAt;

  const UserPreferencesModel({
    this.cartaoFavoritoId,
    this.updatedAt,
  });

  /// Instância vazia/padrão
  factory UserPreferencesModel.empty() {
    return const UserPreferencesModel();
  }

  /// Criar com cartão favorito
  factory UserPreferencesModel.withCartaoFavorito(String cartaoId) {
    return UserPreferencesModel(
      cartaoFavoritoId: cartaoId,
      updatedAt: DateTime.now(),
    );
  }

  /// Remover cartão favorito
  UserPreferencesModel removeCartaoFavorito() {
    return UserPreferencesModel(
      cartaoFavoritoId: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Verificar se um cartão é o favorito
  bool isCartaoFavorito(String? cartaoId) {
    if (cartaoId == null || cartaoFavoritoId == null) return false;
    return cartaoFavoritoId == cartaoId;
  }

  /// Verificar se há cartão favorito definido
  bool get hasCartaoFavorito => cartaoFavoritoId != null;

  /// Criar cópia com modificações
  UserPreferencesModel copyWith({
    String? cartaoFavoritoId,
    DateTime? updatedAt,
  }) {
    return UserPreferencesModel(
      cartaoFavoritoId: cartaoFavoritoId ?? this.cartaoFavoritoId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'cartaoFavoritoId': cartaoFavoritoId,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Criar do Map
  factory UserPreferencesModel.fromMap(Map<String, dynamic> map) {
    return UserPreferencesModel(
      cartaoFavoritoId: map['cartaoFavoritoId'],
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  /// Converter para JSON
  String toJson() => json.encode(toMap());

  /// Criar do JSON
  factory UserPreferencesModel.fromJson(String source) {
    return UserPreferencesModel.fromMap(json.decode(source));
  }

  @override
  String toString() {
    return 'UserPreferencesModel(cartaoFavoritoId: $cartaoFavoritoId, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserPreferencesModel &&
        other.cartaoFavoritoId == cartaoFavoritoId &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return cartaoFavoritoId.hashCode ^ updatedAt.hashCode;
  }
}