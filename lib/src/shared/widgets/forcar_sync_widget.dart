// 🔄 Forçar Sincronização Widget - iPoupei Mobile
//
// Widget para forçar sincronização manual dos dados
// Estilo similar ao ImportarDadosWidget mas em teal
//
// Baseado em: Material Design + Card Pattern

import 'package:flutter/material.dart';
import '../../database/hard_reset_service.dart';
import 'interactive_loading_widget.dart';

/// Widget elegante para forçar sincronização
class ForcarSyncWidget extends StatelessWidget {
  final VoidCallback? onSyncSuccess;

  const ForcarSyncWidget({
    super.key,
    this.onSyncSuccess,
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
            Color(0xFF14B8A6), // teal-500
            Color(0xFF0F766E), // teal-700
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withAlpha(78),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSincronizacao(context),
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
                    Icons.sync,
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
                        'Forçar Sincronização',
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
                          'Atualizar dados do servidor',
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
                    color: Colors.white.withAlpha(52),
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

  /// 🔄 HANDLE HARD RESET
  void _handleSincronizacao(BuildContext context) async {
    if (HardResetService.instance.isResetting) {
      _showAlreadyResettingMessage(context);
      return;
    }

    final confirmar = await _showConfirmDialog(context);
    if (!confirmar) return;

    await _executarHardReset(context);
  }

  /// ❓ CONFIRMAÇÃO DE HARD RESET
  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hard Reset'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta ação irá:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• Apagar TODOS os dados locais',
            ),
            Text(
              '• Recarregar tudo do Servidor',
            ),
            Text(
              '• Resolver problemas de cache',
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Certifique-se de ter conexão estável com internet.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Reset'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 🔄 EXECUTAR HARD RESET
  Future<void> _executarHardReset(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => InteractiveLoadingWidget(
          progressStream: HardResetService.instance.progressStream,
          onCompleted: () {
            Navigator.of(context).pop();
            _showSucessoReset(context);
            if (onSyncSuccess != null) {
              onSyncSuccess!();
            }
          },
        ),
      );

      final sucesso = await HardResetService.instance.performHardReset();

      if (!sucesso) {
        Navigator.of(context).pop();
        _showErroReset(context);
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErroReset(context);
    }
  }

  /// ✅ MOSTRAR SUCESSO
  void _showSucessoReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Reset Concluído!'),
          ],
        ),
        content: const Text(
          'Todos os dados foram recarregados com sucesso.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ❌ MOSTRAR ERRO
  void _showErroReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro no Reset'),
          ],
        ),
        content: const Text(
          'Falha ao executar o hard reset. Tente novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ⚠️ MENSAGEM JÁ RESETANDO
  void _showAlreadyResettingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ Hard reset já em andamento...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
