// 📱 Transaction Detail Card - iPoupei Mobile
//
// Componente reutilizável para exibir detalhes completos de transação
// Inclui conta/cartão, categoria, subcategoria e metadados de grupo
//
// Baseado em: Card completo de editar_transacao_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/theme/app_colors.dart';
import '../models/transacao_model.dart';
import '../../../services/grupos_metadados_service.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../categorias/data/categoria_icons.dart';
import '../../categorias/services/categoria_service.dart';
import '../../contas/services/conta_service.dart';
import '../../cartoes/services/cartao_service.dart';
import '../../contas/data/contas_sugeridas.dart';

class TransactionDetailCard extends StatefulWidget {
  final TransacaoModel transacao;
  final bool showMetadata;
  final bool loadDataAutomatically;

  const TransactionDetailCard({
    super.key,
    required this.transacao,
    this.showMetadata = true,
    this.loadDataAutomatically = true,
  });

  @override
  State<TransactionDetailCard> createState() => _TransactionDetailCardState();
}

class _TransactionDetailCardState extends State<TransactionDetailCard> {
  // Dados carregados dinamicamente
  String? _nomeConta;
  String? _nomeCartao;
  String? _nomeCategoria;
  String? _nomeSubcategoria;
  String? _iconeConta;
  String? _iconeCartao;
  String? _iconeCategoria;
  Color? _corConta;
  Color? _corCartao;
  Color? _corCategoria;
  String? _bancoConta; // Nome do banco da conta
  String? _logoBanco;  // Caminho do logo do banco

  // Metadados do grupo
  GrupoMetadados? _metadadosGrupo;
  double? _valorTotalGrupo;
  double? _valorEfetivadoGrupo;
  double? _valorPendenteGrupo;
  int? _itemsEfetivados;
  int? _itemsPendentes;
  DateTime? _dataPrimeiraTransacao;
  DateTime? _dataUltimaTransacao;
  int? _posicaoAtualNoGrupo;
  int? _totalTransacoesGrupo;

  final _gruposMetadadosService = GruposMetadadosService.instance;
  bool _carregandoDados = true;

  @override
  void initState() {
    super.initState();
    if (widget.loadDataAutomatically) {
      _carregarDadosRelacionados();
    } else {
      _carregandoDados = false;
    }
  }

