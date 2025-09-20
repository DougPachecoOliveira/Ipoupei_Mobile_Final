// 🎯 Smart Field - iPoupei Mobile
// 
// Campo inteligente com ícone inline, validação visual e estados  
// Adaptado do projeto device para arquitetura mobile
// 
// Features:
// - Contextos de cores (receita, despesa, cartão, transferência)
// - Validação visual em tempo real
// - Ícones inline e dots coloridos
// - Suporte a readonly/onTap
// - Formatação automática

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/app_colors.dart';

/// Campo inteligente com ícone inline, validação visual e estados
class SmartField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? value;
  final String? hint;
  final IconData? icon;
  final Widget? leadingIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final bool isCartaoContext;
  final String? transactionContext; // 'receita', 'despesa', 'transferencia'
  final bool showDot;
  final Color? dotColor;
  
  const SmartField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.value,
    this.icon,
    this.leadingIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.onEditingComplete,
    this.isCartaoContext = false,
    this.transactionContext,
    this.showDot = false,
    this.dotColor,
  });

  @override
  State<SmartField> createState() => _SmartFieldState();
}

class _SmartFieldState extends State<SmartField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasContent = false;
  String? _currentError;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.value);
    _focusNode = widget.focusNode ?? FocusNode();
    _hasContent = _controller.text.isNotEmpty || widget.value?.isNotEmpty == true;
    
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
    
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _hasContent = _controller.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void didUpdateWidget(SmartField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != null && widget.controller == null) {
      _controller.text = widget.value!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // Cores por contexto - Sistema inteligente baseado no tipo
  Color get _borderColor {
    if (!widget.enabled) return AppColors.cinzaBorda;
    if (_currentError != null) return AppColors.vermelhoErro;
    if (_isFocused) {
      return _getFocusColor();
    }
    if (_hasContent) {
      return _getContentColor();
    }
    return AppColors.cinzaBorda;
  }

  // Cor quando focado - baseada no contexto da transação
  Color _getFocusColor() {
    if (widget.isCartaoContext) return AppColors.roxoHeader;
    
    switch (widget.transactionContext) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return AppColors.vermelhoHeader;
      case 'transferencia':
        return AppColors.azulHeader;
      default:
        return AppColors.tealPrimary; // Padrão teal
    }
  }

  // Cor quando tem conteúdo - baseada no contexto da transação
  Color _getContentColor() {
    if (widget.isCartaoContext) return AppColors.roxoHeader;
    
    switch (widget.transactionContext) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return AppColors.vermelhoHeader;
      case 'transferencia':
        return AppColors.azulHeader;
      default:
        return AppColors.verdeSucesso; // Padrão sucesso
    }
  }

  Color get _iconColor {
    if (_isFocused) {
      return _getFocusColor();
    }
    return AppColors.cinzaMedio;
  }

  Color get _labelColor {
    if (_isFocused) {
      return _getFocusColor();
    }
    return AppColors.cinzaTexto;
  }

  void _handleChanged(String value) {
    // Executar validação se disponível
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (mounted) {
        setState(() {
          _currentError = error;
        });
      }
    }
    
    // Chamar callback original
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.readOnly || widget.onTap != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Row(
            children: [
              // Dot colorido (se configurado)
              if (widget.showDot) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.dotColor ?? AppColors.roxoPrimario,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Ícone personalizado
              if (widget.leadingIcon != null) ...[
                widget.leadingIcon!,
                const SizedBox(width: 8),
              ],
              // Ícone padrão (só se não tem leadingIcon nem dot)
              if (widget.leadingIcon == null && !widget.showDot && widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: _iconColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _borderColor,
                width: _isFocused ? 2 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Ícone inline (quando não tem label)
              if (widget.icon != null && widget.label.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: _iconColor,
                  ),
                ),
              ],
              
              Expanded(
                child: isReadOnly
                    ? InkWell(
                        onTap: widget.enabled ? widget.onTap : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _controller.text.isNotEmpty 
                                ? _controller.text 
                                : widget.hint ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: _controller.text.isNotEmpty
                                  ? AppColors.cinzaEscuro
                                  : AppColors.cinzaLegenda,
                            ),
                          ),
                        ),
                      )
                    : TextFormField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        autofocus: widget.autofocus,
                        keyboardType: widget.keyboardType,
                        inputFormatters: widget.inputFormatters,
                        textInputAction: widget.textInputAction,
                        maxLines: widget.maxLines,
                        maxLength: widget.maxLength,
                        onChanged: _handleChanged,
                        onEditingComplete: widget.onEditingComplete,
                        validator: widget.validator,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.cinzaEscuro,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          hintStyle: const TextStyle(
                            color: AppColors.cinzaLegenda,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          counterText: '',
                        ),
                      ),
              ),
            ],
          ),
        ),
        
        if (_currentError != null) ...[
          const SizedBox(height: 4),
          Text(
            _currentError!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.vermelhoErro,
            ),
          ),
        ],
      ],
    );
  }
}