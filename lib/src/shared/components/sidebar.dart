// lib/shared/components/sidebar.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/shared/theme/app_colors.dart';
import '../../modules/importacao/pages/importacao_modal.dart';
import '../../modules/transacoes/pages/transferencia_form_page.dart';
import '../../supabase_auth_service.dart';
import '../../modules/auth/pages/login_ipoupei_page.dart';

/// Sidebar lateral com navegação completa (baseada no iPoupei Device)
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header do usuário
              _buildUserHeader(context),
              const Divider(height: 1),

              // Menu principal
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Principais (5 primeiros)
                    _buildMenuItem(
                      context: context,
                      icon: Icons.dashboard_outlined,
                      label: 'Início',
                      route: '/dashboard',
                      isSelected: currentRoute == '/dashboard',
                      onTap: () => _navigateBack(context),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      label: 'Transações',
                      route: '/transacoes',
                      isSelected: currentRoute == '/transacoes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/transacoes');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_outlined,
                      label: 'Contas',
                      route: '/contas',
                      isSelected: currentRoute == '/contas',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/contas');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.credit_card_outlined,
                      label: 'Cartões',
                      route: '/cartoes',
                      isSelected: currentRoute == '/cartoes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/cartoes');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.category_outlined,
                      label: 'Categorias',
                      route: '/categorias',
                      isSelected: currentRoute == '/categorias',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/categorias');
                      },
                    ),

                    // Seção MOVIMENTAÇÕES
                    _buildSectionTitle('MOVIMENTAÇÕES'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'Receitas',
                      route: '/transacoes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/transacoes');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.remove_circle_outline,
                      label: 'Despesas',
                      route: '/transacoes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/transacoes');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.swap_horiz,
                      label: 'Transferências',
                      route: '/transferencias',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransferenciaFormPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.article_outlined,
                      label: 'Extrato de Contas',
                      route: '/contas',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/contas');
                      },
                    ),

                    // Seção ANÁLISE
                    _buildSectionTitle('ANÁLISE'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.assessment_outlined,
                      label: 'Relatórios',
                      route: '/relatorios',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/relatorios');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.analytics_outlined,
                      label: 'Diagnóstico',
                      route: '/diagnostico',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/diagnostico');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.schedule,
                      label: 'Quanto vale sua hora?',
                      route: '/valor-hora',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/valor-hora');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Planejamento',
                      route: '/planejamento',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/planejamento');
                      },
                    ),

                    // Seção GESTÃO
                    _buildSectionTitle('GESTÃO'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.upload_file,
                      label: 'Importar Transações',
                      route: '/importacao',
                      onTap: () => _handleImportacao(context),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.lightbulb_outline,
                      label: 'Categorias Sugeridas',
                      route: '/categorias-sugeridas',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/categorias-sugeridas');
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      label: 'Configurações',
                      route: '/configuracoes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/configuracoes');
                      },
                    ),

                    const SizedBox(height: 20),


                    // Botão de Logout
                    _buildMenuItem(
                      context: context,
                      icon: Icons.logout,
                      label: 'Sair',
                      route: '/logout',
                      onTap: () => _handleLogout(context),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final nome = user?.userMetadata?['nome'] ??
                 user?.userMetadata?['full_name'] ??
                 'Usuário iPoupei';
    final email = user?.email ?? 'usuario@ipoupei.com';
    final avatarUrl = user?.userMetadata?['avatar_url'] ??
                     user?.userMetadata?['picture'];

    // Obter iniciais do nome
    String getInitials(String name) {
      final parts = name.trim().split(' ');
      if (parts.isEmpty) return 'U';
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/configuracoes');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar com foto ou iniciais
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.tealTransparente20,
                borderRadius: BorderRadius.circular(14),
              ),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              getInitials(nome),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.tealPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        getInitials(nome),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealPrimary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cinzaEscuro,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cinzaTexto,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.cinzaMedio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.cinzaTexto,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    bool isSelected = false,
    bool hasLock = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealTransparente10 : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.tealPrimary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.tealPrimary : AppColors.cinzaMedio,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.tealPrimary : AppColors.cinzaEscuro,
                ),
              ),
            ),
            if (hasLock)
              const Icon(
                Icons.lock_outline,
                color: AppColors.cinzaMedio,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> _handleImportacao(BuildContext context) async {
    Navigator.pop(context); // Fecha o drawer

    try {
      final resultado = await ImportacaoModal.show(context);

      if (resultado != null && resultado['sucesso'] == true) {
        final transacoesSalvas = resultado['transacoesSalvas'] ?? 0;
        final transacoesPuladas = resultado['transacoesPuladas'] ?? 0;

        // Mostrar feedback de sucesso
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ $transacoesSalvas transação(ões) importada(s)!' +
                (transacoesPuladas > 0 ? '\n$transacoesPuladas foram puladas.' : ''),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
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

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context); // Fecha o drawer

    try {
      await SupabaseAuthService.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginIpoupeiPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}