  /// Carregar todos os dados relacionados à transação
  Future<void> _carregarDadosRelacionados() async {
    try {
      // Carregar dados de conta/cartão
      await _carregarDadosConta();

      // Carregar dados de categoria
      await _carregarDadosCategoria();

      // Carregar metadados do grupo (se aplicável)
      if (widget.showMetadata) {
        await _carregarMetadadosGrupo();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados relacionados: $e');
    } finally {
      if (mounted) {
        setState(() {
          _carregandoDados = false;
        });
      }
    }
  }

  /// Carregar dados da conta ou cartão
  Future<void> _carregarDadosConta() async {
    try {
      if (widget.transacao.contaId != null) {
        final contas = await ContaService.instance.fetchContas();
        final conta = ContaService.instance.getContaById(
          widget.transacao.contaId!,
          contas,
        );
        if (conta != null) {
          _nomeConta = conta.nome;
          _iconeConta = conta.icone;
          _bancoConta = conta.banco;
          if (conta.cor != null) {
            _corConta = _corDeString(conta.cor!);
          }

          // Buscar logo do banco
          if (conta.banco != null && conta.banco!.isNotEmpty) {
            _logoBanco = _buscarLogoBanco(conta.banco!);
          }
        }
      }

      if (widget.transacao.cartaoId != null) {
        final cartao = await CartaoService.instance.buscarCartaoPorId(
          widget.transacao.cartaoId!,
        );
        if (cartao != null) {
          _nomeCartao = cartao.nome;
          _iconeCartao = _obterIconeCartaoPorBandeira(cartao.bandeira);
          if (cartao.cor != null) {
            _corCartao = _corDeString(cartao.cor!);
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados da conta/cartão: $e');
    }
  }

  /// Carregar dados da categoria
  Future<void> _carregarDadosCategoria() async {
    try {
      if (widget.transacao.categoriaId != null) {
        final categorias = await CategoriaService.instance.fetchCategorias();
        final categoria = CategoriaService.instance.getCategoriaById(
          widget.transacao.categoriaId!,
          categorias,
        );
        if (categoria != null) {
          _nomeCategoria = categoria.nome;
          _iconeCategoria = categoria.icone;
          if (categoria.cor != null) {
            _corCategoria = _corDeString(categoria.cor!);
          }
        }
      }

      if (widget.transacao.subcategoriaId != null) {
        final subcategorias = await CategoriaService.instance.fetchSubcategorias();
        final subcategoria = CategoriaService.instance.getSubcategoriaById(
          widget.transacao.subcategoriaId!,
          subcategorias,
        );
        _nomeSubcategoria = subcategoria?.nome;
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados da categoria: $e');
    }
  }

  /// Carregar metadados do grupo (parcelas/recorrências)
  Future<void> _carregarMetadadosGrupo() async {
    if (!_temParcelasOuRecorrencias()) return;

    try {
      String tipoGrupo;
      String grupoId;

      if (widget.transacao.grupoRecorrencia != null) {
        tipoGrupo = 'grupo_recorrencia';
        grupoId = widget.transacao.grupoRecorrencia!;
      } else if (widget.transacao.grupoParcelamento != null) {
        tipoGrupo = 'grupo_parcelamento';
        grupoId = widget.transacao.grupoParcelamento!;
      } else {
        return;
      }

      final metadados = await _gruposMetadadosService.obterMetadadosGrupo(
        grupoId,
        widget.transacao.usuarioId,
      );

      if (metadados != null) {
        _metadadosGrupo = metadados;
        _valorTotalGrupo = metadados.valorTotal;
        _valorEfetivadoGrupo = metadados.valorEfetivado;
        _valorPendenteGrupo = metadados.valorPendente;
        _itemsEfetivados = metadados.itemsEfetivados;
        _itemsPendentes = metadados.itemsPendentes;
        _totalTransacoesGrupo = metadados.totalItems;
        _dataPrimeiraTransacao = metadados.dataPrimeira;
        _dataUltimaTransacao = metadados.dataUltima;
        _posicaoAtualNoGrupo = 1; // Pode ser calculado mais precisamente
      }
    } catch (e) {
      debugPrint('Erro ao carregar metadados do grupo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoDados) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cinzaClaro,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCorTipoTransacao().withAlpha(52),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(21),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📍 LINHA 1: Tipo + Valor + Status
            Row(
              children: [
                // Tipo da transação
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCorTipoTransacao().withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconeTipoTransacao(),
                        size: 14,
                        color: _getCorTipoTransacao(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTextoTipoTransacao(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getCorTipoTransacao(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Valor
                Expanded(
                  child: Text(
                    CurrencyFormatter.format(widget.transacao.valor),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
                // Status Badge
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 12),

            // 📍 LINHA 2: Conta/Cartão + Categoria
            Row(
              children: [
                // Ícone da conta/cartão
                _buildIconeQuadradoConta(size: 28),
                const SizedBox(width: 10),
                // Nome da conta
                Expanded(
                  flex: widget.transacao.categoriaId != null ? 2 : 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNomeConta(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                      Text(
                        widget.transacao.descricao,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.cinzaTexto,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Categoria (se existir)
                if (widget.transacao.categoriaId != null) ...[
                  const SizedBox(width: 8),
                  _buildIconeQuadradoCategoria(
                    iconeString: _iconeCategoria,
                    cor: _getCorCategoria(),
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  // Nome da categoria + subcategoria
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNomeCategoria(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cinzaEscuro,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_getNomeSubcategoria().isNotEmpty)
                          Text(
                            _getNomeSubcategoria(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.cinzaTexto,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // 📍 LINHA 3: Informações adicionais (parcelas/recorrência)
            if (_temParcelasOuRecorrencias() && widget.showMetadata) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 14,
                    color: AppColors.cinzaTexto,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatarDetalhesProgresso(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.cinzaTexto,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // 📍 LINHA 4: Observações (se existirem)
            if (widget.transacao.observacoes != null &&
                widget.transacao.observacoes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 14,
                    color: AppColors.cinzaTexto,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.transacao.observacoes!.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.cinzaTexto,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Badge de status da transação
  Widget _buildStatusBadge() {
    if (widget.transacao.efetivado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.verdeSucesso.withAlpha(26),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'EFETIVADO',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.verdeSucesso,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.amareloAlerta.withAlpha(26),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'PENDENTE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.amareloAlerta,
          ),
        ),
      );
    }
  }

  /// Construir ícone quadrado para categoria
  Widget _buildIconeQuadradoCategoria({
    String? iconeString,
    required Color cor,
    double size = 32,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: iconeString != null && iconeString.isNotEmpty
            ? _getIconeByName(iconeString, size: size * 0.6, color: Colors.white)
            : const Icon(Icons.category, color: Colors.white),
      ),
    );
  }

  /// Buscar logo do banco nas contas sugeridas
  String? _buscarLogoBanco(String banco) {
    if (banco.isEmpty) return null;

    try {
      final bancoEncontrado = ContasSugeridas.todas.firstWhere(
        (contaSugerida) => contaSugerida['banco'] == banco,
        orElse: () => <String, dynamic>{},
      );

      return bancoEncontrado['logo'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Widget de logo do banco
  Widget _buildLogoWidget(String? logo, {required double size, required IconData fallbackIcon}) {
    final iconSize = size * 0.6;

    if (logo == null || logo.isEmpty) {
      return Icon(fallbackIcon, color: Colors.white, size: iconSize);
    }

    try {
      final lowerLogo = logo.toLowerCase();

      if (lowerLogo.endsWith('.svg')) {
        return SvgPicture.asset(
          logo,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          placeholderBuilder: (BuildContext context) => Icon(
            fallbackIcon,
            color: Colors.white,
            size: iconSize,
          ),
        );
      }

      return Image.asset(
        logo,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          fallbackIcon,
          color: Colors.white,
          size: iconSize,
        ),
      );
    } catch (e) {
      return Icon(fallbackIcon, color: Colors.white, size: iconSize);
    }
  }

  /// Construir ícone quadrado para conta/cartão
  Widget _buildIconeQuadradoConta({double size = 32}) {
    String? iconeString;
    Color cor;
    IconData fallbackIcon;
    String? logo;

    if (widget.transacao.cartaoId != null) {
      // É um cartão
      iconeString = _iconeCartao;
      cor = _corCartao ?? AppColors.roxoPrimario;
      fallbackIcon = Icons.credit_card;
      logo = null; // Cartões não usam logos de banco
    } else {
      // É uma conta - usar logo do banco se disponível
      iconeString = _iconeConta;
      cor = _corConta ?? _getCorTipoTransacao();
      fallbackIcon = Icons.account_balance;
      logo = _logoBanco;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: logo != null
            ? _buildLogoWidget(logo, size: size, fallbackIcon: fallbackIcon)
            : iconeString != null && iconeString.isNotEmpty
                ? _getIconeByName(iconeString, size: size * 0.6, color: Colors.white)
                : Icon(fallbackIcon, color: Colors.white, size: size * 0.6),
      ),
    );
  }

  /// Helper methods
  bool _temParcelasOuRecorrencias() {
    return widget.transacao.grupoRecorrencia != null ||
           widget.transacao.grupoParcelamento != null;
  }

  String _getNomeConta() {
    if (widget.transacao.cartaoId != null) {
      return _nomeCartao ?? 'Cartão de Crédito';
    } else if (widget.transacao.contaId != null) {
      return _nomeConta ?? 'Conta Principal';
    } else {
      return 'Conta Principal';
    }
  }

  String _getNomeCategoria() {
    if (widget.transacao.categoriaId != null) {
      return _nomeCategoria ?? 'Categoria';
    }
    return '';
  }

  String _getNomeSubcategoria() {
    if (widget.transacao.subcategoriaId != null) {
      return _nomeSubcategoria ?? '';
    }
    return '';
  }

  Color _getCorCategoria() {
    return _corCategoria ?? AppColors.azul;
  }

  IconData _getIconeTipoTransacao() {
    if (widget.transacao.tipo == 'receita') {
      return Icons.trending_up;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null
          ? Icons.credit_card
          : Icons.trending_down;
    } else {
      return Icons.swap_horiz; // transferência
    }
  }

  Color _getCorTipoTransacao() {
    if (widget.transacao.tipo == 'receita') {
      return AppColors.verdeSucesso;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null
          ? AppColors.roxoPrimario
          : AppColors.vermelhoErro;
    } else {
      return AppColors.azul; // transferência
    }
  }

  String _getTextoTipoTransacao() {
    if (widget.transacao.tipo == 'receita') {
      return 'RECEITA';
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null ? 'CARTÃO' : 'DESPESA';
    } else {
      return 'TRANSFERÊNCIA';
    }
  }

  /// Formatar detalhes de período e progresso
  String _formatarDetalhesProgresso() {
    if (_metadadosGrupo == null) return '';

    String formatarData(DateTime? data) {
      if (data == null) return 'N/A';

      const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                     'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

      final mes = meses[data.month - 1];
      final ano = data.year.toString().substring(2);

      return '$mes/$ano';
    }

    List<String> detalhes = [];

    // Adicionar período (datas) - formato compacto
    final inicioData = formatarData(_dataPrimeiraTransacao);
    if (_dataUltimaTransacao != null) {
      final fimData = formatarData(_dataUltimaTransacao);
      detalhes.add('De $inicioData à $fimData');
    } else {
      detalhes.add('A partir de $inicioData');
    }

    // Adicionar informações financeiras - formato compacto
    if (_valorTotalGrupo != null && _valorEfetivadoGrupo != null) {
      final valorEfetivado = CurrencyFormatter.format(_valorEfetivadoGrupo!);
      final valorTotal = CurrencyFormatter.format(_valorTotalGrupo!);
      detalhes.add('$valorEfetivado/$valorTotal');
    }

    return detalhes.join(' • ');
  }

  /// Obter widget de ícone por nome
  Widget _getIconeByName(String icone, {required double size, Color? color}) {
    return CategoriaIcons.renderIcon(icone, size, color: color);
  }

  /// Obter ícone do cartão baseado na bandeira
  String _obterIconeCartaoPorBandeira(String? bandeira) {
    if (bandeira == null) return 'credit_card';

    switch (bandeira.toLowerCase()) {
      case 'visa':
        return 'payment';
      case 'mastercard':
        return 'credit_card';
      case 'elo':
        return 'account_balance_wallet';
      case 'american express':
      case 'amex':
        return 'credit_score';
      case 'hipercard':
        return 'contactless';
      case 'diners':
        return 'dining';
      default:
        return 'credit_card';
    }
  }

  /// Converte string de cor para Color
  Color _corDeString(String corString) {
    try {
      final cor = corString.replaceAll('#', '');
      final corCompleta = cor.length == 6 ? 'FF$cor' : cor;
      return Color(int.parse(corCompleta, radix: 16));
    } catch (e) {
      return AppColors.tealPrimary;
    }
  }
}