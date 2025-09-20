import 'cartao_model.dart';

/// ✅ CARTÃO ENRIQUECIDO COM DADOS CALCULADOS
/// Extensão do CartaoModel que inclui campos calculados equivalentes ao React
/// Usado apenas para exibição - não é salvo no banco
class CartaoEnrichedModel extends CartaoModel {
  final double? gastoAtual;           // Equivalente ao React useCartoesData
  final String? proximaFaturaVencimento;  // Equivalente ao React
  final String? mesReferenciaAtual;   // Equivalente ao React

  const CartaoEnrichedModel({
    required super.id,
    required super.usuarioId,
    required super.nome,
    required super.limite,
    required super.diaFechamento,
    required super.diaVencimento,
    super.bandeira,
    super.banco,
    super.contaDebitoId,
    super.cor,
    super.observacoes,
    super.ativo = true,
    required super.createdAt,
    required super.updatedAt,
    super.syncStatus = 'pending',
    // ✅ CAMPOS ENRIQUECIDOS
    this.gastoAtual,
    this.proximaFaturaVencimento,
    this.mesReferenciaAtual,
  });

  /// ✅ CRIAR A PARTIR DE CartaoModel BASE
  factory CartaoEnrichedModel.fromCartao(
    CartaoModel cartao, {
    double? gastoAtual,
    String? proximaFaturaVencimento,
    String? mesReferenciaAtual,
  }) {
    return CartaoEnrichedModel(
      id: cartao.id,
      usuarioId: cartao.usuarioId,
      nome: cartao.nome,
      limite: cartao.limite,
      diaFechamento: cartao.diaFechamento,
      diaVencimento: cartao.diaVencimento,
      bandeira: cartao.bandeira,
      banco: cartao.banco,
      contaDebitoId: cartao.contaDebitoId,
      cor: cartao.cor,
      observacoes: cartao.observacoes,
      ativo: cartao.ativo,
      createdAt: cartao.createdAt,
      updatedAt: cartao.updatedAt,
      syncStatus: cartao.syncStatus,
      // ✅ CAMPOS CALCULADOS
      gastoAtual: gastoAtual,
      proximaFaturaVencimento: proximaFaturaVencimento,
      mesReferenciaAtual: mesReferenciaAtual,
    );
  }

  /// ✅ FORMATTERS ADICIONAIS (EQUIVALENTES AO REACT)
  String get gastoAtualFormatado => gastoAtual != null 
      ? 'R\$ ${gastoAtual!.toStringAsFixed(2).replaceAll('.', ',')}'
      : 'R\$ 0,00';

  double get limiteDisponivel => limite - (gastoAtual ?? 0.0);

  String get limiteDisponivelFormatado => 
      'R\$ ${limiteDisponivel.toStringAsFixed(2).replaceAll('.', ',')}';

  double get percentualUtilizado => limite > 0 ? ((gastoAtual ?? 0.0) / limite) * 100 : 0.0;

  String get percentualUtilizadoFormatado => '${percentualUtilizado.toStringAsFixed(1)}%';

  /// ✅ STATUS DE UTILIZAÇÃO (IGUAL REACT cartoesUtils.js)
  String get statusUtilizacao {
    if (percentualUtilizado <= 30) return 'status-verde';
    if (percentualUtilizado <= 60) return 'status-amarelo';
    return 'status-vermelho';
  }

  /// ✅ COPY WITH ESTENDIDO
  @override
  CartaoEnrichedModel copyWith({
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
    // ✅ CAMPOS ENRIQUECIDOS
    double? gastoAtual,
    String? proximaFaturaVencimento,
    String? mesReferenciaAtual,
  }) {
    return CartaoEnrichedModel(
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
      // ✅ CAMPOS ENRIQUECIDOS
      gastoAtual: gastoAtual ?? this.gastoAtual,
      proximaFaturaVencimento: proximaFaturaVencimento ?? this.proximaFaturaVencimento,
      mesReferenciaAtual: mesReferenciaAtual ?? this.mesReferenciaAtual,
    );
  }

  /// ✅ TO STRING ESTENDIDO
  @override
  String toString() {
    return 'CartaoEnrichedModel(id: $id, nome: $nome, limite: $limite, gastoAtual: $gastoAtual, ativo: $ativo)';
  }
}