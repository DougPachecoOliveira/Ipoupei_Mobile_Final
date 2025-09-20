import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';


/// Página específica para alterar categoria de transações
class AlterarCategoriaPage extends StatefulWidget {
  final TransacaoModel transacao;
  final VoidCallback onCategoriaAlterada;

  const AlterarCategoriaPage({
    super.key,
    required this.transacao,
    required this.onCategoriaAlterada,
  });

  @override
  State<AlterarCategoriaPage> createState() => _AlterarCategoriaPageState();
}

class _AlterarCategoriaPageState extends State<AlterarCategoriaPage> {
  CategoriaModel? _categoriaSelecionada;
  SubcategoriaModel? _subcategoriaSelecionada;
  List<CategoriaModel> _categorias = [];
  List<SubcategoriaModel> _subcategorias = [];
  bool _carregandoCategorias = true;
  bool _carregandoSubcategorias = false;
  
  // Dados originais
  String? _categoriaOriginalNome;
  String? _subcategoriaOriginalNome;
  
  // Detecção de recorrência/parcelamento
  bool _temRecorrenciaOuParcelamento = false;
  EscopoEdicao _escopoSelecionado = EscopoEdicao.apenasEsta;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      // Buscar categoria atual
      if (widget.transacao.categoriaId != null) {
        final categorias = await CategoriaService.instance.fetchCategorias();
        final categoria = categorias.where((c) => c.id == widget.transacao.categoriaId).firstOrNull;
        if (categoria != null) {
          _categoriaOriginalNome = categoria.nome;
          _categoriaSelecionada = categoria;
        }
      }
      
      // Buscar subcategoria atual
      if (widget.transacao.subcategoriaId != null) {
        final subcategorias = await CategoriaService.instance.fetchSubcategorias();
        final subcategoria = subcategorias.where((s) => s.id == widget.transacao.subcategoriaId).firstOrNull;
        if (subcategoria != null) {
          _subcategoriaOriginalNome = subcategoria.nome;
          _subcategoriaSelecionada = subcategoria;
        }
      }
      
      // Carregar todas as categorias do tipo da transação
      await _carregarCategorias();
      
