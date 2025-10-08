// 📱 Importação Review Page - iPoupei Mobile
//
// Página para revisão de transações importadas
// PageView com swipe entre cards + progress + estatísticas
// Salva via TransacaoService existente
//
// Baseado em: PageView + TransacaoImportCard + batch save

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transacao_importada_model.dart';
import '../widgets/transacao_import_card.dart';
import '../services/importacao_service.dart';
import '../../contas/models/conta_model.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../shared/theme/app_colors.dart';
import '../../auth/components/loading_overlay.dart';

/// Página para revisão e aprovação de transações importadas
class ImportacaoReviewPage extends StatefulWidget {
  final List<TransacaoImportada> transacoes;
  final ContaModel? conta;
  final CartaoModel? cartao;
  final String tipoImportacao; // 'conta' ou 'cartao'

  const ImportacaoReviewPage({
    super.key,
    required this.transacoes,
    this.conta,
    this.cartao,
    required this.tipoImportacao,
  });

  @override
  State<ImportacaoReviewPage> createState() => _ImportacaoReviewPageState();
}

class _ImportacaoReviewPageState extends State<ImportacaoReviewPage>
    with TickerProviderStateMixin {
  final _importacaoService = ImportacaoService.instance;
  final _pageController = PageController();

  // Estados
  int _currentIndex = 0;
  bool _loading = false;
  bool _salvando = false;
  List<TransacaoImportada> _transacoesEditadas = [];
  Set<int> _transacoesPuladas = {};
  Set<int> _transacoesSalvas = {};

  // Animações
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _transacoesEditadas = List.from(widget.transacoes);

    // Inicializar animação de progresso
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _atualizarProgresso();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Atualiza animação de progresso
  void _atualizarProgresso() {
    final progresso = (_currentIndex + 1) / widget.transacoes.length;
    _progressController.animateTo(progresso);
  }

  /// Vai para próxima transação
  void _proximaTransacao() {
    if (_currentIndex < widget.transacoes.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _atualizarProgresso();
    } else {
      _finalizarImportacao();
    }
  }

  /// Salva transação atual e vai para próxima
  void _salvarEProxima() {
    final transacao = _transacoesEditadas[_currentIndex];

    // Validar se tem categoria obrigatória
    if (transacao.categoriaId == null || transacao.categoriaId!.isEmpty) {
      _mostrarErro('Categoria é obrigatória');
      return;
    }

    setState(() {
      _transacoesSalvas.add(_currentIndex);
    });

    // Feedback haptic
    HapticFeedback.lightImpact();

    _proximaTransacao();
  }

  /// Pula transação atual
  void _pularTransacao() {
    setState(() {
      _transacoesPuladas.add(_currentIndex);
    });

    // Feedback haptic
    HapticFeedback.selectionClick();

    _proximaTransacao();
  }

  /// Finaliza importação salvando todas as transações aprovadas
  Future<void> _finalizarImportacao() async {
    final transacoesParaSalvar = _transacoesEditadas
        .asMap()
        .entries
        .where((entry) => _transacoesSalvas.contains(entry.key))
        .map((entry) => entry.value)
        .toList();

    if (transacoesParaSalvar.isEmpty) {
      _mostrarDialogoSemTransacoes();
      return;
    }

    setState(() => _salvando = true);

    try {
      await _mostrarDialogoConfirmacao(transacoesParaSalvar);
    } catch (e) {
      _mostrarErro('Erro ao salvar transações: $e');
    } finally {
      setState(() => _salvando = false);
    }
  }

  /// Mostra diálogo de confirmação antes de salvar
  Future<void> _mostrarDialogoConfirmacao(List<TransacaoImportada> transacoes) async {
    // ✅ VALIDAR PREVIAMENTE QUAIS TRANSAÇÕES SERÃO BLOQUEADAS
    final transacoesBloqueadas = <TransacaoImportada>[];
    final transacoesValidas = <TransacaoImportada>[];

    setState(() => _loading = true);

    for (final transacao in transacoes) {
      final validacao = await _importacaoService.validarImportacaoTransacao(transacao);
      if (validacao['valido'] == false) {
        transacoesBloqueadas.add(transacao);
      } else {
        transacoesValidas.add(transacao);
      }
    }

    setState(() => _loading = false);

    // Se houver bloqueadas, mostrar aviso primeiro
    if (transacoesBloqueadas.isNotEmpty && mounted) {
      final continuarMesmoAssim = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Atenção'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transacoesBloqueadas.length} transação(ões) não pode(m) ser importada(s) pois a fatura do período está fechada:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...transacoesBloqueadas.take(5).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${t.descricao}', style: const TextStyle(fontSize: 12)),
              )),
              if (transacoesBloqueadas.length > 5)
                Text('... e mais ${transacoesBloqueadas.length - 5}'),
              const SizedBox(height: 16),
              Text(
                'Apenas ${transacoesValidas.length} transação(ões) serão importadas.',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Importar ${transacoesValidas.length}'),
            ),
          ],
        ),
      );

      if (continuarMesmoAssim != true) return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogoConfirmacao(transacoesValidas),
    );

    if (resultado == true) {
      await _executarSalvamento(transacoesValidas);
    }
  }

  /// Executa o salvamento das transações
  Future<void> _executarSalvamento(List<TransacaoImportada> transacoes) async {
    try {
      final ids = await _importacaoService.salvarTransacoesImportadas(transacoes);

      if (mounted) {
        // Feedback de sucesso
        HapticFeedback.mediumImpact();

        // Mostrar resultado
        await _mostrarDialogoSucesso(ids.length, transacoes.length);

        // Voltar para tela anterior
        Navigator.of(context).pop({
          'sucesso': true,
          'transacoesSalvas': ids.length,
          'transacoesPuladas': _transacoesPuladas.length,
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar: $e');
      _mostrarErro('Erro ao salvar transações: $e');
    }
  }

  /// Mostra erro em SnackBar
  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Atualiza transação editada
  void _onTransacaoChanged(TransacaoImportada transacao) {
    setState(() {
      _transacoesEditadas[_currentIndex] = transacao;
    });
  }

  /// Vai para transação anterior
  void _transacaoAnterior() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _atualizarProgresso();
    }
  }

  /// Constrói header com progresso e estatísticas
  Widget _buildHeader() {
    final corTema = widget.tipoImportacao == 'conta'
        ? (_transacoesEditadas[_currentIndex].tipo == 'receita' ? Colors.teal : AppColors.vermelhoHeader)
        : const Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: corTema,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Barra de progresso
            Row(
              children: [
                Text(
                  '${_currentIndex + 1} de ${widget.transacoes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.white.withAlpha(78),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 6,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${((_currentIndex + 1) / widget.transacoes.length * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEstatistica(
                  'Salvas',
                  _transacoesSalvas.length.toString(),
                  Icons.check_circle_outline,
                  Colors.white,
                ),
                _buildEstatistica(
                  'Puladas',
                  _transacoesPuladas.length.toString(),
                  Icons.skip_next_outlined,
                  Colors.white.withAlpha(208),
                ),
                _buildEstatistica(
                  'Restantes',
                  (widget.transacoes.length - _transacoesSalvas.length - _transacoesPuladas.length).toString(),
                  Icons.pending_outlined,
                  Colors.white.withAlpha(208),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói estatística individual
  Widget _buildEstatistica(String label, String valor, IconData icon, Color cor) {
    return Column(
      children: [
        Icon(icon, color: cor, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: cor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: cor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Constrói navegação inferior
  Widget _buildBottomNavigation() {
    return Container(
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
        child: Row(
          children: [
            // Botão voltar
            if (_currentIndex > 0)
              IconButton(
                onPressed: _transacaoAnterior,
                icon: const Icon(Icons.arrow_back_ios),
                tooltip: 'Anterior',
              ),
            if (_currentIndex == 0)
              const SizedBox(width: 48),

            const Spacer(),

            // Botão finalizar (se está na última)
            if (_currentIndex == widget.transacoes.length - 1 && _transacoesSalvas.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _finalizarImportacao,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Finalizar Importação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),

            const Spacer(),

            // Botão próximo
            if (_currentIndex < widget.transacoes.length - 1)
              IconButton(
                onPressed: _proximaTransacao,
                icon: const Icon(Icons.arrow_forward_ios),
                tooltip: 'Próxima',
              ),
            if (_currentIndex == widget.transacoes.length - 1)
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  /// Constrói diálogo de confirmação
  Widget _buildDialogoConfirmacao(List<TransacaoImportada> transacoes) {
    final receitas = transacoes.where((t) => t.tipo == 'receita').length;
    final despesas = transacoes.where((t) => t.tipo == 'despesa').length;
    final totalValor = transacoes.fold<double>(0, (sum, t) => sum + t.valor);

    return AlertDialog(
      title: const Text('Confirmar Importação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deseja salvar ${transacoes.length} transação(ões)?'),
          const SizedBox(height: 16),
          if (receitas > 0)
            Text('• $receitas receita(s)'),
          if (despesas > 0)
            Text('• $despesas despesa(s)'),
          const SizedBox(height: 8),
          Text(
            'Valor total: R\$ ${totalValor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'As transações serão salvas em: ${widget.conta?.nome ?? widget.cartao?.nome}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  /// Constrói diálogo de sucesso
  Future<void> _mostrarDialogoSucesso(int salvas, int total) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Importação Concluída'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$salvas transação(ões) importada(s) com sucesso!'),
            if (_transacoesPuladas.isNotEmpty)
              Text('${_transacoesPuladas.length} transação(ões) foram puladas.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Constrói diálogo quando não há transações para salvar
  void _mostrarDialogoSemTransacoes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nenhuma Transação Selecionada'),
        content: const Text('Você precisa salvar pelo menos uma transação antes de finalizar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: LoadingOverlay(
        isLoading: _salvando,
        message: 'Salvando transações...',
        child: Column(
          children: [
            // Header com progresso
            _buildHeader(),

            // Cards com PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _atualizarProgresso();
                },
                itemCount: widget.transacoes.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    child: TransacaoImportCard(
                      transacao: _transacoesEditadas[index],
                      index: index + 1,
                      total: widget.transacoes.length,
                      conta: widget.conta,
                      cartao: widget.cartao,
                      onSave: _salvarEProxima,
                      onSkip: _pularTransacao,
                      onTransacaoChanged: _onTransacaoChanged,
                    ),
                  );
                },
              ),
            ),

            // Navegação inferior
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
}