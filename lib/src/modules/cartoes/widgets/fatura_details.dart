import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/fatura_model.dart';
import '../../transacoes/models/transacao_model.dart';
import 'package:intl/intl.dart';

/// Widget detalhado de uma fatura
/// Mostra informações completas da fatura com design moderno
class FaturaDetails extends StatelessWidget {
  final FaturaModel fatura;
  final List<TransacaoModel> transacoes;
  final bool showActions;
  final Function(TransacaoModel)? onTransacaoTap;
  final VoidCallback? onPagarFatura;
  final VoidCallback? onReabrirFatura;

  const FaturaDetails({
    super.key,
    required this.fatura,
    required this.transacoes,
    this.showActions = true,
    this.onTransacaoTap,
    this.onPagarFatura,
    this.onReabrirFatura,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildResumoValores(),
          const SizedBox(height: 16),
          if (showActions) _buildActions(context),
          const SizedBox(height: 16),
          _buildTransacoesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.roxoHeader,
            AppColors.roxoHeader.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.roxoHeader.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fatura.periodoFormatado,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vencimento: ${DateFormat('dd/MM/yyyy').format(fatura.dataVencimento)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          if (fatura.isVencida)
            Text(
              '${fatura.diasAteVencimento.abs()} dias em atraso',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    String text = fatura.statusDescricao;
    
    switch (fatura.status) {
      case 'paga':
        backgroundColor = Colors.green;
        break;
      case 'vencida':
        backgroundColor = Colors.red;
        break;
      case 'fechada':
        backgroundColor = Colors.orange;
        break;
      default:
        backgroundColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResumoValores() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildValorRow(
            'Valor Total',
            fatura.valorTotalFormatado,
            Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          if (fatura.valorPago > 0) ...[
            const Divider(height: 24),
            _buildValorRow(
              'Valor Pago',
              fatura.valorPagoFormatado,
              Colors.green[600]!,
            ),
            const SizedBox(height: 8),
            _buildValorRow(
              'Restante',
              fatura.valorRestanteFormatado,
              fatura.valorRestante > 0 ? Colors.red[600]! : Colors.green[600]!,
              fontWeight: FontWeight.w600,
            ),
          ],
          const Divider(height: 24),
          _buildValorRow(
            'Valor Mínimo',
            fatura.valorMinimoFormatado,
            Colors.orange[600]!,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: fatura.percentualPago / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              fatura.percentualPago >= 100 ? Colors.green : AppColors.roxoHeader,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${fatura.percentualPago.toStringAsFixed(1)}% pago',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValorRow(
    String label,
    String valor,
    Color color, {
    FontWeight fontWeight = FontWeight.normal,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.grey[700],
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (!fatura.paga && onPagarFatura != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onPagarFatura,
              icon: const Icon(Icons.payment),
              label: const Text('Pagar Fatura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (fatura.paga && onReabrirFatura != null) ...[
          if (!fatura.paga) const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReabrirFatura,
              icon: const Icon(Icons.refresh),
              label: const Text('Reabrir Fatura'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.roxoHeader,
                side: BorderSide(color: AppColors.roxoHeader),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransacoesList() {
    if (transacoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação encontrada',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Transações (${transacoes.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transacoes.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return _buildTransacaoItem(transacoes[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTransacaoItem(TransacaoModel transacao) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTransacaoTap != null ? () => onTransacaoTap!(transacao) : null,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.roxoHeader.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: AppColors.roxoHeader,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transacao.descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(transacao.data),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (transacao.totalParcelas != null && transacao.totalParcelas! > 1)
                    Text(
                      'Parcela ${transacao.parcelaAtual}/${transacao.totalParcelas}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              CurrencyFormatter.format(transacao.valor),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transacao.tipo == 'receita' ? Colors.green[600] : Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}