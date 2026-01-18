// 📊 Importar Dados Widget - iPoupei Mobile
//
// Widget bonito e simples para importação de dados
// Linha única com visual elegante para relatórios page
//
// Baseado em: Material Design + Card Pattern

import 'package:flutter/material.dart';
import '../pages/importacao_modal.dart';
import '../../shared/theme/app_colors.dart';

/// Widget elegante de uma linha para importar dados
class ImportarDadosWidget extends StatelessWidget {
  final VoidCallback? onImportSuccess;

  const ImportarDadosWidget({
    super.key,
    this.onImportSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF3B82F6), // blue-500
            Color(0xFF1D4ED8), // blue-700
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withAlpha(78),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleImportacao(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Ícone com background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(52),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 16),

                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Importar Dados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: const Text(
                          'Extratos bancários e faturas de cartão',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Seta
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Manipula o clique na importação
  Future<void> _handleImportacao(BuildContext context) async {
    try {
      print('🚀 [IMPORT_DEBUG] Iniciando fluxo de importação...');
      final resultado = await ImportacaoModal.show(context);
      print('📋 [IMPORT_DEBUG] Resultado do modal: $resultado');

      if (resultado != null && resultado['sucesso'] == true) {
        final transacoesSalvas = resultado['transacoesSalvas'] ?? 0;
        final transacoesPuladas = resultado['transacoesPuladas'] ?? 0;

        // Mostrar feedback de sucesso
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ $transacoesSalvas transação(ões) importada(s) com sucesso!' +
                (transacoesPuladas > 0 ? '\n$transacoesPuladas foram puladas.' : ''),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );

          // Callback para atualizar dados
          onImportSuccess?.call();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na importação: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}