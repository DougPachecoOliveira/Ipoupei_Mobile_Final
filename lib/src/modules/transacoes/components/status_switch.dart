// 🔄 Status Switch - iPoupei Mobile
// 
// Switch customizado para status de transações adaptado do projeto device
// Compatível com a arquitetura mobile existente
// 
// Features:
// - Visual diferenciado com container colorido
// - Estados claros com ícones e descrições
// - Animações suaves de transição
// - Cores contextuais por tipo de transação
// - Feedback tátil (haptic feedback)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Switch customizado para status de transações
/// Suporte a diferentes contextos (receita, despesa, etc.)
class StatusSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDisabled;
  final String? trueLabel;
  final String? falseLabel;
  final String? trueDescription;
  final String? falseDescription;
  final IconData? trueIcon;
  final IconData? falseIcon;
  final Color? activeColor;
  final Color? inactiveColor;
  final StatusSwitchContext context;

  const StatusSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
    this.trueLabel,
    this.falseLabel,
    this.trueDescription,
    this.falseDescription,
    this.trueIcon,
    this.falseIcon,
    this.activeColor,
    this.inactiveColor,
    this.context = StatusSwitchContext.generic,
  });

  // Factory para receitas (Recebida/A Receber)
  StatusSwitch.receita({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
  }) : trueLabel = 'Já Recebida',
       falseLabel = 'A Receber',
       trueDescription = 'Dinheiro na conta',
       falseDescription = 'Aguardando recebimento',
       trueIcon = Icons.check_circle,
       falseIcon = Icons.schedule,
       activeColor = Colors.green.shade600,
       inactiveColor = Colors.orange.shade600,
       context = StatusSwitchContext.receita;

  // Factory para despesas (Paga/A Pagar)
  StatusSwitch.despesa({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
  }) : trueLabel = 'Já Paga',
       falseLabel = 'A Pagar',
       trueDescription = 'Despesa quitada',
       falseDescription = 'Aguardando pagamento',
       trueIcon = Icons.check_circle,
       falseIcon = Icons.schedule,
       activeColor = Colors.red.shade600,
       inactiveColor = Colors.orange.shade600,
       context = StatusSwitchContext.despesa;

  // Factory para cartões (Pago/Pendente)
  StatusSwitch.cartao({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
  }) : trueLabel = 'Pago',
       falseLabel = 'Pendente',
       trueDescription = 'Fatura quitada',
       falseDescription = 'Aguardando pagamento',
       trueIcon = Icons.credit_card,
       falseIcon = Icons.schedule,
       activeColor = Colors.purple.shade600,
       inactiveColor = Colors.orange.shade600,
       context = StatusSwitchContext.cartao;

  @override
  Widget build(BuildContext context) {
    final currentValue = value;
    final currentActiveColor = activeColor ?? _getDefaultActiveColor();
    final currentInactiveColor = inactiveColor ?? Colors.grey.shade600;

    return GestureDetector(
      onTap: isDisabled ? null : () {
        // Haptic feedback no mobile
        HapticFeedback.lightImpact();
        onChanged(!currentValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: currentValue 
              ? currentActiveColor.withValues(alpha: 0.08)
              : currentInactiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: currentValue 
                ? currentActiveColor.withValues(alpha: 0.3)
                : currentInactiveColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentValue ? currentActiveColor : currentInactiveColor,
                boxShadow: [
                  BoxShadow(
                    color: (currentValue ? currentActiveColor : currentInactiveColor)
                        .withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  key: ValueKey(currentValue),
                  currentValue 
                      ? (trueIcon ?? Icons.check)
                      : (falseIcon ?? Icons.schedule),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            
            const SizedBox(width: 12),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      key: ValueKey(currentValue),
                      currentValue 
                          ? (trueLabel ?? 'Ativo')
                          : (falseLabel ?? 'Inativo'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: currentValue ? currentActiveColor : currentInactiveColor,
                      ),
                    ),
                  ),
                  
                  if (_hasDescription) ...[
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        key: ValueKey('${currentValue}_desc'),
                        currentValue 
                            ? (trueDescription ?? '')
                            : (falseDescription ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Switch nativo otimizado
            Transform.scale(
              scale: 0.8,
              child: Switch(
                key: ValueKey(currentValue),
                value: currentValue,
                onChanged: isDisabled ? null : (newValue) {
                  HapticFeedback.selectionClick();
                  onChanged(newValue);
                },
                activeColor: currentActiveColor,
                activeTrackColor: currentActiveColor.withValues(alpha: 0.3),
                inactiveTrackColor: currentInactiveColor.withValues(alpha: 0.3),
                inactiveThumbColor: currentInactiveColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasDescription => 
      trueDescription != null || falseDescription != null;

  Color _getDefaultActiveColor() {
    switch (context) {
      case StatusSwitchContext.receita:
        return Colors.green.shade600;
      case StatusSwitchContext.despesa:
        return Colors.red.shade600;
      case StatusSwitchContext.cartao:
        return Colors.purple.shade600;
      case StatusSwitchContext.transferencia:
        return Colors.blue.shade600;
      case StatusSwitchContext.generic:
        return Colors.blue.shade600;
    }
  }
}

/// Contextos disponíveis para StatusSwitch
enum StatusSwitchContext {
  receita,
  despesa,
  cartao,
  transferencia,
  generic,
}