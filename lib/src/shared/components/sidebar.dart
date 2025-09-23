// lib/shared/components/sidebar.dart

import 'package:flutter/material.dart';
import '../../modules/shared/theme/app_colors.dart';

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
                      onTap: () => _showInDevelopment(context, 'Transações'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_outlined,
                      label: 'Contas',
                      route: '/contas',
                      isSelected: currentRoute == '/contas',
                      onTap: () => _showInDevelopment(context, 'Contas'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.credit_card_outlined,
                      label: 'Cartões',
                      route: '/cartoes',
                      isSelected: currentRoute == '/cartoes',
                      onTap: () => _showInDevelopment(context, 'Cartões'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.category_outlined,
                      label: 'Categorias',
                      route: '/categorias',
                      isSelected: currentRoute == '/categorias',
                      onTap: () => _showInDevelopment(context, 'Categorias'),
                    ),

                    // Seção MOVIMENTAÇÕES
                    _buildSectionTitle('MOVIMENTAÇÕES'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'Receitas',
                      route: '/receitas',
                      onTap: () => _showInDevelopment(context, 'Receitas'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.remove_circle_outline,
                      label: 'Despesas',
                      route: '/despesas',
                      onTap: () => _showInDevelopment(context, 'Despesas'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.swap_horiz,
                      label: 'Transferências',
                      route: '/transferencias',
                      onTap: () => _showInDevelopment(context, 'Transferências'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.article_outlined,
                      label: 'Extrato de Contas',
                      route: '/extrato',
                      onTap: () => _showInDevelopment(context, 'Extrato de Contas'),
                    ),

                    // Seção ANÁLISE
                    _buildSectionTitle('ANÁLISE'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.assessment_outlined,
                      label: 'Relatórios',
                      route: '/relatorios',
                      isSelected: true, // Página atual
                      onTap: () => _navigateBack(context),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.analytics_outlined,
                      label: 'Diagnóstico',
                      route: '/diagnostico',
                      onTap: () => _showInDevelopment(context, 'Diagnóstico'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.schedule,
                      label: 'Quanto vale sua hora?',
                      route: '/valor-hora',
                      onTap: () => _showInDevelopment(context, 'Quanto vale sua hora?'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.show_chart,
                      label: 'Evolução Temporal',
                      route: '/evolucao',
                      onTap: () => _showInDevelopment(context, 'Evolução Temporal'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.timeline,
                      label: 'Projeções',
                      route: '/projecoes',
                      onTap: () => _showInDevelopment(context, 'Projeções'),
                    ),

                    // Seção GESTÃO
                    _buildSectionTitle('GESTÃO'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.lightbulb_outline,
                      label: 'Categorias Sugeridas',
                      route: '/categorias-sugeridas',
                      onTap: () => _showInDevelopment(context, 'Categorias Sugeridas'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.archive_outlined,
                      label: 'Contas Arquivadas',
                      route: '/contas-arquivadas',
                      onTap: () => _showInDevelopment(context, 'Contas Arquivadas'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      label: 'Configurações',
                      route: '/configuracoes',
                      onTap: () => _showInDevelopment(context, 'Configurações'),
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cinzaMedio,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuário iPoupei',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'usuario@ipoupei.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaTexto,
                  ),
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

  void _showInDevelopment(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Em desenvolvimento'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}