import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../modules/shared/theme/app_colors.dart';

/// SmartField - Campo inteligente que se adapta ao contexto da transação
class SmartField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final String? transactionContext;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final String? errorText;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const SmartField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.transactionContext,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.onChanged,
    this.inputFormatters,
    this.keyboardType,
    this.errorText,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  State<SmartField> createState() => _SmartFieldState();
}

class _SmartFieldState extends State<SmartField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Obter cor baseada no contexto da transação
  Color _getContextColor() {
    if (!widget.enabled) return AppColors.cinzaMedio;
    
    switch (widget.transactionContext?.toLowerCase()) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return AppColors.vermelhoErro;
      case 'cartao':
      case 'cartão':
        return AppColors.roxoPrimario;
      default:
        return AppColors.azul;
    }
  }

  /// Obter cor da borda baseada no estado
  Color _getBorderColor() {
    if (widget.errorText != null) return AppColors.vermelhoErro;
    if (_isFocused) return _getContextColor();
    return AppColors.cinzaBorda;
  }

  /// Obter sugestões inteligentes baseadas no contexto
  List<String> _getSmartSuggestions() {
    switch (widget.transactionContext?.toLowerCase()) {
      case 'receita':
        return [
          'Salário',
          'Freelance',
          'Investimentos',
          'Vendas',
          'Comissão',
          'Bonificação',
        ];
      case 'despesa':
        return [
          'Alimentação',
          'Transporte',
          'Supermercado',
          'Combustível',
          'Farmácia',
          'Restaurante',
        ];
      case 'cartao':
      case 'cartão':
        return [
          'Compra online',
          'Loja física',
          'Assinatura',
          'Streaming',
          'App delivery',
          'E-commerce',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final contextColor = _getContextColor();
    final borderColor = _getBorderColor();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com ícone
        if (widget.label.isNotEmpty) ...[
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: contextColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: contextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Campo de texto - linha simples
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: borderColor,
                width: _isFocused ? 2 : 1,
              ),
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 16,
              color: widget.enabled ? AppColors.cinzaEscuro : AppColors.cinzaTexto,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: AppColors.cinzaTexto,
                fontSize: 16,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 0,
                vertical: widget.maxLines == 1 ? 12 : 8,
              ),
              counterStyle: TextStyle(
                color: AppColors.cinzaTexto,
                fontSize: 12,
              ),
              errorStyle: const TextStyle(
                color: AppColors.vermelhoErro,
                fontSize: 12,
              ),
            ),
          ),
        ),
        
        // Erro
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: AppColors.vermelhoErro,
              fontSize: 12,
            ),
          ),
        ],
        
        // Sugestões inteligentes (se apropriado)
        if (_isFocused && 
            widget.controller.text.isEmpty && 
            _getSmartSuggestions().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: contextColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: contextColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: contextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sugestões',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: contextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _getSmartSuggestions().map((suggestion) {
                    return GestureDetector(
                      onTap: () {
                        widget.controller.text = suggestion;
                        widget.onChanged?.call(suggestion);
                        _focusNode.unfocus();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: contextColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: contextColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 11,
                            color: contextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}