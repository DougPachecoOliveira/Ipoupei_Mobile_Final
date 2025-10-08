// 📊 Planejamento Model - iPoupei Mobile
//
// Modelo para planejamentos de orçamento
// Baseado na estrutura da tabela 'planejamentos' do Supabase
//
// Integração: Supabase + Local Database

class PlanejamentoModel {
  final String id;
  final String usuarioId;
  final int ano;
  final int mes;
  final String categoriaId;
  final String? subcategoriaId;
  final String tipo; // 'receita' ou 'despesa'
  final double valorPlanejado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Dados adicionais calculados
  final String? categoriaNome;
  final String? categoriaIcone;
  final String? categoriaCor;
  final String? subcategoriaNome;
  final double valorRealizado;
  final double valorPrevisto;
  final double mediaHistorica;
  final int totalTransacoesRealizadas;
  final int totalTransacoesPrevistas;

  const PlanejamentoModel({
    required this.id,
    required this.usuarioId,
    required this.ano,
    required this.mes,
    required this.categoriaId,
    this.subcategoriaId,
    required this.tipo,
    required this.valorPlanejado,
    this.createdAt,
    this.updatedAt,
    this.categoriaNome,
    this.categoriaIcone,
    this.categoriaCor,
    this.subcategoriaNome,
    this.valorRealizado = 0.0,
    this.valorPrevisto = 0.0,
    this.mediaHistorica = 0.0,
    this.totalTransacoesRealizadas = 0,
    this.totalTransacoesPrevistas = 0,
  });

  // ===========================
  // GETTERS CALCULADOS
  // ===========================

  /// Total do mês (realizado + previsto)
  double get totalMes => valorRealizado + valorPrevisto;

  /// Percentual de cumprimento da meta
  double get percentualCumprimento {
    if (valorPlanejado <= 0) return 0.0;
    return (totalMes / valorPlanejado) * 100;
  }

  /// Status da meta baseado no percentual
  StatusMeta get statusMeta {
    final pct = percentualCumprimento;
    if (pct <= 0) return StatusMeta.semDados;
    if (pct >= 100) return StatusMeta.ultrapassou;
    if (pct >= 80) return StatusMeta.boaCaminho;
    if (pct >= 50) return StatusMeta.emAndamento;
    return StatusMeta.baixo;
  }

  /// Cor para a barra de progresso
  String get corProgresso {
    switch (statusMeta) {
      case StatusMeta.ultrapassou:
        return '#ef4444'; // Vermelho
      case StatusMeta.boaCaminho:
        return '#10b981'; // Verde
      case StatusMeta.emAndamento:
        return '#f59e0b'; // Amarelo
      case StatusMeta.baixo:
        return '#6b7280'; // Cinza
      case StatusMeta.semDados:
        return '#d1d5db'; // Cinza claro
    }
  }

  /// Ícone para o status
  String get iconeStatus {
    switch (statusMeta) {
      case StatusMeta.ultrapassou:
        return '⚠️';
      case StatusMeta.boaCaminho:
        return '✅';
      case StatusMeta.emAndamento:
        return '🟡';
      case StatusMeta.baixo:
        return '🔴';
      case StatusMeta.semDados:
        return '⚫';
    }
  }

  /// Indica se é receita
  bool get isReceita => tipo == 'receita';

  /// Indica se é despesa
  bool get isDespesa => tipo == 'despesa';

  // ===========================
  // SERIALIZAÇÃO
  // ===========================

