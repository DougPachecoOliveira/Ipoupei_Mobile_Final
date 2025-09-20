// 🔄 Modal de Migração de Categoria - iPoupei Mobile
// 
// Modal para migrar dados de uma categoria para outra
// Funcionalidades:
// - Seletor de categoria destino
// - Exibir resumo do que será migrado
// - Validações e confirmações
// - Loading states

import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../data/categoria_icons.dart';

class MigrarCategoriaModal extends StatefulWidget {
  final CategoriaModel categoriaOrigem;
  final int qtdTransacoes;
  final int qtdSubcategorias;
  final List<CategoriaModel> categoriasDisponiveis;

  const MigrarCategoriaModal({
    super.key,
    required this.categoriaOrigem,
    required this.qtdTransacoes,
    required this.qtdSubcategorias,
    required this.categoriasDisponiveis,
  });

  @override
  State<MigrarCategoriaModal> createState() => _MigrarCategoriaModalState();
}

class _MigrarCategoriaModalState extends State<MigrarCategoriaModal> {
  CategoriaModel? _categoriaDestino;
  bool _isLoading = false;

  List<CategoriaModel> get _categoriasCompatveis {
    return widget.categoriasDisponiveis
        .where((categoria) => 
            categoria.tipo == widget.categoriaOrigem.tipo && // Mesmo tipo
            categoria.id != widget.categoriaOrigem.id && // Não a própria categoria
            categoria.ativo // Apenas categorias ativas
        )
        .toList();
  }

  Future<void> _executarMigracao() async {
    
    if (_categoriaDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria destino')),
      );
      return;
    }


    setState(() => _isLoading = true);

    try {
      
      final resultado = await CategoriaService.instance.migrarCategoria(
        categoriaOrigemId: widget.categoriaOrigem.id,
        categoriaDestinoId: _categoriaDestino!.id,
      );


      if (resultado['success']) {
        Navigator.pop(context, {
          'success': true,
          'message': resultado['message'],
          'categoriaDestinoId': _categoriaDestino!.id,
          'transacoesMigradas': resultado['transacoesMigradas'],
          'subcategoriasMigradas': resultado['subcategoriasMigradas'],
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['error'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na migração: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                  color: AppColors.tealPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: AppColors.tealPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Migrar Categoria',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                    Text(
                      'Transferir dados de "${widget.categoriaOrigem.nome}"',
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
          
          // Resumo do que será migrado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cinzaClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O que será migrado:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.qtdTransacoes > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 18,
                        color: AppColors.tealPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.qtdTransacoes} transação${widget.qtdTransacoes > 1 ? 'ões' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                if (widget.qtdSubcategorias > 0) ...[
                  if (widget.qtdTransacoes > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 18,
                        color: AppColors.tealPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.qtdSubcategorias} subcategoria${widget.qtdSubcategorias > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Seletor de categoria destino
          const Text(
            'Categoria destino:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_categoriasCompatveis.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.amareloAlerta10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amareloAlerta30),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppColors.amareloAlerta,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nenhuma categoria compatível encontrada. Crie uma categoria do mesmo tipo primeiro.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.amareloAlerta,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categoriasCompatveis.length,
                itemBuilder: (context, index) {
                  final categoria = _categoriasCompatveis[index];
                  final isSelected = _categoriaDestino?.id == categoria.id;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _categoriaDestino = categoria),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.tealPrimary.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.tealPrimary : AppColors.cinzaBorda,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _parseColor(categoria.cor).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: CategoriaIcons.renderIcon(categoria.icone, 20,
                                    color: _parseColor(categoria.cor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoria.nome,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? AppColors.tealPrimary : AppColors.cinzaEscuro,
                                      ),
                                    ),
                                    Text(
                                      categoria.tipo == 'receita' ? 'Receita' : 'Despesa',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.cinzaTexto,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.tealPrimary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Botões
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                  onPressed: _isLoading || _categoriaDestino == null || _categoriasCompatveis.isEmpty
                      ? null
                      : _executarMigracao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Migrar Dados',
                          style: TextStyle(
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