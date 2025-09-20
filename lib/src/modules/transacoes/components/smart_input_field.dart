// 📱 Smart Input Field - iPoupei Mobile
// 
// Campo inteligente adaptado do projeto device
// Compatível com a arquitetura mobile existente
// 
// Baseado em: TextFormField + Visual Feedback

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo inteligente com feedback visual e validação contextual
/// Mantém compatibilidade total com TextFormField existente
class SmartInputField extends StatefulWidget {
  // Parâmetros idênticos ao TextFormField para compatibilidade
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;
  
  // Parâmetros específicos do SmartField
  final TransactionContext? context; // Para cores contextuais
  final bool showVisualFeedback; // Ativar/desativar feedback visual
  final String? prefixText;
  
  const SmartInputField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.onEditingComplete,
    this.context,
    this.showVisualFeedback = true,
    this.prefixText,
  });

  @override
  State<SmartInputField> createState() => _SmartInputFieldState();
}

class _SmartInputFieldState extends State<SmartInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasContent = false;
  String? _currentError;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _hasContent = _controller.text.isNotEmpty || widget.initialValue?.isNotEmpty == true;
    
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
  void didUpdateWidget(SmartInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != null && 
        widget.controller == null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  /// Cores contextuais baseadas no tipo de transação
  Color get _borderColor {
    if (!widget.enabled) return Colors.grey.shade300;
    if (_currentError != null) return Colors.red.shade600;
    
    if (!widget.showVisualFeedback) {
      return _isFocused ? Theme.of(context).primaryColor : Colors.grey.shade300;
    }
    
    if (_isFocused) {
      switch (widget.context) {
        case TransactionContext.receita:
          return Colors.green.shade600;
        case TransactionContext.despesa:
          return Colors.red.shade600;
        case TransactionContext.cartao:
          return Colors.purple.shade600;
        case TransactionContext.transferencia:
          return Colors.blue.shade600;
        default:
          return Theme.of(context).primaryColor;
      }
    }
    
    if (_hasContent) {
      switch (widget.context) {
        case TransactionContext.receita:
          return Colors.green.shade400;
        case TransactionContext.despesa:
          return Colors.red.shade400;
        case TransactionContext.cartao:
          return Colors.purple.shade400;
        case TransactionContext.transferencia:
          return Colors.blue.shade400;
        default:
          return Colors.grey.shade400;
      }
    }
    
    return Colors.grey.shade300;
  }

  Color get _labelColor {
    if (!widget.showVisualFeedback) {
      return _isFocused ? Theme.of(context).primaryColor : Colors.grey.shade600;
    }
    
    if (_isFocused) {
      switch (widget.context) {
        case TransactionContext.receita:
          return Colors.green.shade600;
        case TransactionContext.despesa:
          return Colors.red.shade600;
        case TransactionContext.cartao:
          return Colors.purple.shade600;
        case TransactionContext.transferencia:
          return Colors.blue.shade600;
        default:
          return Theme.of(context).primaryColor;
      }
    }
    
    return Colors.grey.shade600;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo principal - mantém compatibilidade total com TextFormField
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: _borderColor,
              width: _isFocused && widget.showVisualFeedback ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly || widget.onTap != null,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: _handleChanged,
            onTap: widget.onTap,
            onEditingComplete: widget.onEditingComplete,
            style: const TextStyle(fontSize: 16),
            validator: widget.validator,
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: TextStyle(color: _labelColor),
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null 
                  ? Icon(widget.prefixIcon, color: _labelColor)
                  : null,
              suffixIcon: widget.suffixIcon,
              prefixText: widget.prefixText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
          ),
        ),
        
        // Feedback visual de erro (se houver)
        if (_currentError != null && widget.showVisualFeedback) ...[
          const SizedBox(height: 4),
          Text(
            _currentError!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Contextos de transação para cores inteligentes
enum TransactionContext {
  receita,
  despesa,
  cartao,
  transferencia,
}