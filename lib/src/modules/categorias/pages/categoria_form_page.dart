// 📂 Categoria Form Page - iPoupei Mobile
// 
// Página para criar e editar categorias
// Formulário simples sem modal
// 
// Baseado em: Material Design + Form Pattern

import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';
import '../../../shared/components/color_picker/advanced_color_picker.dart';
import '../../../shared/components/color_picker/models/color_picker_config.dart';

class CategoriaFormPage extends StatefulWidget {
  final String modo; // 'criar' ou 'editar'
  final String? tipo; // Para criar nova categoria
  final CategoriaModel? categoria; // Para editar categoria existente

  const CategoriaFormPage({
    super.key,
    required this.modo,
    this.tipo,
    this.categoria,
  });

  @override
  State<CategoriaFormPage> createState() => _CategoriaFormPageState();
}

class _CategoriaFormPageState extends State<CategoriaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoriaService = CategoriaService.instance;
  
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  
  String _tipoSelecionado = 'despesa';
  String _corSelecionada = '#008080';  // Default igual React
  String _iconeSelecionado = '📁';      // Default igual React
  
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    
    _nomeController = TextEditingController();
    _descricaoController = TextEditingController();
    
    if (widget.modo == 'criar' && widget.tipo != null) {
      _tipoSelecionado = widget.tipo!;
    } else if (widget.modo == 'editar' && widget.categoria != null) {
      _nomeController.text = widget.categoria!.nome;
      _descricaoController.text = widget.categoria!.descricao ?? '';
      _tipoSelecionado = widget.categoria!.tipo ?? 'despesa';
      _corSelecionada = widget.categoria!.cor ?? '#008080';
      _iconeSelecionado = widget.categoria!.icone ?? '📁';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  /// 💾 SALVAR CATEGORIA
  Future<void> _salvarCategoria() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      if (widget.modo == 'criar') {
        await _categoriaService.addCategoria(
          nome: _nomeController.text.trim(),
          tipo: _tipoSelecionado,
          cor: _corSelecionada,
          icone: _iconeSelecionado,
          descricao: _descricaoController.text.trim().isEmpty 
              ? null 
              : _descricaoController.text.trim(),
        );
      } else {
        await _categoriaService.updateCategoria(
          categoriaId: widget.categoria!.id,
          nome: _nomeController.text.trim(),
          tipo: _tipoSelecionado,
          cor: _corSelecionada,
          icone: _iconeSelecionado,
          descricao: _descricaoController.text.trim().isEmpty 
              ? null 
              : _descricaoController.text.trim(),
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar categoria: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🎨 Modal com todas as cores estendidas usando o novo seletor
  Future<void> _mostrarModalCoresExtendidas() async {
    final selectedColor = await AdvancedColorPicker.show(
      context: context,
      type: ColorPickerType.category,
      currentColor: _corSelecionada,
      categoryType: _tipoSelecionado, // Sugerir cores baseadas no tipo
    );
    if (selectedColor != null) {
      setState(() {
        _corSelecionada = selectedColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        title: Text(widget.modo == 'criar' ? 'Nova Categoria' : 'Editar Categoria'),
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _salvarCategoria,
              child: const Text(
                'Salvar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome da categoria
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da categoria',
                  border: OutlineInputBorder(),
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
              ),
              
              const SizedBox(height: 16),
              
              // Tipo
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'receita', child: Text('Receita')),
                  DropdownMenuItem(value: 'despesa', child: Text('Despesa')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _tipoSelecionado = value);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Descrição (opcional)
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 200) {
                    return 'Descrição deve ter no máximo 200 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Ícone
              Text(
                'Ícone',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Ícone 1: 📁
                  GestureDetector(
                    onTap: () => setState(() => _iconeSelecionado = '📁'),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _iconeSelecionado == '📁' ? Colors.blue : Colors.grey,
                          width: _iconeSelecionado == '📁' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('📁', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ícone 2: 💰
                  GestureDetector(
                    onTap: () => setState(() => _iconeSelecionado = '💰'),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _iconeSelecionado == '💰' ? Colors.blue : Colors.grey,
                          width: _iconeSelecionado == '💰' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('💰', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Cor (básica)
              Text(
                'Cor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    // Lista de cores principais (mesmas de contas/cartões)
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          final coresDisponiveis = [
                            '#8A05BE', // Roxo Nubank
                            '#FF6500', // Laranja Inter
                            '#FFD700', // Amarelo C6
                            '#21C25E', // Verde PicPay
                            '#DC143C', // Vermelho Santander
                            '#1E3A8A', // Azul BTG
                            '#000000', // Preto XP
                            '#6B7280', // Cinza Padrão
                          ];

                          final cor = coresDisponiveis[index];
                          final corAtual = Color(int.parse(cor.replaceFirst('#', '0xFF')));
                          final selecionada = cor == _corSelecionada;

                          return Container(
                            margin: EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _corSelecionada = cor;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: corAtual,
                                  shape: BoxShape.circle,
                                  border: selecionada
                                      ? Border.all(color: Colors.grey[400]!, width: 3)
                                      : Border.all(color: Colors.grey[300]!, width: 1),
                                ),
                                child: selecionada
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Botão "Mais Cores"
                    GestureDetector(
                      onTap: _mostrarModalCoresExtendidas,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Icon(Icons.add, color: Colors.grey, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botão salvar (repetido para melhor UX)
              ElevatedButton(
                onPressed: _loading ? null : _salvarCategoria,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.modo == 'criar' ? 'Criar Categoria' : 'Salvar Alterações',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}