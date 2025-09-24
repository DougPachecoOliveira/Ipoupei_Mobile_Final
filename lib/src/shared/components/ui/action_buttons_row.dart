// 🎯 Action Buttons Row - iPoupei Mobile
//
// Componente reutilizável para linha de 6 botões de ação
// Usado em gestão de contas, cartões e outras telas
//
// Features:
// - Layout responsivo em 2 linhas de 3 botões
// - AutoSizeText para acessibilidade
// - Cores personalizáveis
// - Ícones e callbacks configuráveis

import 'package:flutter/material.dart';
import '../../../modules/shared/theme/app_colors.dart';
import 'app_text.dart';

/// Dados de um botão de ação
class ActionButtonData {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const ActionButtonData({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
    this.enabled = true,
  });
}

/// Widget de linha com 6 botões de ação organizados em 2x3
class ActionButtonsRow extends StatelessWidget {
  final List<ActionButtonData> buttons;
  final double? spacing;
  final double? buttonHeight;
  final double? iconSize;

  const ActionButtonsRow({
    super.key,
    required this.buttons,
    this.spacing = 8.0,
    this.buttonHeight = 66.0,
    this.iconSize = 20.0,
  }) : assert(buttons.length == 6, 'ActionButtonsRow deve ter exatamente 6 botões');

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // Primeira linha - 3 botões
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(child: _buildActionButton(context, buttons[i])),
                if (i < 2) SizedBox(width: spacing),
              ],
            ],
          ),

          SizedBox(height: spacing),

          // Segunda linha - 3 botões
          Row(
            children: [
              for (int i = 3; i < 6; i++) ...[
                Expanded(child: _buildActionButton(context, buttons[i])),
                if (i < 5) SizedBox(width: spacing),
              ],
            ],
          ),
        ],
    );
  }

  /// Constrói um único botão de ação
  Widget _buildActionButton(BuildContext context, ActionButtonData buttonData) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: buttonData.enabled ? buttonData.onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: buttonHeight,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                buttonData.icon,
                size: iconSize,
                color: buttonData.enabled
                    ? buttonData.color
                    : Colors.grey.withOpacity(0.5),
              ),

              const SizedBox(height: 4),

              AppText.cardSecondary(
                buttonData.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                color: buttonData.enabled
                    ? AppColors.cinzaEscuro
                    : Colors.grey.withOpacity(0.5),
                group: AppTextGroups.cardSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Factory method para botões de conta
class AccountActionButtons {
  static List<ActionButtonData> getButtons({
    required VoidCallback? onEdit,
    required VoidCallback? onAdjustBalance,
    required VoidCallback? onViewReports,
    required VoidCallback? onTransactions,
    required VoidCallback? onArchive,
    required VoidCallback? onSettings,
  }) {
    return [
      ActionButtonData(
        icon: Icons.edit_outlined,
        title: 'EDITAR',
        color: AppColors.azul,
        onTap: onEdit,
      ),
      ActionButtonData(
        icon: Icons.account_balance_outlined,
        title: 'SALDO',
        color: AppColors.verdeSucesso,
        onTap: onAdjustBalance,
      ),
      ActionButtonData(
        icon: Icons.bar_chart_outlined,
        title: 'RELATÓRIOS',
        color: AppColors.roxoPrimario,
        onTap: onViewReports,
      ),
      ActionButtonData(
        icon: Icons.swap_horiz_outlined,
        title: 'TRANSAÇÕES',
        color: AppColors.amareloAlerta,
        onTap: onTransactions,
      ),
      ActionButtonData(
        icon: Icons.archive_outlined,
        title: 'ARQUIVAR',
        color: Colors.orange,
        onTap: onArchive,
      ),
      ActionButtonData(
        icon: Icons.settings_outlined,
        title: 'CONFIG',
        color: Colors.grey,
        onTap: onSettings,
      ),
    ];
  }
}

/// Factory method para botões de cartão
class CardActionButtons {
  static List<ActionButtonData> getButtons({
    required VoidCallback? onEdit,
    required VoidCallback? onViewStatement,
    required VoidCallback? onPayBill,
    required VoidCallback? onViewReports,
    required VoidCallback? onBlock,
    required VoidCallback? onSettings,
  }) {
    return [
      ActionButtonData(
        icon: Icons.edit_outlined,
        title: 'EDITAR',
        color: AppColors.azul,
        onTap: onEdit,
      ),
      ActionButtonData(
        icon: Icons.receipt_long_outlined,
        title: 'FATURA',
        color: AppColors.verdeSucesso,
        onTap: onViewStatement,
      ),
      ActionButtonData(
        icon: Icons.payment_outlined,
        title: 'PAGAR',
        color: AppColors.roxoPrimario,
        onTap: onPayBill,
      ),
      ActionButtonData(
        icon: Icons.bar_chart_outlined,
        title: 'RELATÓRIOS',
        color: AppColors.amareloAlerta,
        onTap: onViewReports,
      ),
      ActionButtonData(
        icon: Icons.block_outlined,
        title: 'BLOQUEAR',
        color: Colors.red,
        onTap: onBlock,
      ),
      ActionButtonData(
        icon: Icons.settings_outlined,
        title: 'CONFIG',
        color: Colors.grey,
        onTap: onSettings,
      ),
    ];
  }
}