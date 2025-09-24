import 'package:flutter/material.dart';
import '../models/conta_model.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../../shared/components/ui/app_text.dart';

/// 🏦 ContaCard - Inspirado no CartaoCard mas para contas
/// Mesmo visual moderno com gradiente e informações detalhadas
class ContaCard extends StatelessWidget {
  final ContaModel conta;
  final double? entradaMensal;
  final double? saidaMensal;
  final double? saldoMedio;
  final String? periodoAtual;
  final bool showMovimentacao;
  final bool showMetricas;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final Widget? trailing;

  const ContaCard({
    Key? key,
    required this.conta,
    this.entradaMensal,
    this.saidaMensal,
    this.saldoMedio,
    this.periodoAtual,
    this.showMovimentacao = true,
    this.showMetricas = true,
    this.isCompact = false,
    this.onTap,
    this.onMenuTap,
    this.trailing,
  }) : super(key: key);

  Color _getCorConta() {
    if (conta.cor != null && conta.cor!.isNotEmpty) {
      try {
        return Color(int.parse(conta.cor!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Se não conseguir parsear a cor, usa cor padrão
      }
    }
    return AppColors.tealPrimary;
  }

  IconData _getIconeConta() {
    if (conta.tipo == null || conta.tipo!.isEmpty) {
      return Icons.account_balance_wallet_outlined;
    }
    
    switch (conta.tipo!.toLowerCase()) {
      case 'corrente':
        return Icons.account_balance;
      case 'poupanca':  
        return Icons.savings;
      case 'carteira':
        return Icons.account_balance_wallet;
      case 'investimento':
        return Icons.trending_up;
      case 'outros':
        return Icons.more_horiz;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  bool get _saldoNegativo => conta.saldo < 0;

  /// Gradiente da conta baseado na cor
  Gradient _buildGradiente(Color corBase) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        corBase,
        corBase.withOpacity(0.8),
        corBase.withOpacity(0.9),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final corConta = _getCorConta();

    return Card(
      elevation: conta.contaPrincipal ? 0 : 2, // Remove elevation padrão se for principal
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _buildGradiente(corConta),
            // 🟡 CONTORNO DOURADO SUTIL PARA CONTA PRINCIPAL
            border: conta.contaPrincipal 
                ? Border.all(color: Colors.amber.shade400, width: 2)
                : null,
            boxShadow: conta.contaPrincipal 
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: isCompact ? _buildCompactContent() : _buildFullContent(),
        ),
      ),
    );
  }

  /// Conteúdo compacto (para listas)
  Widget _buildCompactContent() {
    return Row(
      children: [
        _buildIconeConta(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.cardTitle(
                conta.nome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                color: Colors.white,
                group: AppTextGroups.cardTitles,
              ),
              AppText.cardSecondary(
                conta.banco ?? 'Sem banco',
                style: const TextStyle(
                  fontSize: 13,
                ),
                color: Colors.white.withOpacity(0.8),
                group: AppTextGroups.cardSecondary,
              ),
            ],
          ),
        ),
        AppText.cardValue(
          CurrencyFormatter.format(conta.saldo),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          color: _saldoNegativo ? Colors.red.shade300 : Colors.white,
          group: AppTextGroups.cardValues,
        ),
        // ⭐ ESTRELA + MENU PARA CONTAS
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estrela dourada para conta principal
            if (conta.contaPrincipal)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            // Menu dos 3 pontinhos
            if (onMenuTap != null)
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ],
    );
  }

  /// Conteúdo completo (para detalhes)
  Widget _buildFullContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da conta
        _buildHeaderConta(),
        
        const SizedBox(height: 16),
        
        // Saldo principal
        _buildSaldoPrincipal(),
        
        if (showMovimentacao) ...[
          const SizedBox(height: 12),
          _buildSecaoMovimentacao(),
        ],
        
        if (showMetricas) ...[
          const SizedBox(height: 12),
          _buildSecaoMetricas(),
        ],
      ],
    );
  }

  /// Header com nome, banco e ícone
  Widget _buildHeaderConta() {
    return Row(
      children: [
        _buildIconeConta(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.cardTitle(
                conta.nome,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                color: Colors.white,
                group: AppTextGroups.cardTitles,
              ),
              AppText.cardSecondary(
                '${conta.banco ?? 'Sem banco'} • ${conta.tipo ?? 'Conta'}',
                style: const TextStyle(
                  fontSize: 14,
                ),
                color: Colors.white.withOpacity(0.8),
                group: AppTextGroups.cardSecondary,
              ),
            ],
          ),
        ),
        // ⭐ ESTRELA + MENU PARA CONTAS
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estrela dourada para conta principal
            if (conta.contaPrincipal)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            // Menu dos 3 pontinhos
            if (onMenuTap != null)
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ],
    );
  }

  /// Saldo principal em destaque
  Widget _buildSaldoPrincipal() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppText.cardValue(
        CurrencyFormatter.format(conta.saldo),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        color: _saldoNegativo ? Colors.red.shade300 : Colors.white,
        group: AppTextGroups.cardValues,
      ),
    );
  }

  /// Seção de movimentação (entrada vs saída)
  Widget _buildSecaoMovimentacao() {
    if (entradaMensal == null && saidaMensal == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (entradaMensal != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.cardSecondary(
                    'Entradas',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    color: Colors.white.withOpacity(0.8),
                    group: AppTextGroups.cardSecondary,
                  ),
                  AppText.cardValue(
                    CurrencyFormatter.format(entradaMensal!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    color: Colors.white,
                    group: AppTextGroups.cardValues,
                  ),
                ],
              ),
            ),
          ],
          if (entradaMensal != null && saidaMensal != null)
            Container(
              width: 1,
              height: 30,
              color: Colors.white.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
          if (saidaMensal != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText.cardSecondary(
                    'Saídas',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    color: Colors.white.withOpacity(0.8),
                    group: AppTextGroups.cardSecondary,
                  ),
                  AppText.cardValue(
                    CurrencyFormatter.format(saidaMensal!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    color: Colors.white,
                    group: AppTextGroups.cardValues,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Seção de métricas extras
  Widget _buildSecaoMetricas() {
    if (saldoMedio == null && periodoAtual == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (saldoMedio != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.cardSecondary(
                    'Saldo Médio',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    color: Colors.white.withOpacity(0.8),
                    group: AppTextGroups.cardSecondary,
                  ),
                  AppText.cardValue(
                    CurrencyFormatter.format(saldoMedio!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    color: Colors.white,
                    group: AppTextGroups.cardValues,
                  ),
                ],
              ),
            ),
          ],
          if (periodoAtual != null) ...[
            AppText.cardSecondary(
              periodoAtual!,
              style: const TextStyle(
                fontSize: 12,
              ),
              color: Colors.white.withOpacity(0.7),
              group: AppTextGroups.cardSecondary,
            ),
          ],
        ],
      ),
    );
  }

  /// Ícone da conta em círculo
  Widget _buildIconeConta() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIconeConta(),
        color: Colors.white,
        size: 20,
      ),
    );
  }
}