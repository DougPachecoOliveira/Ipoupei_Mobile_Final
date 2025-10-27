// 📱 Transação Import Card - iPoupei Mobile
//
// Card para revisão de transações importadas
// Design mobile-first com SmartFields igual ao transacao_form_page
// Auto-seleção de categoria/subcategoria
//
// Baseado em: SmartField + transacao_form_page + design de cards

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transacao_importada_model.dart';
import '../../transacoes/components/smart_field.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';
import '../../categorias/data/categoria_icons.dart';
import '../../shared/theme/app_colors.dart';
import '../../contas/models/conta_model.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../cartoes/services/cartao_data_service.dart';
import '../../cartoes/models/fatura_model.dart';

/// Card para revisão e edição de transação importada
class TransacaoImportCard extends StatefulWidget {
  final TransacaoImportada transacao;
  final int index;
  final int total;
  final VoidCallback onSave;
  final VoidCallback onSkip;
  final ContaModel? conta;
  final CartaoModel? cartao;
  final Function(TransacaoImportada) onTransacaoChanged;

  const TransacaoImportCard({
    super.key,
    required this.transacao,
    required this.index,
    required this.total,
    required this.onSave,
    required this.onSkip,
    this.conta,
    this.cartao,
    required this.onTransacaoChanged,
  });

  @override
  State<TransacaoImportCard> createState() => _TransacaoImportCardState();
}

class _TransacaoImportCardState extends State<TransacaoImportCard> {
  final _categoriaService = CategoriaService.instance;
  final _cartaoDataService = CartaoDataService.instance;

  // Controllers para campos editáveis
  final _categoriaController = TextEditingController();
  final _subcategoriaController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _dataController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  // Estados
  List<CategoriaModel> _categorias = [];
  List<SubcategoriaModel> _subcategorias = [];
  CategoriaModel? _categoriaEscolhida;
  SubcategoriaModel? _subcategoriaEscolhida;
  TransacaoImportada _transacaoEditada = TransacaoImportada(
    id: '', data: DateTime.now(), descricao: '', valor: 0, tipo: '', origem: '', usuarioId: '',
  );

  bool _loading = false;
  bool _autoCategorizando = false;

  @override
  void initState() {
    super.initState();
    _transacaoEditada = widget.transacao;
    _inicializarCampos();
    _carregarCategorias();
    _tentarAutoCategorizacao();
  }

