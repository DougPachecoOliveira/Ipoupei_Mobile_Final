// 💰 Smart Currency Input - iPoupei Mobile
// 
// Campo monetário INTELIGENTE que implementa as melhores práticas:
// 1. Só aceita números (sem letras/símbolos) 
// 2. Vírgula aparece automaticamente após 3 dígitos
// 3. Formatação brasileira automática
// 4. Separadores de milhares automáticos
// 
// Baseado em: Boas práticas + UX otimizada

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../modules/shared/theme/app_colors.dart';

/// Input de moeda inteligente com formatação automática
class SmartCurrencyInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(double)? onValueChanged;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final double? initialValue;
  final bool showIcon;
  final Color? accentColor;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const SmartCurrencyInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onValueChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.initialValue,
    this.showIcon = true,
    this.accentColor,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<SmartCurrencyInput> createState() => _SmartCurrencyInputState();
}

class _SmartCurrencyInputState extends State<SmartCurrencyInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Inicializa com valor se fornecido
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _currentValue = widget.initialValue!;
      _controller.text = _formatForDisplay(_currentValue);
    }
    
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
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
    }
  }

  void _onTextChange() {
    // Extrai o valor numérico do texto formatado
    final numericValue = _extractNumericValue(_controller.text);
    
    if (_currentValue != numericValue) {
      _currentValue = numericValue;
      widget.onValueChanged?.call(_currentValue);
    }
    
    widget.onChanged?.call(_controller.text);
  }

  /// Extrai valor numérico de string formatada
  double _extractNumericValue(String text) {
    if (text.isEmpty) return 0.0;
    
    // Remove tudo exceto dígitos, vírgula e ponto
    String cleaned = text.replaceAll(RegExp(r'[^0-9,.]'), '');
    
    // Se tem vírgula, trata como formato brasileiro
    if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length == 2) {
        final integerPart = parts[0].replaceAll('.', '');
        final decimalPart = parts[1].length > 2 
            ? parts[1].substring(0, 2) 
            : parts[1].padRight(2, '0');
        return double.tryParse('$integerPart.$decimalPart') ?? 0.0;
      }
    }
    
    return double.tryParse(cleaned.replaceAll('.', '')) ?? 0.0;
  }

  /// Formata valor para exibição: R$ 1.234,56
  String _formatForDisplay(double value) {
    if (value == 0) return '';
    return 'R\$ ${_formatNumber(value)}';
  }

  /// Formata número com padrão brasileiro
  String _formatNumber(double value) {
    final formatted = value.toStringAsFixed(2);
    final parts = formatted.split('.');
    
    String integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Adiciona separadores de milhares
    if (integerPart.length > 3) {
      final reversed = integerPart.split('').reversed.join('');
      final chunks = <String>[];
      
      for (int i = 0; i < reversed.length; i += 3) {
        final end = i + 3 < reversed.length ? i + 3 : reversed.length;
        chunks.add(reversed.substring(i, end));
      }
      
      integerPart = chunks.join('.').split('').reversed.join('');
    }
    
    return '$integerPart,$decimalPart';
  }

  Color get _accentColor => widget.accentColor ?? AppColors.tealPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Row(
            children: [
              if (widget.showIcon) ...[
                Icon(
                  Icons.monetization_on,
                  size: 16,
                  color: _isFocused ? _accentColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.labelText!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isFocused ? _accentColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          keyboardType: TextInputType.number,
          inputFormatters: [
            BrazilianCurrencyFormatter(),
          ],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'R\$ 0,00',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: widget.showIcon ? Icon(
              Icons.attach_money,
              color: _isFocused ? _accentColor : Colors.grey.shade500,
            ) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _accentColor,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _controller.text.isNotEmpty 
                    ? _accentColor.withOpacity(0.5)
                    : Colors.grey.shade300,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

/// Formatter que implementa as regras específicas solicitadas
class BrazilianCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se texto vazio, retorna vazio
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // 🎯 REGRA 1: SÓ ACEITA NÚMEROS
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Converte para número
    final value = int.tryParse(digitsOnly) ?? 0;
    
    String formatted;
    
    // 🎯 REGRA 2: VÍRGULA APARECE APÓS 3 DÍGITOS
    if (digitsOnly.length <= 2) {
      // 1 ou 2 dígitos: 0,01 - 0,99
      formatted = 'R\$ 0,${digitsOnly.padLeft(2, '0')}';
    } else {
      // 3+ dígitos: 1,00 - 999,99 - 1.000,00
      final valueInReais = value / 100.0;
      formatted = _formatCurrencyValue(valueInReais);
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
  /// Formata valor monetário com padrão brasileiro
  String _formatCurrencyValue(double value) {
    final formatted = value.toStringAsFixed(2);
    final parts = formatted.split('.');
    
    String integerPart = parts[0];
    final decimalPart = parts[1];
    
    // 🎯 REGRA 3: SEPARADORES DE MILHARES AUTOMÁTICOS
    if (integerPart.length > 3) {
      final reversed = integerPart.split('').reversed.join('');
      final chunks = <String>[];
      
      for (int i = 0; i < reversed.length; i += 3) {
        final end = i + 3 < reversed.length ? i + 3 : reversed.length;
        chunks.add(reversed.substring(i, end));
      }
      
      integerPart = chunks.join('.').split('').reversed.join('');
    }
    
    return 'R\$ $integerPart,$decimalPart';
  }
}