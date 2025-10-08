import 'package:flutter/material.dart';

class ConfirmacaoModal extends StatelessWidget {
  final String titulo;
  final String mensagem;
  final String textoCancelar;
  final String textoConfirmar;
  final Color? corConfirmar;
  final IconData? icone;

  const ConfirmacaoModal({
    Key? key,
    required this.titulo,
    required this.mensagem,
    this.textoCancelar = 'Cancelar',
    this.textoConfirmar = 'Confirmar',
    this.corConfirmar,
    this.icone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cor = corConfirmar ?? Colors.blue;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ✅ HEADER COM ÍCONE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                if (icone != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icone!,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                if (icone != null) const SizedBox(height: 16),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          /// ✅ CONTEÚDO
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              mensagem,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
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
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      textoCancelar,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// CONFIRMAR
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      textoConfirmar,
                      style: const TextStyle(
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
}

/// ✅ MODAL DE CONFIRMAÇÃO RÁPIDA
class ConfirmacaoRapida {
  /// ✅ CONFIRMAÇÃO SIMPLES
  static Future<bool> mostrar({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    String textoCancelar = 'Cancelar',
    String textoConfirmar = 'Confirmar',
    Color? cor,
    IconData? icone,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmacaoModal(
        titulo: titulo,
        mensagem: mensagem,
        textoCancelar: textoCancelar,
        textoConfirmar: textoConfirmar,
        corConfirmar: cor,
        icone: icone,
      ),
    );

    return resultado ?? false;
  }

  /// ✅ CONFIRMAÇÃO DE EXCLUSÃO
  static Future<bool> excluir({
    required BuildContext context,
    required String item,
    String? detalhes,
  }) async {
    return mostrar(
      context: context,
      titulo: 'Excluir $item',
      mensagem: detalhes ?? 'Tem certeza que deseja excluir este $item?\n\nEsta ação não pode ser desfeita.',
      textoConfirmar: 'Excluir',
      cor: Colors.red,
      icone: Icons.delete,
    );
  }

  /// ✅ CONFIRMAÇÃO DE ARQUIVAMENTO
  static Future<bool> arquivar({
    required BuildContext context,
    required String item,
  }) async {
    return mostrar(
      context: context,
      titulo: 'Arquivar $item',
      mensagem: 'Tem certeza que deseja arquivar este $item?\n\nVocê pode reativá-lo a qualquer momento.',
      textoConfirmar: 'Arquivar',
      cor: Colors.orange,
      icone: Icons.archive,
    );
  }

  /// ✅ CONFIRMAÇÃO DE REATIVAÇÃO
  static Future<bool> reativar({
    required BuildContext context,
    required String item,
  }) async {
    return mostrar(
      context: context,
      titulo: 'Reativar $item',
      mensagem: 'Tem certeza que deseja reativar este $item?',
      textoConfirmar: 'Reativar',
      cor: Colors.green,
      icone: Icons.unarchive,
    );
  }

  /// ✅ CONFIRMAÇÃO DE LIMPEZA
  static Future<bool> limpar({
    required BuildContext context,
    required String titulo,
    required String mensagem,
  }) async {
    return mostrar(
      context: context,
      titulo: titulo,
      mensagem: mensagem,
      textoConfirmar: 'Limpar',
      cor: Colors.orange,
      icone: Icons.delete_sweep,
    );
  }
}