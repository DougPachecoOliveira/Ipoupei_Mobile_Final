import '../utils/safe_conversions.dart';

class FaturaModel {
  final String id;
  final String cartaoId;
  final String usuarioId;
  final int ano;
  final int mes;
  final DateTime dataFechamento;
  final DateTime dataVencimento;
  final double valorTotal;
  final double valorPago;
  final double valorMinimo;
  final String status; // 'aberta', 'fechada', 'vencida', 'paga'
  final bool paga;
  final DateTime? dataPagamento;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool sincronizado;

  const FaturaModel({
    required this.id,
    required this.cartaoId,
    required this.usuarioId,
    required this.ano,
    required this.mes,
    required this.dataFechamento,
    required this.dataVencimento,
    required this.valorTotal,
    this.valorPago = 0.0,
    required this.valorMinimo,
    required this.status,
    this.paga = false,
    this.dataPagamento,
    this.observacoes,
    required this.createdAt,
    required this.updatedAt,
    this.sincronizado = false,
  });

  /// ✅ PARSE BOOLEAN PARA SQLITE (0/1)
  static bool _parseBool(dynamic value) {
    if (value is int) return value == 1;
    if (value is bool) return value;
    return false;
  }

  /// ✅ FROM JSON (SUPABASE/SQLITE)
  factory FaturaModel.fromJson(Map<String, dynamic> json) {
    return FaturaModel(
      id: json['id'] as String,
      cartaoId: json['cartao_id'] as String,
      usuarioId: json['usuario_id'] as String,
      ano: SafeConversions.toInt(json['ano'], defaultValue: DateTime.now().year),
      mes: SafeConversions.toInt(json['mes'], defaultValue: DateTime.now().month),
      dataFechamento: SafeConversions.parseDateTimeWithFallback(json['data_fechamento'], DateTime.now()),
      dataVencimento: SafeConversions.parseDateTimeWithFallback(json['data_vencimento'], DateTime.now()),
      valorTotal: SafeConversions.toDouble(json['valor_total']),
      valorPago: SafeConversions.toDouble(json['valor_pago']),
      valorMinimo: SafeConversions.toDouble(json['valor_minimo']),
      status: json['status'] as String? ?? 'aberta',
      paga: SafeConversions.toBoolean(json['paga']),
      dataPagamento: SafeConversions.parseDateTime(json['data_pagamento']),
      observacoes: json['observacoes'] as String?,
      createdAt: SafeConversions.parseDateTimeWithFallback(json['created_at'], DateTime.now()),
      updatedAt: SafeConversions.parseDateTimeWithFallback(json['updated_at'], DateTime.now()),
      sincronizado: SafeConversions.toBoolean(json['sincronizado']),
    );
  }

