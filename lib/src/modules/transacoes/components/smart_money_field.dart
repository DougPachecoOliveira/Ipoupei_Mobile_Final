// 💰 Smart Money Field - iPoupei Mobile
// 
// Campo inteligente para valores monetários adaptado do projeto device
// Compatível com a arquitetura mobile existente
// 
// Features:
// - Digite 3500 → R$ 3.500,00
// - Digite 35,50 → R$ 35,50  
// - Formatação automática e inteligente
// - Preview em tempo real
// - Validação visual contextual

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'smart_input_field.dart';
import '../../../shared/utils/format_currency.dart';

/// Campo inteligente para entrada de valores monetários
/// Mantém total compatibilidade com o sistema existente
class SmartMoneyField extends StatefulWidget {
  // Parâmetros compatíveis com TextFormField
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(double)? onValueChanged;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;
  
  // Parâmetros específicos do SmartMoney
  final TransactionContext? context;
  final bool showVisualFeedback;
  final bool showPreview;
  final bool showHint;
  
  const SmartMoneyField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onValueChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.context,
    this.showVisualFeedback = true,
    this.showPreview = true,
    this.showHint = true,
  });

  @override
  State<SmartMoneyField> createState() => _SmartMoneyFieldState();
}

class _SmartMoneyFieldState extends State<SmartMoneyField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasContent = false;
  double _currentValue = 0.0;
  String? _currentError;

  // Formatador de moeda brasileira
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Inicializa com valor se fornecido
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _currentValue = _parseValue(widget.initialValue!);
      _controller.text = _formatForDisplay(_currentValue);
    }
    
    _hasContent = _controller.text.isNotEmpty;
    
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(SmartMoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != null && 
        !_isFocused &&
        widget.controller == null) {
      _currentValue = _parseValue(widget.initialValue!);
      _controller.text = _formatForDisplay(_currentValue);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });

      if (_isFocused) {
        // Ao ganhar foco, mostra valor simples para edição
        if (_currentValue > 0) {
          _controller.text = _formatForEdit(_currentValue);
        } else {
          _controller.text = '';
        }
        // Posiciona cursor no final
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      } else {
        // Ao perder foco, processa e formata para display
        _processAndFormat();
      }
    }
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {
        _hasContent = _controller.text.isNotEmpty;
      });
    }
  }

  void _processAndFormat() {
    final text = _controller.text.trim();
    print('🔍 SmartMoney DEBUG:');
    print('   Input text: "$text"');
    
    _currentValue = _parseValue(text);
    print('   Parsed value: $_currentValue');
    
    final formatted = _formatForDisplay(_currentValue);
    print('   Formatted: "$formatted"');
    
    _controller.text = formatted;
    print('   Final controller text: "${_controller.text}"');
    print('');
    
    // Executar validação se disponível
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (mounted) {
        setState(() {
          _currentError = error;
        });
      }
    }
    
    // Chamar callbacks
    widget.onChanged?.call(_controller.text);
    widget.onValueChanged?.call(_currentValue);
  }

  /// Formata para exibição: R$ 3.500,00
  String _formatForDisplay(double value) {
    if (value == 0) return '';
    final result = formatCurrency(value);
    print('   🔍 _formatForDisplay($value) = "$result"');
    return result;
  }

  /// Formata para edição: 3500,00 ou 35,50
  String _formatForEdit(double value) {
    if (value == 0) return '';
    
    // Se é valor inteiro, mostra sem decimais
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    
    // Se tem decimais, mostra com vírgula
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// Parse SIMPLES sem cents-first - APENAS NÚMEROS NORMAIS
  double _parseValue(String text) {
    if (text.isEmpty) return 0.0;
    
    // Usar o parseCurrency do nosso utilitário
    final result = parseCurrency(text);
    print('   🔍 _parseValue("$text") = $result');
    return result;
  }

  // Funções cents-first removidas - causavam bugs

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

  Color get _iconColor {
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
    
    if (_hasContent) {
      switch (widget.context) {
        case TransactionContext.receita:
          return Colors.green.shade500;
        case TransactionContext.despesa:
          return Colors.red.shade500;
        case TransactionContext.cartao:
          return Colors.purple.shade500;
        case TransactionContext.transferencia:
          return Colors.blue.shade500;
        default:
          return Colors.grey.shade600;
      }
    }
    
    return Colors.grey.shade600;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com ícone monetário
        if (widget.labelText != null) ...[
          Row(
            children: [
              Icon(
                Icons.monetization_on,
                size: 16,
                color: _iconColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.labelText!,
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
        
        // Campo de entrada principal
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: _borderColor,
              width: _isFocused && widget.showVisualFeedback ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Ícone monetário no início
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  Icons.attach_money,
                  size: 20,
                  color: _iconColor,
                ),
              ),
              
              // Campo de texto
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly || widget.onTap != null,
                  autofocus: widget.autofocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    SimpleMoneyFormatter(),
                  ],
                  textInputAction: widget.textInputAction ?? TextInputAction.next,
                  onTap: widget.onTap,
                  onEditingComplete: widget.onEditingComplete,
                  validator: widget.validator,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Ex: 3500 ou 35,50',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    counterText: '',
                  ),
                ),
              ),
              
              // Preview do valor formatado (quando focado e tem valor)
              if (widget.showPreview && _isFocused && _currentValue > 0) ...[
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatForDisplay(_currentValue),
                    style: TextStyle(
                      fontSize: 12,
                      color: _iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Mensagem de erro
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
        
        // Dica de uso (só quando focado, vazio e habilitada)
        if (widget.showHint && _isFocused && !_hasContent) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 12,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Digite: 9 → 0,09 | 95 → 0,95 | 950 → 9,50 | 9500 → 95,00',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Formatter SIMPLES que mostra vírgula em tempo real (sem cents-first)
class SimpleMoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se está vazio, retorna vazio
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Remove tudo que não é dígito
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Converte para double e formata normalmente
    double value = double.tryParse(digitsOnly) ?? 0.0;
    
    // Formata com pontos e vírgula brasileira
    String formatted;
    if (value == 0) {
      formatted = '';
    } else {
      // Usar nosso formatCurrency sem símbolo para tempo real
      formatted = formatCurrencyWithoutSymbol(value);
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}