  factory PlanejamentoModel.fromJson(Map<String, dynamic> json) {
    return PlanejamentoModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      ano: json['ano'] as int,
      mes: json['mes'] as int,
      categoriaId: json['categoria_id'] as String,
      subcategoriaId: json['subcategoria_id'] as String?,
      tipo: json['tipo'] as String,
      valorPlanejado: (json['valor_planejado'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      categoriaNome: json['categoria_nome'] as String?,
      categoriaIcone: json['categoria_icone'] as String?,
      categoriaCor: json['categoria_cor'] as String?,
      subcategoriaNome: json['subcategoria_nome'] as String?,
      valorRealizado: (json['valor_realizado'] as num?)?.toDouble() ?? 0.0,
      valorPrevisto: (json['valor_previsto'] as num?)?.toDouble() ?? 0.0,
      mediaHistorica: (json['media_historica'] as num?)?.toDouble() ?? 0.0,
      totalTransacoesRealizadas: json['total_transacoes_realizadas'] as int? ?? 0,
      totalTransacoesPrevistas: json['total_transacoes_previstas'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'ano': ano,
      'mes': mes,
      'categoria_id': categoriaId,
      'subcategoria_id': subcategoriaId,
      'tipo': tipo,
      'valor_planejado': valorPlanejado,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // ⚠️ REMOVIDOS: campos virtuais que não existem na tabela física
      // 'categoria_nome': categoriaNome,
      // 'categoria_icone': categoriaIcone,
      // 'categoria_cor': categoriaCor,
      // 'subcategoria_nome': subcategoriaNome,
      // 'valor_realizado': valorRealizado,
      // 'valor_previsto': valorPrevisto,
      // 'media_historica': mediaHistorica,
      // 'total_transacoes_realizadas': totalTransacoesRealizadas,
      // 'total_transacoes_previstas': totalTransacoesPrevistas,
    };
  }

  /// Método separado para dados expandidos com joins
  Map<String, dynamic> toJsonExpanded() {
    return {
      ...toJson(),
      'categoria_nome': categoriaNome,
      'categoria_icone': categoriaIcone,
      'categoria_cor': categoriaCor,
      'subcategoria_nome': subcategoriaNome,
      'valor_realizado': valorRealizado,
      'valor_previsto': valorPrevisto,
      'media_historica': mediaHistorica,
      'total_transacoes_realizadas': totalTransacoesRealizadas,
      'total_transacoes_previstas': totalTransacoesPrevistas,
    };
  }

  // ===========================
  // UTILITÁRIOS
  // ===========================

  PlanejamentoModel copyWith({
    String? id,
    String? usuarioId,
    int? ano,
    int? mes,
    String? categoriaId,
    String? subcategoriaId,
    String? tipo,
    double? valorPlanejado,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoriaNome,
    String? categoriaIcone,
    String? categoriaCor,
    String? subcategoriaNome,
    double? valorRealizado,
    double? valorPrevisto,
    double? mediaHistorica,
    int? totalTransacoesRealizadas,
    int? totalTransacoesPrevistas,
  }) {
    return PlanejamentoModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      ano: ano ?? this.ano,
      mes: mes ?? this.mes,
      categoriaId: categoriaId ?? this.categoriaId,
      subcategoriaId: subcategoriaId ?? this.subcategoriaId,
      tipo: tipo ?? this.tipo,
      valorPlanejado: valorPlanejado ?? this.valorPlanejado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoriaNome: categoriaNome ?? this.categoriaNome,
      categoriaIcone: categoriaIcone ?? this.categoriaIcone,
      categoriaCor: categoriaCor ?? this.categoriaCor,
      subcategoriaNome: subcategoriaNome ?? this.subcategoriaNome,
      valorRealizado: valorRealizado ?? this.valorRealizado,
      valorPrevisto: valorPrevisto ?? this.valorPrevisto,
      mediaHistorica: mediaHistorica ?? this.mediaHistorica,
      totalTransacoesRealizadas: totalTransacoesRealizadas ?? this.totalTransacoesRealizadas,
      totalTransacoesPrevistas: totalTransacoesPrevistas ?? this.totalTransacoesPrevistas,
    );
  }

  @override
  String toString() {
    return 'PlanejamentoModel(id: $id, categoriaId: $categoriaId, subcategoriaId: $subcategoriaId, '
           'tipo: $tipo, valorPlanejado: $valorPlanejado, totalMes: $totalMes, '
           'percentual: ${percentualCumprimento.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanejamentoModel &&
           other.id == id &&
           other.categoriaId == categoriaId &&
           other.subcategoriaId == subcategoriaId &&
           other.ano == ano &&
           other.mes == mes;
  }

  @override
  int get hashCode {
    return Object.hash(id, categoriaId, subcategoriaId, ano, mes);
  }
}

// ===========================
// ENUM STATUS META
// ===========================

enum StatusMeta {
  semDados,      // 0%
  baixo,         // 1-49%
  emAndamento,   // 50-79%
  boaCaminho,    // 80-99%
  ultrapassou,   // >= 100%
}

// ===========================
// ENUM TIPOS
// ===========================

enum TipoPlanejamento {
  receita('receita'),
  despesa('despesa');

  const TipoPlanejamento(this.value);
  final String value;

  static TipoPlanejamento fromString(String value) {
    return values.firstWhere((e) => e.value == value);
  }
}