// 📌 Transações Pendentes Widget - iPoupei Mobile
//
// Widget compacto e charmoso para mostrar transações vencidas
// Agrupa por data e mostra ícone da categoria com sua cor
//
// Design: Agrupamento por data + visual elegante + navegação para transações

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/transacao_pendente_model.dart';
import '../services/transacoes_pendentes_service.dart';
import '../../transacoes/services/transacao_service.dart';
import '../../transacoes/pages/transacoes_page.dart';
import '../../../shared/components/modals/transacao_opcoes_modal.dart';

/// Widget para transações pendentes vencidas
class TransacoesPendentesWidget extends StatefulWidget {
  final Function() onTransacoesTap;

  const TransacoesPendentesWidget({
    super.key,
    required this.onTransacoesTap,
  });

  @override
  State<TransacoesPendentesWidget> createState() => _TransacoesPendentesWidgetState();
}

class _TransacoesPendentesWidgetState extends State<TransacoesPendentesWidget> {
  final TransacoesPendentesService _service = TransacoesPendentesService.instance;

  ResumoTransacoesPendentes? _resumo;
  bool _loading = false;
  String? _error;
  bool _expandido = false;
  bool _minimizado = false;
  static const int _limiteTransacoes = 4;

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
  }

  /// 🔄 Carregar transações pendentes
  Future<void> _carregarTransacoes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resumo = await _service.obterResumoAgrupado();

      debugPrint('🔍 [TRANSACOES_WIDGET] Resumo carregado: ${resumo.totalTransacoes} transações');

      setState(() {
        _resumo = resumo;
        _loading = false;
      });
    } catch (e) {
      debugPrint('🔍 [TRANSACOES_WIDGET] Erro ao carregar: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Sempre mostrar para teste (remover depois)
    debugPrint('🔍 [TRANSACOES_WIDGET] Build - Loading: $_loading, Resumo: ${_resumo?.totalTransacoes ?? 0}, Error: $_error');

    // Não mostrar se estiver carregando e não tem dados
    if (_loading && (_resumo == null || !_resumo!.hasTransacoes)) {
      debugPrint('🔍 [TRANSACOES_WIDGET] Ocultando: Loading + sem dados');
      return const SizedBox.shrink();
    }

    // Não mostrar se não tem transações pendentes
    if (_resumo != null && !_resumo!.hasTransacoes && !_loading) {
      debugPrint('🔍 [TRANSACOES_WIDGET] Ocultando: Sem transações + não carregando');
      return const SizedBox.shrink();
    }

    // Não mostrar se deu erro
    if (_error != null) {
      debugPrint('🔍 [TRANSACOES_WIDGET] Ocultando: Erro $_error');
      return const SizedBox.shrink();
    }

    debugPrint('🔍 [TRANSACOES_WIDGET] Mostrando widget com ${_resumo?.totalTransacoes ?? 0} transações');

    return Container(
      // Sem margin - usa o padding do ScrollView igual outros widgets
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compacto
          _buildHeader(),

          // Conteúdo com animação
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _minimizado ? 0 : null,
            child: _minimizado
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      if (_loading)
                        _buildLoadingState()
                      else if (_resumo != null && _resumo!.hasTransacoes)
                        ..._buildGruposList()
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
          ),

          // Padding bottom
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 📋 Header compacto com alerta
  Widget _buildHeader() {
    final totalTransacoes = _resumo?.totalTransacoes ?? 0;
    final totalCriticas = _resumo?.quantidadeCriticas ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de alerta
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: totalCriticas > 0
                  ? AppColors.vermelhoErro.withAlpha(26)
                  : AppColors.amareloAlerta.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.schedule,
              color: totalCriticas > 0 ? AppColors.vermelhoErro : AppColors.amareloAlerta,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),

          // Título
          const Expanded(
            child: Text(
              'Transações Pendentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.cinzaEscuro,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Contador de pendências
          if (totalTransacoes > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: totalCriticas > 0
                    ? AppColors.vermelhoErro.withAlpha(26)
                    : AppColors.amareloAlerta.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _expandido || totalTransacoes <= _limiteTransacoes
                    ? '$totalTransacoes vencida${totalTransacoes > 1 ? 's' : ''}'
                    : '${_limiteTransacoes}+ vencidas',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: totalCriticas > 0 ? AppColors.vermelhoErro : AppColors.amareloAlerta,
                ),
              ),
            ),

          // Botões de ação (minimizar e refresh)
          const SizedBox(width: 8),
          if (!_loading) ...[
            // Botão minimizar/expandir
            GestureDetector(
              onTap: () {
                setState(() {
                  _minimizado = !_minimizado;
                  if (_minimizado) {
                    _expandido = false; // Reset expansão ao minimizar
                  }
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.cinzaClaro,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _minimizado ? Icons.expand_more : Icons.expand_less,
                  color: AppColors.cinzaMedio,
                  size: 14,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Botão refresh
            GestureDetector(
              onTap: _carregarTransacoes,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.cinzaClaro,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: AppColors.cinzaMedio,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ⏳ Estado de loading
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// 📋 Lista de grupos por data
  List<Widget> _buildGruposList() {
    if (_resumo == null || _resumo!.gruposPorData.isEmpty) {
      return [];
    }

    final widgets = <Widget>[];
    int transacoesAdicionadas = 0;
    final totalTransacoes = _resumo!.totalTransacoes;

    // Coletar todas as transações em ordem
    final todasTransacoes = <TransacaoPendente>[];
    for (final grupo in _resumo!.gruposPorData) {
      todasTransacoes.addAll(grupo.transacoes);
    }

    // Limitar transações se não expandido
    final transacoesParaMostrar = _expandido
        ? todasTransacoes
        : todasTransacoes.take(_limiteTransacoes).toList();

    // Renderizar transações
    for (int i = 0; i < transacoesParaMostrar.length; i++) {
      final transacao = transacoesParaMostrar[i];
      final isLast = i == transacoesParaMostrar.length - 1;

      widgets.add(_buildTransacaoItem(transacao, true));

      // Divider (exceto no último item)
      if (!isLast) {
        widgets.add(_buildDivider());
      }
    }

    // Botão "Ver mais" se há mais transações
    if (!_expandido && totalTransacoes > _limiteTransacoes) {
      widgets.add(_buildBotaoVerMais(totalTransacoes - _limiteTransacoes));
    }

    return widgets;
  }

  /// 📅 Header de data consolidada
  Widget _buildDataHeader(TransacoesPorData grupo) {
    return InkWell(
      onTap: widget.onTransacoesTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        color: AppColors.cinzaClaro.withAlpha(50),
        child: Row(
          children: [
            // Ícone de calendário
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: grupo.corCriticidade.withAlpha(26),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.calendar_today,
                color: grupo.corCriticidade,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),

            // Texto da data
            Expanded(
              child: Text(
                grupo.textoDescritivo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: grupo.corCriticidade,
                ),
              ),
            ),

            // Valor total do grupo
            Text(
              CurrencyFormatter.format(grupo.valorTotal),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: grupo.corCriticidade,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 Item individual da transação
  Widget _buildTransacaoItem(TransacaoPendente transacao, bool mostrarData) {
    return InkWell(
      onTap: () => _mostrarOpcoesRapidas(transacao),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            // Ícone da categoria
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: transacao.corCategoria,
                borderRadius: BorderRadius.circular(6),
              ),
              child: transacao.renderIconeCategoria(
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),

            // Informações da transação
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descrição com ícone discreto de tipo
                  Row(
                    children: [
                      // Ícone discreto do tipo (receita/despesa)
                      Icon(
                        transacao.iconeDiscreto,
                        size: 12,
                        color: transacao.corTipo.withAlpha(156),
                      ),
                      const SizedBox(width: 4),

                      // Descrição
                      Expanded(
                        child: Text(
                          transacao.descricao,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cinzaEscuro,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Data e atraso (se for item único ou crítico)
                  if (mostrarData || transacao.isCritica)
                    Text(
                      mostrarData
                          ? '${transacao.dataCompacta} - ${transacao.textoAtraso}'
                          : transacao.textoAtraso,
                      style: TextStyle(
                        fontSize: 11,
                        color: transacao.isCritica
                            ? AppColors.vermelhoErro
                            : AppColors.cinzaTexto,
                        fontWeight: transacao.isCritica ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),

            // Valor da transação
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(transacao.valor),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: transacao.corTipo,
                  ),
                ),

                // Badge crítico se necessário
                if (transacao.isCritica)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.vermelhoErro,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'CRÍTICO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ➖ Divider compacto
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 62), // Alinhado com texto
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.cinzaBorda,
      ),
    );
  }

  /// 🔽 Botão "Ver mais"
  Widget _buildBotaoVerMais(int transacoesRestantes) {
    return InkWell(
      onTap: () {
        setState(() {
          _expandido = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.expand_more,
              size: 16,
              color: AppColors.cinzaMedio,
            ),
            const SizedBox(width: 6),
            Text(
              'Ver mais $transacoesRestantes transaçõe${transacoesRestantes > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.cinzaMedio,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔄 Navegar para transações pendentes com filtros
  void _navegarParaTransacoesPendentes() {
    Navigator.pop(context); // Fecha modal

    // Calcular período: da transação mais antiga até hoje
    DateTime? dataMaisAntiga;
    DateTime dataHoje = DateTime.now();

    if (_resumo != null && _resumo!.gruposPorData.isNotEmpty) {
      // Pega a data mais antiga (já está ordenado por data crescente)
      dataMaisAntiga = _resumo!.gruposPorData.first.data;
      debugPrint('📅 Data mais antiga pendente: ${dataMaisAntiga.toIso8601String()}');
    } else {
      // Fallback: últimos 30 dias se não houver dados
      dataMaisAntiga = dataHoje.subtract(const Duration(days: 30));
      debugPrint('📅 Usando fallback de 30 dias: ${dataMaisAntiga.toIso8601String()}');
    }

    debugPrint('📅 Navegando para transações pendentes:');
    debugPrint('   - Período: ${dataMaisAntiga.toIso8601String().split('T')[0]} até ${dataHoje.toIso8601String().split('T')[0]}');
    debugPrint('   - Total pendentes: ${_resumo?.totalTransacoes ?? 0}');

    // Navegar para TransacoesPage com filtros
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransacoesPage(
          modoInicial: TransacoesPageMode.todas,
          filtrosIniciais: {
            'status': ['pendente'], // Apenas transações pendentes
            'dataInicio': dataMaisAntiga,
            'dataFim': dataHoje,
          },
        ),
      ),
    );
  }

  /// 💬 Modal de opções rápidas para transação pendente
  void _mostrarOpcoesRapidas(TransacaoPendente transacao) async {
    // Buscar transação completa
    final transacaoService = TransacaoService.instance;
    final transacaoCompleta = await transacaoService.fetchTransacaoPorId(transacao.id);

    if (transacaoCompleta == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar transação')),
        );
      }
      return;
    }

    if (!mounted) return;

    // Mostrar modal usando o componente compartilhado
    TransacaoOpcoesModal.mostrar(
      context: context,
      transacao: transacaoCompleta,
      onAtualizarLista: _carregarTransacoes,
      onVerTodasPendentes: _navegarParaTransacoesPendentes,
    );
  }
}