// 📂 Categorias Page - iPoupei Mobile
// 
// Página principal para gestão de categorias e subcategorias
// Engine offline-sync baseada nos padrões de gestão de cartão
// Versão com dados mockados para teste
// 
// Baseado em: Material Design + Category Management + Offline-First

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria_model.dart';
import '../data/categoria_icons.dart';
import '../services/categoria_service.dart';
import '../../transacoes/services/transacao_service.dart';
import '../../../database/local_database.dart';
import '../../../shared/utils/format_currency.dart';
import '../../../sync/sync_manager.dart';
import '../components/criar_categoria_modal.dart';
import '../components/criar_subcategoria_modal.dart';
import '../components/migrar_categoria_modal.dart';
import '../components/excluir_categoria_modal.dart';
import 'categoria_form_page.dart';
import 'subcategoria_form_page.dart';
import 'categorias_sugeridas_page.dart';
import 'gestao_categoria_page.dart';
import '../../shared/theme/app_colors.dart';


// ===============================================
// 🔧 COMPONENTES UI - SUBSTITUINDO IMPORTS
// ===============================================
class LoadingWidget extends StatelessWidget {
  final String message;
  
  const LoadingWidget({
    super.key,
    this.message = 'Carregando...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  
  const AppErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }
}

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}



// ===============================================  
// 📊 DADOS REAIS CARREGADOS DO BANCO
// ===============================================

class _CategoriasPageState extends State<CategoriasPage> with TickerProviderStateMixin {
  final CategoriaService _categoriaService = CategoriaService.instance;
  final TransacaoService _transacaoService = TransacaoService.instance;
  final LocalDatabase _localDatabase = LocalDatabase.instance;
  
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  // Estados principais - seguindo padrão do CartaoDataService
  List<CategoriaModel> _receitas = [];
  List<CategoriaModel> _despesas = [];
  List<SubcategoriaModel> _subcategorias = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  
  // Estados para dados financeiros reais
  Map<String, double> _valoresPorCategoria = {}; // categoria_id -> valor
  double _totalReceitas = 0.0;
  double _totalDespesas = 0.0;
  double _totalPago = 0.0; // Total efetivado de despesas no período
  double _totalRecebido = 0.0; // Total efetivado de receitas no período
  bool _carregandoValores = false; // Race condition protection
  
  // Estados visuais - baseados no projeto antigo
  DateTime _dataAtual = DateTime.now();
  String _periodoAtual = '';
  bool _modoAnual = false; // false = mensal, true = anual
  Color _headerColor = AppColors.vermelhoHeader;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _atualizarPeriodoTexto();
    
