// 📂 Categoria Form Page - iPoupei Mobile
// 
// Página para criar e editar categorias
// Formulário simples sem modal
// 
// Baseado em: Material Design + Form Pattern

import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';

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
              Wrap(
                spacing: 8,
                children: [
                  '#008080', // Default React
                  '#FF6B6B', // Vermelho
                  '#4ECDC4', // Turquesa  
                  '#45B7D1', // Azul
                  '#96CEB4', // Verde
                  '#FECA57', // Amarelo
                  '#FF9FF3', // Rosa
                  '#54A0FF', // Azul claro
                ].map((cor) => GestureDetector(
                  onTap: () => setState(() => _corSelecionada = cor),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(cor.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: _corSelecionada == cor
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                )).toList(),
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