import 'package:flutter/material.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/fatura_operations_service.dart';

class ModalPagamentoFatura extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final CartaoModel cartao;
  final FaturaModel? fatura;
  final VoidCallback onSuccess;

  const ModalPagamentoFatura({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.cartao,
    required this.fatura,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<ModalPagamentoFatura> createState() => _ModalPagamentoFaturaState();
}

class _ModalPagamentoFaturaState extends State<ModalPagamentoFatura> {
  final FaturaOperationsService _faturaOperations = FaturaOperationsService.instance;
  final _formKey = GlobalKey<FormState>();
  
  String? _contaId;
  double? _valorPago;
  DateTime? _dataPagamento = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fatura != null) {
      _valorPago = widget.fatura!.valorTotal;
    }
  }

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
                const Icon(Icons.payment, color: Colors.green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pagar Fatura',
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
                  if (widget.fatura != null)
                    Text('Vencimento: ${_formatarData(widget.fatura!.dataVencimento)}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Formulário
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conta de Pagamento
                  const Text('Conta de Pagamento *'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _contaId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecione a conta',
                    ),
                    validator: (value) => value == null ? 'Selecione uma conta' : null,
                    onChanged: (value) => setState(() => _contaId = value),
                    items: const [
                      // TODO: Buscar contas reais do banco
                      DropdownMenuItem(
                        value: 'conta1',
                        child: Text('Conta Principal'),
                      ),
                      DropdownMenuItem(
                        value: 'conta2',
                        child: Text('Conta Poupança'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Valor Pago
                  const Text('Valor a Pagar *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _valorPago?.toStringAsFixed(2).replaceAll('.', ','),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Digite o valor';
                      final valor = double.tryParse(value.replaceAll(',', '.'));
                      if (valor == null || valor <= 0) return 'Valor inválido';
                      return null;
                    },
                    onChanged: (value) {
                      _valorPago = double.tryParse(value.replaceAll(',', '.'));
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Data do Pagamento
                  const Text('Data do Pagamento *'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Text(_formatarData(_dataPagamento!)),
                        ],
                      ),
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
                  onPressed: _isLoading ? null : _confirmarPagamento,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar Pagamento'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataPagamento!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (data != null) {
      setState(() => _dataPagamento = data);
    }
  }

  Future<void> _confirmarPagamento() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_contaId == null || _valorPago == null || _valorPago! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado = await _faturaOperations.pagarFatura(
        cartaoId: widget.cartao.id,
        faturaVencimento: widget.fatura!.dataVencimento.toIso8601String().split('T')[0],
        contaId: _contaId!,
        valorPago: _valorPago!,
        dataPagamento: _dataPagamento,
      );

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura paga com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
        widget.onClose();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Erro ao pagar fatura'),
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