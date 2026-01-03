// 🔄 Forçar Sincronização Widget - iPoupei Mobile
//
// Widget para forçar sincronização manual dos dados
// Estilo similar ao ImportarDadosWidget mas em teal
//
// Baseado em: Material Design + Card Pattern

import 'package:flutter/material.dart';
import '../../database/hard_reset_service.dart';
import '../../sync/sync_manager.dart';
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

  /// 🔄 HANDLE SINCRONIZAÇÃO
  void _handleSincronizacao(BuildContext context) async {
    // Verificar se já está sincronizando
    if (SyncManager.instance.status == SyncStatus.syncing) {
      _showAlreadySyncingMessage(context);
      return;
    }

    // Mostrar confirmação
    final confirmar = await _showConfirmDialog(context);
    if (!confirmar) return;

    // Executar sincronização
    await _executarSincronizacao(context);
  }

  /// ❓ CONFIRMAÇÃO DE SINCRONIZAÇÃO
  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Colors.teal),
            SizedBox(width: 8),
            Text('Forçar Sincronização'),
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
            Text('• Buscar atualizações do servidor'),
            Text('• Sincronizar dados locais'),
            Text('• Atualizar todas as telas'),
            SizedBox(height: 12),
            Text(
              'ℹ️ Use quando houver dados desatualizados.',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
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
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 🔄 EXECUTAR SINCRONIZAÇÃO
  Future<void> _executarSincronizacao(BuildContext context) async {
    try {
      // Mostrar loading simples
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text('Sincronizando dados...'),
            ],
          ),
        ),
      );

      // Executar sync
      await SyncManager.instance.syncAll();

      // Fechar loading
      Navigator.of(context).pop();

      // Mostrar sucesso
      _showSucessoSync(context);

      // Callback de sucesso
      if (onSyncSuccess != null) {
        onSyncSuccess!();
      }

    } catch (e) {
      // Fechar loading se estiver aberto
      Navigator.of(context).pop();

      // Mostrar erro
      _showErroSync(context, e.toString());
    }
  }

  /// ✅ MOSTRAR SUCESSO
  void _showSucessoSync(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Sincronizado!'),
          ],
        ),
        content: const Text(
          'Todos os dados foram sincronizados com sucesso.',
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
  void _showErroSync(BuildContext context, String erro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro na Sincronização'),
          ],
        ),
        content: Text('Falha ao sincronizar: $erro'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ⚠️ MENSAGEM JÁ SINCRONIZANDO
  void _showAlreadySyncingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ Sincronização já em andamento...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}