    // Listener para mudança de cores baseado na tab - igual ao projeto antigo
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _headerColor = _getHeaderColor();
        });
      }
    });
    
    _headerColor = _getHeaderColor();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ===============================================
  // 🎨 MÉTODOS DE UI - BASEADOS NO PROJETO ANTIGO
  // ===============================================

  Color _getHeaderColor() {
    switch (_tabController.index) {
      case 0: // Despesas
        return AppColors.vermelhoHeader;
      case 1: // Receitas  
        return AppColors.tealPrimary;
      default:
        return AppColors.vermelhoHeader;
    }
  }

  Color _getBackgroundColor() {
    switch (_tabController.index) {
      case 0: // Despesas
        return AppColors.vermelhoHeader.withAlpha(26);
      case 1: // Receitas
        return AppColors.tealPrimary.withAlpha(26);
      default:
        return AppColors.vermelhoHeader.withAlpha(26);
    }
  }

  Color _getPeriodBackgroundColor() {
    switch (_tabController.index) {
      case 0: // Despesas
        return AppColors.vermelhoHeader.withAlpha(52);
      case 1: // Receitas
        return AppColors.tealPrimary.withAlpha(52);
      default:
        return AppColors.vermelhoHeader.withAlpha(52);
    }
  }

  void _atualizarPeriodoTexto() {
    setState(() {
      if (_modoAnual) {
        // Modo anual: mostra apenas o ano
        _periodoAtual = _dataAtual.year.toString();
      } else {
        // Modo mensal: mostra mês/ano
        final meses = [
          'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
          'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
        ];
        _periodoAtual = '${meses[_dataAtual.month - 1]}/${_dataAtual.year.toString().substring(2)}';
      }
    });
  }

  void _periodoAnterior() {
    setState(() {
      if (_modoAnual) {
        // Navegar por anos
        _dataAtual = DateTime(_dataAtual.year - 1, _dataAtual.month);
      } else {
        // Navegar por meses
        _dataAtual = DateTime(_dataAtual.year, _dataAtual.month - 1);
      }
      _atualizarPeriodoTexto();
    });
    // Recarregar valores do novo período
    _carregarCategorias();
  }

  void _proximoPeriodo() {
    setState(() {
      if (_modoAnual) {
        // Navegar por anos
        _dataAtual = DateTime(_dataAtual.year + 1, _dataAtual.month);
      } else {
        // Navegar por meses
        _dataAtual = DateTime(_dataAtual.year, _dataAtual.month + 1);
      }
      _atualizarPeriodoTexto();
    });
    // Recarregar valores do novo período
    _carregarCategorias();
  }

  /// 🔄 ALTERNAR ENTRE MODO MENSAL E ANUAL
  void _alternarModo() {
    setState(() {
      _modoAnual = !_modoAnual;
      _atualizarPeriodoTexto();
    });
    // Recarregar dados com novo período
    _carregarCategorias();
  }

  // ===============================================
  // 🔄 ENGINE OFFLINE-SYNC - BASEADA NO CARTÃO
  // ===============================================

  /// 🔄 CARREGAR CATEGORIAS (seguindo padrão da contas page)
  Future<void> _carregarCategorias() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      // 📡 SYNC: Atualizar categorias do Supabase
      try {
        final syncManager = SyncManager.instance;
        await syncManager.syncCategorias();
      } catch (syncError) {
        debugPrint('⚠️ Erro no sync de categorias: $syncError');
        // Continua mesmo com erro no sync (offline-first)
      }
      
      // 🏠 USAR LocalDatabase (OFFLINE-FIRST) - DADOS REAIS DO SQLITE
      debugPrint('🔄 CategoriasPage: Carregando categorias do SQLite...');
      final categoriasData = await _localDatabase.fetchCategoriasLocal();
      final subcategoriasData = await _localDatabase.fetchSubcategoriasLocal();
      
      debugPrint('✅ CategoriasPage: SQLite retornou ${categoriasData.length} categorias');
      
      // Converter para modelos
      final categorias = categoriasData.map((data) => CategoriaModel.fromJson(data)).toList();
      final subcategorias = subcategoriasData.map((data) => SubcategoriaModel.fromJson(data)).toList();
      
      debugPrint('✅ CategoriasPage: Convertido para ${categorias.length} modelos');
      
      // Buscar valores das transações do período atual
      await _carregarValoresTransacoes();
      
      setState(() {
        _receitas = categorias.where((c) => c.tipo == 'receita').toList();
        _despesas = categorias.where((c) => c.tipo == 'despesa').toList();
        _subcategorias = subcategorias;
        _loading = false;
      });
      
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar categorias: $e';
        _loading = false;
      });
    }
  }

  /// 🔄 REFRESH PULL-TO-REFRESH (seguindo padrão da contas page)
  Future<void> _onRefresh() async {
    await _carregarCategorias();
  }

  /// Filtrar categorias por pesquisa
  List<CategoriaModel> _filtrarCategorias(List<CategoriaModel> categorias) {
    if (_searchQuery.isEmpty) return categorias;
    
    return categorias.where((categoria) {
      return categoria.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (categoria.descricao?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  // ===============================================
  // 🎬 AÇÕES DE NAVEGAÇÃO
  // ===============================================

  void _novaCategoria() async {
    final tipoAtual = _tabController.index == 0 ? 'despesa' : 'receita';
    
    final categoria = await showModalBottomSheet<CategoriaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CriarCategoriaModal(
        tipo: tipoAtual,
        onCategoriaCriada: (categoria) {
          debugPrint('✅ Nova categoria criada: ${categoria.nome}');
        },
      ),
    );
    
    if (categoria != null && mounted) {
      await _carregarCategorias();
    }
  }

  void _editarCategoria(CategoriaModel categoria) async {
    final categoriaAtualizada = await showModalBottomSheet<CategoriaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CriarCategoriaModal(
        tipo: categoria.tipo,
        categoriaParaEditar: categoria,
        onCategoriaCriada: (categoriaEditada) {
          debugPrint('✅ Categoria editada: ${categoriaEditada.nome}');
        },
      ),
    );
    
    if (categoriaAtualizada != null && mounted) {
      await _carregarCategorias();
    }
  }

  void _novaSubcategoria(CategoriaModel categoria) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CriarSubcategoriaModal(
        categoria: categoria,
        onSubcategoriaCriada: (subcategoria) {
          debugPrint('✅ Nova subcategoria criada: ${subcategoria['nome']}');
        },
      ),
    );
    
    if (result != null && mounted) {
      await _carregarCategorias();
      _showSuccessSnackBar('Subcategoria criada com sucesso!');
    }
  }

  void _abrirCategoriasSugeridas() async {
    try {
      final result = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(
          builder: (context) => const CategoriasSugeridasPage(),
        ),
      );

      if (result == true && mounted) {
        // Forçar limpeza de cache do serviço antes de recarregar
        _categoriaService.limparCache();

        await _carregarCategorias();
        _showSuccessSnackBar('Categorias importadas com sucesso!');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao abrir categorias sugeridas: $e');
    }
  }

  void _navegarParaGestaoCategoria(CategoriaModel categoria) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestaoCategoriaPage(categoria: categoria),
      ),
    );
    
    // Recarregar dados se houve migração ou exclusão
    if (result != null && result['migrationOccurred'] == true && mounted) {
      
      // Forçar limpeza de cache do serviço antes de recarregar
      _categoriaService.limparCache();
      
      await _carregarCategorias();
    }
  }

  // ===============================================
  // 🚨 AÇÕES DE EXCLUSÃO
  // ===============================================

  Future<void> _excluirCategoria(CategoriaModel categoria) async {
    try {
      // Carregar todas as categorias para possível migração
      final todasCategorias = [..._receitas, ..._despesas];
      
      final resultado = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ExcluirCategoriaModal(
            categoria: categoria,
            todasCategorias: todasCategorias,
          ),
        ),
      );
      
      if (resultado != null && resultado['success']) {
        
        // Forçar limpeza de cache do serviço antes de recarregar
        _categoriaService.limparCache();
        
        await _carregarCategorias();
        _showSuccessSnackBar(resultado['message'] ?? 'Categoria excluída com sucesso!');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao abrir exclusão: $e');
    }
  }

  // ===============================================
  // 🔄 AÇÕES DE MIGRAÇÃO
  // ===============================================

  Future<void> _migrarCategoria(CategoriaModel categoria) async {
    try {
      // Verificar se tem dependências primeiro
      final dependencias = await _categoriaService.verificarDependenciasCategoria(categoria.id);
      
      if (!dependencias['success'] || !dependencias['temDependencias']) {
        _showErrorSnackBar('Esta categoria não possui dados para migrar.');
        return;
      }
      
      // Carregar todas as categorias para migração
      final todasCategorias = [..._receitas, ..._despesas];
      
      final resultado = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: MigrarCategoriaModal(
            categoriaOrigem: categoria,
            qtdTransacoes: dependencias['qtdTransacoes'] ?? 0,
            qtdSubcategorias: dependencias['qtdSubcategorias'] ?? 0,
            categoriasDisponiveis: todasCategorias,
          ),
        ),
      );
      
      if (resultado != null && resultado['success']) {
        print('🔄 DEBUG: Recarregando categorias após migração...');
        
        // Forçar limpeza de cache do serviço antes de recarregar
        _categoriaService.limparCache();
        
        await _carregarCategorias();
        _showSuccessSnackBar(resultado['message'] ?? 'Migração realizada com sucesso!');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao abrir migração: $e');
    }
  }

  // ===============================================
  // 🔧 UTILITÁRIOS
  // ===============================================

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.tealEscuro,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  // ===============================================
  // 🎨 BUILD METHODS
  // ===============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Gerenciar Categorias',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _carregarCategorias(),
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _novaCategoria,
            tooltip: 'Nova Categoria',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            color: _headerColor,
            child: Column(
              children: [
                // Seletor de período
                _buildSeletorPeriodo(),
                
                // Tabs Despesas/Receitas
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  color: _getBackgroundColor(),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_down, size: 18),
                            SizedBox(width: 8),
                            Text('Despesas'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up, size: 18),
                            SizedBox(width: 8),
                            Text('Receitas'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSeletorPeriodo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ Período navegável (lado esquerdo)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                onPressed: _periodoAnterior,
              ),
              GestureDetector(
                onTap: _alternarModo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _periodoAtual,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_modoAnual) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.date_range,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                onPressed: _proximoPeriodo,
              ),
            ],
          ),

          // ✅ Total efetivado (lado direito)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total do Período',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatarValor(_getTotalPeriodo()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Carregando categorias...'),
      );
    }

    if (_error != null) {
      return Center(
        child: AppErrorWidget(
          title: 'Erro ao carregar categorias',
          message: _error!,
          onRetry: () => _carregarCategorias(),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildListaCategorias(_filtrarCategorias(_despesas), 'despesa'),
        _buildListaCategorias(_filtrarCategorias(_receitas), 'receita'),
      ],
    );
  }

  Widget _buildListaCategorias(List<CategoriaModel> categorias, String tipo) {
    if (categorias.isEmpty) {
      return _buildEstadoVazio(tipo);
    }

    // Total de categorias (receitas + despesas)
    final totalCategorias = _receitas.length + _despesas.length;
    final mostrarBanner = totalCategorias < 5; // Só mostra se tem menos de 5

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categorias.length + (mostrarBanner ? 1 : 0), // +1 só se tem banner
        itemBuilder: (context, index) {
          // Último item: banner de sugestões (só se totalCategorias < 5)
          if (mostrarBanner && index == categorias.length) {
            return _buildSugestionBanner();
          }
          
          final categoria = categorias[index];
          return _buildCategoriaCard(categoria);
        },
      ),
    );
  }

  Widget _buildCategoriaCard(CategoriaModel categoria) {
    final subcategorias = _subcategorias
        .where((sub) => sub.categoriaId == categoria.id)
        .toList();
    
    // DEBUG: Log para verificar ícone
    debugPrint('🔍 Categoria: ${categoria.nome}, Ícone DB: "${categoria.icone}"');
    final bool isEmoji = CategoriaIcons.isEmoji(categoria.icone);
    final Color corCategoria = _parseColor(categoria.cor);
    
    // Valores reais das transações do mês atual
    final valorMes = _getValorRealCategoria(categoria);
    final porcentagem = _getPorcentagemRealCategoria(categoria, valorMes);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: () => _navegarParaGestaoCategoria(categoria),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: corCategoria, // Sempre usar cor de fundo
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: isEmoji 
                ? Text(
                    categoria.icone,
                    style: const TextStyle(fontSize: 20),
                  )
                : Icon(
                    CategoriaIcons.getIconFromName(categoria.icone),
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ),
        title: Text(
          categoria.nome,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${porcentagem.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCurrency(valorMes),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: categoria.tipo == 'receita' 
                    ? const Color(0xFF14B8A6) // Teal para receitas
                    : const Color(0xFFEF4444), // Vermelho para despesas
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'gestao':
                    _navegarParaGestaoCategoria(categoria);
                    break;
                  case 'edit':
                    _editarCategoria(categoria);
                    break;
                  case 'subcategoria':
                    _novaSubcategoria(categoria);
                    break;
                  case 'migrar':
                    _migrarCategoria(categoria);
                    break;
                  case 'delete':
                    _excluirCategoria(categoria);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'gestao',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard, color: AppColors.tealPrimary),
                      SizedBox(width: 8),
                      Text('Gestão'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'subcategoria',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Nova subcategoria'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'migrar',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: AppColors.tealPrimary),
                      SizedBox(width: 8),
                      Text('Migrar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
          ),
          // Linha divisória cinza clara que começa após o ícone (como no arquivo offline)
          Container(
            margin: const EdgeInsets.only(left: 72), // 16 (padding) + 40 (ícone) + 16 (gap)
            height: 0.5,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVazio(String tipo) {
    final emoji = tipo == 'despesa' ? '💸' : '💰';
    final tipoTexto = tipo == 'despesa' ? 'despesas' : 'receitas';
    final corBotao = tipo == 'despesa' ? AppColors.vermelhoHeader : AppColors.tealPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Nenhuma categoria de $tipoTexto',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Organize suas finanças criando\ncategorias personalizadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Botão principal - Importar Categorias Sugeridas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _abrirCategoriasSugeridas,
                icon: const Icon(Icons.download),
                label: const Text('Importar Categorias Essenciais'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Botão secundário - Criar manualmente
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _novaCategoria,
                icon: const Icon(Icons.add),
                label: Text('Criar categoria de $tipoTexto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: corBotao,
                  side: BorderSide(color: corBotao),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSugestionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quer mais categorias?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Veja nossa lista de sugestões',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _abrirCategoriasSugeridas,
            child: const Text('Ver sugestões'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFAB() {
    return FloatingActionButton(
      onPressed: _novaCategoria,
      backgroundColor: _headerColor,
      heroTag: 'categorias_fab',
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // ===============================================
  // 🔧 UTILITÁRIOS AUXILIARES
  // ===============================================

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  /// 🚀 MÉTODO OTIMIZADO BASEADO NO PADRÃO DO CONTAS (PERFORMANCE MÁXIMA!)
  Future<void> _carregarValoresTransacoes() async {
    
    if (_carregandoValores) return;
    _carregandoValores = true;
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _carregandoValores = false;
        return;
      }

      // Calcular período baseado na data atual e modo
      DateTime dataInicio, dataFim;
      if (_modoAnual) {
        dataInicio = DateTime(_dataAtual.year, 1, 1);
        dataFim = DateTime(_dataAtual.year, 12, 31);
      } else {
        dataInicio = DateTime(_dataAtual.year, _dataAtual.month, 1);
        dataFim = DateTime(_dataAtual.year, _dataAtual.month + 1, 0);
      }

      // Limpar dados anteriores
      _valoresPorCategoria.clear();
      _totalReceitas = 0.0;
      _totalDespesas = 0.0;
      _totalPago = 0.0;
      _totalRecebido = 0.0;

      debugPrint('🚀 Período otimizado: ${dataInicio.day}/${dataInicio.month}/${dataInicio.year} até ${dataFim.day}/${dataFim.month}/${dataFim.year}');
      
      // 🚀 USAR NOVO MÉTODO OTIMIZADO - Uma única query com JOIN no servidor/SQLite
      final categoriasComValores = await _categoriaService.fetchCategoriasComValoresCache(
        dataInicio: dataInicio,
        dataFim: dataFim,
        forceRefresh: false, // Usa cache quando possível
      );
      
      debugPrint('⚡ ${categoriasComValores.length} categorias com valores pré-calculados!');
      
      // Processar dados pré-calculados (muito mais rápido que N+1 queries!)
      for (final item in categoriasComValores) {
        final categoriaId = item['id'] as String;
        final valorTotal = (item['valor_total'] as num?)?.toDouble() ?? 0.0;
        final tipo = item['tipo'] as String?;
        
        if (valorTotal > 0) {
          _valoresPorCategoria[categoriaId] = valorTotal;

          if (tipo == 'receita') {
            _totalReceitas += valorTotal;
            _totalRecebido += valorTotal; // Por enquanto, assumindo que receitas são efetivadas
          } else {
            _totalDespesas += valorTotal;
            _totalPago += valorTotal; // Por enquanto, assumindo que despesas são efetivadas
          }
        }
      }
      
      debugPrint('💰 Totais otimizados - Receitas: R\$ $_totalReceitas, Despesas: R\$ $_totalDespesas');
      debugPrint('💳 Totais efetivados - Recebido: R\$ $_totalRecebido, Pago: R\$ $_totalPago');
      
    } catch (e) {
      debugPrint('❌ Erro no método otimizado, usando fallback: $e');
      // Fallback para método original se otimizado falhar
      await _carregarValoresTransacoesFallback();
    } finally {
      _carregandoValores = false;
    }
  }

  /// 💰 FALLBACK: MÉTODO ORIGINAL (APENAS SE OTIMIZADO FALHAR)
  Future<void> _carregarValoresTransacoesFallback() async {
    debugPrint('⚠️ Usando fallback do método original...');
    
    try {
      DateTime dataInicio, dataFim;
      if (_modoAnual) {
        dataInicio = DateTime(_dataAtual.year, 1, 1);
        dataFim = DateTime(_dataAtual.year, 12, 31);
      } else {
        dataInicio = DateTime(_dataAtual.year, _dataAtual.month, 1);
        dataFim = DateTime(_dataAtual.year, _dataAtual.month + 1, 0);
      }
      
      final todasTransacoes = await _transacaoService.fetchTransacoes(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      final Map<String, String> categoriaMap = {};
      for (final categoria in [..._receitas, ..._despesas]) {
        categoriaMap[categoria.id] = categoria.tipo;
      }
      
      for (final transacao in todasTransacoes) {
        if (transacao.efetivado && transacao.categoriaId != null) {
          final categoriaId = transacao.categoriaId!;
          final tipoCategoria = categoriaMap[categoriaId];
          
          if (tipoCategoria != null) {
            _valoresPorCategoria[categoriaId] = 
                (_valoresPorCategoria[categoriaId] ?? 0.0) + transacao.valor;
            
            if (tipoCategoria == 'receita') {
              _totalReceitas += transacao.valor;
            } else {
              _totalDespesas += transacao.valor;
            }
          }
        }
      }
      
    } catch (e) {
      debugPrint('❌ Erro no fallback: $e');
      _valoresPorCategoria.clear();
      _totalReceitas = 0.0;
      _totalDespesas = 0.0;
    }
  }


  /// 💰 OBTER VALOR REAL DA CATEGORIA
  double _getValorRealCategoria(CategoriaModel categoria) {
    return _valoresPorCategoria[categoria.id] ?? 0.0;
  }

  /// 📊 CALCULAR PORCENTAGEM REAL DA CATEGORIA
  double _getPorcentagemRealCategoria(CategoriaModel categoria, double valor) {
    if (valor == 0) return 0.0;
    
    // Usar total correto baseado no tipo da categoria
    final total = categoria.tipo == 'receita' ? _totalReceitas : _totalDespesas;
    
    if (total == 0) return 0.0;
    
    return (valor / total) * 100.0;
  }

  void _toggleSearch() {
    // 🛡️ IMPLEMENTAÇÃO DE BUSCA FUNCIONAL
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Categoria'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Digite o nome da categoria...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              // A busca será aplicada automaticamente através de _filtrarCategorias
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Formatar valor monetário
  String _formatarValor(double valor) {
    return formatCurrency(valor);
  }

  /// Obter total do período baseado na aba atual
  double _getTotalPeriodo() {
    if (_tabController.index == 0) {
      return _totalPago; // Aba Despesas
    } else {
      return _totalRecebido; // Aba Receitas
    }
  }
}