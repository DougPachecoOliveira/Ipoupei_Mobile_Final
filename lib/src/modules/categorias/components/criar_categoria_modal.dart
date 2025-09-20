import 'dart:math';

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../services/categoria_service.dart';
import '../data/categoria_icons.dart';
import '../models/categoria_model.dart';
import 'escolher_icone_modal.dart';

/// Modal compacto e reutilizável para criar/editar categorias
class CriarCategoriaModal extends StatefulWidget {
  final String tipo; // 'receita' ou 'despesa'
  final String? nomeInicial; // Pré-preenchimento opcional
  final CategoriaModel? categoriaParaEditar; // Para edição
  final Function(CategoriaModel)? onCategoriaCriada; // Callback

  const CriarCategoriaModal({
    super.key,
    required this.tipo,
    this.nomeInicial,
    this.categoriaParaEditar,
    this.onCategoriaCriada,
  });

  @override
  State<CriarCategoriaModal> createState() => _CriarCategoriaModalState();
}

class _CriarCategoriaModalState extends State<CriarCategoriaModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _nomeFocus = FocusNode();
  final _categoriaService = CategoriaService.instance;
  
  // Estados
  bool _salvando = false;
  String _corSelecionada = '';
  String _iconeSelecionado = '🏷️';
  
  // Getter para verificar se é edição
  bool get _isEditing => widget.categoriaParaEditar != null;
  
  // Cores dinâmicas baseadas no tipo
  Color get _headerColor {
    return widget.tipo == 'despesa' 
        ? AppColors.vermelhoHeader 
        : AppColors.tealPrimary;
  }
  
  List<String> get _coresPrincipais {
    return widget.tipo == 'despesa' 
        ? [
            '#DC3545', // Vermelho principal
            '#FF6B6B', // Coral
            '#E74C3C', // Vermelho claro
            '#F39C12', // Laranja
            '#E67E22', // Laranja escuro
            '#8B5CF6', // Roxo
            '#6366F1', // Índigo
            '#EC4899', // Rosa
          ]
        : [
            '#008080', // Teal principal
            '#10B981', // Verde sucesso
            '#06D6A0', // Verde água
            '#3B82F6', // Azul
            '#1E40AF', // Azul escuro
            '#6366F1', // Roxo
            '#8B5CF6', // Violeta
            '#EC4899', // Rosa
          ];
  }

  // ✅ MÉTODO SORTEAR (todas as cores disponíveis)
  List<String> get _todasAsCores {
    return [
      '#DC3545', '#FF6B6B', '#E74C3C', '#C0392B', '#A93226',
      '#F39C12', '#E67E22', '#D35400', '#F1C40F', '#F4D03F',
      '#008080', '#10B981', '#06D6A0', '#26C485', '#059669',
      '#3B82F6', '#1E40AF', '#2563EB', '#1D4ED8', '#1E3A8A',
      '#8B5CF6', '#6366F1', '#7C3AED', '#6D28D9', '#5B21B6',
      '#EC4899', '#F472B6', '#E879F9', '#C084FC', '#A78BFA',
      '#EF4444', '#F87171', '#FB7185', '#FBBF24', '#FCD34D',
      '#22C55E', '#4ADE80', '#34D399', '#06B6D4', '#0EA5E9',
    ];
  }

  void _sortearCor() {
    final random = Random();
    final coresDisponiveis = _todasAsCores.where((cor) => cor != _corSelecionada).toList();
    final novaCor = coresDisponiveis[random.nextInt(coresDisponiveis.length)];
    
    setState(() {
      _corSelecionada = novaCor;
    });
  }

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Modo edição: preencher com dados existentes
      final categoria = widget.categoriaParaEditar!;
      _nomeController.text = categoria.nome;
      _corSelecionada = categoria.cor ?? _coresPrincipais.first;
      _iconeSelecionado = categoria.icone;
    } else {
      // Modo criação
      // Pré-preencher nome se fornecido
      if (widget.nomeInicial != null) {
        _nomeController.text = widget.nomeInicial!;
      }
      
      // Cor padrão baseada no tipo
      _corSelecionada = _coresPrincipais.first;
      
      // Ícone padrão baseado no tipo
      _iconeSelecionado = widget.tipo == 'despesa' ? '💰' : '💸';
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
        color: Colors.white,
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
            _isEditing ? Icons.edit : (widget.tipo == 'despesa' ? Icons.trending_down : Icons.trending_up),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditing 
                ? 'Editar Categoria'
                : 'Nova Categoria ${widget.tipo == 'despesa' ? 'de Despesa' : 'de Receita'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
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
            _buildCampoNome(),
            const SizedBox(height: 24),
            _buildSeletorCor(),
            const SizedBox(height: 24),
            _buildSeletorIcone(),
            const SizedBox(height: 24),
            _buildPreview(),
            const SizedBox(height: 32),
            _buildBotoes(),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descrição',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nomeController,
          focusNode: _nomeFocus,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'Digite o nome da categoria',
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

  Widget _buildSeletorCor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(int.parse(_corSelecionada.replaceAll('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Cor da Categoria',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: _sortearCor,
              child: Text(
                'Sortear',
                style: TextStyle(
                  color: _headerColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _coresPrincipais.map((cor) {
            final isSelected = cor == _corSelecionada;
            return GestureDetector(
              onTap: () => setState(() => _corSelecionada = cor),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(int.parse(cor.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected 
                    ? Border.all(color: Colors.black87, width: 3)
                    : null,
                ),
                child: isSelected 
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeletorIcone() {
    final isEmoji = CategoriaIcons.isEmoji(_iconeSelecionado);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(int.parse(_corSelecionada.replaceAll('#', '0xFF'))),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: isEmoji 
                  ? Text(
                      _iconeSelecionado,
                      style: const TextStyle(fontSize: 16),
                    )
                  : Icon(
                      CategoriaIcons.getIconFromName(_iconeSelecionado),
                      color: Colors.white,
                      size: 16,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Ícone da Categoria',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: _abrirSeletorIcone,
              child: Text(
                'Escolher',
                style: TextStyle(
                  color: _headerColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Mostrar alguns ícones sugeridos
        Wrap(
          spacing: 8,
          children: _getIconesSugeridos()
              .map((icone) {
            final isSelected = icone == _iconeSelecionado;
            final isIconeEmoji = CategoriaIcons.isEmoji(icone);
            
            return GestureDetector(
              onTap: () => setState(() => _iconeSelecionado = icone),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? _headerColor.withAlpha(26) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? _headerColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isIconeEmoji
                    ? Text(
                        icone,
                        style: const TextStyle(fontSize: 20),
                      )
                    : Icon(
                        CategoriaIcons.getIconFromName(icone),
                        size: 20,
                        color: isSelected ? _headerColor : Colors.grey.shade600,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _getIconesSugeridos() {
    if (widget.tipo == 'despesa') {
      return ['🍽️', '🚗', '🏠', '🎉', '👕', '🏥'];
    } else {
      return ['💰', '💼', '🎯', '📈', '💸', '🏆'];
    }
  }

  Widget _buildPreview() {
    if (_nomeController.text.trim().isEmpty) return const SizedBox.shrink();
    
    final isEmoji = CategoriaIcons.isEmoji(_iconeSelecionado);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(int.parse(_corSelecionada.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isEmoji 
                    ? Text(
                        _iconeSelecionado,
                        style: const TextStyle(fontSize: 20),
                      )
                    : Icon(
                        CategoriaIcons.getIconFromName(_iconeSelecionado),
                        color: Colors.white,
                        size: 20,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nomeController.text.trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Text(
                'R\$ 0,00',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
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
                ? _salvarCategoria 
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
                : Text(
                    _isEditing ? 'SALVAR ALTERAÇÕES' : 'SALVAR CATEGORIA',
                    style: const TextStyle(
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

  void _abrirSeletorIcone() async {
    final iconeEscolhido = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EscolherIconeModal(
        tipoCategoria: widget.tipo,
        iconeSelecionado: _iconeSelecionado,
      ),
    );
    
    if (iconeEscolhido != null) {
      setState(() {
        _iconeSelecionado = iconeEscolhido;
      });
    }
  }

  Future<void> _salvarCategoria() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _salvando = true);

    try {
      // Converter ícone para string (seguindo arquivo offline)
      String iconeParaSalvar;
      if (_iconeSelecionado is String) {
        iconeParaSalvar = _iconeSelecionado;
      } else if (_iconeSelecionado is IconData) {
        final iconData = _iconeSelecionado as IconData;
        // Converte IconData para formato icon_XXXX (como arquivo offline)
        iconeParaSalvar = 'icon_${iconData.codePoint.toRadixString(16)}';
      } else {
        iconeParaSalvar = 'folder'; // default como arquivo offline
      }
      
      
      CategoriaModel categoria;
      
      if (_isEditing) {
        // Atualizar categoria existente
        categoria = await _categoriaService.updateCategoria(
          categoriaId: widget.categoriaParaEditar!.id,
          nome: _nomeController.text.trim(),
          cor: _corSelecionada,
          icone: iconeParaSalvar,
        );
      } else {
        // Criar nova categoria
        categoria = await _categoriaService.addCategoria(
          nome: _nomeController.text.trim(),
          tipo: widget.tipo,
          cor: _corSelecionada,
          icone: iconeParaSalvar,
        );
      }

      _mostrarSucesso(
        _isEditing 
          ? 'Categoria atualizada com sucesso!' 
          : 'Categoria criada com sucesso!'
      );
      
      // Callback se fornecido
      if (widget.onCategoriaCriada != null) {
        widget.onCategoriaCriada!(categoria);
      }
      
      // Fechar modal
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, categoria);
      }
      
    } catch (e) {
      _mostrarErro('Erro ao salvar categoria: $e');
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      ),
    );
  }
}