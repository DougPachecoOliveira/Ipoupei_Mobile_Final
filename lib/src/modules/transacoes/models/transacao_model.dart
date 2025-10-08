// 💳 Transacao Model - iPoupei Mobile
// 
// Modelo de dados para transações financeiras
// Estrutura idêntica ao Supabase (39 colunas)
// 
// Baseado em: Data Model Pattern

class TransacaoModel {
  final String id;
  final String usuarioId;
  final String? contaId;
  final String? contaDestinoId;
  final String? cartaoId;
  final String? categoriaId;
  final String? subcategoriaId;
  final String tipo; // 'receita', 'despesa', 'transferencia'
  final String descricao;
  final double valor;
  final DateTime data;
  final bool efetivado;
  final String? observacoes;
  final String? recorrencia;
  final int? numeroParcelaAtual;
  final int? numeroTotalParcelas;
  // Campos de parcelamento (padrão do SQLite)
  final int? parcelaAtual;
  final int? totalParcelas; 
  final String? grupoParcelamento;
  final String? transacaoOrigemId;
  final bool parcelaUnica;
  final DateTime? dataLimite;
  final String? status;
  final String? tipoCartao;
  final bool isCartaoCredito;
  final bool ajusteManual;
  final String? motivoAjuste;
  final String? tagTransacao;
  final double? taxaConversao;
  final String? moedaOriginal;
  final double? valorOriginal;
  final String? localizacaoGps;
  final String? anexos;
  final String? hashVerificacao;
  final bool sincronizado;
  final DateTime? dataSincronizacao;
  final String? idExterno;
  final String? origemImportacao;
  final String? metadados;
  
  // ✅ CAMPOS DE RECORRÊNCIA (REACT)
  final String? grupoRecorrencia;
  final bool ehRecorrente;
  final String? tipoRecorrencia; // 'semanal', 'quinzenal', 'mensal', 'anual'
  final int? numeroRecorrencia;
  final int? totalRecorrencias;
  final DateTime? dataProximaRecorrencia;
  final bool recorrente;
  
  // ✅ TIPOS DE TRANSAÇÃO (REACT)
  final String? tipoReceita; // 'extra', 'previsivel', 'parcelada'
  final String? tipoDespesa; // 'extra', 'previsivel', 'parcelada'
  
  // ✅ CAMPOS DE CARTÃO (REACT)
  final double? valorParcela;
  final int? numeroParcelas;
  final DateTime? faturaVencimento;
  
  // ✅ CAMPOS DE AUDITORIA (REACT)
  final DateTime? dataEfetivacao;
  final bool transferencia;
  
