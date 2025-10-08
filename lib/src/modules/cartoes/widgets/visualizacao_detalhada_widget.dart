import 'package:flutter/material.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';

class VisualizacaoDetalhadaWidget extends StatelessWidget {
  final CartaoModel cartaoSelecionado;
  final List<CartaoModel> cartoes;
  final FaturaModel? faturaAtual;
  final List<FaturaModel> faturasProcessadas;
  final Map<String, dynamic> statusFatura;
  final bool mostrarValores;
  final String Function(double) formatarValorComPrivacidade;
  final VoidCallback onVoltarConsolidada;
  final Function(String) onTrocarCartao;
  final Function(String) onTrocarFatura;
  final VoidCallback onToggleMostrarValores;
  final Function(Map<String, dynamic>) onExcluirTransacao;
  final VoidCallback onAbrirModalPagamento;
  final VoidCallback onAbrirModalReabertura;
  final VoidCallback onAbrirModalEstorno;

  const VisualizacaoDetalhadaWidget({
    Key? key,
    required this.cartaoSelecionado,
    required this.cartoes,
    required this.faturaAtual,
    required this.faturasProcessadas,
    required this.statusFatura,
    required this.mostrarValores,
    required this.formatarValorComPrivacidade,
    required this.onVoltarConsolidada,
    required this.onTrocarCartao,
    required this.onTrocarFatura,
    required this.onToggleMostrarValores,
    required this.onExcluirTransacao,
    required this.onAbrirModalPagamento,
    required this.onAbrirModalReabertura,
    required this.onAbrirModalEstorno,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header com informações do cartão e fatura
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seletor de Cartão
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: cartaoSelecionado.id,
                      isExpanded: true,
                      onChanged: (value) => value != null ? onTrocarCartao(value) : null,
                      items: cartoes.map((cartao) => DropdownMenuItem(
                        value: cartao.id,
                        child: Text('${cartao.nome} - ${cartao.bandeira}'),
                      )).toList(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onVoltarConsolidada,
                    tooltip: 'Voltar',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informações da Fatura Atual
              if (faturaAtual != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: faturaAtual!.dataVencimento.toIso8601String().split('T')[0],
                        isExpanded: true,
                        onChanged: (value) => value != null ? onTrocarFatura(value) : null,
                        items: faturasProcessadas.map((fatura) => DropdownMenuItem(
                          value: fatura.dataVencimento.toIso8601String().split('T')[0],
                          child: Text(
                            '${_formatarMesPortugues(fatura.dataVencimento)} - ${fatura.paga ? "Paga" : "Em Aberto"}'
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Resumo da Fatura
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      'Valor Total',
                      formatarValorComPrivacidade(faturaAtual!.valorTotal),
                      Colors.blue,
                    ),
                    _buildInfoItem(
                      'Status',
                      statusFatura['status_paga'] == true ? 'Paga' : 'Em Aberto',
                      statusFatura['status_paga'] == true ? Colors.green : Colors.orange,
                    ),
                    _buildInfoItem(
                      'Vencimento',
                      'Dia ${cartaoSelecionado.diaVencimento}',
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Ações da Fatura
        if (faturaAtual != null)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!(statusFatura['status_paga'] == true))
                  ElevatedButton.icon(
                    onPressed: onAbrirModalPagamento,
                    icon: const Icon(Icons.payment),
                    label: const Text('Pagar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                
                if (statusFatura['status_paga'] == true)
                  ElevatedButton.icon(
                    onPressed: onAbrirModalReabertura,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reabrir'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                
                if (statusFatura['status_paga'] == true)
                  ElevatedButton.icon(
                    onPressed: onAbrirModalEstorno,
                    icon: const Icon(Icons.undo),
                    label: const Text('Estorno'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
              ],
            ),
          ),
        
        // Lista de Transações
        Expanded(
          child: _buildListaTransacoes(),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String valor, Color cor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildListaTransacoes() {
    // Simulando transações vazias por enquanto
    // TODO: Implementar busca real de transações
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhuma transação encontrada'),
          SizedBox(height: 8),
          Text(
            'As transações desta fatura aparecerão aqui',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatarMesPortugues(DateTime data) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[data.month - 1]} ${data.year}';
  }
}