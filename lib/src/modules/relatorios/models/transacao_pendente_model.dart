// 📌 Transação Pendente Model - iPoupei Mobile
//
// Modelo para transações vencidas e não efetivadas
// Inclui dados da categoria (ícone, cor) e agrupamento por data
//
// Critérios: efetivado = 0 AND data < hoje

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../categorias/data/categoria_icons.dart';

/// Modelo para transação pendente vencida
class TransacaoPendente {
  final String id;
  final String descricao;
  final double valor;
  final DateTime dataTransacao;
  final String tipo; // receita ou despesa
  final String? categoriaId;
  final String? categoriaNome;
  final String? categoriaCor;
  final String? categoriaIcone;

  TransacaoPendente({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.dataTransacao,
    required this.tipo,
    this.categoriaId,
    this.categoriaNome,
    this.categoriaCor,
    this.categoriaIcone,
  });

  /// Construtor a partir de dados do banco
  factory TransacaoPendente.fromMap(Map<String, dynamic> map) {
    return TransacaoPendente(
      id: map['id'] ?? '',
      descricao: map['descricao'] ?? 'Transação',
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      dataTransacao: DateTime.parse(map['data'] ?? DateTime.now().toIso8601String()),
      tipo: map['tipo'] ?? 'despesa',
      categoriaId: map['categoria_id'],
      categoriaNome: map['categoria_nome'] ?? 'Geral',
      categoriaCor: map['categoria_cor'],
      categoriaIcone: map['categoria_icone'],
    );
  }

  /// Calcular dias de atraso
  int get diasAtraso {
    final hoje = DateTime.now();
    final diferenca = hoje.difference(DateTime(dataTransacao.year, dataTransacao.month, dataTransacao.day));
    return diferenca.inDays;
  }

  /// Verificar se a transação está realmente vencida (data no passado)
  bool get isVencida {
    final hoje = DateTime.now();
    final dataTransacaoSemHora = DateTime(dataTransacao.year, dataTransacao.month, dataTransacao.day);
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    return dataTransacaoSemHora.isBefore(hojeSemHora);
  }

  /// Verificar se é crítica (mais de 7 dias atrasada)
  bool get isCritica => diasAtraso > 7;

  /// Texto de atraso
  String get textoAtraso {
    if (diasAtraso == 1) return 'Venceu ontem';
    if (diasAtraso <= 7) return 'Venceu há $diasAtraso dias';
    return 'Venceu há $diasAtraso dias';
  }

  /// Cor do tipo (receita/despesa)
  Color get corTipo {
    return tipo == 'receita'
        ? const Color(0xFF10B981) // Verde
        : const Color(0xFFDC3545); // Vermelho
  }

  /// Ícone discreto do tipo (receita/despesa) - para usar ao lado da descrição
  IconData get iconeDiscreto {
    return tipo == 'receita'
        ? Icons.arrow_upward // Seta para cima (receita)
        : Icons.arrow_downward; // Seta para baixo (despesa)
  }

  /// Cor da categoria ou padrão
  Color get corCategoria {
    if (categoriaCor != null && categoriaCor!.isNotEmpty) {
      try {
        // Tenta fazer parse da cor hexadecimal
        final hex = categoriaCor!.replaceAll('#', '');
        return Color(int.parse('0xFF$hex'));
      } catch (e) {
        // Fallback para cor do tipo
        return corTipo;
      }
    }
    return corTipo;
  }

  /// Ícone da categoria ou padrão
  IconData get iconeCategoria {
    if (categoriaIcone != null && categoriaIcone!.isNotEmpty) {
      try {
        return CategoriaIcons.getIconFromName(categoriaIcone!);
      } catch (e) {
        // Fallback para ícone padrão
      }
    }

    // Fallback para ícone baseado no tipo
    if (tipo == 'receita') {
      return Icons.trending_up_outlined;
    }
    return Icons.shopping_cart_outlined;
  }

  /// Widget do ícone da categoria renderizado
  Widget renderIconeCategoria({double size = 16, Color? color}) {
    if (categoriaIcone != null && categoriaIcone!.isNotEmpty) {
      return CategoriaIcons.renderIcon(
        categoriaIcone!,
        size,
        color: color ?? Colors.white,
      );
    }

    // Fallback
    return Icon(
      iconeCategoria,
      size: size,
      color: color ?? Colors.white,
    );
  }

  /// Data formatada para agrupamento
  String get dataFormatada => DateFormat('dd/MM/yyyy').format(dataTransacao);

  /// Data formatada compacta
  String get dataCompacta => DateFormat('dd/MM').format(dataTransacao);

  @override
  String toString() {
    return 'TransacaoPendente{'
        'id: $id, '
        'descricao: $descricao, '
        'valor: $valor, '
        'dataTransacao: $dataTransacao, '
        'diasAtraso: $diasAtraso'
        '}';
  }
}

