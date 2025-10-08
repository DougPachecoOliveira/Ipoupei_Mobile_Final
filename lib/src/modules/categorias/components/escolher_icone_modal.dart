// lib/modules/categorias/components/escolher_icone_modal.dart

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../data/categoria_icons.dart';

/// Modal para seleção de ícones com suporte a tipos simples e ricos
/// 🔝 Ícones Simples (Material Icons) - Aparecem primeiro
/// 🎨 Biblioteca Rica (Emojis) - Aparecem depois
class EscolherIconeModal extends StatefulWidget {
  final String tipoCategoria; // 'receita' ou 'despesa'
  final dynamic iconeSelecionado; // Ícone atualmente selecionado

  const EscolherIconeModal({
    super.key,
    required this.tipoCategoria,
    this.iconeSelecionado,
  });

  @override
  State<EscolherIconeModal> createState() => _EscolherIconeModalState();
}

class _EscolherIconeModalState extends State<EscolherIconeModal>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  String _textoBusca = '';
  dynamic _iconeSelecionado; // Pode ser IconData ou String
  String _tipoIconeSelecionado = 'simple'; // 'simple' ou 'rich'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _iconeSelecionado = widget.iconeSelecionado;
    
    // Determinar tipo do ícone atual
    if (widget.iconeSelecionado != null) {
      // Se for uma string (nome do ícone ou emoji)
      if (widget.iconeSelecionado is String) {
        final iconeString = widget.iconeSelecionado as String;
        
        // Verificar se é emoji
        if (CategoriaIcons.isEmoji(iconeString)) {
          _iconeSelecionado = iconeString;
          _tipoIconeSelecionado = 'rich';
          _tabController.index = 1;
        } else {
          // É nome de ícone, converter para IconData
          _iconeSelecionado = CategoriaIcons.getIconFromName(iconeString);
          _tipoIconeSelecionado = 'simple';
          _tabController.index = 0;
        }
      } else if (widget.iconeSelecionado is IconData) {
        _iconeSelecionado = widget.iconeSelecionado;
        _tipoIconeSelecionado = 'simple';
        _tabController.index = 0;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  /// Obter ícones baseado no tipo de categoria e busca
  List<dynamic> _getIcons() {
    if (_tabController.index == 0) {
      // Aba Simples - Material Icons
      return _getFilteredSimpleIcons();
    } else {
      // Aba Rica - Emojis
      return _getFilteredRichIcons();
    }
  }

  List<IconData> _getFilteredSimpleIcons() {
    List<IconData> allIcons = [];
    
    if (_textoBusca.isEmpty) {
      // Sem busca - mostrar todos os ícones organizados
      if (widget.tipoCategoria == 'despesa') {
        allIcons = CategoriaIcons.getRecommendedSimpleIcons('despesa');
      } else {
        allIcons = CategoriaIcons.getRecommendedSimpleIcons('receita');
      }
      // Adicionar mais ícones de todas as categorias
      allIcons.addAll(CategoriaIcons.getAllSimpleIcons().take(500));
    } else {
      // Com busca - filtrar por nome de categoria
      final searchResults = CategoriaIcons.searchSimpleIcons(_textoBusca);
      allIcons = searchResults.map((result) => result['icon'] as IconData).toList();
      
      if (allIcons.isEmpty) {
        // Se não encontrou na busca, mostrar todos
        allIcons = CategoriaIcons.getAllSimpleIcons();
      }
    }
    
    return allIcons.take(600).toList(); // Limitar a 600 para performance
  }

  List<String> _getFilteredRichIcons() {
    List<String> allIcons = [];
    
    if (_textoBusca.isEmpty) {
      // Sem busca - mostrar todos os emojis organizados
      if (widget.tipoCategoria == 'despesa') {
        allIcons = CategoriaIcons.getRecommendedRichIcons('despesa');
      } else {
        allIcons = CategoriaIcons.getRecommendedRichIcons('receita');
      }
      // Adicionar mais emojis de todas as categorias
      allIcons.addAll(CategoriaIcons.getAllRichIcons());
    } else {
      // Com busca - filtrar por nome de categoria
      final searchResults = CategoriaIcons.searchRichIcons(_textoBusca);
      allIcons = searchResults.map((result) => result['icon'] as String).toList();
      
      if (allIcons.isEmpty) {
        // Se não encontrou na busca, mostrar todos
        allIcons = CategoriaIcons.getAllRichIcons();
      }
    }
    
    return allIcons.take(400).toList(); // Limitar a 400 emojis
  }

  /// Verificar se ícone está selecionado
  bool _isIconSelected(dynamic icon) {
    if (_iconeSelecionado == null) return false;
    
    // Comparação robusta
    if (icon is IconData && _iconeSelecionado is IconData) {
      final iconSelected = _iconeSelecionado as IconData;
      return icon.codePoint == iconSelected.codePoint &&
             icon.fontFamily == iconSelected.fontFamily;
    } else if (icon is String && _iconeSelecionado is String) {
      return icon == _iconeSelecionado;
    }
    
    return false;
  }
  
  /// Selecionar ícone
  void _selectIcon(dynamic icon) {
    setState(() {
      _iconeSelecionado = icon;
      _tipoIconeSelecionado = icon is IconData ? 'simple' : 'rich';
    });
  }

  /// Confirmar seleção
  void _confirmarSelecao() {
    if (_iconeSelecionado != null) {
      dynamic iconeParaRetornar;
      
      if (_iconeSelecionado is IconData) {
        // Para Material Icons, retornar o nome do ícone
        iconeParaRetornar = _getIconName(_iconeSelecionado as IconData);
        debugPrint('✅ Retornando nome do ícone: $iconeParaRetornar');
      } else if (_iconeSelecionado is String) {
        // Manter string (emoji)
        iconeParaRetornar = _iconeSelecionado;
        debugPrint('✅ Retornando string: $iconeParaRetornar');
      } else {
        iconeParaRetornar = '🏷️';
        debugPrint('⚠️ Retornando fallback: 🏷️');
      }
      
      Navigator.of(context).pop(iconeParaRetornar);
    }
  }

  String _getIconName(IconData iconData) {
    // Usar o método do CategoriaIcons que tem todos os 600+ ícones mapeados
    return CategoriaIcons.getNameFromIcon(iconData);
  }

  /// Cancelar seleção
  void _cancelar() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(child: _buildTabBarView()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelar,
          ),
          const SizedBox(width: 12),
          const Text(
            'Escolher Ícone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Preview do ícone selecionado
          if (_iconeSelecionado != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.tealPrimary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: _buildIconPreviewWidget(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getIconDisplayName(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.tealPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconPreviewWidget() {
    if (_iconeSelecionado == null) {
      return const Icon(Icons.help_outline, size: 20, color: AppColors.tealPrimary);
    }
    
    if (_iconeSelecionado is IconData) {
      return Icon(
        _iconeSelecionado as IconData,
        size: 20,
        color: AppColors.tealPrimary,
      );
    } else if (_iconeSelecionado is String) {
      return Text(
        _iconeSelecionado as String,
        style: const TextStyle(fontSize: 18),
      );
    }
    
    return const Icon(Icons.help_outline, size: 20, color: AppColors.tealPrimary);
  }

  String _getIconDisplayName() {
    if (_iconeSelecionado == null) return 'Nenhum';
    
    if (_iconeSelecionado is IconData) {
      return _getIconName(_iconeSelecionado as IconData);
    } else if (_iconeSelecionado is String) {
      return _iconeSelecionado as String;
    }
    
    return 'Personalizado';
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _buscaController,
        decoration: InputDecoration(
          hintText: 'Buscar ícones...',
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.tealPrimary),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _textoBusca = value;
          });
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tabController.index = 0;
                  _textoBusca = '';
                  _buscaController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _tabController.index == 0 
                      ? AppColors.tealPrimary 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _tabController.index == 0 
                        ? AppColors.tealPrimary 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.outlined_flag, 
                      size: 20,
                      color: _tabController.index == 0 
                          ? Colors.white 
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Simples',
                      style: TextStyle(
                        color: _tabController.index == 0 
                            ? Colors.white 
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tabController.index = 1;
                  _textoBusca = '';
                  _buscaController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _tabController.index == 1 
                      ? AppColors.tealPrimary 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _tabController.index == 1 
                        ? AppColors.tealPrimary 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎨',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Coloridos',
                      style: TextStyle(
                        color: _tabController.index == 1 
                            ? Colors.white 
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return IndexedStack(
      index: _tabController.index,
      children: [
        _buildSimpleIconsTab(),
        _buildRichIconsTab(),
      ],
    );
  }

  Widget _buildSimpleIconsTab() {
    final icones = _getFilteredSimpleIcons();
    final categorias = CategoriaIcons.getCategories();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_textoBusca.isEmpty) ...[
          // Mostrar por categorias quando não há busca
          for (String categoria in categorias) ...[
            _buildCategoryHeader(categoria, CategoriaIcons.getSimpleIconsByCategory(categoria).length),
            const SizedBox(height: 8),
            _buildSimpleIconGrid(CategoriaIcons.getSimpleIconsByCategory(categoria)),
            const SizedBox(height: 20),
          ],
        ] else ...[
          // Resultados da busca
          Text(
            'Resultados para "${_textoBusca}" (${icones.length} encontrados)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSimpleIconGrid(icones),
        ],
      ],
    );
  }

  Widget _buildRichIconsTab() {
    final emojis = _getFilteredRichIcons();
    final categorias = CategoriaIcons.getCategories();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_textoBusca.isEmpty) ...[
          // Mostrar por categorias quando não há busca
          for (String categoria in categorias) ...[
            _buildCategoryHeader(categoria, CategoriaIcons.getRichIconsByCategory(categoria).length),
            const SizedBox(height: 8),
            _buildRichIconGrid(CategoriaIcons.getRichIconsByCategory(categoria)),
            const SizedBox(height: 20),
          ],
        ] else ...[
          // Resultados da busca
          Text(
            'Resultados para "${_textoBusca}" (${emojis.length} encontrados)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildRichIconGrid(emojis),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(String categoria, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tealPrimary.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tealPrimary.withAlpha(78)),
          ),
          child: Text(
            categoria.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.tealPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count ícones)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleIconGrid(List<IconData> icones) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: icones.length,
      itemBuilder: (context, index) {
        final icon = icones[index];
        final isSelected = _isIconSelected(icon);
        
        return GestureDetector(
          onTap: () => _selectIcon(icon),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.tealPrimary.withAlpha(26)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppColors.tealPrimary 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 24,
                color: isSelected 
                    ? AppColors.tealPrimary 
                    : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRichIconGrid(List<String> icones) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: icones.length,
      itemBuilder: (context, index) {
        final icon = icones[index];
        final isSelected = _isIconSelected(icon);
        
        return GestureDetector(
          onTap: () => _selectIcon(icon),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.tealPrimary.withAlpha(26)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppColors.tealPrimary 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelar,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _iconeSelecionado != null ? _confirmarSelecao : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}