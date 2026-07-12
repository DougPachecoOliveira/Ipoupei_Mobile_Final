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
import '../shared/services/navigation_context_service.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 2}); // Inicia em Relatórios

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // 🧭 Escuta mudanças no contexto de navegação para atualizar filtros
    navigationContext.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    navigationContext.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) {
      // ✅ Usar addPostFrameCallback para evitar setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Força rebuild para aplicar novos filtros
          });
        }
      });
    }
  }

  List<Widget> get _pages {
    final filtros = navigationContext.hasContextoAtivo
        ? navigationContext.getFiltrosParaTransacoes()
        : null;

    // 🧭 Determinar modo inicial baseado no contexto
    final modoInicial = navigationContext.deveUsarModoContextual
        ? TransacoesPageMode.cartoes
        : navigationContext.deveUsarModoReceitas
            ? TransacoesPageMode.receitas
            : navigationContext.deveUsarModoDespesas
                ? TransacoesPageMode.despesas
                : TransacoesPageMode.todas;

    debugPrint('🧭 MainNavigation: Contexto ativo: ${navigationContext.hasContextoAtivo}');
    debugPrint('🧭 MainNavigation: Modo contextual cartões: ${navigationContext.deveUsarModoContextual}');
    debugPrint('🧭 MainNavigation: Modo receitas: ${navigationContext.deveUsarModoReceitas}');
    debugPrint('🧭 MainNavigation: Modo despesas: ${navigationContext.deveUsarModoDespesas}');
    debugPrint('🧭 MainNavigation: Modo inicial: $modoInicial');
    debugPrint('🧭 MainNavigation: Filtros gerados: $filtros');

    return [
      const ContasPage(),
      const CartoesConsolidadoPage(),
      const RelatoriosPage(),
      const CategoriasPage(),
      TransacoesPage(
        modoInicial: modoInicial,
        filtrosIniciais: filtros,
        showNavigationBar: false,
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 2, // Só permite sair do app se estiver na aba Relatórios
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 2) {
          // Se tentou sair mas não está em Relatórios, navega para Relatórios
          setState(() {
            _currentIndex = 2;
          });

          // Feedback visual opcional
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pressione voltar novamente para sair'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            // Indicador de sync no topo direito
            const Positioned(
              top: 4,
              right: 8,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
