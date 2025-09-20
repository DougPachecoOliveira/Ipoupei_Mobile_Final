import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../cartoes/services/cartao_service.dart';
import '../../categorias/data/categoria_icons.dart';
import '../../contas/widgets/conta_card.dart';
import '../../cartoes/widgets/cartao_card.dart';

class AlterarContaPage extends StatefulWidget {
  final TransacaoModel transacao;
  final Function() onContaAlterada;

  const AlterarContaPage({
    super.key,
    required this.transacao,
    required this.onContaAlterada,
  });

  @override
  State<AlterarContaPage> createState() => _AlterarContaPageState();
}

class _AlterarContaPageState extends State<AlterarContaPage> {
  List<ContaModel> _contas = [];
  List<CartaoModel> _cartoes = [];
  String? _contaSelecionadaId;
  String? _cartaoSelecionadoId;
  bool _carregandoContas = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Inicializar seleção baseada no tipo da transação
    if (_deveUsarCartao()) {
      _cartaoSelecionadoId = widget.transacao.cartaoId;
      _contaSelecionadaId = null;
    } else {
      _contaSelecionadaId = widget.transacao.contaId;
      _cartaoSelecionadoId = null;
    }
    _carregarContasECartoes();
  }

  Future<void> _carregarContasECartoes() async {
    try {
      final contas = await ContaService.instance.getContasAtivas();
      final cartoes = await CartaoService.instance.listarCartoesAtivos();
      
      setState(() {
        _contas = contas;
        _cartoes = cartoes;
        _carregandoContas = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar contas: $e';
        _carregandoContas = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _getCorHeader(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.transacao.descricao.isNotEmpty 
                  ? widget.transacao.descricao 
                  : (_deveUsarCartao() ? 'Alterar Cartão' : 'Alterar Conta'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _deveUsarCartao() ? Icons.credit_card : Icons.swap_horiz,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _podeSalvar() && !_salvando ? _salvarAlteracao : null,
            child: Text(
              'Salvar',
              style: TextStyle(
                color: _podeSalvar() && !_salvando ? Colors.white : Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _carregandoContas
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.vermelhoErro,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _erro = null;
                            _carregandoContas = true;
                          });
                          _carregarContasECartoes();
                        },
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header com info da transação
                            _buildHeaderTransacao(),
                            const SizedBox(height: 24),

                            // Lista de contas ou cartões (determinado automaticamente pelo tipo)
                            _buildListaSelecao(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Botão de confirmação fixo na parte inferior
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: _buildBotaoSalvar(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeaderTransacao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCorHeader().withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCorHeader().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.transacao.tipo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getCorHeader(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatarValor(widget.transacao.valor),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.transacao.descricao,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.transacao.cartaoId != null 
                ? 'Cartão atual: ${_getNomeCartaoAtual()}'
                : 'Conta atual: ${_getNomeContaAtual()}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildListaSelecao() {
    final isCartao = _deveUsarCartao();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCartao ? 'Selecione o Cartão' : 'Selecione a Conta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getCorHeader(),
          ),
        ),
        const SizedBox(height: 8),
        
        if (isCartao) ...[
          if (_cartoes.isEmpty)
            _buildMensagemVazia('Nenhum cartão ativo encontrado')
          else
            ..._cartoes.map((cartao) => _buildCartaoSelecionavel(cartao)).toList(),
        ] else ...[
          if (_contas.isEmpty)
            _buildMensagemVazia('Nenhuma conta ativa encontrada')
          else
            ..._contas.map((conta) => _buildContaSelecionavel(conta)).toList(),
        ],
      ],
    );
  }

  Widget _buildContaSelecionavel(ContaModel conta) {
    final selecionada = _contaSelecionadaId == conta.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: selecionada ? BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.verdeSucesso, width: 3),
      ) : null,
      child: Stack(
        children: [
          ContaCard(
            conta: conta,
            isCompact: true,
            onTap: () {
              setState(() {
                _contaSelecionadaId = conta.id;
                _cartaoSelecionadoId = null;
              });
            },
          ),
          if (selecionada)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.verdeSucesso,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartaoSelecionavel(CartaoModel cartao) {
    final selecionado = _cartaoSelecionadoId == cartao.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: selecionado ? BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.verdeSucesso, width: 3),
      ) : null,
      child: Stack(
        children: [
          CartaoCard(
            cartao: cartao,
            isCompact: true,
            onTap: () {
              setState(() {
                _cartaoSelecionadoId = cartao.id;
                _contaSelecionadaId = null;
              });
            },
          ),
          if (selecionado)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.verdeSucesso,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMensagemVazia(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cinzaClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          mensagem,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.cinzaTexto,
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    final podeSalvar = _podeSalvar();
    final isCartao = _deveUsarCartao();
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: podeSalvar && !_salvando ? _salvarAlteracao : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: podeSalvar && !_salvando ? _getCorHeader() : AppColors.cinzaMedio,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _salvando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCartao ? Icons.credit_card : Icons.account_balance_wallet,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    podeSalvar 
                      ? 'Confirmar Alteração'
                      : 'Selecione uma opção',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _salvarAlteracao() async {
    if (!_podeSalvar() || _salvando) return;

    setState(() {
      _salvando = true;
    });

    try {
      final isCartao = _deveUsarCartao();
      
      if (isCartao && _cartaoSelecionadoId != null) {
        // Alterar para cartão
        final resultado = await TransacaoEditService.instance.alterarCartao(
          widget.transacao,
          novoCartaoId: _cartaoSelecionadoId!,
        );
        
        if (resultado.sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.mensagem ?? 'Cartão alterado com sucesso'),
              backgroundColor: AppColors.tealPrimary,
            ),
          );
          widget.onContaAlterada();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.erro ?? 'Erro ao alterar cartão'),
              backgroundColor: AppColors.vermelhoErro,
            ),
          );
        }
      } else if (!isCartao && _contaSelecionadaId != null) {
        // Alterar para conta
        final resultado = await TransacaoEditService.instance.alterarConta(
          widget.transacao,
          novaContaId: _contaSelecionadaId!,
        );
        
        if (resultado.sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.mensagem ?? 'Conta alterada com sucesso'),
              backgroundColor: AppColors.tealPrimary,
            ),
          );
          widget.onContaAlterada();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.erro ?? 'Erro ao alterar conta'),
              backgroundColor: AppColors.vermelhoErro,
            ),
          );
        }
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar alteração: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _salvando = false;
      });
    }
  }

  bool _deveUsarCartao() {
    // Cartão apenas para despesas de cartão de crédito
    return widget.transacao.cartaoId != null || 
           (widget.transacao.tipo == 'despesa' && widget.transacao.cartaoId != null);
  }

  bool _podeSalvar() {
    final isCartao = _deveUsarCartao();
    if (isCartao) {
      return _cartaoSelecionadoId != null && _cartaoSelecionadoId != widget.transacao.cartaoId;
    } else {
      return _contaSelecionadaId != null && _contaSelecionadaId != widget.transacao.contaId;
    }
  }

  bool _podeAlternarTipo() {
    // Permitir alternar apenas se não for recorrente/parcelada
    return widget.transacao.grupoRecorrencia == null && 
           widget.transacao.grupoParcelamento == null;
  }

  String _getNomeContaAtual() {
    if (widget.transacao.contaId == null) return 'N/A';
    final conta = _contas.firstWhere(
      (c) => c.id == widget.transacao.contaId,
      orElse: () => ContaModel(
        id: '',
        usuarioId: '',
        nome: 'Conta não encontrada',
        tipo: 'corrente',
        saldoInicial: 0,
        saldo: 0,
        ativo: false,
        incluirSomaTotal: false,
        contaPrincipal: false,
        ordem: 0,
        origemDiagnostico: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return conta.nome;
  }

  String _getNomeCartaoAtual() {
    if (widget.transacao.cartaoId == null) return 'N/A';
    final cartao = _cartoes.firstWhere(
      (c) => c.id == widget.transacao.cartaoId,
      orElse: () => CartaoModel(
        id: '',
        usuarioId: '',
        nome: 'Cartão não encontrado',
        limite: 0,
        diaFechamento: 1,
        diaVencimento: 1,
        ativo: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: 'synced',
      ),
    );
    return cartao.nome;
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Color _getCorHeader() {
    if (widget.transacao.cartaoId != null) return AppColors.roxoPrimario;
    
    switch (widget.transacao.tipo) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return AppColors.vermelhoHeader;
      case 'transferencia':
        return AppColors.azulHeader;
      default:
        return AppColors.tealPrimary;
    }
  }

  // Métodos para cores e ícones específicos das contas/cartões
  Color _getCorDaConta(ContaModel conta) {
    if (conta.cor != null && conta.cor!.isNotEmpty) {
      return _corDeString(conta.cor!);
    }
    
    // Fallback baseado no tipo
    switch (conta.tipo) {
      case 'corrente':
        return AppColors.azul;
      case 'poupanca':
        return AppColors.tealPrimary;
      case 'investimento':
        return AppColors.roxoPrimario;
      default:
        return AppColors.cinzaEscuro;
    }
  }

  IconData _getIconeDaConta(ContaModel conta) {
    if (conta.icone != null && conta.icone!.isNotEmpty) {
      // Usar o sistema de ícones do CategoriaIcons se disponível
      return _getIconDataByName(conta.icone!);
    }
    
    // Fallback baseado no tipo
    switch (conta.tipo) {
      case 'corrente':
        return Icons.account_balance;
      case 'poupanca':
        return Icons.savings;
      case 'investimento':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getCorDoCartao(CartaoModel cartao) {
    if (cartao.cor != null && cartao.cor!.isNotEmpty) {
      return _corDeString(cartao.cor!);
    }
    return AppColors.roxoPrimario; // Cor padrão para cartões
  }

  IconData _getIconeDoCartao(CartaoModel cartao) {
    if (cartao.bandeira != null) {
      switch (cartao.bandeira!.toLowerCase()) {
        case 'visa':
          return Icons.payment;
        case 'mastercard':
          return Icons.credit_card;
        case 'elo':
          return Icons.credit_card_outlined;
        default:
          return Icons.credit_card;
      }
    }
    return Icons.credit_card;
  }

  // Métodos auxiliares
  Color _corDeString(String corString) {
    try {
      // Remove # se existir
      final cor = corString.replaceAll('#', '');
      
      // Adiciona FF para alpha se necessário
      final corCompleta = cor.length == 6 ? 'FF$cor' : cor;
      
      return Color(int.parse(corCompleta, radix: 16));
    } catch (e) {
      return AppColors.tealPrimary; // Fallback
    }
  }

  IconData _getIconDataByName(String iconeName) {
    // Lista básica de ícones comuns - pode ser expandida
    switch (iconeName.toLowerCase()) {
      case 'account_balance':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'money':
        return Icons.attach_money;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.account_balance_wallet;
    }
  }
}