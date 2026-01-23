// 🏷️ Transação Importada Model - iPoupei Mobile
//
// Modelo para transações extraídas de arquivos bancários
// Representa dados parseados antes de serem salvos como TransacaoModel
//
// Baseado em: TransacaoModel + dados específicos de importação

import 'dart:convert';

/// Modelo para transações extraídas de arquivos bancários
class TransacaoImportada {
  final String id;
  final DateTime data;
  final String descricao;
  final double valor;
  final String tipo; // 'receita' ou 'despesa'
  final String origem; // 'CSV', 'PDF', 'OFX', etc.
  final String usuarioId;

  // IDs para vincular
  final String? contaId;
  final String? cartaoId;
  final String? categoriaId;
  final String? subcategoriaId;
  final DateTime? faturaVencimento;

  // Estados
  final bool efetivado;
  final String observacoes;

  // Dados da importação
  final String linhaBruta;
  final int indiceOriginal;
  final Map<String, dynamic> metadados;
  final String? fingerprintImportacao;

  TransacaoImportada({
    required this.id,
    required this.data,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.origem,
    required this.usuarioId,
    this.contaId,
    this.cartaoId,
    this.categoriaId,
    this.subcategoriaId,
    this.faturaVencimento,
    this.efetivado = false,
    this.observacoes = '',
    this.linhaBruta = '',
    this.indiceOriginal = 0,
    this.metadados = const {},
    this.fingerprintImportacao,
  });

  /// Cria cópia com campos modificados
  TransacaoImportada copyWith({
    String? id,
    DateTime? data,
    String? descricao,
    double? valor,
    String? tipo,
    String? origem,
    String? usuarioId,
    String? contaId,
    String? cartaoId,
    String? categoriaId,
    String? subcategoriaId,
    DateTime? faturaVencimento,
    bool? efetivado,
    String? observacoes,
    String? linhaBruta,
    int? indiceOriginal,
    Map<String, dynamic>? metadados,
    String? fingerprintImportacao,
  }) {
    return TransacaoImportada(
      id: id ?? this.id,
      data: data ?? this.data,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      origem: origem ?? this.origem,
      usuarioId: usuarioId ?? this.usuarioId,
      contaId: contaId ?? this.contaId,
      cartaoId: cartaoId ?? this.cartaoId,
      categoriaId: categoriaId ?? this.categoriaId,
      subcategoriaId: subcategoriaId ?? this.subcategoriaId,
      faturaVencimento: faturaVencimento ?? this.faturaVencimento,
      efetivado: efetivado ?? this.efetivado,
      observacoes: observacoes ?? this.observacoes,
      linhaBruta: linhaBruta ?? this.linhaBruta,
      indiceOriginal: indiceOriginal ?? this.indiceOriginal,
      metadados: metadados ?? this.metadados,
      fingerprintImportacao: fingerprintImportacao ?? this.fingerprintImportacao,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'origem': origem,
      'usuarioId': usuarioId,
      'contaId': contaId,
      'cartaoId': cartaoId,
      'categoriaId': categoriaId,
      'subcategoriaId': subcategoriaId,
      'faturaVencimento': faturaVencimento?.toIso8601String(),
      'efetivado': efetivado,
      'observacoes': observacoes,
      'linhaBruta': linhaBruta,
      'indiceOriginal': indiceOriginal,
      'metadados': metadados,
      'fingerprintImportacao': fingerprintImportacao,
    };
  }

  /// Cria instância do JSON
  factory TransacaoImportada.fromJson(Map<String, dynamic> json) {
    return TransacaoImportada(
      id: json['id'] ?? '',
      data: DateTime.parse(json['data']),
      descricao: json['descricao'] ?? '',
      valor: (json['valor'] ?? 0.0).toDouble(),
      tipo: json['tipo'] ?? 'despesa',
      origem: json['origem'] ?? 'CSV',
      usuarioId: json['usuarioId'] ?? '',
      contaId: json['contaId'],
      cartaoId: json['cartaoId'],
      categoriaId: json['categoriaId'],
      subcategoriaId: json['subcategoriaId'],
      faturaVencimento: json['faturaVencimento'] != null
          ? DateTime.parse(json['faturaVencimento'])
          : null,
      efetivado: json['efetivado'] ?? false,
      observacoes: json['observacoes'] ?? '',
      linhaBruta: json['linhaBruta'] ?? '',
      indiceOriginal: json['indiceOriginal'] ?? 0,
      metadados: Map<String, dynamic>.from(json['metadados'] ?? {}),
      fingerprintImportacao: json['fingerprintImportacao'],
    );
  }

  /// Cria lista do JSON
  static List<TransacaoImportada> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => TransacaoImportada.fromJson(json))
        .toList();
  }

  /// Converte para string JSON
  String toJsonString() => jsonEncode(toJson());

  /// Verifica se é válida para salvar
  bool get isValida {
    return descricao.trim().isNotEmpty &&
           valor > 0 &&
           (contaId != null || cartaoId != null) &&
           categoriaId != null &&
           categoriaId!.isNotEmpty;
  }

  /// Indica se é transação de conta bancária
  bool get isContaBancaria => contaId != null && contaId!.isNotEmpty;

  /// Indica se é transação de cartão de crédito
  bool get isCartaoCredito => cartaoId != null && cartaoId!.isNotEmpty;

  /// Valor formatado em moeda brasileira
  String get valorFormatado {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Data formatada para exibição
  String get dataFormatada {
    return '${data.day.toString().padLeft(2, '0')}/'
           '${data.month.toString().padLeft(2, '0')}/'
           '${data.year}';
  }

  /// Resumo para debug
  String get resumo {
    return '$dataFormatada - $descricao - $valorFormatado ($tipo)';
  }

  /// Gera fingerprint de importação baseado nos dados da transação
  String gerarFingerprint(String nomeArquivo) {
    // Normalizar descrição: lowercase, trim, colapsar espaços
    final descricaoNormalizada = descricao
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    // Formato da data: YYYYMMDD
    final dataFormatada = '${data.year.toString().padLeft(4, '0')}'
        '${data.month.toString().padLeft(2, '0')}'
        '${data.day.toString().padLeft(2, '0')}';

    // Valor normalizado (sempre 2 casas decimais)
    final valorFormatado = valor.toStringAsFixed(2);

    // Arquivo de origem normalizado
    final arquivoNormalizado = nomeArquivo.toLowerCase().trim();

    return '$dataFormatada|$valorFormatado|$descricaoNormalizada|$arquivoNormalizado';
  }

  @override
  String toString() {
    return 'TransacaoImportada{'
           'id: $id, '
           'data: $dataFormatada, '
           'descricao: $descricao, '
           'valor: $valorFormatado, '
           'tipo: $tipo, '
           'origem: $origem'
           '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransacaoImportada &&
           other.id == id &&
           other.data == data &&
           other.descricao == descricao &&
           other.valor == valor &&
           other.tipo == tipo;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           data.hashCode ^
           descricao.hashCode ^
           valor.hashCode ^
           tipo.hashCode;
  }
}