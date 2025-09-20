// 🧭 Main Navigation - iPoupei Mobile
// 
// Sistema de navegação principal com bottom navigation
// Facilita teste de todas as funcionalidades
// 
// Baseado em: Bottom Navigation Pattern

import 'package:flutter/material.dart';
import '../modules/contas/pages/contas_page.dart';
import '../modules/categorias/pages/categorias_page.dart';
import '../modules/transacoes/pages/transacoes_page.dart';
import '../modules/relatorios/pages/relatorios_page.dart';
import '../modules/cartoes/pages/cartoes_consolidado_page.dart';
import '../shared/components/ui/sync_status_indicator.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const ContasPage(),
    const CartoesConsolidadoPage(),
    const RelatoriosPage(),
    const CategoriasPage(),
    const TransacoesPage(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Indicador de sync no topo direito
          const Positioned(
            top: 40,
            right: 10,
            child: SyncStatusIndicator(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
      ),
    );
  }
}