      // Analisar recorrência/parcelamento
      _analisarRecorrencia();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _carregandoCategorias = true;
    });

    try {
      final todasCategorias = await CategoriaService.instance.fetchCategorias();
      _categorias = todasCategorias.where((c) => c.tipo == widget.transacao.tipo).toList();
      
      // Se já temos uma categoria selecionada, carregar suas subcategorias
      if (_categoriaSelecionada != null) {
        await _carregarSubcategorias(_categoriaSelecionada!.id);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar categorias: $e')),
      );
    } finally {
      setState(() {
        _carregandoCategorias = false;
      });
    }
  }

  Future<void> _carregarSubcategorias(String categoriaId) async {
    setState(() {
      _carregandoSubcategorias = true;
    });

    try {
      _subcategorias = await CategoriaService.instance.fetchSubcategorias(categoriaId: categoriaId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar subcategorias: $e')),
      );
    } finally {
      setState(() {
        _carregandoSubcategorias = false;
      });
    }
  }

  void _analisarRecorrencia() {
    final transacao = widget.transacao;
    
    // Verificar recorrência
    bool temRecorrencia = transacao.recorrente || 
                         transacao.ehRecorrente ||
                         (transacao.grupoRecorrencia?.isNotEmpty ?? false);
    
    // Verificar parcelamento
    bool temParcelamento = !transacao.parcelaUnica ||
                          (transacao.totalParcelas != null && transacao.totalParcelas! > 1) ||
                          (transacao.grupoParcelamento?.isNotEmpty ?? false);
    
    setState(() {
      _temRecorrenciaOuParcelamento = temRecorrencia || temParcelamento;
    });
  }

  Color _getCorHeader() {
    switch (widget.transacao.tipo) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return widget.transacao.cartaoId != null 
          ? AppColors.roxoPrimario 
          : AppColors.vermelhoErro;
      default:
        return AppColors.azul;
    }
  }

  String _getDescricaoEscopoCategoria(EscopoEdicao escopo) {
    switch (escopo) {
      case EscopoEdicao.apenasEsta:
        return 'Alterar categoria apenas desta transação';
      case EscopoEdicao.estasEFuturas:
        return 'Alterar categoria desta e das próximas transações';
      case EscopoEdicao.todasRelacionadas:
        return 'Alterar categoria de todas as transações relacionadas';
    }
  }

  IconData? _getIconDataByName(String iconName) {
    // Se é um emoji (1 caractere unicode), retorna null
    if (iconName.length <= 2 && !iconName.contains('_')) {
      return null;
    }
    
    // Map básico de ícones - expandir conforme necessário
    final iconMap = {
      'category': Icons.category,
      'restaurant': Icons.restaurant,
      'shopping_cart': Icons.shopping_cart,
      'local_gas_station': Icons.local_gas_station,
      'home': Icons.home,
      'work': Icons.work,
      'school': Icons.school,
      'health_and_safety': Icons.health_and_safety,
      'fitness_center': Icons.fitness_center,
      'movie': Icons.movie,
      'music_note': Icons.music_note,
      'directions_car': Icons.directions_car,
      'flight': Icons.flight,
      'hotel': Icons.hotel,
    };
    
    return iconMap[iconName] ?? Icons.category;
  }

  void _selecionarCategoria(CategoriaModel categoria) async {
    setState(() {
      _categoriaSelecionada = categoria;
      _subcategoriaSelecionada = null; // Reset subcategoria
    });
    
    // Carregar subcategorias da nova categoria
    await _carregarSubcategorias(categoria.id);
  }

  void _selecionarSubcategoria(SubcategoriaModel? subcategoria) {
    setState(() {
      _subcategoriaSelecionada = subcategoria;
    });
  }

  Future<void> _confirmarAlteracao() async {
    if (_categoriaSelecionada == null) return;
    
    try {
      // Salvar categoria com escopo integrado ao service
      await _salvarNovaCategoria(_categoriaSelecionada!, _subcategoriaSelecionada);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoria alterada para "${_categoriaSelecionada!.nome}"'),
        ),
      );
      
      widget.onCategoriaAlterada();
      Navigator.of(context).pop();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alterar categoria: $e')),
      );
    }
  }

  Future<void> _salvarNovaCategoria(CategoriaModel categoria, SubcategoriaModel? subcategoria) async {
    setState(() {
      _processando = true;
    });

    try {
      final resultado = await TransacaoEditService.instance.alterarCategoria(
        widget.transacao,
        novaCategoriaId: categoria.id,
        novaSubcategoriaId: subcategoria?.id,
        escopo: _escopoSelecionado,
      );
      
      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Categoria alterada com sucesso'),
            backgroundColor: AppColors.tealPrimary,
          ),
        );
        
        widget.onCategoriaAlterada();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao alterar categoria'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar categoria: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: AppBar(
        backgroundColor: _getCorHeader(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Alterar Categoria',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.category,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _processando || _categoriaSelecionada == null ? null : _confirmarAlteracao,
            child: _processando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Salvar',
                    style: TextStyle(
                      color: _categoriaSelecionada != null ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _carregandoCategorias
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card da transação
                    _buildCardTransacao(),
                    const SizedBox(height: 24),
                    
                    // Preview da categoria atual vs nova
                    _buildPreviewCategoria(),
                    const SizedBox(height: 24),
                    
                    // Seleção de categoria
                    _buildSeletorCategoria(),
                    const SizedBox(height: 24),
                    
                    // Seleção de subcategoria (se categoria selecionada)
                    if (_categoriaSelecionada != null) ...[
                      _buildSeletorSubcategoria(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Opções de escopo (se há recorrência/parcelamento)
                    if (_temRecorrenciaOuParcelamento) ...[
                      _buildOpcoesEscopo(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Botão de confirmação
                    _buildBotaoConfirmar(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCardTransacao() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCorHeader().withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCorHeader().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.transacao.tipo.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getCorHeader(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'R\$ ${widget.transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.transacao.descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cinzaEscuro,
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

  Widget _buildPreviewCategoria() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorHeader().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: _getCorHeader(), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Preview da Alteração',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCorHeader(),
                  ),
                ),
              ],
            ),
          ),
          
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Categoria atual
                Row(
                  children: [
                    const Text(
                      'Categoria atual:',
                      style: TextStyle(fontSize: 14, color: AppColors.cinzaTexto),
                    ),
                    const Spacer(),
                    Text(
                      _categoriaOriginalNome ?? 'Sem categoria',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Nova categoria
                Row(
                  children: [
                    const Text(
                      'Nova categoria:',
                      style: TextStyle(fontSize: 14, color: AppColors.cinzaTexto),
                    ),
                    const Spacer(),
                    Text(
                      _categoriaSelecionada?.nome ?? 'Selecione uma categoria',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _categoriaSelecionada != null 
                          ? _getCorHeader() 
                          : AppColors.cinzaTexto,
                      ),
                    ),
                  ],
                ),
                
                // Subcategoria (se aplicável)
                if (_subcategoriaOriginalNome != null || _subcategoriaSelecionada != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  // Subcategoria atual
                  Row(
                    children: [
                      const Text(
                        'Subcategoria atual:',
                        style: TextStyle(fontSize: 14, color: AppColors.cinzaTexto),
                      ),
                      const Spacer(),
                      Text(
                        _subcategoriaOriginalNome ?? 'Sem subcategoria',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Nova subcategoria
                  Row(
                    children: [
                      const Text(
                        'Nova subcategoria:',
                        style: TextStyle(fontSize: 14, color: AppColors.cinzaTexto),
                      ),
                      const Spacer(),
                      Text(
                        _subcategoriaSelecionada?.nome ?? 'Nenhuma selecionada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _subcategoriaSelecionada != null 
                            ? _getCorHeader() 
                            : AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorCategoria() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorHeader().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.category, color: _getCorHeader(), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Selecionar Categoria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Grid de chips de categorias
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_categoriaOriginalNome != null) ...[
                  Text(
                    'Categoria atual:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.cinzaTexto,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoriaChip(_categorias.firstWhere(
                    (c) => c.nome == _categoriaOriginalNome, 
                    orElse: () => _categorias.first,
                  ), isOriginal: true),
                  const SizedBox(height: 16),
                ],
                
                Text(
                  'Escolha uma nova categoria:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.cinzaEscuro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categorias.map((categoria) {
                    final isSelected = _categoriaSelecionada?.id == categoria.id;
                    final isOriginal = categoria.nome == _categoriaOriginalNome;
                    
                    if (isOriginal) return const SizedBox.shrink(); // Não duplicar a categoria atual
                    
                    return _buildCategoriaChip(categoria, isSelected: isSelected);
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChip(CategoriaModel categoria, {bool isSelected = false, bool isOriginal = false}) {
    final cor = categoria.cor.isNotEmpty
        ? Color(int.parse('0xFF${categoria.cor.replaceAll('#', '')}'))
        : _getCorHeader();
        
    return GestureDetector(
      onTap: isOriginal ? null : () => _selecionarCategoria(categoria),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOriginal 
              ? AppColors.cinzaMedio.withOpacity(0.2)
              : isSelected 
                  ? cor.withOpacity(0.15)
                  : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOriginal
                ? AppColors.cinzaMedio
                : isSelected 
                    ? cor
                    : AppColors.cinzaBorda,
            width: isSelected || isOriginal ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone da categoria
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: categoria.icone.isNotEmpty
                    ? (categoria.icone.length <= 2 && !categoria.icone.contains('_'))
                        ? Text(categoria.icone, style: const TextStyle(fontSize: 11, color: Colors.white))
                        : const Icon(Icons.category, color: Colors.white, size: 12)
                    : const Icon(Icons.category, color: Colors.white, size: 12),
              ),
            ),
            const SizedBox(width: 8),
            
            // Nome da categoria
            Text(
              categoria.nome,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || isOriginal ? FontWeight.w600 : FontWeight.normal,
                color: isOriginal 
                    ? AppColors.cinzaMedio 
                    : isSelected 
                        ? cor
                        : AppColors.cinzaEscuro,
              ),
            ),
            
            // Indicador visual
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, color: cor, size: 16),
            ] else if (isOriginal) ...[
              const SizedBox(width: 4),
              Icon(Icons.history, color: AppColors.cinzaMedio, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorSubcategoria() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.roxoPrimario.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.subdirectory_arrow_right, color: AppColors.roxoPrimario, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Selecionar Subcategoria (Opcional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.roxoPrimario,
                  ),
                ),
              ],
            ),
          ),
          
          // Grid de chips de subcategorias
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_carregandoSubcategorias)
                  const Center(child: CircularProgressIndicator())
                else if (_subcategorias.isEmpty)
                  Text(
                    'Esta categoria não possui subcategorias',
                    style: TextStyle(
                      color: AppColors.cinzaTexto,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else ...[
                  if (_subcategoriaOriginalNome != null) ...[
                    Text(
                      'Subcategoria atual:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaTexto,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSubcategoriaChip(null, isOriginalEmpty: _subcategoriaOriginalNome == 'Sem subcategoria'),
                    const SizedBox(height: 16),
                  ],
                  
                  Text(
                    'Escolha uma subcategoria (opcional):',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.cinzaEscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Chip "Nenhuma subcategoria"
                  _buildSubcategoriaChip(null, isSelected: _subcategoriaSelecionada == null),
                  
                  const SizedBox(height: 8),
                  
                  // Chips das subcategorias
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subcategorias.map((subcategoria) {
                      final isSelected = _subcategoriaSelecionada?.id == subcategoria.id;
                      return _buildSubcategoriaChip(subcategoria, isSelected: isSelected);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoriaChip(SubcategoriaModel? subcategoria, {bool isSelected = false, bool isOriginalEmpty = false}) {
    final cor = subcategoria?.cor?.isNotEmpty == true
        ? Color(int.parse('0xFF${subcategoria!.cor!.replaceAll('#', '')}'))
        : _getCorHeader();
        
    final isNone = subcategoria == null;
    final displayText = isNone ? 'Nenhuma subcategoria' : subcategoria!.nome;
    
    return GestureDetector(
      onTap: () => _selecionarSubcategoria(subcategoria),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOriginalEmpty 
              ? AppColors.cinzaMedio.withOpacity(0.2)
              : isSelected 
                  ? cor.withOpacity(0.15)
                  : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOriginalEmpty
                ? AppColors.cinzaMedio
                : isSelected 
                    ? cor
                    : AppColors.cinzaBorda,
            width: isSelected || isOriginalEmpty ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone da subcategoria
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isNone ? AppColors.cinzaMedio : cor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isNone
                    ? const Icon(Icons.clear, color: Colors.white, size: 10)
                    : subcategoria!.icone?.isNotEmpty == true
                        ? (subcategoria.icone!.length <= 2 && !subcategoria.icone!.contains('_'))
                            ? Text(subcategoria.icone!, style: const TextStyle(fontSize: 9, color: Colors.white))
                            : Icon(_getIconDataByName(subcategoria.icone!) ?? Icons.subdirectory_arrow_right, color: Colors.white, size: 10)
                        : const Icon(Icons.subdirectory_arrow_right, color: Colors.white, size: 10),
              ),
            ),
            const SizedBox(width: 6),
            
            // Nome da subcategoria
            Text(
              displayText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected || isOriginalEmpty ? FontWeight.w600 : FontWeight.normal,
                color: isOriginalEmpty 
                    ? AppColors.cinzaMedio 
                    : isSelected 
                        ? cor
                        : AppColors.cinzaEscuro,
              ),
            ),
            
            // Indicador visual
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, color: cor, size: 14),
            ] else if (isOriginalEmpty) ...[
              const SizedBox(width: 4),
              Icon(Icons.history, color: AppColors.cinzaMedio, size: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpcoesEscopo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorHeader().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.settings_suggest, color: _getCorHeader(), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Escopo da Alteração',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCorHeader(),
                  ),
                ),
              ],
            ),
          ),
          
          // Opções de escopo
          ...EscopoEdicao.values.map((escopo) {
            final isSelected = _escopoSelecionado == escopo;
            final cor = _getCorHeader();
            
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? cor.withOpacity(0.1) : null,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cinzaBorda.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: RadioListTile<EscopoEdicao>(
                value: escopo,
                groupValue: _escopoSelecionado,
                onChanged: (value) {
                  setState(() {
                    _escopoSelecionado = value ?? EscopoEdicao.apenasEsta;
                  });
                },
                title: Text(
                  escopo.descricao,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? cor : AppColors.cinzaEscuro,
                  ),
                ),
                subtitle: Text(
                  _getDescricaoEscopoCategoria(escopo),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaTexto,
                  ),
                ),
                activeColor: cor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBotaoConfirmar() {
    final isValid = _categoriaSelecionada != null && !_processando;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid ? _confirmarAlteracao : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? _getCorHeader() : AppColors.cinzaMedio,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _processando
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Salvando...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                _temRecorrenciaOuParcelamento 
                  ? 'Confirmar (${_escopoSelecionado.descricao})'
                  : 'Confirmar Alteração',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}