// 👤 User Profile Model - iPoupei Mobile
//
// Modelo de perfil de usuário baseado no React

class UserProfileModel {
  final String id;
  final String email;
  final String? nome;
  final String? telefone;
  final String? avatarUrl;
  final bool aceitaNotificacoes;
  final bool aceitaMarketing;
  final String? provider; // 'google' ou 'email'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.id,
    required this.email,
    this.nome,
    this.telefone,
    this.avatarUrl,
    this.aceitaNotificacoes = true,
    this.aceitaMarketing = false,
    this.provider,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nome: json['nome'],
      telefone: json['telefone'],
      avatarUrl: json['avatar_url'],
      aceitaNotificacoes: json['aceita_notificacoes'] ?? true,
      aceitaMarketing: json['aceita_marketing'] ?? false,
      provider: json['provider'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'telefone': telefone,
      'avatar_url': avatarUrl,
      'aceita_notificacoes': aceitaNotificacoes,
      'aceita_marketing': aceitaMarketing,
      'provider': provider,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? nome,
    String? telefone,
    String? avatarUrl,
    bool? aceitaNotificacoes,
    bool? aceitaMarketing,
    String? provider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aceitaNotificacoes: aceitaNotificacoes ?? this.aceitaNotificacoes,
      aceitaMarketing: aceitaMarketing ?? this.aceitaMarketing,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se é login via Google SSO
  bool get isGoogleUser => provider == 'google';

  /// Retorna iniciais do nome para avatar
  String get initials {
    if (nome == null || nome!.isEmpty) return 'U';
    final parts = nome!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nome![0].toUpperCase();
  }
}
