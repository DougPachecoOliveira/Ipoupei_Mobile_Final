// 🔔 Notificações Page - iPoupei Mobile
// 
// Página principal para visualização de notificações
// Lista, marca como lida e arquiva notificações
// 
// Baseado em: Material Design + Notification Center

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notificacao_service.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  final _notificacaoService = NotificacaoService.instance;
  
  List<Map<String, dynamic>> _notificacoes = [];
  bool _loading = false;
  bool _incluirLidas = true;
  bool _incluirArquivadas = false;

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  /// 🔄 CARREGAR NOTIFICAÇÕES
  Future<void> _carregarNotificacoes() async {
    setState(() => _loading = true);
    
    try {
      final notificacoes = await _notificacaoService.fetchNotificacoes(
        incluirLidas: _incluirLidas,
        incluirArquivadas: _incluirArquivadas,
      );
      
      setState(() => _notificacoes = notificacoes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar notificações: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 📖 MARCAR COMO LIDA
  Future<void> _marcarComoLida(String notificacaoId) async {
    try {
      await _notificacaoService.marcarComoLida(notificacaoId);
      _carregarNotificacoes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar como lida: $e')),
        );
      }
    }
  }

  /// 📦 ARQUIVAR NOTIFICAÇÃO
  Future<void> _arquivarNotificacao(String notificacaoId) async {
    try {
      await _notificacaoService.arquivarNotificacao(notificacaoId);
      _carregarNotificacoes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao arquivar: $e')),
        );
      }
    }
  }

  /// 🎨 ÍCONE POR TIPO
  IconData _getIconePorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'sucesso':
        return Icons.check_circle;
      case 'erro':
        return Icons.error;
      case 'aviso':
        return Icons.warning;
      case 'sistema':
        return Icons.settings;
      case 'financeiro':
        return Icons.account_balance_wallet;
      case 'metas':
        return Icons.flag;
      default:
        return Icons.notifications;
    }
  }

  /// 🎨 COR POR TIPO
  Color _getCorPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'sucesso':
        return Colors.green;
      case 'erro':
        return Colors.red;
      case 'aviso':
        return Colors.orange;
      case 'sistema':
        return Colors.blue;
      case 'financeiro':
        return Colors.purple;
      case 'metas':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 🎨 WIDGET ITEM NOTIFICAÇÃO
  Widget _buildNotificacaoItem(Map<String, dynamic> notificacao) {
    final lida = (notificacao['lida'] as int) == 1;
    final importante = (notificacao['importante'] as int) == 1;
    final arquivada = (notificacao['arquivada'] as int) == 1;
    final tipo = notificacao['tipo'] as String;
    final cor = _getCorPorTipo(tipo);
    final icone = _getIconePorTipo(tipo);
    
    final dataCriacao = DateTime.parse(notificacao['data_criacao']);
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dataCriacao);
    
    return Card(
      elevation: lida ? 1 : 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icone,
            color: cor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notificacao['titulo'],
                style: TextStyle(
                  fontWeight: lida ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (importante)
              Icon(
                Icons.star,
                color: Colors.amber[600],
                size: 16,
              ),
            if (!lida)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notificacao['mensagem'],
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: lida ? FontWeight.normal : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dataFormatada,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            if (arquivada)
              Text(
                'Arquivada',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (acao) {
            switch (acao) {
              case 'marcar_lida':
                _marcarComoLida(notificacao['id']);
                break;
              case 'arquivar':
                _arquivarNotificacao(notificacao['id']);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!lida)
              const PopupMenuItem(
                value: 'marcar_lida',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 20),
                    SizedBox(width: 8),
                    Text('Marcar como lida'),
                  ],
                ),
              ),
            if (!arquivada)
              const PopupMenuItem(
                value: 'arquivar',
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 20),
                    SizedBox(width: 8),
                    Text('Arquivar'),
                  ],
                ),
              ),
          ],
        ),
        onTap: () {
          if (!lida) {
            _marcarComoLida(notificacao['id']);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        title: const Text('Notificações'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (filtro) {
              setState(() {
                switch (filtro) {
                  case 'todas':
                    _incluirLidas = true;
                    _incluirArquivadas = false;
                    break;
                  case 'nao_lidas':
                    _incluirLidas = false;
                    _incluirArquivadas = false;
                    break;
                  case 'arquivadas':
                    _incluirLidas = true;
                    _incluirArquivadas = true;
                    break;
                }
              });
              _carregarNotificacoes();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todas',
                child: Text('Todas'),
              ),
              const PopupMenuItem(
                value: 'nao_lidas',
                child: Text('Não lidas'),
              ),
              const PopupMenuItem(
                value: 'arquivadas',
                child: Text('Incluir arquivadas'),
              ),
            ],
          ),
          IconButton(
            onPressed: _carregarNotificacoes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarNotificacoes,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notificacoes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma notificação',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _notificacoes
                        .map((notificacao) => _buildNotificacaoItem(notificacao))
                        .toList(),
                  ),
      ),
    );
  }
}