/// Agrupamento de transações por data
class TransacoesPorData {
  final DateTime data;
  final List<TransacaoPendente> transacoes;

  TransacoesPorData({
    required this.data,
    required this.transacoes,
  });

  /// Valor total das transações da data
  double get valorTotal => transacoes.fold(0.0, (total, t) => total + t.valor);

  /// Quantidade de transações
  int get quantidade => transacoes.length;

  /// Data formatada
  String get dataFormatada => DateFormat('dd/MM/yyyy').format(data);

  /// Texto descritivo do grupo
  String get textoDescritivo {
    if (quantidade == 1) {
      return '$dataFormatada - 1 transação';
    }
    return '$dataFormatada - $quantidade transações';
  }

  /// Dias de atraso da data
  int get diasAtraso {
    final hoje = DateTime.now();
    final diferenca = hoje.difference(DateTime(data.year, data.month, data.day));
    return diferenca.inDays;
  }

  /// Cor da criticidade do grupo
  Color get corCriticidade {
    if (diasAtraso > 30) return const Color(0xFF7F1D1D); // Vermelho escuro
    if (diasAtraso > 7) return const Color(0xFFDC3545);  // Vermelho
    return const Color(0xFFEA580C); // Laranja
  }

  /// Verificar se o grupo é crítico
  bool get isCritico => diasAtraso > 7;

  @override
  String toString() {
    return 'TransacoesPorData{'
        'data: $data, '
        'quantidade: $quantidade, '
        'valorTotal: $valorTotal'
        '}';
  }
}

/// Resumo de transações pendentes
class ResumoTransacoesPendentes {
  final List<TransacoesPorData> gruposPorData;
  final int totalTransacoes;
  final double valorTotal;
  final int totalDias;

  ResumoTransacoesPendentes({
    required this.gruposPorData,
    required this.totalTransacoes,
    required this.valorTotal,
    required this.totalDias,
  });

  /// Criar resumo a partir de lista de transações
  factory ResumoTransacoesPendentes.fromTransacoes(List<TransacaoPendente> transacoes) {
    if (transacoes.isEmpty) {
      return ResumoTransacoesPendentes(
        gruposPorData: [],
        totalTransacoes: 0,
        valorTotal: 0.0,
        totalDias: 0,
      );
    }

    // Agrupar por data
    final Map<String, List<TransacaoPendente>> grupos = {};

    for (final transacao in transacoes) {
      final dataKey = transacao.dataFormatada;
      grupos[dataKey] ??= [];
      grupos[dataKey]!.add(transacao);
    }

    // Criar grupos ordenados por data (mais antigas primeiro)
    final gruposPorData = grupos.entries
        .map((entry) => TransacoesPorData(
              data: DateFormat('dd/MM/yyyy').parse(entry.key),
              transacoes: entry.value,
            ))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    return ResumoTransacoesPendentes(
      gruposPorData: gruposPorData,
      totalTransacoes: transacoes.length,
      valorTotal: transacoes.fold(0.0, (total, t) => total + t.valor),
      totalDias: gruposPorData.length,
    );
  }

  /// Verificar se tem transações
  bool get hasTransacoes => totalTransacoes > 0;

  /// Verificar se tem transações críticas
  bool get hasTransacoesCriticas => gruposPorData.any((g) => g.isCritico);

  /// Quantidade de transações críticas
  int get quantidadeCriticas => gruposPorData
      .where((g) => g.isCritico)
      .fold(0, (total, g) => total + g.quantidade);

  @override
  String toString() {
    return 'ResumoTransacoesPendentes{'
        'totalTransacoes: $totalTransacoes, '
        'valorTotal: $valorTotal, '
        'totalDias: $totalDias'
        '}';
  }
}

/// Extensões para facilitar o uso
extension TransacoesPendentesExtension on List<TransacaoPendente> {
  /// Agrupar por data
  ResumoTransacoesPendentes get agrupadoPorData =>
      ResumoTransacoesPendentes.fromTransacoes(this);

  /// Filtrar apenas críticas
  List<TransacaoPendente> get apenasCriticas =>
      where((t) => t.isCritica).toList();

  /// Filtrar apenas vencidas (data no passado)
  List<TransacaoPendente> get apenasVencidas =>
      where((t) => t.isVencida).toList();

  /// Ordenar por data (mais antigas primeiro)
  List<TransacaoPendente> get ordenadasPorData {
    final lista = List<TransacaoPendente>.from(this);
    lista.sort((a, b) => a.dataTransacao.compareTo(b.dataTransacao));
    return lista;
  }

  /// Valor total
  double get valorTotal => fold(0.0, (total, t) => total + t.valor);

  /// Quantidade por tipo
  int quantidadePorTipo(String tipo) => where((t) => t.tipo == tipo).length;
}