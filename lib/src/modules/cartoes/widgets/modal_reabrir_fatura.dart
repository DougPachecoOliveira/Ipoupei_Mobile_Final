import 'package:flutter/material.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/fatura_operations_service.dart';

class ModalReabrirFatura extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final CartaoModel cartao;
  final FaturaModel? fatura;
  final VoidCallback onSuccess;

  const ModalReabrirFatura({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.cartao,
    required this.fatura,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<ModalReabrirFatura> createState() => _ModalReabrirFaturaState();
}

class _ModalReabrirFaturaState extends State<ModalReabrirFatura> {
  final FaturaOperationsService _faturaOperations = FaturaOperationsService.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.refresh, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reabrir Fatura',
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cartão: ${widget.cartao.nome}'),
                  Text('Bandeira: ${widget.cartao.bandeira ?? "N/A"}'),
                  if (widget.fatura != null) ...[
                    Text('Vencimento: ${_formatarData(widget.fatura!.dataVencimento)}'),
                    Text('Valor: R\$ ${widget.fatura!.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}'),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Aviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atenção!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Esta ação irá desfazer o pagamento da fatura, tornando todas as transações não efetivadas novamente.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
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
                  onPressed: _isLoading ? null : _confirmarReabertura,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar Reabertura'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarReabertura() async {
    if (widget.fatura == null) return;

    setState(() => _isLoading = true);

    try {
      final resultado = await _faturaOperations.reabrirFatura(
        cartaoId: widget.cartao.id,
        faturaVencimento: widget.fatura!.dataVencimento.toIso8601String().split('T')[0],
      );

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura reaberta com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
        widget.onClose();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Erro ao reabrir fatura'),
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
}