// 💳 Fatura Pendente Model - iPoupei Mobile
//
// Modelo compacto para faturas de cartão vencidas ou próximas ao vencimento
// Foco: Alertas urgentes para o usuário
//
// Critérios: Vencidas OU vencendo nos próximos 3 dias

import 'package:flutter/material.dart';

/// Modelo compacto para faturas pendentes de cartão
class FaturaPendente {
  final String cartaoId;
  final String nomeCartao;
  final double valorFatura;
  final DateTime dataVencimento;
  final String? corCartao; // Para visual do cartão

  FaturaPendente({
    required this.cartaoId,
    required this.nomeCartao,
    required this.valorFatura,
    required this.dataVencimento,
    this.corCartao,
  });

  /// Construtor vazio para testes
  factory FaturaPendente.empty() {
    return FaturaPendente(
      cartaoId: '',
      nomeCartao: 'Cartão Exemplo',
      valorFatura: 0.0,
      dataVencimento: DateTime.now(),
    );
  }

  /// Criar a partir de dados do banco
  factory FaturaPendente.fromMap(Map<String, dynamic> map) {
    return FaturaPendente(
      cartaoId: map['cartao_id'] ?? '',
      nomeCartao: map['nome_cartao'] ?? 'Cartão',
      valorFatura: (map['valor_fatura'] as num?)?.toDouble() ?? 0.0,
      dataVencimento: DateTime.parse(map['data_vencimento'] ?? DateTime.now().toIso8601String()),
      corCartao: map['cor_cartao'],
    );
  }

  /// Calcular dias até o vencimento (negativo se vencido)
  int get diasAteVencimento {
    final hoje = DateTime.now();
    final diferenca = dataVencimento.difference(DateTime(hoje.year, hoje.month, hoje.day));
    return diferenca.inDays;
  }

  /// Verificar se está vencida
  bool get isVencida => diasAteVencimento < 0;

  /// Verificar se vence hoje
  bool get venceHoje => diasAteVencimento == 0;

  /// Verificar se vence nos próximos 3 dias
  bool get venceEm3Dias => diasAteVencimento > 0 && diasAteVencimento <= 3;

  /// Verificar se é crítica (vencida ou vence hoje)
  bool get isCritica => isVencida || venceHoje;

  /// Texto descritivo do status
  String get statusTexto {
    if (isVencida) {
      final diasVencidos = diasAteVencimento.abs();
      return diasVencidos == 1
          ? 'Venceu ontem'
          : 'Venceu há $diasVencidos dias';
    } else if (venceHoje) {
      return 'Vence hoje';
    } else if (diasAteVencimento == 1) {
      return 'Vence amanhã';
    } else {
      return 'Vence em $diasAteVencimento dias';
    }
  }

  /// Cor do status baseada na criticidade
  Color get corStatus {
    if (isVencida) return const Color(0xFFDC3545); // Vermelho
    if (venceHoje) return const Color(0xFFFF6B35); // Laranja
    if (venceEm3Dias) return const Color(0xFFFFC107); // Amarelo
    return const Color(0xFF6C757D); // Cinza
  }

  /// Verificar se deve mostrar badge "VENCIDO"
  bool get mostrarBadgeVencido => isVencida;

  /// Nível de prioridade (para ordenação)
  int get prioridade {
    if (isVencida) return diasAteVencimento; // Mais negativo = mais prioritário
    if (venceHoje) return 0;
    return diasAteVencimento; // Menor número = mais prioritário
  }

  @override
  String toString() {
    return 'FaturaPendente{'
        'cartaoId: $cartaoId, '
        'nomeCartao: $nomeCartao, '
        'valorFatura: $valorFatura, '
        'dataVencimento: $dataVencimento, '
        'diasAteVencimento: $diasAteVencimento'
        '}';
  }
}

/// Tipos de criticidade para grouping
enum CriticidadeFatura {
  vencida,
  venceHoje,
  vence3Dias,
}

/// Extensão para facilitar o uso
extension FaturaPendenteExtension on List<FaturaPendente> {
  /// Filtrar apenas faturas críticas (vencidas ou vencendo em 3 dias)
  List<FaturaPendente> get apenasUrgentes =>
      where((f) => f.isVencida || f.venceEm3Dias || f.venceHoje).toList();

  /// Ordenar por prioridade (mais críticas primeiro)
  List<FaturaPendente> get ordenadasPorPrioridade {
    final lista = List<FaturaPendente>.from(this);
    lista.sort((a, b) => a.prioridade.compareTo(b.prioridade));
    return lista;
  }

  /// Contar faturas vencidas
  int get quantidadeVencidas => where((f) => f.isVencida).length;

  /// Contar faturas vencendo nos próximos 3 dias
  int get quantidadeVencendo3Dias => where((f) => f.venceEm3Dias || f.venceHoje).length;

  /// Valor total pendente
  double get valorTotalPendente => fold(0.0, (total, fatura) => total + fatura.valorFatura);
}