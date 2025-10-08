// 📊 Resumo Financeiro Model - iPoupei Mobile
//
// Modelo de dados para o widget ResumoFinanceiro
// Baseado no DashboardData do iPoupeiDevice
//
// Estrutura: Saldos + Totais + Métodos de cálculo

import 'package:flutter/material.dart';

/// Modelo de dados para resumo financeiro
class ResumoFinanceiroData {
  final double saldoContas;
  final double totalReceitas;
  final double totalDespesas;
  final double saldoTransferencias;
  final double totalCartoes;
  final DateTime dataAtualizacao;

  ResumoFinanceiroData({
    required this.saldoContas,
    required this.totalReceitas,
    required this.totalDespesas,
    required this.saldoTransferencias,
    required this.totalCartoes,
    required this.dataAtualizacao,
  });

  /// Construtor com dados vazios
  factory ResumoFinanceiroData.empty() {
    return ResumoFinanceiroData(
      saldoContas: 0,
      totalReceitas: 0,
      totalDespesas: 0,
      saldoTransferencias: 0,
      totalCartoes: 0,
      dataAtualizacao: DateTime.now(),
    );
  }

  /// Saldo líquido do período (receitas - despesas)
  double get saldoPeriodo => totalReceitas - totalDespesas;

  /// Patrimônio total (contas - cartões)
  double get patrimonioTotal => saldoContas - totalCartoes;

  /// Verificar se tem dados
  bool get hasData =>
    saldoContas != 0 ||
    totalReceitas != 0 ||
    totalDespesas != 0 ||
    saldoTransferencias != 0 ||
    totalCartoes != 0;

  /// Criar a partir de dados de serviço
  factory ResumoFinanceiroData.fromServiceData({
    required double saldoContas,
    required double totalReceitas,
    required double totalDespesas,
    required double saldoTransferencias,
    required double totalCartoes,
  }) {
    return ResumoFinanceiroData(
      saldoContas: saldoContas,
      totalReceitas: totalReceitas,
      totalDespesas: totalDespesas,
      saldoTransferencias: saldoTransferencias,
      totalCartoes: totalCartoes,
      dataAtualizacao: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ResumoFinanceiroData{'
        'saldoContas: $saldoContas, '
        'totalReceitas: $totalReceitas, '
        'totalDespesas: $totalDespesas, '
        'saldoTransferencias: $saldoTransferencias, '
        'totalCartoes: $totalCartoes, '
        'dataAtualizacao: $dataAtualizacao'
        '}';
  }
}

/// Tipos de item do resumo financeiro para navegação
enum TipoResumoFinanceiro {
  contas,
  receitas,
  despesas,
  transferencias,
  cartoes,
}

/// Configuração de um item do resumo
class ItemResumoFinanceiro {
  final TipoResumoFinanceiro tipo;
  final String label;
  final IconData icon;
  final Color color;
  final double Function(ResumoFinanceiroData) valueExtractor;

  const ItemResumoFinanceiro({
    required this.tipo,
    required this.label,
    required this.icon,
    required this.color,
    required this.valueExtractor,
  });
}