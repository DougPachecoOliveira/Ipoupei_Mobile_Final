import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/fatura_model.dart';
import 'package:intl/intl.dart';

/// Seletor de faturas com design moderno
/// Permite navegação entre períodos de faturas do cartão
class FaturaSelector extends StatelessWidget {
  final List<FaturaModel> faturas;
  final String? faturaSelected;
  final Function(String?) onChanged;
  final String label;
  final bool enabled;
  final bool showStatus;
  final bool showValores;

  const FaturaSelector({
    super.key,
    required this.faturas,
    required this.faturaSelected,
    required this.onChanged,
    this.label = 'Período da Fatura',
    this.enabled = true,
    this.showStatus = true,
    this.showValores = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: enabled ? Colors.white : Colors.grey[100],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: faturaSelected,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Selecione um período',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled ? AppColors.roxoHeader : Colors.grey,
                ),
              ),
              onChanged: enabled ? onChanged : null,
              items: faturas.map((fatura) {
                return DropdownMenuItem<String>(
                  value: fatura.id,
                  child: _buildFaturaItem(fatura),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaturaItem(FaturaModel fatura) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      fatura.periodoFormatado,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (showStatus) _buildStatusChip(fatura),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Venc: ${DateFormat('dd/MM').format(fatura.dataVencimento)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (showValores) ...[
                      const SizedBox(width: 16),
                      Text(
                        fatura.valorTotalFormatado,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fatura.isVencida ? Colors.red[600] : Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (fatura.isVencida)
            Icon(
              Icons.warning,
              color: Colors.red[600],
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(FaturaModel fatura) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String text;
    
    switch (fatura.status) {
      case 'paga':
        backgroundColor = Colors.green[600]!;
        text = 'Paga';
        break;
      case 'vencida':
        backgroundColor = Colors.red[600]!;
        text = 'Vencida';
        break;
      case 'fechada':
        backgroundColor = Colors.orange[600]!;
        text = 'Fechada';
        break;
      default:
        backgroundColor = Colors.blue[600]!;
        text = 'Aberta';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Seletor horizontal de período com navegação por setas
/// Design mais compacto para uso em headers
class PeriodoSelector extends StatelessWidget {
  final DateTime periodoAtual;
  final Function(DateTime) onPeriodoChanged;
  final bool enabled;

  const PeriodoSelector({
    super.key,
    required this.periodoAtual,
    required this.onPeriodoChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: enabled ? _periodoAnterior : null,
            icon: Icon(
              Icons.chevron_left,
              color: enabled ? AppColors.roxoHeader : Colors.grey,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              DateFormat('MMM/yyyy', 'pt_BR').format(periodoAtual),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? _proximoPeriodo : null,
            icon: Icon(
              Icons.chevron_right,
              color: enabled ? AppColors.roxoHeader : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _periodoAnterior() {
    final novoPeriodo = DateTime(
      periodoAtual.year,
      periodoAtual.month - 1,
      1,
    );
    onPeriodoChanged(novoPeriodo);
  }

  void _proximoPeriodo() {
    final novoPeriodo = DateTime(
      periodoAtual.year,
      periodoAtual.month + 1,
      1,
    );
    onPeriodoChanged(novoPeriodo);
  }
}

/// Widget compacto de resumo de fatura
/// Para uso em listas ou cards resumidos
class FaturaResumo extends StatelessWidget {
  final FaturaModel fatura;
  final VoidCallback? onTap;
  final bool showActions;

  const FaturaResumo({
    super.key,
    required this.fatura,
    this.onTap,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fatura.isVencida ? Colors.red[200]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fatura.periodoFormatado,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vencimento',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(fatura.dataVencimento),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fatura.isVencida ? Colors.red[600] : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Valor Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      fatura.valorTotalFormatado,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (fatura.valorPago > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: fatura.percentualPago / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  fatura.percentualPago >= 100 ? Colors.green : AppColors.roxoHeader,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pago: ${fatura.valorPagoFormatado} (${fatura.percentualPago.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    String text = fatura.statusDescricao;
    
    switch (fatura.status) {
      case 'paga':
        backgroundColor = Colors.green[600]!;
        break;
      case 'vencida':
        backgroundColor = Colors.red[600]!;
        break;
      case 'fechada':
        backgroundColor = Colors.orange[600]!;
        break;
      default:
        backgroundColor = Colors.blue[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}