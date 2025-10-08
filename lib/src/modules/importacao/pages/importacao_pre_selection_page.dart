// 📋 Importação Pre-Selection Page - iPoupei Mobile
//
// Página com todos os cards pré-selecionados
// User pode desmarcar os que não quer
// Efeito visual de seleção/deseleção
// Salva direto no Supabase igual TransacaoFormPage
//
// Baseado em: CheckboxListTile + batch processing + visual feedback

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transacao_importada_model.dart';
import '../services/importacao_service.dart';
import '../../contas/models/conta_model.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../categorias/services/categoria_service.dart';
import '../../categorias/models/categoria_model.dart';
import '../../shared/theme/app_colors.dart';
import '../../auth/components/loading_overlay.dart';

/// Página de pré-seleção de transações importadas
class ImportacaoPreSelectionPage extends StatefulWidget {
  final List<TransacaoImportada> transacoes;
  final ContaModel? conta;
  final CartaoModel? cartao;
  final String tipoImportacao; // 'conta' ou 'cartao'

  const ImportacaoPreSelectionPage({
    super.key,
    required this.transacoes,
    this.conta,
    this.cartao,
    required this.tipoImportacao,
  });

  @override
  State<ImportacaoPreSelectionPage> createState() => _ImportacaoPreSelectionPageState();
}

class _ImportacaoPreSelectionPageState extends State<ImportacaoPreSelectionPage> {
  final _importacaoService = ImportacaoService.instance;
  final _categoriaService = CategoriaService.instance;

  // Estados
  bool _loading = false;
  bool _salvando = false;
  final Map<int, TransacaoImportada> _transacoesEditadas = {};
  List<CategoriaModel> _categorias = [];

  @override
  void initState() {
    super.initState();

    // 🎯 IMPORTANTE: Inicializar ANTES de qualquer build
    _inicializarTransacoes();

    // Carregar categorias (pode ser assíncrono)
    _carregarCategorias();
  }

  /// Inicializa todas as transações editáveis
  void _inicializarTransacoes() {
    log('🔧 Inicializando ${widget.transacoes.length} transações');
    for (int i = 0; i < widget.transacoes.length; i++) {
      _transacoesEditadas[i] = widget.transacoes[i];
    }
  }

