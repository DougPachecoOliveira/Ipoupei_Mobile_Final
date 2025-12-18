// 🧭 App Bottom Navigation - iPoupei Mobile
//
// Componente reutilizável da barra de navegação inferior
// Para uso consistente em todas as páginas que precisam do navigation bar

import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNavigation({
    super.key,
    this.currentIndex = -1, // -1 indica que não está em uma das principais páginas
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex >= 0 && currentIndex < 5 ? currentIndex : 0,
      onTap: onTap ?? _defaultOnTap,
      selectedItemColor: Colors.blue[600],
      unselectedItemColor: Colors.grey[600],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance),
          label: 'Contas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card),
          label: 'Cartões',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Relatórios',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categorias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Transações',
        ),
      ],
    );
  }

  void _defaultOnTap(int index) {
    // Implementação padrão: não faz nada
    // As páginas específicas podem sobrescrever este comportamento
  }
}