  @override
  void dispose() {
    _categoriaController.dispose();
    _subcategoriaController.dispose();
    _observacoesController.dispose();
    _dataController.dispose();
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  /// Inicializa campos com valores da transação
  void _inicializarCampos() {
    _dataController.text = DateFormat('dd/MM/yyyy').format(_transacaoEditada.data);
    _valorController.text = 'R\$ ${_transacaoEditada.valor.toStringAsFixed(2).replaceAll('.', ',')}';
    _descricaoController.text = _transacaoEditada.descricao;
    _observacoesController.text = _transacaoEditada.observacoes;
  }

  /// Carrega categorias e subcategorias
  Future<void> _carregarCategorias() async {
    setState(() => _loading = true);

    try {
      final categorias = await _categoriaService.fetchCategorias();
      final subcategorias = await _categoriaService.fetchSubcategorias();

      setState(() {
        _categorias = categorias
            .where((c) => c.tipo == _transacaoEditada.tipo && c.ativo)
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
        _subcategorias = subcategorias.where((s) => s.ativo).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar categorias: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Tenta auto-categorização baseada na descrição
  Future<void> _tentarAutoCategorizacao() async {
    if (_autoCategorizando) return;

    setState(() => _autoCategorizando = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final descricao = _transacaoEditada.descricao.toLowerCase();
      String? categoriaNome;
      String? subcategoriaNome;

      // Auto-detecção baseada em padrões
      if (_transacaoEditada.tipo == 'receita') {
        if (descricao.contains('salario') || descricao.contains('salário')) {
          categoriaNome = 'Salário';
        } else if (descricao.contains('freelance') || descricao.contains('extra')) {
          categoriaNome = 'Freelance';
        } else if (descricao.contains('pix') || descricao.contains('transferencia')) {
          categoriaNome = 'Transferência';
        }
      } else {
        // Despesas
        if (descricao.contains('ifood') || descricao.contains('rappi') ||
            descricao.contains('uber eats')) {
          categoriaNome = 'Alimentação';
          subcategoriaNome = 'Delivery';
        } else if (descricao.contains('mercado') || descricao.contains('supermercado') ||
                   descricao.contains('padaria') || descricao.contains('açougue')) {
          categoriaNome = 'Alimentação';
          subcategoriaNome = 'Supermercado';
        } else if (descricao.contains('uber') || descricao.contains('99') ||
                   descricao.contains('cabify') || descricao.contains('taxi')) {
          categoriaNome = 'Transporte';
          subcategoriaNome = 'Aplicativo';
        } else if (descricao.contains('posto') || descricao.contains('gasolina') ||
                   descricao.contains('etanol') || descricao.contains('combustivel')) {
          categoriaNome = 'Transporte';
          subcategoriaNome = 'Combustível';
        } else if (descricao.contains('netflix') || descricao.contains('spotify') ||
                   descricao.contains('amazon prime') || descricao.contains('disney')) {
          categoriaNome = 'Lazer';
          subcategoriaNome = 'Streaming';
        } else if (descricao.contains('farmacia') || descricao.contains('drogaria') ||
                   descricao.contains('hospital') || descricao.contains('clinica')) {
          categoriaNome = 'Saúde';
          subcategoriaNome = 'Medicamentos';
        }
      }

      // Aplicar auto-detecção se encontrou padrão
      if (categoriaNome != null) {
        final categoria = _categorias.firstWhere(
          (c) => c.nome.toLowerCase().contains(categoriaNome!.toLowerCase()),
          orElse: () => CategoriaModel(
            id: '',
            nome: '',
            tipo: '',
            icone: '',
            cor: '',
            ativo: false,
            usuarioId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (categoria.id.isNotEmpty) {
          setState(() {
            _categoriaEscolhida = categoria;
            _categoriaController.text = categoria.nome;
          });

          _atualizarTransacao(categoriaId: categoria.id);

          // Auto-selecionar subcategoria se especificada
          if (subcategoriaNome != null) {
            final subcategoria = _subcategorias.firstWhere(
              (s) => s.categoriaId == categoria.id &&
                     s.nome.toLowerCase().contains(subcategoriaNome!.toLowerCase()),
              orElse: () => SubcategoriaModel(
                id: '',
                nome: '',
                categoriaId: '',
                ativo: false,
                usuarioId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            if (subcategoria.id.isNotEmpty) {
              setState(() {
                _subcategoriaEscolhida = subcategoria;
                _subcategoriaController.text = subcategoria.nome;
              });

              _atualizarTransacao(subcategoriaId: subcategoria.id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro na auto-categorização: $e');
    } finally {
      setState(() => _autoCategorizando = false);
    }
  }

  /// Seleciona categoria
  Future<void> _selecionarCategoria() async {
    if (_categorias.isEmpty) return;

    final categoria = await showModalBottomSheet<CategoriaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCategoriaSelector(),
    );

    if (categoria != null) {
      setState(() {
        _categoriaEscolhida = categoria;
        _categoriaController.text = categoria.nome;

        // Limpar subcategoria ao trocar categoria
        _subcategoriaEscolhida = null;
        _subcategoriaController.text = '';
      });

      _atualizarTransacao(
        categoriaId: categoria.id,
        subcategoriaId: null,
      );

      // Auto-abrir subcategoria após selecionar categoria
      Future.delayed(const Duration(milliseconds: 300), () {
        _selecionarSubcategoria();
      });
    }
  }

  /// Seleciona subcategoria
  Future<void> _selecionarSubcategoria() async {
    if (_categoriaEscolhida == null) return;

    debugPrint('🔍 FILTRO SUBCATEGORIAS:');
    debugPrint('   Categoria escolhida: ${_categoriaEscolhida!.nome} (ID: ${_categoriaEscolhida!.id})');
    debugPrint('   Total de subcategorias carregadas: ${_subcategorias.length}');

    // Tentar filtrar localmente primeiro
    var subcategoriasDisponiveis = _subcategorias
        .where((s) => s.categoriaId == _categoriaEscolhida!.id)
        .toList();

    debugPrint('   Subcategorias compatíveis (local): ${subcategoriasDisponiveis.length}');

    // Se não encontrou localmente, buscar do servidor
    if (subcategoriasDisponiveis.isEmpty) {
      debugPrint('   🔄 Nenhuma subcategoria encontrada localmente, buscando do servidor...');

      try {
        final subcategoriasServidor = await _categoriaService.fetchSubcategorias(
          categoriaId: _categoriaEscolhida!.id
        );

        subcategoriasDisponiveis = subcategoriasServidor.where((s) => s.ativo).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));

        debugPrint('   ✅ ${subcategoriasDisponiveis.length} subcategorias carregadas do servidor');

        if (subcategoriasDisponiveis.isEmpty) {
          debugPrint('   ⚠️ Esta categoria não possui subcategorias');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Esta categoria não possui subcategorias')),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('   ❌ Erro ao buscar subcategorias do servidor: $e');
        return;
      }
    } else {
      debugPrint('   ✅ Subcategorias encontradas localmente:');
      for (final sub in subcategoriasDisponiveis) {
        debugPrint('      - ${sub.nome}');
      }
    }

    final subcategoria = await showModalBottomSheet<SubcategoriaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSubcategoriaSelector(subcategoriasDisponiveis),
    );

    if (subcategoria != null) {
      setState(() {
        _subcategoriaEscolhida = subcategoria;
        _subcategoriaController.text = subcategoria.nome;
      });

      _atualizarTransacao(subcategoriaId: subcategoria.id);
    }
  }

  /// Atualiza transação editada
  void _atualizarTransacao({
    String? categoriaId,
    String? subcategoriaId,
    String? observacoes,
  }) {
    _transacaoEditada = _transacaoEditada.copyWith(
      categoriaId: categoriaId ?? _transacaoEditada.categoriaId,
      subcategoriaId: subcategoriaId ?? _transacaoEditada.subcategoriaId,
      observacoes: observacoes ?? _observacoesController.text,
    );

    widget.onTransacaoChanged(_transacaoEditada);
  }

  /// Constrói ícone colorido para categoria
  Widget _buildSmallColoredIcon({
    required String icone,
    Color? cor,
    Color? fallbackColor,
    double size = 18,
  }) {
    final iconColor = cor ?? fallbackColor ?? Colors.grey;

    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CategoriaIcons.renderIcon(
        icone,
        size,
        color: iconColor,
      ),
    );
  }

  /// Constrói header do card
  Widget _buildHeader() {
    // Verifica se a transação está completa (categoria E subcategoria)
    final transacaoCompleta = _categoriaEscolhida != null && _subcategoriaEscolhida != null;

    // Cor do header baseada na conta/cartão selecionado
    Color corHeader;
    if (_transacaoEditada.tipo == 'receita') {
      if (widget.conta?.cor?.isNotEmpty == true) {
        corHeader = Color(int.parse(widget.conta!.cor!.replaceAll('#', '0xFF')));
      } else {
        corHeader = Colors.teal; // Fallback para receitas
      }
    } else if (widget.cartao != null) {
      if (widget.cartao!.cor?.isNotEmpty == true) {
        corHeader = Color(int.parse(widget.cartao!.cor!.replaceAll('#', '0xFF')));
      } else {
        corHeader = const Color(0xFF7C3AED); // AppColors.roxoPrimario fallback
      }
    } else {
      if (widget.conta?.cor?.isNotEmpty == true) {
        corHeader = Color(int.parse(widget.conta!.cor!.replaceAll('#', '0xFF')));
      } else {
        corHeader = AppColors.vermelhoHeader; // Fallback para despesas
      }
    }

    String textoHeader;
    if (_transacaoEditada.tipo == 'receita') {
      textoHeader = 'Receita';
    } else if (widget.cartao != null) {
      // Calcular fatura correta baseada na data da transação e regras do cartão
      final fatura = _cartaoDataService.calcularFaturaAlvo(
        widget.cartao!,
        _transacaoEditada.data ?? DateTime.now()
      );
      textoHeader = 'Fatura ${DateFormat('MM/yyyy').format(fatura.dataVencimento)}';
    } else {
      textoHeader = 'Despesa';
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: corHeader,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Checkbox - Auto-selecionado se categoria E subcategoria estiverem preenchidas
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: transacaoCompleta,
              onChanged: null, // Read-only - apenas visual
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (transacaoCompleta) {
                  return Colors.white;
                }
                return Colors.white.withAlpha(78);
              }),
              checkColor: corHeader,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            textoHeader,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          // Indicador de status
          if (transacaoCompleta)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'PRONTA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Auto-categorização indicator
          if (_autoCategorizando)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          if (!_autoCategorizando) const SizedBox(width: 8),
          // Contador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(52),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.index} de ${widget.total}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói campos fixos (não editáveis)
  Widget _buildFixedFields() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha com data e valor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _transacaoEditada.dataFormatada,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _transacaoEditada.valorFormatado,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _transacaoEditada.tipo == 'receita'
                      ? Colors.teal
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Descrição
          Text(
            _transacaoEditada.descricao,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Info da conta/cartão
          Row(
            children: [
              widget.conta != null && widget.conta?.icone?.isNotEmpty == true
                  ? CategoriaIcons.renderIcon(
                      widget.conta!.icone,
                      16,
                      color: widget.conta != null
                          ? (widget.conta?.cor?.isNotEmpty == true
                              ? Color(int.parse(widget.conta!.cor!.replaceAll('#', '0xFF')))
                              : Colors.grey[600])
                          : (widget.cartao?.cor?.isNotEmpty == true
                              ? Color(int.parse(widget.cartao!.cor!.replaceAll('#', '0xFF')))
                              : Colors.grey[600]),
                    )
                  : Icon(
                      widget.conta != null ? Icons.account_balance : Icons.credit_card,
                      size: 16,
                      color: widget.conta != null
                          ? (widget.conta?.cor?.isNotEmpty == true
                              ? Color(int.parse(widget.conta!.cor!.replaceAll('#', '0xFF')))
                              : Colors.grey[600])
                          : (widget.cartao?.cor?.isNotEmpty == true
                              ? Color(int.parse(widget.cartao!.cor!.replaceAll('#', '0xFF')))
                              : Colors.grey[600]),
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.conta?.nome ?? widget.cartao?.nome ?? 'N/A',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Status efetivado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _transacaoEditada.efetivado ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _transacaoEditada.efetivado ? 'Efetivado' : 'Pendente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói campos editáveis
  Widget _buildEditableFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Categoria
          SmartField(
            controller: _categoriaController,
            label: 'Categoria',
            hint: 'Selecione uma categoria',
            icon: Icons.local_offer_outlined,
            leadingIcon: _categoriaEscolhida != null
                ? _buildSmallColoredIcon(
                    icone: _categoriaEscolhida!.icone,
                    cor: _categoriaEscolhida!.cor?.isNotEmpty == true
                        ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                        : null,
                    fallbackColor: _transacaoEditada.tipo == 'receita'
                        ? AppColors.tealPrimary
                        : AppColors.vermelhoHeader,
                  )
                : null,
            readOnly: true,
            onTap: _selecionarCategoria,
            isCartaoContext: widget.cartao != null,
            transactionContext: _transacaoEditada.tipo,
          ),

          const SizedBox(height: 12),

          // Subcategoria (só aparece após categoria selecionada)
          if (_categoriaEscolhida != null)
            SmartField(
              controller: _subcategoriaController,
              label: 'Subcategoria',
              hint: 'Opcional',
              icon: Icons.bookmark_outline,
              leadingIcon: _subcategoriaEscolhida != null
                  ? _buildSmallColoredIcon(
                      icone: _categoriaEscolhida!.icone,
                      cor: _categoriaEscolhida!.cor?.isNotEmpty == true
                          ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                          : null,
                      fallbackColor: _transacaoEditada.tipo == 'receita'
                          ? AppColors.tealPrimary
                          : AppColors.vermelhoHeader,
                      size: 16,
                    )
                  : null,
              readOnly: true,
              onTap: _selecionarSubcategoria,
              isCartaoContext: widget.cartao != null,
              transactionContext: _transacaoEditada.tipo,
            ),

          if (_categoriaEscolhida != null) const SizedBox(height: 12),

          // Observações
          SmartField(
            controller: _observacoesController,
            label: 'Observações',
            hint: 'Informações adicionais (opcional)',
            icon: Icons.note_outlined,
            maxLines: 2,
            onChanged: (value) => _atualizarTransacao(observacoes: value),
            isCartaoContext: widget.cartao != null,
            transactionContext: _transacaoEditada.tipo,
          ),
        ],
      ),
    );
  }

  /// Constrói ações do card
  Widget _buildActions() {
    final podeSlvar = _categoriaEscolhida != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Botão Pular
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Pular',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Botão Salvar principal
          Expanded(
            child: ElevatedButton.icon(
              onPressed: podeSlvar ? widget.onSave : null,
              icon: const Icon(Icons.check, size: 18),
              label: Text(
                widget.index == widget.total ? 'Salvar e Finalizar' : 'Salvar e Próxima',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _transacaoEditada.tipo == 'receita'
                    ? Colors.teal
                    : widget.cartao != null
                        ? const Color(0xFF7C3AED)
                        : AppColors.vermelhoHeader,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: podeSlvar ? 2 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói seletor de categoria
  Widget _buildCategoriaSelector() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'Selecionar Categoria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Lista de categorias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final corCategoria = categoria.cor?.isNotEmpty == true
                    ? Color(int.parse(categoria.cor!.replaceAll('#', '0xFF')))
                    : (_transacaoEditada.tipo == 'receita' ? Colors.teal : Colors.red);

                return ListTile(
                  leading: _buildSmallColoredIcon(
                    icone: categoria.icone,
                    cor: corCategoria,
                    size: 24,
                  ),
                  title: Text(categoria.nome),
                  onTap: () => Navigator.pop(context, categoria),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói seletor de subcategoria
  Widget _buildSubcategoriaSelector(List<SubcategoriaModel> subcategorias) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'Selecionar Subcategoria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Lista de subcategorias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subcategorias.length,
              itemBuilder: (context, index) {
                final subcategoria = subcategorias[index];

                return ListTile(
                  leading: _buildSmallColoredIcon(
                    icone: _categoriaEscolhida!.icone,
                    cor: _categoriaEscolhida!.cor?.isNotEmpty == true
                        ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                        : null,
                    fallbackColor: _transacaoEditada.tipo == 'receita'
                        ? Colors.teal
                        : Colors.red,
                    size: 20,
                  ),
                  title: Text(subcategoria.nome),
                  onTap: () => Navigator.pop(context, subcategoria),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(21),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildFixedFields(),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildEditableFields(),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _buildActions(),
        ],
      ),
    );
  }
}