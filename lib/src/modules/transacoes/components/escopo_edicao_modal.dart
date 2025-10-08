import 'package:flutter/material.dart';
import '../services/transacao_edit_service.dart';

class EscopoEdicaoModal extends StatefulWidget {
  final String tipoOperacao;
  final int totalTransacoes;
  final int transacoesLocais;
  final bool requerConexao;
  final String? detalhesOperacao;

  const EscopoEdicaoModal({
    Key? key,
    required this.tipoOperacao,
    required this.totalTransacoes,
    required this.transacoesLocais,
    required this.requerConexao,
    this.detalhesOperacao,
  }) : super(key: key);

  @override
  State<EscopoEdicaoModal> createState() => _EscopoEdicaoModalState();
}

class _EscopoEdicaoModalState extends State<EscopoEdicaoModal> {
  EscopoEdicao? _escopoSelecionado;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ✅ HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Escolher Escopo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tipoOperacao,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          /// ✅ CONTEÚDO
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.detalhesOperacao != null) ...[
                  Text(
                    widget.detalhesOperacao!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                /// OPÇÕES DE ESCOPO
                ...EscopoEdicao.values.map((escopo) {
                  final quantidade = _calcularQuantidadeTransacoes(escopo);
                  final estaDisponivel = _escopoEstaDisponivel(escopo);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: estaDisponivel ? () => _selecionarEscopo(escopo) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _escopoSelecionado == escopo
                                ? Theme.of(context).primaryColor
                                : estaDisponivel
                                    ? Colors.grey[300]!
                                    : Colors.grey[200]!,
                            width: _escopoSelecionado == escopo ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: estaDisponivel
                              ? _escopoSelecionado == escopo
                                  ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                                  : Colors.white
                              : Colors.grey[50],
                        ),
                        child: Row(
                          children: [
                            Radio<EscopoEdicao>(
                              value: escopo,
                              groupValue: _escopoSelecionado,
                              onChanged: estaDisponivel ? _selecionarEscopo : null,
                              activeColor: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    escopo.descricao,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: estaDisponivel
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$quantidade transação${quantidade != 1 ? 'ões' : ''} afetada${quantidade != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: estaDisponivel
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                  if (!estaDisponivel) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Não disponível para esta transação',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                /// INFORMAÇÃO ADICIONAL (se necessário)
                if (_escopoSelecionado != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Operação será executada localmente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// ✅ BOTÕES
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                /// CANCELAR
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// CONTINUAR
                Expanded(
                  child: ElevatedButton(
                    onPressed: _escopoSelecionado != null
                        ? () => Navigator.of(context).pop(_escopoSelecionado)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selecionarEscopo(EscopoEdicao? escopo) {
    setState(() {
      _escopoSelecionado = escopo;
    });
  }

  int _calcularQuantidadeTransacoes(EscopoEdicao escopo) {
    switch (escopo) {
      case EscopoEdicao.apenasEsta:
        return 1;
      case EscopoEdicao.estasEFuturas:
        // Simplificado - seria calculado dinamicamente
        return widget.transacoesLocais;
      case EscopoEdicao.todasRelacionadas:
        return widget.totalTransacoes;
    }
  }

  bool _escopoEstaDisponivel(EscopoEdicao escopo) {
    // Por enquanto, todas as opções estão sempre disponíveis
    // Futuramente aqui seria implementada a lógica para verificar
    // se o escopo é válido para o tipo de transação
    return true;
  }
}

/// ✅ CLASSE HELPER PARA MOSTRAR O MODAL
class EscopoEdicaoHelper {
  static Future<EscopoEdicao?> mostrar({
    required BuildContext context,
    required String tipoOperacao,
    required int totalTransacoes,
    required int transacoesLocais,
    required bool requerConexao,
    String? detalhesOperacao,
  }) async {
    return await showDialog<EscopoEdicao>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EscopoEdicaoModal(
        tipoOperacao: tipoOperacao,
        totalTransacoes: totalTransacoes,
        transacoesLocais: transacoesLocais,
        requerConexao: requerConexao,
        detalhesOperacao: detalhesOperacao,
      ),
    );
  }
}