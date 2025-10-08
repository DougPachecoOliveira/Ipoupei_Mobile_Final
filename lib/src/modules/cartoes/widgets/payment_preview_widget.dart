import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../contas/models/conta_model.dart';
import '../models/fatura_model.dart';

/// 📊 WIDGET DE PREVIEW DE PAGAMENTO 
/// Espelho do preview detalhado do React - mostra TODAS as informações
class PaymentPreviewWidget extends StatelessWidget {
  final String tipoPagamento;
  final double valorFatura;
  final double? valorPago;
  final double? valorParcela;
  final int? numeroParcelas;
  final ContaModel? contaSelecionada;

  const PaymentPreviewWidget({
    super.key,
    required this.tipoPagamento,
    required this.valorFatura,
    this.valorPago,
    this.valorParcela,
    this.numeroParcelas,
    this.contaSelecionada,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.fundoCartao,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 HEADER DO PREVIEW
            Row(
              children: [
                Icon(Icons.preview, color: AppColors.roxoHeader, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Preview do Pagamento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.roxoHeader,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🎯 PREVIEW ESPECÍFICO POR TIPO
            if (tipoPagamento == 'integral') 
              _buildPreviewIntegral()
            else if (tipoPagamento == 'parcial') 
              _buildPreviewParcial()
            else if (tipoPagamento == 'parcelado') 
              _buildPreviewParcelado(),

            const SizedBox(height: 16),

            // 🎯 RESUMO DO PAGAMENTO (SEMPRE PRESENTE)
            _buildResumoFinal(),
          ],
        ),
      ),
    );
  }

  /// ✅ PREVIEW PAGAMENTO INTEGRAL
  Widget _buildPreviewIntegral() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ Pagamento Integral',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text('• Efetivação: ${CurrencyFormatter.format(valorFatura)}'),
          Text('• Estorno: R\$ 0,00'),
          Text('• Débito real: ${CurrencyFormatter.format(valorFatura)}'),
          Text('• Fatura: ✅ Totalmente quitada'),
        ],
      ),
    );
  }

  /// ✅ PREVIEW PAGAMENTO PARCIAL
  Widget _buildPreviewParcial() {
    final valorPagoReal = valorPago ?? 0.0;
    final valorRestante = valorFatura - valorPagoReal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ Pagamento Parcial',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text('• Efetivação: ${CurrencyFormatter.format(valorFatura)}'),
          Text('• Estorno: ${CurrencyFormatter.format(valorRestante)}'),
          Text('• Débito real: ${CurrencyFormatter.format(valorPagoReal)}'),
          Text('• Diferença: ${CurrencyFormatter.format(valorRestante)} → próxima fatura'),
        ],
      ),
    );
  }

  /// ✅ PREVIEW PAGAMENTO PARCELADO
  Widget _buildPreviewParcelado() {
    final valorParcelaReal = valorParcela ?? 0.0;
    final numeroParcelasReal = numeroParcelas ?? 2;
    final valorTotal = valorParcelaReal * numeroParcelasReal;
    final diferenca = valorTotal - valorFatura;
    final percentual = valorFatura > 0 ? (diferenca / valorFatura) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ Pagamento Parcelado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text('• Efetivação: ${CurrencyFormatter.format(valorFatura)}'),
          Text('• Estorno: ${CurrencyFormatter.format(valorFatura)}'),
          Text('• Parcelas: ${numeroParcelasReal}x de ${CurrencyFormatter.format(valorParcelaReal)} (informado pelo banco)'),
          Text('• Débito hoje: R\$ 0,00'),
          
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: diferenca > 0 ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Custo do Parcelamento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diferenca > 0 ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Total a pagar: ${CurrencyFormatter.format(valorTotal)}'),
                Text('Valor original: ${CurrencyFormatter.format(valorFatura)}'),
                if (diferenca > 0) ...[
                  Text(
                    'Você pagará ${CurrencyFormatter.format(diferenca)} a mais (+${percentual.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Sem custo adicional',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 RESUMO FINAL (IGUAL AO REACT)
  Widget _buildResumoFinal() {
    final valorDebitoHoje = _calcularValorDebitoHoje();
    final saldoAtual = contaSelecionada?.saldo ?? 0.0;
    final saldoApos = saldoAtual - valorDebitoHoje;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fundoSecundario,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Resumo do Pagamento',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textoEscuro,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (contaSelecionada != null) ...[
            Text('Conta: ${contaSelecionada!.nome}'),
            Text('Saldo atual: ${CurrencyFormatter.format(saldoAtual)}'),
            Text('Valor a debitar: ${CurrencyFormatter.format(valorDebitoHoje)}'),
            Text(
              'Saldo após pagamento: ${CurrencyFormatter.format(saldoApos)}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: saldoApos >= 0 ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            
            // 🎯 AVISO ESPECIAL PARA PARCELADO
            if (tipoPagamento == 'parcelado') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Parcelado: Nenhum valor será debitado hoje',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Text(
              'Selecione uma conta para ver o resumo completo',
              style: TextStyle(
                color: AppColors.textoSecundario,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🔢 CALCULAR VALOR REAL QUE SERÁ DEBITADO HOJE
  double _calcularValorDebitoHoje() {
    switch (tipoPagamento) {
      case 'integral':
        return valorFatura;
      case 'parcial':
        return valorPago ?? 0.0;
      case 'parcelado':
        return 0.0; // Parcelado não debita hoje
      default:
        return 0.0;
    }
  }
}