// 🎨 Categorias Sugeridas Page - iPoupei Mobile MODERNA
//
// Design inspirado no offline com cards modernos
// Seleção hierárquica de categorias e subcategorias
//
// Visual: Cards com sombras + Chips de subcategorias

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../data/categorias_sugeridas.dart';
import '../services/categoria_service.dart';

/// Página moderna para seleção de categorias sugeridas
class CategoriasSugeridasPage extends StatefulWidget {
  const CategoriasSugeridasPage({super.key});

  @override
  State<CategoriasSugeridasPage> createState() => _CategoriasSugeridasPageState();
}

class _CategoriasSugeridasPageState extends State<CategoriasSugeridasPage> {
  List<CategoriaComSubcategorias> _categorias = [];
  bool _loading = true;
  bool _importing = false;
  int _totalCategoriasSelecionadas = 0;
  int _totalSubcategoriasSelecionadas = 0;

  @override
  void initState() {
    super.initState();
    _carregarCategoriasSugeridas();
  }

  Future<void> _carregarCategoriasSugeridas() async {
    setState(() => _loading = true);

    try {
      // Buscar categorias existentes do banco de dados
      final categoriasExistentes = await _buscarCategoriasExistentes();

      // Criar lista de categorias sugeridas
      _categorias = _obterTodasCategoriasSugeridas(categoriasExistentes);
      _atualizarContadores();

    } catch (error) {
      debugPrint('❌ Erro ao carregar categorias sugeridas: $error');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Busca categorias existentes do banco de dados
  Future<Set<String>> _buscarCategoriasExistentes() async {
    try {
      final categoriasExistentes = <String>{};

      debugPrint('🔍 Iniciando busca de categorias existentes...');

      // Buscar categorias principais (receitas e despesas)
      debugPrint('🔍 Buscando categorias de receita...');
      final categoriasReceitas = await CategoriaService.instance.fetchCategorias(tipo: 'receita');
      debugPrint('🔍 Encontradas ${categoriasReceitas.length} categorias de receita');

      debugPrint('🔍 Buscando categorias de despesa...');
      final categoriasDespesas = await CategoriaService.instance.fetchCategorias(tipo: 'despesa');
      debugPrint('🔍 Encontradas ${categoriasDespesas.length} categorias de despesa');

      // Adicionar nomes das categorias principais ao conjunto
      for (final cat in categoriasReceitas) {
        final nome = cat.nome.toLowerCase();
        categoriasExistentes.add(nome);
        debugPrint('✅ Receita adicionada: $nome');
      }
      for (final cat in categoriasDespesas) {
        final nome = cat.nome.toLowerCase();
        categoriasExistentes.add(nome);
        debugPrint('✅ Despesa adicionada: $nome');
      }

      // Buscar subcategorias também
      debugPrint('🔍 Buscando subcategorias...');
      for (final cat in [...categoriasReceitas, ...categoriasDespesas]) {
        try {
          final subcategorias = await CategoriaService.instance.fetchSubcategorias(categoriaId: cat.id);
          debugPrint('🔍 Categoria ${cat.nome}: ${subcategorias.length} subcategorias');
          for (final sub in subcategorias) {
            final chaveSubcat = '${cat.nome.toLowerCase()}_${sub.nome.toLowerCase()}';
            categoriasExistentes.add(chaveSubcat);
            debugPrint('✅ Subcategoria adicionada: $chaveSubcat');
          }
        } catch (e) {
          debugPrint('⚠️ Erro ao buscar subcategorias de ${cat.nome}: $e');
        }
      }

      debugPrint('📋 Total de categorias existentes encontradas: ${categoriasExistentes.length}');
      debugPrint('📋 Lista completa: ${categoriasExistentes.toList()}');

      return categoriasExistentes;
    } catch (e) {
      debugPrint('❌ Erro ao buscar categorias existentes: $e');
      return <String>{}; // Retorna conjunto vazio em caso de erro
    }
  }

  List<CategoriaComSubcategorias> _obterTodasCategoriasSugeridas(Set<String> nomesExistentes) {
    final categorias = <CategoriaComSubcategorias>[];

    // Adicionar RECEITAS
    for (final catData in CategoriasSugeridasService.receitas) {
      categorias.add(_criarCategoriaComSubcategorias(catData, 'receita', nomesExistentes));
    }

    // Adicionar DESPESAS
    for (final catData in CategoriasSugeridasService.despesas) {
      categorias.add(_criarCategoriaComSubcategorias(catData, 'despesa', nomesExistentes));
    }

    return categorias;
  }

  CategoriaComSubcategorias _criarCategoriaComSubcategorias(
    Map<String, dynamic> catData,
    String tipo,
    Set<String> nomesExistentes,
  ) {
    final nomeCategoria = catData['nome'].toString().toLowerCase();
    final categoriaJaExiste = nomesExistentes.contains(nomeCategoria);
    final subcategoriasList = catData['subcategorias'] as List;

    // Para cada subcategoria, verificar se já existe individualmente
    final subcategoriasNomes = subcategoriasList.map((sub) =>
      sub is Map ? sub['nome'].toString() : sub.toString()
    ).toList();

    final subcategoriasExistem = subcategoriasNomes.map((subNome) =>
      nomesExistentes.contains('${nomeCategoria}_${subNome.toLowerCase()}')
    ).toList();

    final subcategoriasSelecionadas = subcategoriasExistem.map((existe) => !existe).toList();

    // Se categoria pai existe mas tem subcategorias disponíveis, permitir seleção das subcategorias
    final temSubcategoriasDisponiveis = subcategoriasSelecionadas.any((disponivel) => disponivel);

    return CategoriaComSubcategorias(
      nome: catData['nome'],
      tipo: tipo,
      cor: catData['cor'],
      icone: catData['icone'],
      subcategorias: subcategoriasNomes,
      subcategoriasSelecionadas: subcategoriasSelecionadas,
      subcategoriasExistem: subcategoriasExistem,
      selecionada: !categoriaJaExiste && temSubcategoriasDisponiveis,
      jaExiste: categoriaJaExiste,
      temSubcategoriasDisponiveis: temSubcategoriasDisponiveis,
    );
  }

  void _atualizarContadores() {
    _totalCategoriasSelecionadas = _categorias.where((c) => c.selecionada && !c.jaExiste).length;
    _totalSubcategoriasSelecionadas = 0;

    for (final categoria in _categorias) {
      if (!categoria.jaExiste) {
        _totalSubcategoriasSelecionadas += categoria.subcategoriasSelecionadas.where((s) => s).length;
      }
    }
  }

  void _toggleCategoria(int index) {
    setState(() {
      final categoria = _categorias[index];
      if (!categoria.jaExiste) {
        categoria.selecionada = !categoria.selecionada;
        // Selecionar/deselecionar todas as subcategorias
        for (int i = 0; i < categoria.subcategoriasSelecionadas.length; i++) {
          categoria.subcategoriasSelecionadas[i] = categoria.selecionada;
        }
        _atualizarContadores();
      }
    });
  }

  void _toggleSubcategoria(int categoriaIndex, int subIndex) {
    setState(() {
      final categoria = _categorias[categoriaIndex];
      if (!categoria.jaExiste) {
        categoria.subcategoriasSelecionadas[subIndex] = !categoria.subcategoriasSelecionadas[subIndex];

        // Se selecionou uma subcategoria, a categoria pai também deve ser selecionada
        if (categoria.subcategoriasSelecionadas[subIndex]) {
          categoria.selecionada = true;
        } else {
          // Se desmarcou uma subcategoria, verificar se ainda há outras selecionadas
          categoria.selecionada = categoria.subcategoriasSelecionadas.any((selecionada) => selecionada);
        }

        _atualizarContadores();
      }
    });
  }

  void _marcarTodas() {
    setState(() {
      for (final categoria in _categorias) {
        if (!categoria.jaExiste) {
          categoria.selecionada = true;
          for (int i = 0; i < categoria.subcategoriasSelecionadas.length; i++) {
            categoria.subcategoriasSelecionadas[i] = true;
          }
        }
      }
      _atualizarContadores();
    });
  }

  void _desmarcarTodas() {
    setState(() {
      for (final categoria in _categorias) {
        if (!categoria.jaExiste) {
          categoria.selecionada = false;
          for (int i = 0; i < categoria.subcategoriasSelecionadas.length; i++) {
            categoria.subcategoriasSelecionadas[i] = false;
          }
        }
      }
      _atualizarContadores();
    });
  }

  Future<void> _importarSelecionadas() async {
    if (_totalCategoriasSelecionadas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma categoria para importar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _importing = true);

    try {
      debugPrint('🚀 Iniciando importação real de categorias...');

      int categoriasImportadas = 0;
      int subcategoriasImportadas = 0;

      // Importar categorias selecionadas
      for (final categoria in _categorias) {
        if (!categoria.selecionada) continue;

        debugPrint('📝 Importando categoria: ${categoria.nome} (${categoria.tipo})');

        try {
          // Criar categoria principal
          final categoriaModel = await CategoriaService.instance.addCategoria(
            nome: categoria.nome,
            tipo: categoria.tipo,
            cor: categoria.cor,
            icone: categoria.icone,
          );

          categoriasImportadas++;
          debugPrint('✅ Categoria ${categoria.nome} criada com ID: ${categoriaModel.id}');

          // Criar subcategorias selecionadas
          for (int i = 0; i < categoria.subcategorias.length; i++) {
            if (!categoria.subcategoriasSelecionadas[i]) continue;

            final nomeSubcategoria = categoria.subcategorias[i];
            debugPrint('📝 Criando subcategoria: $nomeSubcategoria');

            try {
              await CategoriaService.instance.addSubcategoria(
                categoriaId: categoriaModel.id,
                nome: nomeSubcategoria,
                cor: categoria.cor,
                icone: categoria.icone,
              );

              subcategoriasImportadas++;
              debugPrint('✅ Subcategoria $nomeSubcategoria criada');
            } catch (e) {
              debugPrint('❌ Erro ao criar subcategoria $nomeSubcategoria: $e');
            }
          }

        } catch (e) {
          debugPrint('❌ Erro ao criar categoria ${categoria.nome}: $e');
          // Continua com próxima categoria
        }
      }

      debugPrint('🎉 Importação concluída: $categoriasImportadas categorias, $subcategoriasImportadas subcategorias');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Importadas $categoriasImportadas categorias e $subcategoriasImportadas subcategorias!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }

    } catch (error) {
      debugPrint('❌ Erro na importação: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao importar: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Categorias Sugeridas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_totalCategoriasSelecionadas > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_totalCategoriasSelecionadas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.tealPrimary),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categorias.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSectionHeader();
                      }

                      final categoria = _categorias[index - 1];
                      return _buildCategoriaCard(categoria, index - 1);
                    },
                  ),
                ),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader() {
    final receitas = _categorias.where((c) => c.tipo == 'receita').length;
    final despesas = _categorias.where((c) => c.tipo == 'despesa').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.tealPrimary.withOpacity(0.1),
            AppColors.tealPrimary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tealPrimary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: AppColors.tealPrimary, size: 24),
              SizedBox(width: 8),
              Text(
                'Escolha suas categorias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinzaEscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione categorias e subcategorias que fazem sentido para você',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip('💰', '$receitas receitas', AppColors.verdeSucesso),
              const SizedBox(width: 12),
              _buildStatChip('💸', '$despesas despesas', AppColors.vermelhoErro),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 CARD MODERNO DE CATEGORIA com estado "JÁ IMPORTADA"
  Widget _buildCategoriaCard(CategoriaComSubcategorias categoria, int index) {
    final cor = Color(int.parse(categoria.cor.substring(1), radix: 16) + 0xFF000000);
    final isReceita = categoria.tipo == 'receita';

    // 🎯 Visual diferenciado para categoria já importada
    final jaImportada = categoria.jaExiste;
    final temSubcategoriasDisponiveis = categoria.temSubcategoriasDisponiveis;

    Color bordaCor;
    Color sombraCor;
    double larguraBorda;

    if (jaImportada && temSubcategoriasDisponiveis) {
      // Categoria existe mas tem subcategorias disponíveis
      bordaCor = Colors.green.withOpacity(0.7);
      sombraCor = Colors.green.withOpacity(0.15);
      larguraBorda = 1.5;
    } else if (jaImportada) {
      // Categoria completamente importada
      bordaCor = Colors.green.withOpacity(0.4);
      sombraCor = Colors.green.withOpacity(0.1);
      larguraBorda = 1;
    } else if (categoria.selecionada) {
      // Categoria nova selecionada
      bordaCor = cor;
      sombraCor = cor.withOpacity(0.2);
      larguraBorda = 2;
    } else {
      // Categoria padrão
      bordaCor = AppColors.cinzaBorda.withOpacity(0.3);
      sombraCor = Colors.black.withOpacity(0.08);
      larguraBorda = 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bordaCor, width: larguraBorda),
        boxShadow: [
          BoxShadow(
            color: sombraCor,
            blurRadius: jaImportada ? 8 : (categoria.selecionada ? 12 : 8),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // 🎨 HEADER PRINCIPAL
              _buildCategoriaHeader(categoria, cor, index, isReceita),

              // 🎨 SUBCATEGORIAS
              if (categoria.subcategorias.isNotEmpty)
                _buildSubcategoriasSection(categoria, cor, index),
            ],
          ),

          // 🏷️ BADGE "JÁ IMPORTADA" no canto superior direito
          if (jaImportada)
            Positioned(
              top: 12,
              right: 12,
              child: _buildBadgeJaImportada(temSubcategoriasDisponiveis),
            ),
        ],
      ),
    );
  }

  /// 🏷️ Badge elegante para categoria já importada
  Widget _buildBadgeJaImportada(bool temSubcategoriasDisponiveis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: temSubcategoriasDisponiveis ? Colors.orange : Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            temSubcategoriasDisponiveis ? Icons.refresh : Icons.check_circle,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            temSubcategoriasDisponiveis ? 'Parcial' : 'Importada',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 HEADER PRINCIPAL MELHORADO
  Widget _buildCategoriaHeader(CategoriaComSubcategorias categoria, Color cor, int index, bool isReceita) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleCategoria(index),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 🎨 ÍCONE GRANDE E MODERNO
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: categoria.jaExiste ? AppColors.cinzaMedio : cor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: categoria.jaExiste ? null : [
                    BoxShadow(
                      color: cor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildIconeDisplay(categoria.icone, 24),
                ),
              ),

              const SizedBox(width: 16),

              // 🎨 INFO DA CATEGORIA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria.nome,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: categoria.jaExiste ? AppColors.cinzaMedio : AppColors.cinzaEscuro,
                        decoration: categoria.jaExiste ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (categoria.jaExiste && categoria.temSubcategoriasDisponiveis)
                          Text(
                            '${categoria.subcategoriasDisponiveis} de ${categoria.totalSubcategorias} disponíveis',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (categoria.jaExiste)
                          const Text(
                            'Totalmente importada',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            '${categoria.subcategorias.length} subcategorias',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.cinzaTexto,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          isReceita ? '💰' : '💸',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🎨 CHECKBOX CUSTOMIZADO OU BADGE
              if (!categoria.jaExiste)
                _buildCheckboxCustomizado(categoria.selecionada, cor)
              else
                _buildBadgeJaExiste(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 CHECKBOX CUSTOMIZADO
  Widget _buildCheckboxCustomizado(bool selecionado, Color cor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selecionado ? cor : Colors.transparent,
        border: Border.all(
          color: selecionado ? cor : AppColors.cinzaBorda,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: selecionado
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 18,
            )
          : null,
    );
  }

  /// 🎨 BADGE "JÁ EXISTE"
  Widget _buildBadgeJaExiste() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cinzaMedio.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Já existe',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.cinzaMedio,
        ),
      ),
    );
  }

  /// 🎨 SUBCATEGORIAS EM GRID MODERNO
  Widget _buildSubcategoriasSection(CategoriaComSubcategorias categoria, Color cor, int categoriaIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_rounded, size: 16, color: cor),
              const SizedBox(width: 8),
              Text(
                'Subcategorias',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🎨 GRID DE SUBCATEGORIAS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoria.subcategorias.asMap().entries.map((entry) {
              final subIndex = entry.key;
              final subNome = entry.value;

              return _buildSubcategoriaChip(
                subNome,
                categoria.subcategoriasSelecionadas[subIndex],
                cor,
                () => _toggleSubcategoria(categoriaIndex, subIndex),
                categoria.subcategoriasExistem[subIndex], // Subcategoria específica já existe
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 🎨 CHIP DE SUBCATEGORIA MODERNO com estado individual
  Widget _buildSubcategoriaChip(String nome, bool selecionado, Color cor, VoidCallback onTap, bool subcategoriaJaExiste) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: subcategoriaJaExiste ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: subcategoriaJaExiste
                ? Colors.green.withOpacity(0.1) // Verde suave para já existente
                : selecionado
                    ? cor.withOpacity(0.15)
                    : Colors.white,
            border: Border.all(
              color: subcategoriaJaExiste
                  ? Colors.green.withOpacity(0.5)
                  : selecionado
                      ? cor
                      : AppColors.cinzaBorda.withOpacity(0.5),
              width: subcategoriaJaExiste ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone baseado no estado
              if (subcategoriaJaExiste)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                )
              else if (selecionado)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: cor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 8,
                  ),
                ),

              Flexible(
                child: Text(
                  nome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (selecionado || subcategoriaJaExiste) ? FontWeight.w600 : FontWeight.normal,
                    color: subcategoriaJaExiste
                        ? Colors.green.shade700
                        : selecionado
                            ? cor
                            : AppColors.cinzaTexto,
                  ),
                ),
              ),

              // Badge "Existe" para subcategorias já importadas
              if (subcategoriaJaExiste) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Existe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconeDisplay(String icone, double tamanho) {
    return Text(
      icone,
      style: TextStyle(
        fontSize: tamanho,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cinzaBorda)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_totalCategoriasSelecionadas > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tealPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_totalCategoriasSelecionadas categorias e $_totalSubcategoriasSelecionadas subcategorias serão importadas',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _marcarTodas,
                    child: const Text('Marcar todas'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _desmarcarTodas,
                    child: const Text('Desmarcar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _importing ? null : _importarSelecionadas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _importing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _totalCategoriasSelecionadas > 0
                                ? 'Importar ($_totalCategoriasSelecionadas)'
                                : 'Importar',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo para categoria com subcategorias e estado de seleção
class CategoriaComSubcategorias {
  final String nome;
  final String cor;
  final String icone;
  final String tipo;
  final List<String> subcategorias;
  final bool jaExiste;
  final bool temSubcategoriasDisponiveis;
  final List<bool> subcategoriasExistem; // Quais subcategorias já existem
  bool selecionada;
  List<bool> subcategoriasSelecionadas;

  CategoriaComSubcategorias({
    required this.nome,
    required this.cor,
    required this.icone,
    required this.tipo,
    required this.subcategorias,
    required this.jaExiste,
    required this.temSubcategoriasDisponiveis,
    required this.subcategoriasExistem,
    this.selecionada = false,
    required this.subcategoriasSelecionadas,
  });

  /// Quantas subcategorias estão disponíveis para importar
  int get subcategoriasDisponiveis => subcategoriasSelecionadas.where((s) => s).length;

  /// Total de subcategorias
  int get totalSubcategorias => subcategorias.length;

  /// Quantas subcategorias já existem
  int get subcategoriasExistentes => subcategoriasExistem.where((e) => e).length;
}