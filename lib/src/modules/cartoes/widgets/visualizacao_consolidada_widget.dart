import 'package:flutter/material.dart';
import '../models/cartao_model.dart';

class VisualizacaoConsolidadaWidget extends StatelessWidget {
  final List<CartaoModel> cartoes;
  final Map<String, dynamic> totais;
  final bool mostrarValores;
  final String Function(double) formatarValorComPrivacidade;
  final VoidCallback onToggleMostrarValores;
  final Function(CartaoModel) onVerDetalheCartao;
  final Function(CartaoModel)? onEditarCartao;

  const VisualizacaoConsolidadaWidget({
    Key? key,
    required this.cartoes,
    required this.totais,
    required this.mostrarValores,
    required this.formatarValorComPrivacidade,
    required this.onToggleMostrarValores,
    required this.onVerDetalheCartao,
    this.onEditarCartao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Resumo Superior
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResumoItem(
                    'Faturas Abertas',
                    formatarValorComPrivacidade(totais['faturaAtual'] ?? 0.0),
                    Colors.orange,
                    Icons.credit_card,
                  ),
                  _buildResumoItem(
                    'Limite Total',
                    formatarValorComPrivacidade(totais['limiteTotal'] ?? 0.0),
                    Colors.green,
                    Icons.account_balance_wallet,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResumoItem(
                    'Cartões Ativos',
                    '${cartoes.where((c) => c.ativo).length}',
                    Colors.blue,
                    Icons.credit_card_outlined,
                  ),
                  _buildResumoItem(
                    'Próximo Vencimento',
                    '${totais['diasVencimento'] ?? 0} dias',
                    Colors.red,
                    Icons.schedule,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lista de Cartões
        Expanded(
          child: cartoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhum cartão cadastrado'),
                      const SizedBox(height: 8),
                      Text(
                        'DEBUG: ${cartoes.length} cartões encontrados',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartoes.length,
                  itemBuilder: (context, index) {
                    final cartao = cartoes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCartaoCard(context, cartao),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResumoItem(String label, String valor, Color cor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildCartaoCard(BuildContext context, CartaoModel cartao) {
    final percentualUtilizacao = cartao.limite > 0 
        ? (0.0 / cartao.limite) * 100  // TODO: Implementar cálculo real
        : 0.0;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => onVerDetalheCartao(cartao),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(int.parse(cartao.cor?.replaceAll('#', '0xFF') ?? '0xFF8B5CF6')),
              width: 3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(cartao.cor?.replaceAll('#', '0xFF') ?? '0xFF8B5CF6')),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartao.nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${cartao.bandeira ?? 'Bandeira'} • ${cartao.banco ?? 'Banco'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEditarCartao != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => onEditarCartao!(cartao),
                          tooltip: 'Editar cartão',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      if (!cartao.ativo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ARQUIVADO',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informações do Cartão
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Limite', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        formatarValorComPrivacidade(cartao.limite),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Vencimento', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        'Dia ${cartao.diaVencimento}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Barra de Utilização
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Utilização: ${percentualUtilizacao.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Disponível: ${formatarValorComPrivacidade(cartao.limite)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentualUtilizacao / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentualUtilizacao > 80 
                          ? Colors.red 
                          : percentualUtilizacao > 60 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}