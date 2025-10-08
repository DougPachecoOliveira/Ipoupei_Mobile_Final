// 📱 Conditional Transaction Fields - iPoupei Mobile
// 
// Campos condicionais para transações parceladas e recorrentes
// Integrado com a arquitetura existente do transacao_form_page.dart
// 
// Baseado em: ConditionalFields do projeto device

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'smart_input_field.dart';

/// Widget para campos condicionais de transações
/// Integra-se perfeitamente com o formulário existente
class ConditionalTransactionFields extends StatelessWidget {
  final String tipoTransacao; // 'extra', 'parcelada', 'previsivel'
  final String tipoSelecionado; // 'receita' ou 'despesa'
  final double valorTotal;
  
  // Callbacks para parceladas
  final int numeroParcelas;
  final String frequenciaParcelada;
  final void Function(int) onParcelasChanged;
  final void Function(String) onFrequenciaParceladaChanged;
  
  // Callbacks para previsíveis
  final String frequenciaPrevisivel;
  final int totalRecorrencias;
  final void Function(String) onFrequenciaPrevisivelChanged;
  
  // Configurações visuais
  final bool showPreview;
  final Color? primaryColor;

  const ConditionalTransactionFields({
    super.key,
    required this.tipoTransacao,
    required this.tipoSelecionado,
    required this.valorTotal,
    required this.numeroParcelas,
    required this.frequenciaParcelada,
    required this.onParcelasChanged,
    required this.onFrequenciaParceladaChanged,
    required this.frequenciaPrevisivel,
    required this.totalRecorrencias,
    required this.onFrequenciaPrevisivelChanged,
    this.showPreview = true,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (tipoTransacao == 'extra') {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBackgroundColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // Campos específicos por tipo
          if (tipoTransacao == 'parcelada') 
            _buildParceladaFields(context)
          else if (tipoTransacao == 'previsivel')
            _buildPrevisivelFields(context),
          
          // Preview de cálculos
          if (showPreview && valorTotal > 0)
            _buildPreview(context),
        ],
      ),
    );
  }

  /// Header do widget
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          tipoTransacao == 'parcelada' ? Icons.calendar_month : Icons.repeat,
          size: 20,
          color: _getBackgroundColor(),
        ),
        const SizedBox(width: 8),
        Text(
          tipoTransacao == 'parcelada' ? 'Configuração de Parcelas' : 'Configuração Recorrente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getBackgroundColor(),
          ),
        ),
      ],
    );
  }

  /// Campos para transações parceladas
  Widget _buildParceladaFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Campo de parcelas com controles
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SmartInputField(
                    labelText: 'Parcelas',
                    initialValue: numeroParcelas.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    prefixIcon: Icons.receipt_outlined,
                    context: _getTransactionContext(),
                    showVisualFeedback: true,
                    onChanged: (value) {
                      final parcelas = int.tryParse(value) ?? 2;
                      if (parcelas >= 2 && parcelas <= 60) {
                        onParcelasChanged(parcelas);
                      }
                    },
                    validator: (value) {
                      final numero = int.tryParse(value ?? '');
                      if (numero == null || numero < 2 || numero > 60) {
                        return 'Entre 2 e 60 parcelas';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Controles de incremento/decremento
            _buildParcelasControls(),
            
            const SizedBox(width: 12),
            
            // Frequência
            Expanded(
              flex: 3,
              child: SmartInputField(
                labelText: 'Frequência',
                initialValue: _getFrequenciaLabel(frequenciaParcelada),
                prefixIcon: Icons.schedule,
                context: _getTransactionContext(),
                readOnly: true,
                onTap: () => _showFrequenciaDialog(context, true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Campos para transações previsíveis
  Widget _buildPrevisivelFields(BuildContext context) {
    return SmartInputField(
      labelText: 'Frequência de Recorrência',
      initialValue: _getFrequenciaLabel(frequenciaPrevisivel),
      prefixIcon: Icons.repeat,
      context: _getTransactionContext(),
      readOnly: true,
      onTap: () => _showFrequenciaDialog(context, false),
    );
  }

  /// Controles visuais para parcelas
  Widget _buildParcelasControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBackgroundColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão incrementar
          InkWell(
            onTap: numeroParcelas < 60 
                ? () => onParcelasChanged(numeroParcelas + 1)
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.keyboard_arrow_up,
                color: numeroParcelas < 60 
                    ? _getBackgroundColor()
                    : Colors.grey,
                size: 20,
              ),
            ),
          ),
          
          // Divisor
          Container(
            height: 1,
            color: _getBackgroundColor().withValues(alpha: 0.2),
          ),
          
          // Botão decrementar
          InkWell(
            onTap: numeroParcelas > 2 
                ? () => onParcelasChanged(numeroParcelas - 1)
                : null,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: numeroParcelas > 2 
                    ? _getBackgroundColor()
                    : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Preview dos cálculos
  Widget _buildPreview(BuildContext context) {
    if (valorTotal <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBackgroundColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 16,
            color: _getBackgroundColor(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getPreviewText(),
              style: TextStyle(
                fontSize: 14,
                color: _getBackgroundColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog para seleção de frequência
  void _showFrequenciaDialog(BuildContext context, bool isParcelada) {
    final opcoes = [
      {'value': 'semanal', 'label': 'Semanal'},
      {'value': 'quinzenal', 'label': 'Quinzenal'},
      {'value': 'mensal', 'label': 'Mensal'},
      {'value': 'anual', 'label': 'Anual'},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecionar Frequência',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ...opcoes.map((opcao) {
              final isSelected = isParcelada 
                  ? frequenciaParcelada == opcao['value']
                  : frequenciaPrevisivel == opcao['value'];
              
              return ListTile(
                title: Text(opcao['label']!),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? _getBackgroundColor() : Colors.grey,
                ),
                onTap: () {
                  if (isParcelada) {
                    onFrequenciaParceladaChanged(opcao['value']!);
                  } else {
                    onFrequenciaPrevisivelChanged(opcao['value']!);
                  }
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Helpers
  Color _getBackgroundColor() {
    if (primaryColor != null) return primaryColor!;
    
    switch (tipoSelecionado) {
      case 'receita':
        return Colors.green.shade600;
      case 'despesa':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  TransactionContext _getTransactionContext() {
    switch (tipoSelecionado) {
      case 'receita':
        return TransactionContext.receita;
      case 'despesa':
        return TransactionContext.despesa;
      default:
        return TransactionContext.receita;
    }
  }

  String _getFrequenciaLabel(String frequencia) {
    switch (frequencia) {
      case 'semanal':
        return 'Semanal';
      case 'quinzenal':
        return 'Quinzenal';
      case 'mensal':
        return 'Mensal';
      case 'anual':
        return 'Anual';
      default:
        return 'Mensal';
    }
  }

  String _getPreviewText() {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    if (tipoTransacao == 'parcelada') {
      final valorPorParcela = valorTotal / numeroParcelas;
      return '$numeroParcelas× de ${formatter.format(valorPorParcela)} (${_getFrequenciaLabel(frequenciaParcelada).toLowerCase()})';
    } else {
      return '${formatter.format(valorTotal)} ${_getFrequenciaLabel(frequenciaPrevisivel).toLowerCase()} por $totalRecorrencias vezes';
    }
  }
}