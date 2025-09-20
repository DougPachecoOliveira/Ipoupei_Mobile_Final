import 'package:flutter/material.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';

class CartaoCard extends StatelessWidget {
  final CartaoModel cartao;
  final double? valorUtilizado;
  final double? gastoPeriodo;
  final FaturaModel? faturaAtual;
  final String? periodoAtual;
  final bool showUtilizacao;
  final bool showFaturaInfo;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onPagarFatura;
  final Function(String action)? onMenuAction;
  final Widget? trailing;

  const CartaoCard({
    Key? key,
    required this.cartao,
    this.valorUtilizado,
    this.gastoPeriodo,
    this.faturaAtual,
    this.periodoAtual,
    this.showUtilizacao = true,
    this.showFaturaInfo = true,
    this.isCompact = false,
    this.onTap,
    this.onPagarFatura,
    this.onMenuAction,
    this.trailing,
  }) : super(key: key);

  Color _getCorCartao() {
    if (cartao.cor != null && cartao.cor!.isNotEmpty) {
      try {
        return Color(int.parse(cartao.cor!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Se não conseguir parsear a cor, usa cor padrão
      }
    }
    return AppColors.roxoHeader;
  }

  double get _percentualUtilizacao {
    if (valorUtilizado == null || cartao.limite == null || cartao.limite! <= 0) {
      return 0.0;
    }
    return (valorUtilizado! / cartao.limite!) * 100;
  }

  double get _valorDisponivel {
    if (valorUtilizado == null || cartao.limite == null) {
      return cartao.limite ?? 0.0;
    }
    return cartao.limite! - valorUtilizado!;
  }

  Color get _corUtilizacao {
    final percentual = _percentualUtilizacao;
    if (percentual >= 90) return Colors.red[600]!;
    if (percentual >= 70) return Colors.orange[600]!;
    if (percentual >= 50) return Colors.yellow[700]!;
    return Colors.green[600]!;
  }

  @override
  Widget build(BuildContext context) {
    final utilizacao = _calcularUtilizacao();
    final corCartao = _getCorCartao();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // ✅ PADDING REDUZIDO
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _buildGradiente(corCartao),
          ),
          child: isCompact ? _buildCompactContent() : _buildFullContent(),
        ),
      ),
    );
  }

  /// Conteúdo compacto (para listas)
  Widget _buildCompactContent() {
    return Row(
      children: [
        _buildIconeBandeira(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cartao.nome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showUtilizacao) ...[
                const SizedBox(height: 4),
                _buildBarraUtilizacao(),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }

  /// NOVO: Conteúdo completo compacto (layout da imagem)
  Widget _buildFullContent() {
    final utilizacao = _calcularUtilizacao();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com nome + status + bandeira
        Row(
          children: [
            Expanded(
              child: Text(
                cartao.nome,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusChip(),
            const SizedBox(width: 8),
            _buildIconeBandeira(),
          ],
        ),

        const SizedBox(height: 12),

        // Informações do limite
        if (showUtilizacao) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilizado (${utilizacao.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                'Limite',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(valorUtilizado ?? 0),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                CurrencyFormatter.format(cartao.limite ?? 0),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _buildBarraUtilizacao(),
          const SizedBox(height: 12),

          // Seção da fatura - mostrar quando há fatura relevante
          if (_deveMostrarSecaoFatura()) _buildSecaoFatura(),
          const SizedBox(height: 8),
          
          // Informações finais
          _buildDiasFechamentoVencimento(),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  /// Ícone da bandeira do cartão
  Widget _buildIconeBandeira() {
    final bandeira = cartao.bandeira?.toUpperCase();
    
    Widget icone;
    switch (bandeira) {
      case 'VISA':
        icone = const Icon(Icons.credit_card, color: Colors.white, size: 24);
        break;
      case 'MASTERCARD':
        icone = const Icon(Icons.credit_card, color: Colors.white, size: 24);
        break;
      case 'ELO':
        icone = const Icon(Icons.credit_card, color: Colors.white, size: 24);
        break;
      case 'AMEX':
        icone = const Icon(Icons.credit_card, color: Colors.white, size: 24);
        break;
      default:
        icone = const Icon(Icons.credit_card, color: Colors.white, size: 24);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: icone,
    );
  }

  /// Barra de utilização do limite
  Widget _buildBarraUtilizacao() {
    final utilizacao = _calcularUtilizacao();
    final porcentagem = utilizacao / 100;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentagem.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _obterCorUtilizacao(utilizacao),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// Chip de status da utilização
  Widget _buildStatusChip() {
    final utilizacao = _calcularUtilizacao();
    final status = _obterStatusUtilizacao(utilizacao);
    
    String texto;
    Color cor;
    
    switch (status) {
      case 'critico':
        texto = 'CRÍTICO';
        cor = Colors.red.shade300;
        break;
      case 'alto':
        texto = 'ALTO';
        cor = Colors.orange.shade300;
        break;
      case 'medio':
        texto = 'MÉDIO';
        cor = Colors.yellow.shade300;
        break;
      case 'baixo':
        texto = 'BAIXO';
        cor = Colors.green.shade300;
        break;
      default:
        texto = 'OK';
        cor = Colors.white.withOpacity(0.7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: cor,
        ),
      ),
    );
  }

  /// ✅ DETERMINAR SE DEVE MOSTRAR SEÇÃO DA FATURA
  bool _deveMostrarSecaoFatura() {
    print('🔍 [DEBUG CartaoCard] _deveMostrarSecaoFatura - Cartão: ${cartao.nome}');
    
    if (faturaAtual == null) {
      print('   ❌ faturaAtual é null');
      return false;
    }
    
    print('   📊 Fatura encontrada:');
    print('      💰 Valor total: R\$ ${faturaAtual!.valorTotal}');
    print('      💳 Valor restante: R\$ ${faturaAtual!.valorRestante}');
    print('      📅 Data vencimento: ${faturaAtual!.dataVencimento}');
    print('      ⏰ Dias até vencimento: ${faturaAtual!.diasAteVencimento}');
    print('      ✅ Paga: ${faturaAtual!.paga}');
    print('      🔄 Vencida: ${faturaAtual!.isVencida}');
    print('      ⚠️ Próxima vencimento: ${faturaAtual!.isProximaVencimento}');
    
    // Sempre mostrar se há valor em aberto (não pago)
    if (faturaAtual!.valorRestante > 0.01) {
      print('   ✅ MOSTRANDO: Valor restante > 0.01 (R\$ ${faturaAtual!.valorRestante})');
      return true;
    }
    
    // Mostrar se está vencida ou próxima ao vencimento
    if (faturaAtual!.isVencida || faturaAtual!.isProximaVencimento) {
      print('   ✅ MOSTRANDO: Fatura vencida ou próxima ao vencimento');
      return true;
    }
    
    // Mostrar se fatura foi paga recentemente (últimos 3 dias)
    if (faturaAtual!.paga && faturaAtual!.dataPagamento != null) {
      final diasDesdePagamento = DateTime.now().difference(faturaAtual!.dataPagamento!).inDays;
      if (diasDesdePagamento <= 3) {
        print('   ✅ MOSTRANDO: Paga recentemente ($diasDesdePagamento dias)');
        return true;
      }
    }
    
    // Não mostrar faturas futuras muito distantes (mais de 60 dias)
    final diasAteVencimento = faturaAtual!.diasAteVencimento;
    if (diasAteVencimento > 60) {
      print('   ❌ NÃO MOSTRANDO: Fatura muito futura ($diasAteVencimento dias)');
      return false;
    }
    
    // Para outros casos, mostrar apenas se tem valor significativo
    final valorSignificativo = faturaAtual!.valorTotal > 10.0;
    print('   ${valorSignificativo ? "✅ MOSTRANDO" : "❌ NÃO MOSTRANDO"}: Valor ${valorSignificativo ? "significativo" : "baixo"} (R\$ ${faturaAtual!.valorTotal})');
    return valorSignificativo;
  }

  /// 🆕 NOVA FUNÇÃO: Seção da fatura com botão de pagamento
  Widget _buildSecaoFatura() {
    if (faturaAtual == null) return const SizedBox.shrink();
    
    // 🆕 LÓGICA INTELIGENTE DA FATURA
    final faturaInfo = _obterInfoFaturaInteligente();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  // Labels dinâmicos
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          faturaInfo['labelEsquerda']!, // 🆕 DINÂMICO
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          faturaInfo['labelDireita']!, // 🆕 DINÂMICO
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Valores dinâmicos
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          faturaInfo['valorEsquerdo']!, // 🆕 DINÂMICO
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: faturaInfo['corEsquerdo'], // 🆕 COR DINÂMICA
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          faturaInfo['valorDireito']!, // 🆕 DINÂMICO
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: faturaInfo['corDireito'], // 🆕 COR DINÂMICA
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Menu centralizado
            Align(
              alignment: Alignment.center,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                onSelected: (action) {
                  if (action == 'pagar') {
                    onPagarFatura?.call();
                  } else {
                    // Repassar para o handler principal via onMenuAction
                    onMenuAction?.call(action);
                  }
                },
                itemBuilder: (context) => _buildMenuItems(faturaInfo['status']!), // 🆕 MENU DINÂMICO
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NOVO: Dias de fechamento e vencimento com detecção real de overlap
  Widget _buildDiasFechamentoVencimento() {
    final diaFechamento = cartao.diaFechamento;
    final diaVencimento = cartao.diaVencimento;
    final gasto = gastoPeriodo ?? 0.0;

    // Textos para construir
    final fechaText = diaFechamento != null ? "Fecha dia $diaFechamento" : "";
    final venceText = diaVencimento != null ? "Vence dia $diaVencimento" : "";
    final gastoText = 'Próxima Fatura: ${CurrencyFormatter.format(gasto)}';
    
    // Texto completo da esquerda
    final textoEsquerdo = fechaText.isNotEmpty && venceText.isNotEmpty 
        ? "$fechaText | $venceText"
        : (fechaText.isNotEmpty ? fechaText : venceText);

    return LayoutBuilder(
      builder: (context, constraints) {
        return _ResponsiveInfoLayout(
          textoEsquerdo: textoEsquerdo,
          gastoText: gastoText,
          maxWidth: constraints.maxWidth,
          diaFechamento: diaFechamento,
          diaVencimento: diaVencimento,
        );
      },
    );
  }

  /// Calcular utilização percentual
  double _calcularUtilizacao() {
    if ((cartao.limite ?? 0) <= 0 || !showUtilizacao) return 0.0;
    return ((valorUtilizado ?? 0) / cartao.limite!) * 100;
  }

  /// Obter status da utilização
  String _obterStatusUtilizacao(double utilizacao) {
    if (utilizacao >= 90) return 'critico';
    if (utilizacao >= 70) return 'alto';
    if (utilizacao >= 50) return 'medio';
    if (utilizacao >= 20) return 'baixo';
    return 'ok';
  }

  /// Obter cor da utilização
  Color _obterCorUtilizacao(double utilizacao) {
    if (utilizacao >= 90) return Colors.red.shade300;
    if (utilizacao >= 70) return Colors.orange.shade300;
    if (utilizacao >= 50) return Colors.yellow.shade300;
    return Colors.green.shade300;
  }

  /// Construir gradiente do cartão
  LinearGradient _buildGradiente(Color corBase) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        corBase,
        corBase.withOpacity(0.8),
        corBase.withOpacity(0.9),
      ],
    );
  }

  /// 🆕 LÓGICA INTELIGENTE DA FATURA
  Map<String, dynamic> _obterInfoFaturaInteligente() {
    if (faturaAtual == null) {
      return {
        'labelEsquerda': 'Fatura:',
        'labelDireita': 'Status:',
        'valorEsquerdo': 'R\$ 0,00',
        'valorDireito': 'SEM DADOS',
        'corEsquerdo': Colors.white.withOpacity(0.7),
        'corDireito': Colors.white.withOpacity(0.7),
        'status': 'vazia',
      };
    }
    
    final agora = DateTime.now();
    final vencimento = faturaAtual!.dataVencimento;
    final diasDiferenca = vencimento.difference(agora).inDays;
    
    // 🎯 FATURA PAGA
    if (faturaAtual!.paga) {
      return {
        'labelEsquerda': 'Fatura:',
        'labelDireita': 'Status:',
        'valorEsquerdo': CurrencyFormatter.format(faturaAtual!.valorTotal),
        'valorDireito': 'PAGA',
        'corEsquerdo': Colors.white,
        'corDireito': Colors.green.shade300,
        'status': 'paga',
      };
    }
    
    // 🎯 FATURA VENCIDA
    if (diasDiferenca < 0) {
      return {
        'labelEsquerda': 'Fatura:',
        'labelDireita': 'Vencida há:',
        'valorEsquerdo': CurrencyFormatter.format(faturaAtual!.valorRestante),
        'valorDireito': '${diasDiferenca.abs()} dias',
        'corEsquerdo': Colors.white,
        'corDireito': Colors.red.shade300,
        'status': 'vencida',
      };
    }
    
    // 🎯 FATURA FUTURA/PROJETADA (mais de 60 dias)
    if (diasDiferenca > 60) {
      return {
        'labelEsquerda': 'Projetado:',
        'labelDireita': 'Vence em:',
        'valorEsquerdo': CurrencyFormatter.format(faturaAtual!.valorTotal),
        'valorDireito': '${diasDiferenca} dias',
        'corEsquerdo': Colors.blue.shade300,
        'corDireito': Colors.white,
        'status': 'futura',
      };
    }
    
    // 🎯 FATURA ATUAL/PRÓXIMA (padrão)
    return {
      'labelEsquerda': 'Fatura:',
      'labelDireita': 'Vence em:',
      'valorEsquerdo': CurrencyFormatter.format(faturaAtual!.valorRestante),
      'valorDireito': '$diasDiferenca dias',
      'corEsquerdo': Colors.white,
      'corDireito': diasDiferenca <= 7 ? Colors.orange.shade300 : Colors.white,
      'status': diasDiferenca <= 7 ? 'vencendo' : 'aberta',
    };
  }

  /// 🆕 MENU DINÂMICO POR STATUS
  List<PopupMenuItem<String>> _buildMenuItems(String status) {
    final items = <PopupMenuItem<String>>[];

    // Pagar Fatura (se aplicável)
    if (status == 'vencida' || status == 'vencendo' || status == 'aberta') {
      items.add(
        const PopupMenuItem(
          value: 'pagar',
          child: Row(
            children: [
              Icon(Icons.payment, size: 20),
              SizedBox(width: 8),
              Text('Pagar Fatura'),
            ],
          ),
        ),
      );
    }

    // ✅ "Gestão Completa" - DESTACADO
    items.add(
      const PopupMenuItem(
        value: 'gestao_completa',
        child: Row(
          children: [
            Icon(Icons.dashboard, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text('Gestão Completa', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
          ],
        ),
      ),
    );

    // Extrato
    items.add(
      const PopupMenuItem(
        value: 'extrato',
        child: Row(
          children: [
            Icon(Icons.receipt_long, size: 20),
            SizedBox(width: 8),
            Text('Extrato'),
          ],
        ),
      ),
    );

    // Editar Cartão
    items.add(
      const PopupMenuItem(
        value: 'editar',
        child: Row(
          children: [
            Icon(Icons.edit, size: 20),
            SizedBox(width: 8),
            Text('Editar Cartão'),
          ],
        ),
      ),
    );

    // Ver Faturas
    items.add(
      const PopupMenuItem(
        value: 'ver_faturas',
        child: Row(
          children: [
            Icon(Icons.receipt_long, size: 20),
            SizedBox(width: 8),
            Text('Ver Faturas'),
          ],
        ),
      ),
    );

    // Adicionar Despesa
    items.add(
      const PopupMenuItem(
        value: 'add_despesa',
        child: Row(
          children: [
            Icon(Icons.add_shopping_cart, size: 20),
            SizedBox(width: 8),
            Text('Adicionar Despesa'),
          ],
        ),
      ),
    );

    // Arquivar
    items.add(
      const PopupMenuItem(
        value: 'arquivar',
        child: Row(
          children: [
            Icon(Icons.archive, size: 20),
            SizedBox(width: 8),
            Text('Arquivar'),
          ],
        ),
      ),
    );

    return items;
  }
}

/// Widget customizado que detecta overlap real entre elementos
class _ResponsiveInfoLayout extends StatefulWidget {
  final String textoEsquerdo;
  final String gastoText;
  final double maxWidth;
  final int? diaFechamento;
  final int? diaVencimento;

  const _ResponsiveInfoLayout({
    required this.textoEsquerdo,
    required this.gastoText,
    required this.maxWidth,
    this.diaFechamento,
    this.diaVencimento,
  });

  @override
  State<_ResponsiveInfoLayout> createState() => _ResponsiveInfoLayoutState();
}

class _ResponsiveInfoLayoutState extends State<_ResponsiveInfoLayout> {
  bool _useColumnLayout = false;
  
  @override
  Widget build(BuildContext context) {
    if (_useColumnLayout) {
      // Layout em 2 linhas quando há overlap
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primeira linha: Fecha e Vence
          if (widget.diaFechamento != null || widget.diaVencimento != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.textoEsquerdo,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          const SizedBox(height: 4),
          
          // Segunda linha: Gasto do período
          Text(
            widget.gastoText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      );
    }

    // Layout original em 1 linha - tenta primeiro
    return _OneLineLayout(
      textoEsquerdo: widget.textoEsquerdo,
      gastoText: widget.gastoText,
      diaFechamento: widget.diaFechamento,
      diaVencimento: widget.diaVencimento,
      onOverflow: () {
        // Callback quando detecta overflow - muda para layout em coluna
        if (mounted) {
          setState(() {
            _useColumnLayout = true;
          });
        }
      },
    );
  }
}

/// Widget que tenta layout em 1 linha e detecta overflow
class _OneLineLayout extends StatefulWidget {
  final String textoEsquerdo;
  final String gastoText;
  final int? diaFechamento;
  final int? diaVencimento;
  final VoidCallback onOverflow;

  const _OneLineLayout({
    required this.textoEsquerdo,
    required this.gastoText,
    this.diaFechamento,
    this.diaVencimento,
    required this.onOverflow,
  });

  @override
  State<_OneLineLayout> createState() => _OneLineLayoutState();
}

class _OneLineLayoutState extends State<_OneLineLayout> {
  final GlobalKey _leftKey = GlobalKey();
  final GlobalKey _rightKey = GlobalKey();
  bool _hasCheckedOverflow = false;

  @override
  void initState() {
    super.initState();
    // Agenda verificação de overflow para após o primeiro build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  void _checkOverflow() {
    if (_hasCheckedOverflow) return;
    
    final leftRenderBox = _leftKey.currentContext?.findRenderObject() as RenderBox?;
    final rightRenderBox = _rightKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (leftRenderBox != null && rightRenderBox != null) {
      final leftSize = leftRenderBox.size;
      final leftPosition = leftRenderBox.localToGlobal(Offset.zero);
      final rightPosition = rightRenderBox.localToGlobal(Offset.zero);
      
      // Calcular se há sobreposição
      final leftEnd = leftPosition.dx + leftSize.width;
      final rightStart = rightPosition.dx;
      
      // Se o final do elemento esquerdo ultrapassa o início do direito (com margem)
      if (leftEnd + 8 > rightStart) { // 8px de margem mínima
        _hasCheckedOverflow = true;
        widget.onOverflow();
        return;
      }
    }
    
    _hasCheckedOverflow = true;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Fecha e Vence com fundo (esquerda)
        if (widget.diaFechamento != null || widget.diaVencimento != null)
          Container(
            key: _leftKey,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.textoEsquerdo,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Gasto do período (direita)
        Container(
          key: _rightKey,
          child: Text(
            widget.gastoText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}