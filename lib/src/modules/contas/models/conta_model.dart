// 🏦 Conta Model - iPoupei Mobile
// 
// Modelo de dados para contas bancárias
// Estrutura idêntica ao Supabase
// 
// Baseado em: Data Model Pattern

class ContaModel {
  final String id;
  final String usuarioId;
  final String nome;
  final String tipo; // 'corrente', 'poupanca', 'investimento', 'carteira'
  final String? banco;
  final String? agencia; // Campo que existe no Supabase
  final String? conta; // Campo que existe no Supabase  
  final double saldoInicial;
  final double saldo;
  final String? cor;
  final String? icone; // Campo que existe no Supabase
  final bool ativo;
  final bool incluirSomaTotal;
  final bool contaPrincipal; // Campo conta_principal do Supabase
  final int ordem;
  final String? observacoes;
  final bool origemDiagnostico; // Campo que existe no Supabase
  final DateTime createdAt;
  final DateTime updatedAt;

  ContaModel({
    required this.id,
    required this.usuarioId,
    required this.nome,
    required this.tipo,
    this.banco,
    this.agencia,
    this.conta,
    required this.saldoInicial,
    required this.saldo,
    this.cor,
    this.icone,
    this.ativo = true,
    this.incluirSomaTotal = true,
    this.contaPrincipal = false,
    this.ordem = 1,
    this.observacoes,
    this.origemDiagnostico = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContaModel.fromJson(Map<String, dynamic> json) {
    return ContaModel(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? 'corrente',
      banco: json['banco'],
      agencia: json['agencia'],
      conta: json['conta'],
      saldoInicial: _parseDouble(json['saldo_inicial']),
      saldo: _parseDouble(json['saldo']),
      cor: json['cor'] ?? '#3B82F6',
      icone: json['icone'] ?? 'bank',
      ativo: _parseBool(json['ativo']),
      incluirSomaTotal: _parseBool(json['incluir_soma_total']),
      contaPrincipal: _parseBool(json['conta_principal']),
      ordem: json['ordem'] ?? 1,
      observacoes: json['observacoes'],
      origemDiagnostico: _parseBool(json['origem_diagnostico']),
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
      'banco': banco,
      'agencia': agencia,
      'conta': conta,
      'saldo_inicial': saldoInicial,
      'saldo': saldo,
      'cor': cor,
      'icone': icone,
      'ativo': ativo,
      'incluir_soma_total': incluirSomaTotal,
      'conta_principal': contaPrincipal,
      'ordem': ordem,
      'observacoes': observacoes,
      'origem_diagnostico': origemDiagnostico,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ContaModel copyWith({
    String? id,
    String? usuarioId,
    String? nome,
    String? tipo,
    String? banco,
    String? agencia,
    String? conta,
    double? saldoInicial,
    double? saldo,
    String? cor,
    String? icone,
    bool? ativo,
    bool? incluirSomaTotal,
    bool? contaPrincipal,
    int? ordem,
    String? observacoes,
    bool? origemDiagnostico,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContaModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      banco: banco ?? this.banco,
      agencia: agencia ?? this.agencia,
      conta: conta ?? this.conta,
      saldoInicial: saldoInicial ?? this.saldoInicial,
      saldo: saldo ?? this.saldo,
      cor: cor ?? this.cor,
      icone: icone ?? this.icone,
      ativo: ativo ?? this.ativo,
      incluirSomaTotal: incluirSomaTotal ?? this.incluirSomaTotal,
      contaPrincipal: contaPrincipal ?? this.contaPrincipal,
      ordem: ordem ?? this.ordem,
      observacoes: observacoes ?? this.observacoes,
      origemDiagnostico: origemDiagnostico ?? this.origemDiagnostico,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
  String toString() => 'ContaModel(id: $id, nome: $nome, saldo: $saldo)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContaModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}