import 'package:flutter/material.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/fatura_operations_service.dart';

class ModalEstornoFatura extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final CartaoModel cartao;
  final FaturaModel? fatura;
  final VoidCallback onSuccess;

  const ModalEstornoFatura({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.cartao,
    required this.fatura,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<ModalEstornoFatura> createState() => _ModalEstornoFaturaState();
}

class _ModalEstornoFaturaState extends State<ModalEstornoFatura> {
  final FaturaOperationsService _faturaOperations = FaturaOperationsService.instance;
  final Set<String> _transacoesSelecionadas = {};
  bool _isLoading = false;
  bool _selecionarTodas = false;

  // Lista simulada de transações - TODO: Integrar com serviço real
  final List<Map<String, dynamic>> _transacoes = [
    {
      'id': '1',
      'descricao': 'Compra Supermercado',
      'valor': 150.00,
      'data': '2025-01-15',
      'categoria_nome': 'Alimentação',
      'efetivado': true,
    },
    {
      'id': '2',
      'descricao': 'Combustível',
      'valor': 80.00,
      'data': '2025-01-16',
      'categoria_nome': 'Transporte',
      'efetivado': true,
    },
    {
      'id': '3',
      'descricao': 'Farmácia',
      'valor': 45.50,
      'data': '2025-01-17',
      'categoria_nome': 'Saúde',
      'efetivado': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.undo, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Estorno Parcial de Fatura',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações do Cartão
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cartão: ${widget.cartao.nome}'),
                  Text('Bandeira: ${widget.cartao.bandeira ?? "N/A"}'),
                  if (widget.fatura != null) ...[
                    Text('Vencimento: ${_formatarData(widget.fatura!.dataVencimento)}'),
                    Text('Valor Total: R\$ ${widget.fatura!.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}'),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Seleção de Todas
            CheckboxListTile(
              title: const Text('Selecionar Todas as Transações'),
              value: _selecionarTodas,
              onChanged: _toggleSelecionarTodas,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            const Divider(),
            
            // Lista de Transações
            Expanded(
              child: _transacoes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma transação efetivada encontrada'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transacoes.length,
                      itemBuilder: (context, index) {
                        final transacao = _transacoes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            title: Text(transacao['descricao']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categoria: ${transacao['categoria_nome']}'),
                                Text('Data: ${_formatarDataBr(transacao['data'])}'),
                              ],
                            ),
                            secondary: Text(
                              'R\$ ${transacao['valor'].toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            value: _transacoesSelecionadas.contains(transacao['id']),
                            onChanged: (value) => _toggleTransacao(transacao['id']),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
            ),
            
            // Resumo da Seleção
            if (_transacoesSelecionadas.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_transacoesSelecionadas.length} transações selecionadas'),
                    Text(
                      'Total: R\$ ${_calcularTotalSelecionado().toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : widget.onClose,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading || _transacoesSelecionadas.isEmpty 
                      ? null 
                      : _confirmarEstorno,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar Estorno'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelecionarTodas(bool? value) {
    setState(() {
      _selecionarTodas = value ?? false;
      if (_selecionarTodas) {
        _transacoesSelecionadas.addAll(_transacoes.map((t) => t['id'] as String));
      } else {
        _transacoesSelecionadas.clear();
      }
    });
  }

  void _toggleTransacao(String transacaoId) {
    setState(() {
      if (_transacoesSelecionadas.contains(transacaoId)) {
        _transacoesSelecionadas.remove(transacaoId);
      } else {
        _transacoesSelecionadas.add(transacaoId);
      }
      
      _selecionarTodas = _transacoesSelecionadas.length == _transacoes.length;
    });
  }

  double _calcularTotalSelecionado() {
    return _transacoes
        .where((t) => _transacoesSelecionadas.contains(t['id']))
        .fold(0.0, (total, t) => total + (t['valor'] as double));
  }

  Future<void> _confirmarEstorno() async {
    if (widget.fatura == null || _transacoesSelecionadas.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final resultado = await _faturaOperations.estornarFatura(
        cartaoId: widget.cartao.id,
        faturaVencimento: widget.fatura!.dataVencimento.toIso8601String().split('T')[0],
        transacaoIds: _transacoesSelecionadas.toList(),
      );

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${resultado['transacoes_estornadas']} transações estornadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
        widget.onClose();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Erro ao estornar fatura'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarDataBr(String data) {
    final partes = data.split('-');
    if (partes.length == 3) {
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    }
    return data;
  }
}