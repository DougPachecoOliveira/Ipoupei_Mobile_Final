// 📋 Importação Final Page - iPoupei Mobile
//
// Tela de resumo final das transações categorizadas
// APENAS MOSTRA o que foi editado, SEM MODIFICAR NADA
// Permite selecionar quais importar
//
// Princípio: FIDELIDADE TOTAL às edições do usuário

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

class ImportacaoFinalPage extends StatefulWidget {
  final List<TransacaoImportada> transacoes;
  final ContaModel? conta;
  final CartaoModel? cartao;
  final String tipoImportacao;

  const ImportacaoFinalPage({
    super.key,
    required this.transacoes,
    this.conta,
    this.cartao,
    required this.tipoImportacao,
  });

  @override
  State<ImportacaoFinalPage> createState() => _ImportacaoFinalPageState();
}

class _ImportacaoFinalPageState extends State<ImportacaoFinalPage> {
  final _importacaoService = ImportacaoService.instance;
  final _categoriaService = CategoriaService.instance;

  // Estados
  bool _loading = false;
  bool _salvando = false;
  List<bool> _selecionadas = [];

  // Dados para mostrar nomes
  List<CategoriaModel> _categorias = [];
  List<SubcategoriaModel> _subcategorias = [];

  @override
  void initState() {
    super.initState();
    // Todas selecionadas por padrão
    _selecionadas = List.filled(widget.transacoes.length, true);
    _carregarDados();
  }

  /// Carrega categorias e subcategorias APENAS para mostrar os nomes
  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    try {
      _categorias = await _categoriaService.fetchCategorias();
      _subcategorias = await _categoriaService.fetchSubcategorias();
      debugPrint('✅ Carregado ${_categorias.length} categorias e ${_subcategorias.length} subcategorias');
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Obtém nome da categoria
  String _getNomeCategoria(String? categoriaId) {
    if (categoriaId == null || categoriaId.isEmpty) return '';

    try {
      final categoria = _categorias.firstWhere((c) => c.id == categoriaId);
      return categoria.nome;
    } catch (e) {
      return 'Categoria';
    }
  }

  /// Obtém nome da subcategoria
  String _getNomeSubcategoria(String? subcategoriaId) {
    if (subcategoriaId == null || subcategoriaId.isEmpty) return '';

    try {
      final subcategoria = _subcategorias.firstWhere((s) => s.id == subcategoriaId);
      return subcategoria.nome;
    } catch (e) {
      return '';
    }
  }

  /// Obtém categoria/subcategoria formatada
  String _getCategoriaCompleta(TransacaoImportada transacao) {
    final nomeCategoria = _getNomeCategoria(transacao.categoriaId);
    final nomeSubcategoria = _getNomeSubcategoria(transacao.subcategoriaId);

    if (nomeCategoria.isEmpty) return '';
    if (nomeSubcategoria.isEmpty) return nomeCategoria;

    return '$nomeCategoria / $nomeSubcategoria';
  }

  /// Verifica se transação está completa (categoria E subcategoria)
  bool _transacaoCompleta(TransacaoImportada transacao) {
    return transacao.categoriaId != null &&
           transacao.categoriaId!.isNotEmpty &&
           transacao.subcategoriaId != null &&
           transacao.subcategoriaId!.isNotEmpty;
  }

  /// Conta quantas estão prontas
  int _contarProntas() {
    return widget.transacoes.where((t) => _transacaoCompleta(t)).length;
  }

  /// Conta quantas estão selecionadas
  int _contarSelecionadas() {
    return _selecionadas.where((s) => s).length;
  }

  /// Importa as transações selecionadas
  Future<void> _importar() async {
    final transacoesParaImportar = <TransacaoImportada>[];

    for (int i = 0; i < widget.transacoes.length; i++) {
      if (_selecionadas[i]) {
        transacoesParaImportar.add(widget.transacoes[i]);
      }
    }

    if (transacoesParaImportar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma transação')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final ids = await _importacaoService.salvarTransacoesImportadas(transacoesParaImportar);

      if (mounted) {
        // Sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${ids.length} transação(ões) importada(s) com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Voltar com resultado
        Navigator.pop(context, {
          'sucesso': true,
          'importadas': ids.length,
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao importar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prontas = _contarProntas();
    final selecionadas = _contarSelecionadas();
    final ignoradas = widget.transacoes.length - prontas;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Importar para ${widget.conta?.nome ?? widget.cartao?.nome}'),
        backgroundColor: widget.tipoImportacao == 'cartao'
            ? const Color(0xFF7C3AED)
            : AppColors.azulHeader,
        foregroundColor: Colors.white,
      ),
      body: LoadingOverlay(
        isLoading: _salvando,
        message: 'Importando transações...',
        child: Column(
          children: [
            // Header com resumo
            Container(
              padding: const EdgeInsets.all(16),
              color: widget.tipoImportacao == 'cartao'
                  ? const Color(0xFF7C3AED)
                  : AppColors.azulHeader,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResumoItem(
                          Icons.receipt_long,
                          widget.transacoes.length.toString(),
                          'Total',
                        ),
                        _buildResumoItem(
                          Icons.check_circle,
                          prontas.toString(),
                          'Válidas',
                        ),
                        _buildResumoItem(
                          Icons.warning_amber,
                          ignoradas.toString(),
                          'Ignoradas',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Categorize as transações abaixo. Somente as que tiverem categoria E subcategoria serão importadas.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (ignoradas > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(52),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withAlpha(130)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '$ignoradas transação(ões) sem categoria completa',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Lista de transações
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.transacoes.length,
                      itemBuilder: (context, index) {
                        return _buildTransacaoCard(index);
                      },
                    ),
            ),

            // Botão de importar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: selecionadas > 0 ? _importar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.file_download),
                      const SizedBox(width: 8),
                      Text(
                        'Importar $selecionadas Transações',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(IconData icon, String valor, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTransacaoCard(int index) {
    final transacao = widget.transacoes[index];
    final completa = _transacaoCompleta(transacao);
    final categoriaNome = _getCategoriaCompleta(transacao);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completa ? Colors.green.withAlpha(78) : Colors.orange.withAlpha(78),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: completa ? Colors.green.withAlpha(26) : Colors.orange.withAlpha(26),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selecionadas[index],
                  onChanged: completa
                      ? (value) {
                          setState(() {
                            _selecionadas[index] = value ?? false;
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transacao.descricao,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(transacao.data),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transacao.tipo == 'receita' ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                if (completa)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRONTA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Categoria
          if (categoriaNome.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: completa ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✓ $categoriaNome',
                      style: TextStyle(
                        fontSize: 12,
                        color: completa ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sem categoria completa',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