  /// ✅ TO JSON (BOOLEAN → INTEGER PARA SQLITE)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartao_id': cartaoId,
      'usuario_id': usuarioId,
      'ano': ano,
      'mes': mes,
      'data_fechamento': dataFechamento.toIso8601String().split('T')[0],
      'data_vencimento': dataVencimento.toIso8601String().split('T')[0],
      'valor_total': valorTotal,
      'valor_pago': valorPago,
      'valor_minimo': valorMinimo,
      'status': status,
      'paga': paga ? 1 : 0, // ✅ Boolean → Integer
      'data_pagamento': dataPagamento?.toIso8601String().split('T')[0],
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0, // ✅ Boolean → Integer
    };
  }

  /// ✅ TO SUPABASE (MANTER BOOLEAN)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'cartao_id': cartaoId,
      'usuario_id': usuarioId,
      'ano': ano,
      'mes': mes,
      'data_fechamento': dataFechamento.toIso8601String().split('T')[0],
      'data_vencimento': dataVencimento.toIso8601String().split('T')[0],
      'valor_total': valorTotal,
      'valor_pago': valorPago,
      'valor_minimo': valorMinimo,
      'status': status,
      'paga': paga, // ✅ Boolean para Supabase
      'data_pagamento': dataPagamento?.toIso8601String().split('T')[0],
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// ✅ COPY WITH
  FaturaModel copyWith({
    String? id,
    String? cartaoId,
    String? usuarioId,
    int? ano,
    int? mes,
    DateTime? dataFechamento,
    DateTime? dataVencimento,
    double? valorTotal,
    double? valorPago,
    double? valorMinimo,
    String? status,
    bool? paga,
    DateTime? dataPagamento,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? sincronizado,
  }) {
    return FaturaModel(
      id: id ?? this.id,
      cartaoId: cartaoId ?? this.cartaoId,
      usuarioId: usuarioId ?? this.usuarioId,
      ano: ano ?? this.ano,
      mes: mes ?? this.mes,
      dataFechamento: dataFechamento ?? this.dataFechamento,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      valorTotal: valorTotal ?? this.valorTotal,
      valorPago: valorPago ?? this.valorPago,
      valorMinimo: valorMinimo ?? this.valorMinimo,
      status: status ?? this.status,
      paga: paga ?? this.paga,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// ✅ EQUALITY
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaturaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// ✅ TO STRING
  @override
  String toString() {
    return 'FaturaModel(id: $id, cartao: $cartaoId, ${_getNomeMes()}/$ano, valor: $valorTotalFormatado, status: $status)';
  }

  /// ✅ GETTERS COMPUTADOS
  
  /// Valor restante a pagar
  double get valorRestante => valorTotal - valorPago;
  
  /// Percentual pago
  double get percentualPago => valorTotal > 0 ? (valorPago / valorTotal) * 100 : 0;
  
  /// Está vencida?
  bool get isVencida => !paga && DateTime.now().isAfter(dataVencimento);
  
  /// Dias até vencimento (negativo se vencida)
  int get diasAteVencimento => dataVencimento.difference(DateTime.now()).inDays;
  
  /// Está próxima do vencimento? (5 dias)
  bool get isProximaVencimento => !paga && diasAteVencimento <= 5 && diasAteVencimento >= 0;

  /// ✅ FORMATTERS
  String get valorTotalFormatado => 'R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}';
  String get valorPagoFormatado => 'R\$ ${valorPago.toStringAsFixed(2).replaceAll('.', ',')}';
  String get valorRestanteFormatado => 'R\$ ${valorRestante.toStringAsFixed(2).replaceAll('.', ',')}';
  String get valorMinimoFormatado => 'R\$ ${valorMinimo.toStringAsFixed(2).replaceAll('.', ',')}';
  
  /// ✅ DESCRIÇÕES
  String get statusDescricao {
    switch (status) {
      case 'aberta': return 'Fatura Aberta';
      case 'fechada': return 'Fatura Fechada';
      case 'vencida': return 'Fatura Vencida';
      case 'paga': return 'Fatura Paga';
      case 'parcelado': return 'Parcelado';
      case 'parcial': return 'Pago Parcial';
      case 'futura': return 'Futura';
      default: return status;
    }
  }

  String get periodoFormatado => '${_getNomeMes()}/$ano';
  
  String get dataVencimentoFormatada {
    return '${dataVencimento.day.toString().padLeft(2, '0')}/${dataVencimento.month.toString().padLeft(2, '0')}/${dataVencimento.year}';
  }

  String _getNomeMes() {
    const meses = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return mes >= 1 && mes <= 12 ? meses[mes] : mes.toString();
  }

  /// ✅ VALIDAÇÕES
  bool get isValid => 
      cartaoId.isNotEmpty && 
      ano > 2000 && 
      mes >= 1 && mes <= 12 &&
      valorTotal >= 0 &&
      valorMinimo >= 0 &&
      valorPago >= 0 &&
      ['aberta', 'fechada', 'vencida', 'paga', 'parcelado', 'parcial', 'futura'].contains(status);

  /// ✅ CORES POR STATUS
  static const Map<String, String> statusCores = {
    'aberta': '#2196F3',     // Azul
    'fechada': '#FF9800',    // Laranja
    'vencida': '#F44336',    // Vermelho
    'paga': '#4CAF50',       // Verde
    'parcelado': '#9C27B0',  // Roxo
    'parcial': '#FFC107',    // Âmbar
    'futura': '#9E9E9E',     // Cinza
  };

  String get corStatus => statusCores[status] ?? '#9E9E9E';
}