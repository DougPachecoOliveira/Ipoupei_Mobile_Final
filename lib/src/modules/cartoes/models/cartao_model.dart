import '../utils/safe_conversions.dart';

class CartaoModel {
  final String id;
  final String usuarioId;
  final String nome;
  final double limite;
  final int diaFechamento; // 1-31
  final int diaVencimento; // 1-31
  final String? bandeira; // Visa, Mastercard, etc
  final String? banco;
  final String? contaDebitoId; // ID da conta para débito automático
  final String? cor; // Hex color #FF5722
  final String? observacoes;
  final bool ativo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus; // Para sync offline - 'pending', 'synced', 'error'

  const CartaoModel({
    required this.id,
    required this.usuarioId,
    required this.nome,
    required this.limite,
    required this.diaFechamento,
    required this.diaVencimento,
    this.bandeira,
    this.banco,
    this.contaDebitoId,
    this.cor,
    this.observacoes,
    this.ativo = true,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  /// ✅ FROM JSON (SUPABASE/SQLITE) - com conversões seguras
  factory CartaoModel.fromJson(Map<String, dynamic> json) {
    return CartaoModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      nome: json['nome'] as String,
      limite: SafeConversions.toDouble(json['limite']),
      diaFechamento: SafeConversions.toInt(json['dia_fechamento'], defaultValue: 1),
      diaVencimento: SafeConversions.toInt(json['dia_vencimento'], defaultValue: 10),
      bandeira: json['bandeira'] as String?,
      banco: json['banco'] as String?,
      contaDebitoId: json['conta_debito_id'] as String?,
      cor: json['cor'] as String?,
      observacoes: json['observacoes'] as String?,
      ativo: SafeConversions.toBoolean(json['ativo'], defaultValue: true),
      createdAt: SafeConversions.parseDateTimeWithFallback(json['created_at'], DateTime.now()),
      updatedAt: SafeConversions.parseDateTimeWithFallback(json['updated_at'], DateTime.now()),
      syncStatus: json['sync_status'] ?? 'pending',
    );
  }

  /// ✅ TO JSON (BOOLEAN → INTEGER PARA SQLITE)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome,
      'limite': limite,
      'dia_fechamento': diaFechamento,
      'dia_vencimento': diaVencimento,
      'bandeira': bandeira,
      'banco': banco,
      'conta_debito_id': contaDebitoId,
      'cor': cor,
      'observacoes': observacoes,
      'ativo': ativo ? 1 : 0, // ✅ Boolean → Integer
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  /// ✅ TO SUPABASE (MANTER BOOLEAN)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome,
      'limite': limite,
      'dia_fechamento': diaFechamento,
      'dia_vencimento': diaVencimento,
      'bandeira': bandeira,
      'banco': banco,
      'conta_debito_id': contaDebitoId,
      'cor': cor,
      'observacoes': observacoes,
      'ativo': ativo, // ✅ Boolean para Supabase
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// ✅ COPY WITH
  CartaoModel copyWith({
    String? id,
    String? usuarioId,
    String? nome,
    double? limite,
    int? diaFechamento,
    int? diaVencimento,
    String? bandeira,
    String? banco,
    String? contaDebitoId,
    String? cor,
    String? observacoes,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return CartaoModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nome: nome ?? this.nome,
      limite: limite ?? this.limite,
      diaFechamento: diaFechamento ?? this.diaFechamento,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      bandeira: bandeira ?? this.bandeira,
      banco: banco ?? this.banco,
      contaDebitoId: contaDebitoId ?? this.contaDebitoId,
      cor: cor ?? this.cor,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// ✅ EQUALITY
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartaoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// ✅ TO STRING
  @override
  String toString() {
    return 'CartaoModel(id: $id, nome: $nome, limite: $limite, ativo: $ativo)';
  }

  /// ✅ VALIDAÇÕES
  bool get isValid => 
      nome.trim().isNotEmpty && 
      limite > 0 && 
      diaFechamento >= 1 && 
      diaFechamento <= 31 &&
      diaVencimento >= 1 && 
      diaVencimento <= 31;

  /// ✅ FORMATTERS
  String get limiteFormatado => 'R\$ ${limite.toStringAsFixed(2).replaceAll('.', ',')}';
  
  String get diasFormatados => 'Fechamento: $diaFechamento | Vencimento: $diaVencimento';

  /// ✅ CORES PREDEFINIDAS
  static const Map<String, String> coresPadrao = {
    'Azul': '#2196F3',
    'Verde': '#4CAF50',
    'Laranja': '#FF9800',
    'Roxo': '#9C27B0',
    'Vermelho': '#F44336',
    'Cinza': '#9E9E9E',
  };

  /// ✅ BANDEIRAS COMUNS
  static const List<String> bandeirasPadrao = [
    'Visa',
    'Mastercard',
    'Elo',
    'American Express',
    'Hipercard',
    'Diners',
  ];
}