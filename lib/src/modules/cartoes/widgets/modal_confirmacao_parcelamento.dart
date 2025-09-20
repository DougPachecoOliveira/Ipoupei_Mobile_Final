import 'package:flutter/material.dart';

class ModalConfirmacaoParcelamento extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String transacaoDescricao;
  final int parcelaAtual;
  final int totalParcelas;
  final Function(bool excluirTodas) onConfirmar;

  const ModalConfirmacaoParcelamento({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.transacaoDescricao,
    required this.parcelaAtual,
    required this.totalParcelas,
    required this.onConfirmar,
  }) : super(key: key);

  @override
  State<ModalConfirmacaoParcelamento> createState() => _ModalConfirmacaoParcelamentoState();
}

class _ModalConfirmacaoParcelamentoState extends State<ModalConfirmacaoParcelamento> {
  String _opcaoSelecionada = 'parcela'; // 'parcela', 'todas', 'futuras'

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
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Excluir Parcelamento',
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
            
            // Informações da Transação
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transação: ${widget.transacaoDescricao}'),
                  Text('Parcela atual: ${widget.parcelaAtual}/${widget.totalParcelas}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Esta transação faz parte de um parcelamento. Como deseja proceder?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Opções
            Column(
              children: [
                // Apenas esta parcela
                RadioListTile<String>(
                  title: const Text('Excluir apenas esta parcela'),
                  subtitle: Text('Parcela ${widget.parcelaAtual}/${widget.totalParcelas}'),
                  value: 'parcela',
                  groupValue: _opcaoSelecionada,
                  onChanged: (value) => setState(() => _opcaoSelecionada = value!),
                ),
                
                // Todas as parcelas
                RadioListTile<String>(
                  title: const Text('Excluir todo o parcelamento'),
                  subtitle: Text('Todas as ${widget.totalParcelas} parcelas'),
                  value: 'todas',
                  groupValue: _opcaoSelecionada,
                  onChanged: (value) => setState(() => _opcaoSelecionada = value!),
                ),
                
                // Parcelas futuras
                if (widget.parcelaAtual < widget.totalParcelas)
                  RadioListTile<String>(
                    title: const Text('Excluir esta e as próximas parcelas'),
                    subtitle: Text('${widget.totalParcelas - widget.parcelaAtual + 1} parcelas (da ${widget.parcelaAtual}ª até a ${widget.totalParcelas}ª)'),
                    value: 'futuras',
                    groupValue: _opcaoSelecionada,
                    onChanged: (value) => setState(() => _opcaoSelecionada = value!),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Aviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Atenção: Esta ação não pode ser desfeita. Apenas parcelas não efetivadas podem ser excluídas.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
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
                  onPressed: widget.onClose,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => widget.onConfirmar(_opcaoSelecionada == 'todas'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Confirmar Exclusão'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}