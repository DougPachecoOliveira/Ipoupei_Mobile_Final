// 🏠 Home Page - iPoupei Mobile
// 
// Tela principal com resumo financeiro
// Integra com dados offline/online
// 
// Baseado em: Material Design + Dashboard Pattern

import 'package:flutter/material.dart';
import '../../../supabase_auth_service.dart';
import '../../../auth_integration.dart';
import '../../../sync/sync_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthUser? _currentUser;
  SyncStatus _syncStatus = SyncStatus.idle;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupListeners();
  }
  
  /// 📊 CARREGA DADOS DO USUÁRIO
  void _loadUserData() {
    _currentUser = authIntegration.authService.currentUser;
    _syncStatus = syncManager.status;
  }
  
  /// 👂 CONFIGURA LISTENERS
  void _setupListeners() {
    // Escuta mudanças do usuário
    authIntegration.authService.userStream.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
      
      // Se usuário deslogou, volta para login
      if (user == null && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
    
    // Escuta status de sincronização
    syncManager.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
      }
    });
  }
  
  /// 🚪 REALIZA LOGOUT
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true) {
      try {
        await authIntegration.authService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao sair: $e')),
          );
        }
      }
    }
  }
  
  /// 🎨 WIDGET DE STATUS DE SYNC
  Widget _buildSyncStatus() {
    IconData icon;
    Color color;
    String text;
    
    switch (_syncStatus) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        text = 'Sincronizando...';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        color = Colors.orange;
        text = 'Offline';
        break;
      case SyncStatus.error:
        icon = Icons.error_outline;
        color = Colors.red;
        text = 'Erro de sync';
        break;
      default:
        icon = Icons.cloud_done;
        color = Colors.green;
        text = 'Sincronizado';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
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
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'iPoupei',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (_currentUser != null)
              Text(
                'Olá, ${_currentUser!.nome ?? _currentUser!.email}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          _buildSyncStatus(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de boas-vindas
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bem-vindo ao iPoupei Mobile! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seu controle financeiro agora funciona offline!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[300],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sincronização com Supabase configurada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[300],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Funcionamento offline garantido',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resumo financeiro (placeholder)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo Financeiro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Placeholders para quando implementar o dashboard real
                    _buildSummaryItem(
                      'Saldo Total',
                      'R\$ 0,00',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryItem(
                      'Receitas do Mês',
                      'R\$ 0,00',
                      Icons.trending_up,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryItem(
                      'Despesas do Mês',
                      'R\$ 0,00',
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Ações rápidas
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    'Adicionar\nReceita',
                    Icons.add_circle,
                    Colors.green,
                    () {
                      // TODO: Navegar para adicionar receita
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    'Adicionar\nDespesa',
                    Icons.remove_circle,
                    Colors.red,
                    () {
                      // TODO: Navegar para adicionar despesa
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    'Minhas\nContas',
                    Icons.account_balance,
                    Colors.blue,
                    () {
                      Navigator.of(context).pushNamed('/contas');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    'Ver\nRelatórios',
                    Icons.bar_chart,
                    Colors.purple,
                    () {
                      // TODO: Navegar para relatórios
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}