  // ✅ CAMPOS AVANÇADOS (REACT)
  final List<String>? tags;
  final Map<String, dynamic>? localizacao;
  final List<String>? compartilhadaCom;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  TransacaoModel({
    required this.id,
    required this.usuarioId,
    this.contaId,
    this.contaDestinoId,
    this.cartaoId,
    this.categoriaId,
    this.subcategoriaId,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
    this.efetivado = true,
    this.observacoes,
    this.recorrencia,
    this.numeroParcelaAtual,
    this.numeroTotalParcelas,
    this.parcelaAtual,
    this.totalParcelas,
    this.grupoParcelamento,
    this.transacaoOrigemId,
    this.parcelaUnica = true,
    this.dataLimite,
    this.status,
    this.tipoCartao,
    this.isCartaoCredito = false,
    this.ajusteManual = false,
    this.motivoAjuste,
    this.tagTransacao,
    this.taxaConversao,
    this.moedaOriginal,
    this.valorOriginal,
    this.localizacaoGps,
    this.anexos,
    this.hashVerificacao,
    this.sincronizado = false,
    this.dataSincronizacao,
    this.idExterno,
    this.origemImportacao,
    this.metadados,
    
    // ✅ NOVOS CAMPOS REACT
    this.grupoRecorrencia,
    this.ehRecorrente = false,
    this.tipoRecorrencia,
    this.numeroRecorrencia,
    this.totalRecorrencias,
    this.dataProximaRecorrencia,
    this.recorrente = false,
    this.tipoReceita,
    this.tipoDespesa,
    this.valorParcela,
    this.numeroParcelas,
    this.faturaVencimento,
    this.dataEfetivacao,
    this.transferencia = false,
    this.tags,
    this.localizacao,
    this.compartilhadaCom,
    
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransacaoModel.fromJson(Map<String, dynamic> json) {
    return TransacaoModel(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      contaId: json['conta_id'],
      contaDestinoId: json['conta_destino_id'],
      cartaoId: json['cartao_id'],
      categoriaId: json['categoria_id'],
      subcategoriaId: json['subcategoria_id'],
      tipo: json['tipo'] ?? 'despesa',
      descricao: json['descricao'] ?? '',
      valor: _parseDouble(json['valor']),
      data: _parseDateTime(json['data']),
      efetivado: _parseBool(json['efetivado']),
      observacoes: json['observacoes'],
      recorrencia: json['recorrencia'], // ✅ Campo correto para recorrencia String?
      numeroParcelaAtual: json['parcela_atual'], 
      numeroTotalParcelas: json['total_parcelas'],
      parcelaAtual: json['parcela_atual'],
      totalParcelas: json['total_parcelas'],
      grupoParcelamento: json['grupo_parcelamento'],
      transacaoOrigemId: json['transacao_origem_id'],
      parcelaUnica: _parseBool(json['parcela_unica']),
      dataLimite: _parseDateTimeOptional(json['data_limite']),
      status: json['status'],
      tipoCartao: json['tipo_cartao'],
      isCartaoCredito: _parseBool(json['is_cartao_credito']),
      ajusteManual: _parseBool(json['ajuste_manual']),
      motivoAjuste: json['motivo_ajuste'],
      tagTransacao: json['tag_transacao'],
      taxaConversao: _parseDoubleOptional(json['taxa_conversao']),
      moedaOriginal: json['moeda_original'],
      valorOriginal: _parseDoubleOptional(json['valor_original']),
      localizacaoGps: json['localizacao_gps'],
      anexos: json['anexos'],
      hashVerificacao: json['hash_verificacao'],
      sincronizado: _parseBool(json['sincronizado']),
      dataSincronizacao: _parseDateTimeOptional(json['data_sincronizacao']),
      idExterno: json['id_externo'],
      origemImportacao: json['origem_importacao'],
      metadados: json['metadados'],
      
      // ✅ NOVOS CAMPOS REACT (com _parseBool para SQLite)
      grupoRecorrencia: json['grupo_recorrencia'],
      ehRecorrente: _parseBool(json['eh_recorrente']),
      tipoRecorrencia: json['tipo_recorrencia'],
      numeroRecorrencia: json['numero_recorrencia'],
      totalRecorrencias: json['total_recorrencias'],
      dataProximaRecorrencia: _parseDateTimeOptional(json['data_proxima_recorrencia']),
      recorrente: _parseBool(json['recorrente']),
      tipoReceita: json['tipo_receita'],
      tipoDespesa: json['tipo_despesa'],
      valorParcela: _parseDoubleOptional(json['valor_parcela']),
      numeroParcelas: json['numero_parcelas'],
      faturaVencimento: _parseDateTimeOptional(json['fatura_vencimento']),
      dataEfetivacao: _parseDateTimeOptional(json['data_efetivacao']),
      transferencia: _parseBool(json['transferencia']),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      localizacao: json['localizacao'],
      compartilhadaCom: json['compartilhada_com'] != null ? List<String>.from(json['compartilhada_com']) : null,
      
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'conta_id': contaId,
      'conta_destino_id': contaDestinoId,
      'cartao_id': cartaoId,
      'categoria_id': categoriaId,
      'subcategoria_id': subcategoriaId,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String().split('T')[0],
      'efetivado': efetivado ? 1 : 0,
      'observacoes': observacoes,
      'eh_recorrente': ehRecorrente ? 1 : 0,
      'parcela_atual': parcelaAtual,
      'total_parcelas': totalParcelas,
      'grupo_parcelamento': grupoParcelamento,
      'transacao_origem_id': transacaoOrigemId,
      'parcela_unica': parcelaUnica ? 1 : 0,
      'data_limite': dataLimite?.toIso8601String().split('T')[0],
      'status': status,
      'tipo_cartao': tipoCartao,
      'is_cartao_credito': isCartaoCredito ? 1 : 0,
      'ajuste_manual': ajusteManual ? 1 : 0,
      'motivo_ajuste': motivoAjuste,
      'tag_transacao': tagTransacao,
      'taxa_conversao': taxaConversao,
      'moeda_original': moedaOriginal,
      'valor_original': valorOriginal,
      'localizacao_gps': localizacaoGps,
      'anexos': anexos,
      'hash_verificacao': hashVerificacao,
      'sincronizado': sincronizado ? 1 : 0,
      'data_sincronizacao': dataSincronizacao?.toIso8601String(),
      'id_externo': idExterno,
      'origem_importacao': origemImportacao,
      'metadados': metadados,
      
      // ✅ NOVOS CAMPOS REACT (convertendo boolean para INTEGER)
      'grupo_recorrencia': grupoRecorrencia,
      'eh_recorrente': ehRecorrente ? 1 : 0,
      'tipo_recorrencia': tipoRecorrencia,
      'numero_recorrencia': numeroRecorrencia,
      'total_recorrencias': totalRecorrencias,
      'data_proxima_recorrencia': dataProximaRecorrencia?.toIso8601String().split('T')[0],
      'recorrente': recorrente ? 1 : 0,
      'tipo_receita': tipoReceita,
      'tipo_despesa': tipoDespesa,
      'valor_parcela': valorParcela,
      'numero_parcelas': numeroParcelas,
      'fatura_vencimento': faturaVencimento?.toIso8601String().split('T')[0],
      'data_efetivacao': dataEfetivacao?.toIso8601String(),
      'transferencia': transferencia ? 1 : 0,
      'tags': tags,
      'localizacao': localizacao,
      'compartilhada_com': compartilhadaCom,
      
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// ✅ TO SUPABASE JSON (SEM CAMPOS EXCLUSIVOS DO SQLITE)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'conta_id': contaId,
      'conta_destino_id': contaDestinoId,
      'cartao_id': cartaoId,
      'categoria_id': categoriaId,
      'subcategoria_id': subcategoriaId,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String().split('T')[0],
      'efetivado': efetivado, // ✅ Boolean para Supabase
      'observacoes': observacoes,
      'eh_recorrente': ehRecorrente, // ✅ Boolean para Supabase
      'numero_total_parcelas': numeroTotalParcelas,
      'parcela_atual': parcelaAtual,
      'total_parcelas': totalParcelas,
      'grupo_parcelamento': grupoParcelamento,
      'transacao_origem_id': transacaoOrigemId,
      'parcela_unica': parcelaUnica, // ✅ Boolean para Supabase
      'data_limite': dataLimite?.toIso8601String().split('T')[0],
      'status': status,
      'tipo_cartao': tipoCartao,
      // ❌ REMOVIDO: 'is_cartao_credito' - Campo não existe no Supabase
      'ajuste_manual': ajusteManual, // ✅ Boolean para Supabase
      'motivo_ajuste': motivoAjuste,
      'tag_transacao': tagTransacao,
      'taxa_conversao': taxaConversao,
      'moeda_original': moedaOriginal,
      'valor_original': valorOriginal,
      'localizacao_gps': localizacaoGps,
      'anexos': anexos,
      'hash_verificacao': hashVerificacao,
      // ❌ REMOVIDO: 'sincronizado' - Campo não existe no Supabase
      'data_sincronizacao': dataSincronizacao?.toIso8601String(),
      'id_externo': idExterno,
      'origem_importacao': origemImportacao,
      'metadados': metadados,
      
      // ✅ NOVOS CAMPOS REACT (mantendo boolean para Supabase)
      'grupo_recorrencia': grupoRecorrencia,
      'eh_recorrente': ehRecorrente, // ✅ Boolean para Supabase
      'tipo_recorrencia': tipoRecorrencia,
      'numero_recorrencia': numeroRecorrencia,
      'total_recorrencias': totalRecorrencias,
      'data_proxima_recorrencia': dataProximaRecorrencia?.toIso8601String().split('T')[0],
      'recorrente': recorrente, // ✅ Boolean para Supabase
      'tipo_receita': tipoReceita,
      'tipo_despesa': tipoDespesa,
      'valor_parcela': valorParcela,
      'numero_parcelas': numeroParcelas,
      'fatura_vencimento': faturaVencimento?.toIso8601String().split('T')[0],
      'data_efetivacao': dataEfetivacao?.toIso8601String(),
      'transferencia': transferencia, // ✅ Boolean para Supabase
      'tags': tags,
      'localizacao': localizacao,
      'compartilhada_com': compartilhadaCom,
      
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransacaoModel copyWith({
    String? id,
    String? usuarioId,
    String? contaId,
    String? contaDestinoId,
    String? cartaoId,
    String? categoriaId,
    String? subcategoriaId,
    String? tipo,
    String? descricao,
    double? valor,
    DateTime? data,
    bool? efetivado,
    String? observacoes,
    String? recorrencia,
    int? numeroParcelaAtual,
    int? numeroTotalParcelas,
    String? transacaoOrigemId,
    bool? parcelaUnica,
    DateTime? dataLimite,
    String? status,
    String? tipoCartao,
    bool? isCartaoCredito,
    bool? ajusteManual,
    String? motivoAjuste,
    String? tagTransacao,
    double? taxaConversao,
    String? moedaOriginal,
    double? valorOriginal,
    String? localizacaoGps,
    String? anexos,
    String? hashVerificacao,
    bool? sincronizado,
    DateTime? dataSincronizacao,
    String? idExterno,
    String? origemImportacao,
    String? metadados,
    
    // ✅ NOVOS CAMPOS REACT
    String? grupoRecorrencia,
    bool? ehRecorrente,
    String? tipoRecorrencia,
    int? numeroRecorrencia,
    int? totalRecorrencias,
    DateTime? dataProximaRecorrencia,
    bool? recorrente,
    String? tipoReceita,
    String? tipoDespesa,
    double? valorParcela,
    int? numeroParcelas,
    DateTime? faturaVencimento,
    DateTime? dataEfetivacao,
    bool? transferencia,
    List<String>? tags,
    Map<String, dynamic>? localizacao,
    List<String>? compartilhadaCom,
    
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransacaoModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      contaId: contaId ?? this.contaId,
      contaDestinoId: contaDestinoId ?? this.contaDestinoId,
      cartaoId: cartaoId ?? this.cartaoId,
      categoriaId: categoriaId ?? this.categoriaId,
      subcategoriaId: subcategoriaId ?? this.subcategoriaId,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      efetivado: efetivado ?? this.efetivado,
      observacoes: observacoes ?? this.observacoes,
      recorrencia: recorrencia ?? this.recorrencia,
      numeroParcelaAtual: numeroParcelaAtual ?? this.numeroParcelaAtual,
      numeroTotalParcelas: numeroTotalParcelas ?? this.numeroTotalParcelas,
      transacaoOrigemId: transacaoOrigemId ?? this.transacaoOrigemId,
      parcelaUnica: parcelaUnica ?? this.parcelaUnica,
      dataLimite: dataLimite ?? this.dataLimite,
      status: status ?? this.status,
      tipoCartao: tipoCartao ?? this.tipoCartao,
      isCartaoCredito: isCartaoCredito ?? this.isCartaoCredito,
      ajusteManual: ajusteManual ?? this.ajusteManual,
      motivoAjuste: motivoAjuste ?? this.motivoAjuste,
      tagTransacao: tagTransacao ?? this.tagTransacao,
      taxaConversao: taxaConversao ?? this.taxaConversao,
      moedaOriginal: moedaOriginal ?? this.moedaOriginal,
      valorOriginal: valorOriginal ?? this.valorOriginal,
      localizacaoGps: localizacaoGps ?? this.localizacaoGps,
      anexos: anexos ?? this.anexos,
      hashVerificacao: hashVerificacao ?? this.hashVerificacao,
      sincronizado: sincronizado ?? this.sincronizado,
      dataSincronizacao: dataSincronizacao ?? this.dataSincronizacao,
      idExterno: idExterno ?? this.idExterno,
      origemImportacao: origemImportacao ?? this.origemImportacao,
      metadados: metadados ?? this.metadados,
      
      // ✅ NOVOS CAMPOS REACT
      grupoRecorrencia: grupoRecorrencia ?? this.grupoRecorrencia,
      ehRecorrente: ehRecorrente ?? this.ehRecorrente,
      tipoRecorrencia: tipoRecorrencia ?? this.tipoRecorrencia,
      numeroRecorrencia: numeroRecorrencia ?? this.numeroRecorrencia,
      totalRecorrencias: totalRecorrencias ?? this.totalRecorrencias,
      dataProximaRecorrencia: dataProximaRecorrencia ?? this.dataProximaRecorrencia,
      recorrente: recorrente ?? this.recorrente,
      tipoReceita: tipoReceita ?? this.tipoReceita,
      tipoDespesa: tipoDespesa ?? this.tipoDespesa,
      valorParcela: valorParcela ?? this.valorParcela,
      numeroParcelas: numeroParcelas ?? this.numeroParcelas,
      faturaVencimento: faturaVencimento ?? this.faturaVencimento,
      dataEfetivacao: dataEfetivacao ?? this.dataEfetivacao,
      transferencia: transferencia ?? this.transferencia,
      tags: tags ?? this.tags,
      localizacao: localizacao ?? this.localizacao,
      compartilhadaCom: compartilhadaCom ?? this.compartilhadaCom,
      
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods para parsing
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseDoubleOptional(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _parseDateTimeOptional(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }

  @override
  String toString() => 'TransacaoModel(id: $id, descricao: $descricao, valor: $valor)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransacaoModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}