  /// Carrega categorias para auto-categorização
  Future<void> _carregarCategorias() async {
    setState(() => _loading = true);
    try {
      _categorias = await _categoriaService.listarCategorias();
      _autoCategorizarTransacoes();
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Auto-categoriza todas as transações
  void _autoCategorizarTransacoes() {
    for (int i = 0; i < widget.transacoes.length; i++) {
      final transacao = widget.transacoes[i];

      // Auto-detectar categoria baseado na descrição
      final categoriaDetectada = _detectarCategoria(transacao.descricao, transacao.tipo);

      if (categoriaDetectada != null) {
        _transacoesEditadas[i] = TransacaoImportada(
          id: transacao.id,
          data: transacao.data,
          descricao: transacao.descricao,
          valor: transacao.valor,
          tipo: transacao.tipo,
          origem: transacao.origem,
          usuarioId: transacao.usuarioId,
          contaId: transacao.contaId,
          cartaoId: transacao.cartaoId,
          categoriaId: categoriaDetectada.id,
          subcategoriaId: transacao.subcategoriaId,
          faturaVencimento: transacao.faturaVencimento,
          efetivado: transacao.efetivado,
          observacoes: transacao.observacoes,
          linhaBruta: transacao.linhaBruta,
          indiceOriginal: transacao.indiceOriginal,
          metadados: transacao.metadados,
        );
      }
    }
    setState(() {});
  }

  /// Detecta categoria automaticamente
  CategoriaModel? _detectarCategoria(String descricao, String tipo) {
    final descricaoLower = descricao.toLowerCase();

    // Procurar categoria que contenha palavras-chave da descrição
    for (final categoria in _categorias) {
      if (categoria.tipo.toLowerCase() == tipo.toLowerCase()) {
        final nomeCategoria = categoria.nome.toLowerCase();

        // Verificações específicas
        if ((nomeCategoria.contains('alimentação') || nomeCategoria.contains('comida')) &&
            (descricaoLower.contains('ifood') || descricaoLower.contains('uber eats') ||
             descricaoLower.contains('rappi') || descricaoLower.contains('mercado'))) {
          return categoria;
        }

        if ((nomeCategoria.contains('transporte')) &&
            (descricaoLower.contains('uber') || descricaoLower.contains('99') ||
             descricaoLower.contains('posto') || descricaoLower.contains('gasolina'))) {
          return categoria;
        }

        if ((nomeCategoria.contains('saúde')) &&
            (descricaoLower.contains('farmacia') || descricaoLower.contains('hospital'))) {
          return categoria;
        }

        // Fallback: primeira categoria do tipo
        if (categoria.tipo.toLowerCase() == tipo.toLowerCase()) {
          return categoria;
        }
      }
    }

    return null;
  }

  /// Conta transações válidas (com categoria e subcategoria)
  int get _transacoesValidasCount {
    return _transacoesEditadas.values.where((t) =>
      t.categoriaId != null &&
      t.categoriaId!.isNotEmpty &&
      t.subcategoriaId != null &&
      t.subcategoriaId!.isNotEmpty
    ).length;
  }

  /// Conta transações que serão ignoradas
  int get _transacoesIgnoradasCount {
    return widget.transacoes.length - _transacoesValidasCount;
  }

  /// Salva transações válidas (com categoria e subcategoria)
  Future<void> _salvarTransacoes() async {
    log('🚀 [SALVAR] Iniciando salvamento das transações...');

    // Filtrar apenas transações válidas
    final transacoesParaSalvar = _transacoesEditadas.values
        .where((t) =>
          t.categoriaId != null &&
          t.categoriaId!.isNotEmpty &&
          t.subcategoriaId != null &&
          t.subcategoriaId!.isNotEmpty
        )
        .toList();

    log('💾 [SALVAR] Total de transações válidas: ${transacoesParaSalvar.length}');
    log('⚠️ [SALVAR] Total de transações ignoradas: $_transacoesIgnoradasCount');

    if (transacoesParaSalvar.isEmpty) {
      _mostrarSnackBar('Nenhuma transação possui categoria e subcategoria definidas', isError: true);
      return;
    }

    setState(() => _salvando = true);

    try {
      final resultados = await _importacaoService.salvarTransacoesImportadas(transacoesParaSalvar);

      if (resultados.isNotEmpty) {
        _mostrarSnackBar('${resultados.length} transações salvas com sucesso!', isError: false);

        // Aguardar um pouco para mostrar o feedback
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'transacoesSalvas': resultados.length,
            'totalImportadas': transacoesParaSalvar.length,
          });
        }
      } else {
        _mostrarSnackBar('Erro ao salvar transações', isError: true);
      }
    } catch (e) {
      _mostrarSnackBar('Erro: ${e.toString()}', isError: true);
    } finally {
      setState(() => _salvando = false);
    }
  }

  /// Mostra SnackBar
  void _mostrarSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.vermelhoErro : AppColors.verdeSucesso,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          widget.tipoImportacao == 'cartao'
              ? 'Importar para ${widget.cartao?.nome ?? "Cartão"}'
              : 'Importar para ${widget.conta?.nome ?? "Conta"}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.azulHeader,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _loading || _salvando,
        child: Column(
          children: [
            // Header com estatísticas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.azulHeader,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Total',
                        '${widget.transacoes.length}',
                        Icons.receipt_long,
                        Colors.white,
                      ),
                      _buildStatCard(
                        'Válidas',
                        '$_transacoesValidasCount',
                        Icons.check_circle,
                        AppColors.verdeSucesso,
                      ),
                      _buildStatCard(
                        'Ignoradas',
                        '$_transacoesIgnoradasCount',
                        Icons.warning_amber,
                        _transacoesIgnoradasCount > 0 ? Colors.orange : Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Categorize as transações abaixo. Somente as que tiverem categoria E subcategoria serão importadas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(234),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_transacoesIgnoradasCount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(52),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$_transacoesIgnoradasCount transação(ões) sem categoria completa',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lista de transações
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.transacoes.length,
                itemBuilder: (context, index) {
                  final transacao = widget.transacoes[index];
                  final transacaoEditada = _transacoesEditadas[index] ?? transacao;

                  // Verifica se tem categoria e subcategoria
                  final temCategoriaCompleta = transacaoEditada.categoriaId != null &&
                                               transacaoEditada.categoriaId!.isNotEmpty &&
                                               transacaoEditada.subcategoriaId != null &&
                                               transacaoEditada.subcategoriaId!.isNotEmpty;

                  return InkWell(
                    onTap: () => _editarTransacao(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: temCategoriaCompleta
                            ? AppColors.verdeSucesso.withAlpha(12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: temCategoriaCompleta ? AppColors.verdeSucesso : Colors.orange.shade300,
                          width: temCategoriaCompleta ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: temCategoriaCompleta
                                ? AppColors.verdeSucesso.withAlpha(52)
                                : Colors.orange.withAlpha(26),
                            blurRadius: temCategoriaCompleta ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                        children: [
                          // CHECKBOX - Auto-marcado quando categoria E subcategoria estão preenchidas
                          Transform.scale(
                            scale: 1.3,
                            child: Checkbox(
                              value: temCategoriaCompleta,
                              onChanged: null, // Read-only - apenas visual indicativo
                              fillColor: WidgetStateProperty.resolveWith((states) {
                                if (temCategoriaCompleta) {
                                  return AppColors.verdeSucesso;
                                }
                                return Colors.grey.shade400;
                              }),
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                              // Informações da transação
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Descrição - destaque se válida
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            transacao.descricao,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: temCategoriaCompleta
                                                  ? AppColors.verdeSucesso.withAlpha(234)
                                                  : AppColors.textoEscuro,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (temCategoriaCompleta) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.verdeSucesso,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'PRONTA',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    // Data e valor
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(transacao.data),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textoSecundario,
                                          ),
                                        ),
                                        Text(
                                          'R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: transacao.tipo == 'receita'
                                                ? AppColors.verdeSucesso
                                                : AppColors.vermelhoErro,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    // Status de categorização - destacado
                                    const SizedBox(height: 8),
                                    if (temCategoriaCompleta) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.verdeSucesso.withAlpha(26),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.verdeSucesso.withAlpha(78),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: AppColors.verdeSucesso,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                '✓ ${_getNomeCategoria(transacaoEditada.categoriaId!)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.verdeSucesso,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withAlpha(26),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.orange.withAlpha(78),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 16,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Categorização incompleta',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange.shade800,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Ícone de tipo
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: transacao.tipo == 'receita'
                                      ? AppColors.verdeSucesso.withAlpha(26)
                                      : AppColors.vermelhoErro.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  transacao.tipo == 'receita'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: transacao.tipo == 'receita'
                                      ? AppColors.verdeSucesso
                                      : AppColors.vermelhoErro,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                },
              ),
            ),
          ],
        ),
      ),

      // Botão flutuante para salvar
      floatingActionButton: _transacoesValidasCount > 0
          ? FloatingActionButton.extended(
              onPressed: _salvando ? null : _salvarTransacoes,
              backgroundColor: AppColors.verdeSucesso,
              icon: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _salvando
                    ? 'Salvando...'
                    : 'Importar $_transacoesValidasCount Transações',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  /// Constrói card de estatística
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withAlpha(208),
            fontSize: 12,
          ),
        ),
      ],
    );
  }


  /// Obtém nome da categoria
  String _getNomeCategoria(String categoriaId) {
    try {
      final categoria = _categorias.firstWhere((c) => c.id == categoriaId);
      return categoria.nome;
    } catch (e) {
      return 'Categoria detectada';
    }
  }

  /// Abre modal para editar categoria/subcategoria
  Future<void> _editarTransacao(int index) async {
    final transacao = _transacoesEditadas[index] ?? widget.transacoes[index];

    // Aqui você pode abrir um modal ou navegar para uma tela de edição
    // Por enquanto, vou apenas fazer um debug
    log('🔧 Editar transação $index: ${transacao.descricao}');

    // TODO: Implementar modal de edição com SmartFields
    _mostrarSnackBar('Clique no card para editar categoria/subcategoria', isError: false);
  }
}