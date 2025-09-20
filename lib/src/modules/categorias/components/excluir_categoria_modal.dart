// 🗑️ Modal de Exclusão de Categoria - iPoupei Mobile
// 
// Modal para excluir categoria com validação de dependências
// Funcionalidades:
// - Verificar se categoria tem transações/subcategorias
// - Forçar migração se necessário
// - Exclusão direta se não houver dependências
// - Loading states e tratamento de erros

import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';
import '../../shared/theme/app_colors.dart';
import '../data/categoria_icons.dart';
import 'migrar_categoria_modal.dart';

class ExcluirCategoriaModal extends StatefulWidget {
  final CategoriaModel categoria;
  final List<CategoriaModel> todasCategorias;

  const ExcluirCategoriaModal({
    super.key,
    required this.categoria,
    required this.todasCategorias,
  });

  @override
  State<ExcluirCategoriaModal> createState() => _ExcluirCategoriaModalState();
}

class _ExcluirCategoriaModalState extends State<ExcluirCategoriaModal> {
  bool _isLoading = true;
  Map<String, dynamic>? _dependencias;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _verificarDependencias();
  }

  Future<void> _verificarDependencias() async {
    try {
      final resultado = await CategoriaService.instance.verificarDependenciasCategoria(widget.categoria.id);
      setState(() {
        _dependencias = resultado;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao verificar dependências: $e')),
      );
    }
  }

  Future<void> _excluirDiretamente() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a categoria "${widget.categoria.nome}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.vermelhoErro),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isDeleting = true);

    try {
      final resultado = await CategoriaService.instance.excluirCategoriaSeguro(
        categoriaId: widget.categoria.id,
      );

      if (resultado['success']) {
        Navigator.pop(context, {
          'success': true,
          'message': resultado['message'],
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['error'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na exclusão: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _abrirModalMigracao() async {
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: MigrarCategoriaModal(
          categoriaOrigem: widget.categoria,
          qtdTransacoes: _dependencias?['qtdTransacoes'] ?? 0,
          qtdSubcategorias: _dependencias?['qtdSubcategorias'] ?? 0,
          categoriasDisponiveis: widget.todasCategorias,
        ),
      ),
    );

    if (resultado != null && resultado['success']) {
      // Migração bem-sucedida - opção: só migrar OU migrar + excluir
      if (resultado['onlyMigrate'] == true) {
        // Apenas migração, sem exclusão
        Navigator.pop(context, {
          'success': true,
          'message': 'Dados migrados com sucesso (categoria mantida)',
          'migrationResult': resultado,
        });
        return;
      }
      
      // Migração bem-sucedida, agora excluir a categoria
      setState(() => _isDeleting = true);

      try {
        final exclusao = await CategoriaService.instance.excluirCategoriaSeguro(
          categoriaId: widget.categoria.id,
          categoriaDestinoId: resultado['categoriaDestinoId'],
        );

        if (exclusao['success']) {
          Navigator.pop(context, {
            'success': true,
            'message': 'Categoria excluída após migração dos dados',
            'migrationResult': resultado,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(exclusao['error'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na exclusão final: $e')),
        );
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.vermelhoErro.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.vermelhoErro,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Excluir Categoria',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                    Text(
                      '"${widget.categoria.nome}"',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Categoria info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cinzaClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(widget.categoria.cor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CategoriaIcons.renderIcon(
                      widget.categoria.icone,
                      24,
                      color: _parseColor(widget.categoria.cor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoria.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                      Text(
                        widget.categoria.tipo == 'receita' ? 'Categoria de Receita' : 'Categoria de Despesa',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Conteúdo baseado no estado
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_dependencias?['success'] != true)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.vermelhoErro10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.vermelhoErro30),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.vermelhoErro,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Erro ao verificar dependências da categoria.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.vermelhoErro,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_dependencias!['temDependencias'])
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.amareloAlerta10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amareloAlerta30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: AppColors.amareloAlerta,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Categoria possui dados vinculados',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amareloAlerta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_dependencias!['qtdTransacoes'] > 0)
                        Text(
                          '• ${_dependencias!['qtdTransacoes']} transação${_dependencias!['qtdTransacoes'] > 1 ? 'ões' : ''} vinculada${_dependencias!['qtdTransacoes'] > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.amareloAlerta,
                          ),
                        ),
                      if (_dependencias!['qtdSubcategorias'] > 0)
                        Text(
                          '• ${_dependencias!['qtdSubcategorias']} subcategoria${_dependencias!['qtdSubcategorias'] > 1 ? 's' : ''} vinculada${_dependencias!['qtdSubcategorias'] > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.amareloAlerta,
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'É necessário migrar estes dados para outra categoria antes de excluir.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.amareloAlerta,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.verdeSucesso10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.verdeSucesso30),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.verdeSucesso,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta categoria não possui dados vinculados e pode ser excluída com segurança.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.verdeSucesso,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Botões
          if (!_isLoading && _dependencias?['success'] == true)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isDeleting ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting
                        ? null
                        : _dependencias!['temDependencias']
                            ? _abrirModalMigracao
                            : _excluirDiretamente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dependencias!['temDependencias']
                          ? AppColors.tealPrimary
                          : AppColors.vermelhoErro,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _dependencias!['temDependencias'] ? 'Migrar e Excluir' : 'Excluir',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          
          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('0xFF${colorString.substring(1)}'));
      }
      return AppColors.tealPrimary;
    } catch (e) {
      return AppColors.tealPrimary;
    }
  }
}