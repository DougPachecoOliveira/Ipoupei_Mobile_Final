// lib/src/modules/categorias/components/criar_subcategoria_modal.dart
import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../services/categoria_service.dart';
import '../models/categoria_model.dart';
import '../data/categoria_icons.dart';

/// Modal compacto para criar subcategorias
/// Muito mais simples que categoria - só nome + preview da categoria pai
class CriarSubcategoriaModal extends StatefulWidget {
  final CategoriaModel categoria; // Categoria pai (para cores/ícone)
  final String? nomeInicial; // Pré-preenchimento opcional
  final Function(Map<String, dynamic>)? onSubcategoriaCriada;

  const CriarSubcategoriaModal({
    super.key,
    required this.categoria,
    this.nomeInicial,
    this.onSubcategoriaCriada,
  });

  @override
  State<CriarSubcategoriaModal> createState() => _CriarSubcategoriaModalState();
}

class _CriarSubcategoriaModalState extends State<CriarSubcategoriaModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _nomeFocus = FocusNode();
  
  bool _salvando = false;
  
  // Cores dinâmicas baseadas na categoria pai
  Color get _headerColor {
    return widget.categoria.tipo == 'despesa' 
        ? AppColors.vermelhoHeader 
        : AppColors.tealPrimary;
  }
  
  Color get _categoriaColor {
    try {
      return Color(int.parse(widget.categoria.cor.replaceAll('#', '0xFF')));
    } catch (e) {
      return _headerColor;
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Pré-preencher nome se fornecido
    if (widget.nomeInicial != null) {
      _nomeController.text = widget.nomeInicial!;
    }
    
    // Auto-focus no campo nome
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nomeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 
                MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _headerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            widget.categoria.tipo == 'despesa' ? Icons.trending_down : Icons.trending_up,
            color: AppColors.branco,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova Subcategoria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.branco,
                  ),
                ),
                Text(
                  'de ${widget.categoria.nome}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.branco,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.branco),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoriaInfo(),
            const SizedBox(height: 24),
            _buildCampoNome(),
            const SizedBox(height: 24),
            if (_nomeController.text.trim().isNotEmpty) _buildPreview(),
            if (_nomeController.text.trim().isNotEmpty) const SizedBox(height: 32),
            _buildBotoes(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _categoriaColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _categoriaColor.withAlpha(78)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _categoriaColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CategoriaIcons.renderIcon(
                widget.categoria.icone,
                20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoria: ${widget.categoria.nome}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _categoriaColor,
                  ),
                ),
                const Text(
                  'As subcategorias herdam ícone e cor',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaTexto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nome da Subcategoria',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.cinzaEscuro,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nomeController,
          focusNode: _nomeFocus,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'Ex: Aluguel, Supermercado, Gasolina...',
            border: const UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _headerColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            if (value.trim().length < 2) {
              return 'Nome deve ter pelo menos 2 caracteres';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.cinzaEscuro,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cinzaClaro,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cinzaBorda),
          ),
          child: Row(
            children: [
              // Ícone da categoria pai (menor)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _categoriaColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: CategoriaIcons.renderIcon(
                    widget.categoria.icone,
                    16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoria.nome,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                    Text(
                      _nomeController.text.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'R\$ 0,00',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.cinzaTexto,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotoes() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nomeController.text.trim().length >= 2 && !_salvando 
                ? _salvarSubcategoria 
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _headerColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SALVAR SUBCATEGORIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: _headerColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _salvarSubcategoria() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _salvando = true);

    try {
      final categoriaService = CategoriaService.instance;
      
      // Verificar se nome já existe nesta categoria
      final subcategorias = await categoriaService.fetchSubcategorias(categoriaId: widget.categoria.id);
      final nomeJaExiste = subcategorias.any((sub) => 
        sub.nome.toLowerCase().trim() == _nomeController.text.trim().toLowerCase());
      
      if (nomeJaExiste) {
        _mostrarErro('Já existe uma subcategoria com este nome');
        return;
      }

      final resultado = await categoriaService.addSubcategoria(
        categoriaId: widget.categoria.id,
        nome: _nomeController.text.trim(),
        cor: widget.categoria.cor,     // Herda da categoria
        icone: widget.categoria.icone, // Herda da categoria
      );

      _mostrarSucesso('Subcategoria criada com sucesso!');
      
      // Dados para retornar
      final subcategoriaCriada = {
        'id': resultado.id,
        'nome': resultado.nome,
        'categoria_id': widget.categoria.id,
        'icone': widget.categoria.icone,
        'cor': widget.categoria.cor,
        'tipo': widget.categoria.tipo,
      };
      
      // Callback se fornecido
      if (widget.onSubcategoriaCriada != null) {
        widget.onSubcategoriaCriada!(subcategoriaCriada);
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        Navigator.pop(context, subcategoriaCriada);
      }
      
    } catch (e) {
      _mostrarErro('Erro ao criar subcategoria: $e');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _mostrarSucesso(String mensagem) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.tealEscuro,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.vermelhoErro,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      ),
    );
  }
}