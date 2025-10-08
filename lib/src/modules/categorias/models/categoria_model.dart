// 📂 Categoria Model - iPoupei Mobile
// 
// Modelo de dados para categorias
// Estrutura idêntica ao Supabase
// 
// Baseado em: Data Model Pattern

class CategoriaModel {
  final String id;
  final String usuarioId;
  final String nome;
  final String tipo; // 'receita', 'despesa' - NOT NULL no banco
  final String cor;
  final String icone;
  final bool ativo;
  final int ordem;
  final String? classificacaoRegra; // Campo específico do Supabase
  final String? descricao;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoriaModel({
    required this.id,
    required this.usuarioId,
    required this.nome,
    required this.tipo,
    this.cor = '#6B7280', // Padrão do banco
    this.icone = 'folder', // Padrão do banco
    this.ativo = true,
    this.ordem = 0, // Padrão do banco
    this.classificacaoRegra,
    this.descricao,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      cor: json['cor'] ?? '#6B7280', // Padrão do banco
      icone: json['icone'] ?? 'folder', // Padrão do banco
      ativo: _parseBool(json['ativo']),
      ordem: json['ordem'] ?? 0, // Padrão do banco
      classificacaoRegra: json['classificacao_regra'],
      descricao: json['descricao'],
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome,
      'tipo': tipo,
      'cor': cor,
      'icone': icone,
      'ativo': ativo,
      'ordem': ordem,
      'classificacao_regra': classificacaoRegra,
      'descricao': descricao,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CategoriaModel copyWith({
    String? id,
    String? usuarioId,
    String? nome,
    String? tipo,
    String? cor,
    String? icone,
    bool? ativo,
    int? ordem,
    String? classificacaoRegra,
    String? descricao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      cor: cor ?? this.cor,
      icone: icone ?? this.icone,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      classificacaoRegra: classificacaoRegra ?? this.classificacaoRegra,
      descricao: descricao ?? this.descricao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  @override
  String toString() => 'CategoriaModel(id: $id, nome: $nome)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriaModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// 📂 Subcategoria Model
class SubcategoriaModel {
  final String id;
  final String categoriaId;
  final String usuarioId; // Campo específico do Supabase
  final String nome;
  final String? cor;
  final String? icone;
  final bool ativo;
  final int ordem;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubcategoriaModel({
    required this.id,
    required this.categoriaId,
    required this.usuarioId,
    required this.nome,
    this.cor,
    this.icone,
    this.ativo = true,
    this.ordem = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubcategoriaModel.fromJson(Map<String, dynamic> json) {
    return SubcategoriaModel(
      id: json['id'] ?? '',
      categoriaId: json['categoria_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      nome: json['nome'] ?? '',
      cor: json['cor'],
      icone: json['icone'],
      ativo: CategoriaModel._parseBool(json['ativo']),
      ordem: json['ordem'] ?? 1,
      createdAt: CategoriaModel._parseDateTime(json['created_at']),
      updatedAt: CategoriaModel._parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoria_id': categoriaId,
      'usuario_id': usuarioId,
      'nome': nome,
      'cor': cor,
      'icone': icone,
      'ativo': ativo,
      'ordem': ordem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SubcategoriaModel copyWith({
    String? id,
    String? categoriaId,
    String? usuarioId,
    String? nome,
    String? cor,
    String? icone,
    bool? ativo,
    int? ordem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubcategoriaModel(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      usuarioId: usuarioId ?? this.usuarioId,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      icone: icone ?? this.icone,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'SubcategoriaModel(id: $id, nome: $nome)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubcategoriaModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}