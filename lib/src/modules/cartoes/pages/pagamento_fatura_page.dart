// 💳 Pagamento de Fatura - iPoupei Mobile
//
// Página de pagamento de fatura adaptada do projeto device
// Compatível com a arquitetura mobile existente
//
// Features:
// - 3 tipos de pagamento: Integral, Parcial, Parcelado
// - Interface adaptada para mobile
// - Validações em tempo real
// - Preview dos valores
// - Sistema de feedback integrado

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Imports do projeto mobile
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/app_button.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/components/ui/smart_currency_input.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/fatura_operations_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../../shared/utils/operation_feedback_helper.dart';
import '../../transacoes/components/tipo_selector.dart';
import '../../transacoes/components/smart_field.dart';

/// ✅ FORMATTER EXATO DO PROJETO ORIGINAL
class MoneyInputFormatter extends TextInputFormatter {
  final bool allowNegative;

  MoneyInputFormatter({this.allowNegative = true});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    try {
      final numbersOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (numbersOnly.isEmpty) {
        return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      }

      final number = int.parse(numbersOnly);
      final formatted = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: '',
        decimalDigits: 2,
      ).format(number / 100);

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}

class PagamentoFaturaPage extends StatefulWidget {
  final FaturaModel fatura;
  final CartaoModel cartao;

  const PagamentoFaturaPage({
    super.key,
    required this.fatura,
    required this.cartao,
  });

  @override
  State<PagamentoFaturaPage> createState() => _PagamentoFaturaPageState();
}

class _PagamentoFaturaPageState extends State<PagamentoFaturaPage> {
  // Services
  final _faturaService = FaturaOperationsService.instance;
  final _contaService = ContaService.instance;

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _parcelasController = TextEditingController(text: '2');
  final _valorParcelaController = TextEditingController();
  
  // Focus nodes
  final _valorFocus = FocusNode();
  final _parcelasFocus = FocusNode();

  // Estado do formulário
  String _tipoPagamento = 'integral';
  Map<String, dynamic> _formData = {};
  bool _isProcessando = false;
  List<ContaModel> _contas = [];

  // Tipos de pagamento com padrão TipoSelector (com descrições para forçar tamanhos)
  static const List<TipoSelectorOption> _tiposPagamento = [
    TipoSelectorOption(
      id: 'integral',
      nome: 'Integral',
      icone: Icons.paid,
      descricao: 'Pagar tudo',
      cor: Colors.green,
    ),
    TipoSelectorOption(
      id: 'parcial',
      nome: 'Parcial',
      icone: Icons.pie_chart,
      descricao: 'Pagar parte',
      cor: Colors.orange,
    ),
    TipoSelectorOption(
      id: 'parcelado',
      nome: 'Parcelado',
      icone: Icons.timeline,
      descricao: 'Em parcelas',
      cor: Colors.blue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadContas();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _parcelasController.dispose();
    _valorParcelaController.dispose();
    _valorFocus.dispose();
    _parcelasFocus.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _tipoPagamento = 'integral';
    
    _formData = {
      'tipoPagamento': _tipoPagamento,
      'valor': CurrencyFormatter.formatForInput(widget.fatura.valorRestante),
      'contaSelecionada': null,
      'faturaDestino': null,
      'numeroParcelas': 2,
    };
    
    // Pré-preencher valor formatado para integral
    _valorController.text = CurrencyFormatter.formatForInput(widget.fatura.valorRestante);
  }

  Future<void> _loadContas() async {
    try {
      final contas = await _contaService.getContasAtivas();
      setState(() {
        _contas = contas;
        // Pré-selecionar conta padrão do cartão se disponível
        if (widget.cartao.contaDebitoId != null) {
          final contaPadrao = contas.firstWhere(
            (c) => c.id == widget.cartao.contaDebitoId,
            orElse: () => contas.first,
          );
          _formData['contaSelecionada'] = contaPadrao;
        } else if (contas.isNotEmpty) {
          _formData['contaSelecionada'] = contas.first;
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar contas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      foregroundColor: AppColors.branco,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context, false),
      ),
      title: const Text(
        'Pagar Fatura',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _isProcessando ? null : _confirmarPagamento,
          child: Text(
            'PAGAR',
            style: TextStyle(
              color: _isProcessando 
                  ? AppColors.cinzaMedio
                  : AppColors.branco,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildResumoFatura(),
            const SizedBox(height: 20),
            _buildTipoSelector(),
            const SizedBox(height: 20),
            _buildCamposBasicos(),
            const SizedBox(height: 16),
            _buildCamposCondicionais(),
            const SizedBox(height: 20),
            _buildPreview(),
            const SizedBox(height: 32),
            _buildBotoesAcao(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoFatura() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roxoTransparente10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.roxoTransparente20,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.cartao.nome} - ${widget.fatura.periodoFormatado}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.roxoHeader,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoLinha('💰', 'Valor', widget.fatura.valorTotalFormatado),
          _buildInfoLinha('⏰', 'Vence', _calcularDiasVencimento()),
          _buildInfoLinha('✅', 'Pago', widget.fatura.valorPagoFormatado),
          _buildInfoLinha('🔴', 'Restante', widget.fatura.valorRestanteFormatado),
        ],
      ),
    );
  }

  Widget _buildInfoLinha(String emoji, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMO VOCÊ QUER PAGAR?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.cinzaTexto,
          ),
        ),
        const SizedBox(height: 12),
        TipoSelector(
          tipoSelecionado: _tipoPagamento,
          onChanged: _onTipoChanged,
          tipos: _tiposPagamento,
        ),
      ],
    );
  }


  Widget _buildCamposBasicos() {
    return Column(
      children: [
        // Frase explicativa do tipo selecionado
        if (_tipoPagamento.isNotEmpty) ...[
          Text(
            _getFraseExplicativa(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        
        // Campo Valor - só aparece para parcial
        if (_tipoPagamento == 'parcial') ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppColors.roxoHeader,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Valor do Pagamento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _valorController,
                focusNode: _valorFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  MoneyInputFormatter(allowNegative: false),
                ],
                onChanged: (valor) {
                  _formData['valor'] = valor;
                  setState(() {});
                },
                validator: _validarValor,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.cinzaEscuro,
                ),
                decoration: InputDecoration(
                  hintText: 'R\$ 0,00',
                  hintStyle: const TextStyle(
                    color: AppColors.cinzaTexto,
                    fontSize: 16,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinzaBorda),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinzaBorda),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.roxoHeader, width: 2),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.vermelhoErro),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.vermelhoErro, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Campos de parcelado (ficam acima da conta)
        if (_tipoPagamento == 'parcelado') ...[
          Row(
            children: [
              // Número de Parcelas com SmartField roxa
              Expanded(
                child: SmartField(
                  key: const ValueKey('numero_parcelas'),
                  controller: _parcelasController,
                  focusNode: _parcelasFocus,
                  label: 'Número de Parcelas',
                  hint: '2',
                  icon: Icons.timeline,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  isCartaoContext: true, // Isso deixa a cor roxa
                  onChanged: (valor) {
                    _formData['numeroParcelas'] = int.tryParse(valor) ?? 2;
                    setState(() {});
                  },
                  validator: (value) {
                    final parcelas = int.tryParse(value ?? '') ?? 0;
                    if (parcelas < 2) return 'Mínimo de 2 parcelas';
                    if (parcelas > 60) return 'Máximo de 60 parcelas';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _buildSetinha(Icons.keyboard_arrow_up, () => _ajustarParcelas(1)),
                  _buildSetinha(Icons.keyboard_arrow_down, () => _ajustarParcelas(-1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // ✅ CAMPO VALOR DA PARCELA (APÓS NÚMERO DE PARCELAS)
          SmartField(
            key: const ValueKey('valor_parcela'),
            controller: _valorParcelaController,
            focusNode: _valorFocus,
            label: 'Valor da Parcela',
            hint: 'R\$ 0,00',
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            isCartaoContext: true, // Cor roxa
            onChanged: (valor) {
              _formData['valorParcela'] = CurrencyFormatter.parse(valor);
              setState(() {});
            },
            validator: (value) {
              final valorParcela = CurrencyFormatter.parse(value ?? '');
              if (valorParcela <= 0) return 'Valor deve ser maior que zero';
              return null;
            },
          ),
          
          // ✅ MENSAGEM EXPLICATIVA EM VERMELHO
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              '* Valor informado pelo banco por parcela',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
        
        // Campo Conta usando SmartField com dropdown simulado
        SmartField(
          key: const ValueKey('conta_debito'),
          label: 'Conta para Débito',
          hint: 'Selecione uma conta',
          icon: Icons.account_balance,
          value: _formData['contaSelecionada'] != null 
              ? '${(_formData['contaSelecionada'] as ContaModel).nome} - ${CurrencyFormatter.format((_formData['contaSelecionada'] as ContaModel).saldo)}'
              : '',
          readOnly: true,
          onTap: _mostrarSeletorConta,
          validator: (value) => _formData['contaSelecionada'] == null ? 'Selecione uma conta' : null,
          isCartaoContext: true,
        ),
      ],
    );
  }

  Widget _buildCamposCondicionais() {
    // Campos condicionais agora estão integrados em _buildCamposBasicos
    return const SizedBox.shrink();
  }

  Widget _buildSetinha(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.roxoTransparente10,
          borderRadius: icon == Icons.keyboard_arrow_up 
              ? const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                )
              : const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildPreview() {
    final simulacao = _simularPagamento();
    
    if (simulacao['erro'] != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.vermelhoErro10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.vermelhoErro20,
          ),
        ),
        child: Row(
          children: [
            const Text('❌', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                simulacao['erro'],
                style: const TextStyle(
                  color: AppColors.vermelhoErro,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roxoTransparente10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.roxoTransparente20,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Preview do ${simulacao['tipo']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.roxoHeader,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_buildPreviewContent(simulacao)),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Row(
      children: [
        Expanded(
          child: AppButton.outline(
            text: 'CANCELAR',
            onPressed: _isProcessando ? null : () => Navigator.pop(context, false),
            customColor: AppColors.roxoHeader,
            icon: Icons.arrow_back,
            fullWidth: true,
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: AppButton(
            text: _isProcessando ? 'PROCESSANDO...' : 'PAGAR',
            onPressed: _isProcessando ? null : _confirmarPagamento,
            variant: AppButtonVariant.primary,
            customColor: AppColors.roxoHeader,
            fullWidth: true,
            isLoading: _isProcessando,
          ),
        ),
      ],
    );
  }

  void _onTipoChanged(String novoTipo) {
    setState(() {
      _tipoPagamento = novoTipo;
      _formData['tipoPagamento'] = novoTipo;
      
      if (novoTipo == 'integral') {
        _valorController.text = CurrencyFormatter.formatForInput(widget.fatura.valorRestante);
        _formData['valor'] = CurrencyFormatter.formatForInput(widget.fatura.valorRestante);
      } else if (novoTipo == 'parcial') {
        // Forçar limpeza completa para o modo parcial
        _valorController.clear();
        _formData['valor'] = '';
      } else {
        _valorController.text = '';
        _formData['valor'] = '';
      }
      
      // Limpar campo de valor da parcela quando mudar tipo
      if (novoTipo != 'parcelado') {
        _valorParcelaController.text = '';
        _formData['valorParcela'] = 0.0;
      }
    });
  }

  String _getFraseExplicativa() {
    switch (_tipoPagamento) {
      case 'integral':
        return 'Quitar fatura completa';
      case 'parcial':
        return 'Pagar parte e transferir restante';
      case 'parcelado':
        return 'Dividir em parcelas futuras';
      default:
        return '';
    }
  }

  Color _getCorTipo() {
    switch (_tipoPagamento) {
      case 'integral':
        return Colors.green;
      case 'parcial':
        return Colors.orange;
      case 'parcelado':
        return Colors.blue;
      default:
        return AppColors.cinzaTexto;
    }
  }

  void _mostrarSeletorConta() async {
    final conta = await showModalBottomSheet<ContaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle do modal
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cinzaClaro,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Título
                  Text(
                    'Selecione uma conta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Lista scrollável
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _contas.length,
                      itemBuilder: (context, index) {
                        final contaItem = _contas[index];
                        return ListTile(
                          leading: Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.roxoHeader,
                          ),
                          title: Text(contaItem.nome),
                          subtitle: Text(CurrencyFormatter.format(contaItem.saldo)),
                          onTap: () => Navigator.pop(context, contaItem),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
    
    if (conta != null) {
      setState(() {
        _formData['contaSelecionada'] = conta;
      });
    }
  }

  void _ajustarParcelas(int incremento) {
    final parcelasAtual = int.tryParse(_parcelasController.text) ?? 2;
    final novasParcelas = (parcelasAtual + incremento).clamp(2, 60);
    
    setState(() {
      _parcelasController.text = novasParcelas.toString();
      _formData['numeroParcelas'] = novasParcelas;
    });
  }

  String? _validarValor(String? value) {
    if (_tipoPagamento == 'integral') return null;
    if (_tipoPagamento == 'parcelado') return null; // No modo parcelado, não validamos o campo valor principal
    
    final valor = CurrencyFormatter.parse(value ?? '0');
    if (valor <= 0) return 'Valor deve ser maior que zero';
    if (valor > widget.fatura.valorRestante) return 'Valor maior que o restante da fatura';
    if (_tipoPagamento == 'parcial' && valor >= widget.fatura.valorRestante) {
      return 'Para pagamento parcial, valor deve ser menor que o total';
    }
    return null;
  }

  Map<String, dynamic> _simularPagamento() {
    final valorString = _tipoPagamento == 'integral' 
        ? CurrencyFormatter.formatForInput(widget.fatura.valorRestante)
        : (_formData['valor'] ?? '0');
    final valor = CurrencyFormatter.parse(valorString);
    
    // No modo parcelado, não exigimos validação do valor principal
    if (_tipoPagamento != 'parcelado') {
      if (valor <= 0) return {'erro': 'Informe um valor válido'};
      if (valor > widget.fatura.valorRestante) return {'erro': 'Valor maior que o saldo da fatura'};
    }
    
    switch (_tipoPagamento) {
      case 'integral':
        return {
          'tipo': 'Pagamento Integral',
          'resumo': ['Fatura será quitada completamente', 'Todas as transações serão efetivadas']
        };
        
      case 'parcial':
        return {
          'tipo': 'Pagamento Parcial',
          'resumo': [
            'Será pago: ${CurrencyFormatter.format(valor)}',
            'Restante: ${CurrencyFormatter.format(widget.fatura.valorRestante - valor)} → Próxima fatura'
          ]
        };
        
      case 'parcelado':
        final parcelas = _formData['numeroParcelas'] ?? 2;
        final valorOriginal = widget.fatura.valorRestante;
        final valorParcelaStr = _valorParcelaController.text;
        final valorParcela = CurrencyFormatter.parse(valorParcelaStr);
        
        // Validar se valor da parcela foi preenchido
        if (valorParcela <= 0) {
          return {'erro': 'Informe o valor da parcela'};
        }
        
        final valorTotalParcelado = valorParcela * parcelas;
        
        // Validação: valor total não pode ser menor que o valor da fatura
        if (valorTotalParcelado < valorOriginal) {
          return {
            'erro': 'Valor total das parcelas (${CurrencyFormatter.format(valorTotalParcelado)}) não pode ser menor que o valor da fatura (${CurrencyFormatter.format(valorOriginal)})'
          };
        }
        
        final prejuizo = valorTotalParcelado - valorOriginal;
        final percentualJuros = (prejuizo / valorOriginal) * 100;
        
        return {
          'tipo': 'Pagamento Parcelado',
          'resumo': [
            '✅ Fatura atual: Será quitada completamente (${CurrencyFormatter.format(valorOriginal)})',
            '💳 Débito na conta: ${CurrencyFormatter.format(valorOriginal)}',
            '📅 Parcelas futuras: ${parcelas}x de ${CurrencyFormatter.format(valorParcela)}',
            '💰 Total a pagar: ${CurrencyFormatter.format(valorTotalParcelado)}',
            prejuizo > 0 
              ? '📈 Custo adicional: ${CurrencyFormatter.format(prejuizo)} (+${percentualJuros.toStringAsFixed(1)}%)'
              : '✅ Sem custos adicionais'
          ]
        };
        
      default:
        return {'erro': 'Tipo de pagamento inválido'};
    }
  }

  List<Widget> _buildPreviewContent(Map<String, dynamic> simulacao) {
    final resumo = simulacao['resumo'] as List<String>? ?? [];
    
    return resumo.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('🔹', style: TextStyle(fontSize: 12, color: AppColors.roxoHeader)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.cinzaEscuro,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  String _calcularDiasVencimento() {
    final hoje = DateTime.now();
    final vencimento = widget.fatura.dataVencimento;
    final diferenca = vencimento.difference(hoje).inDays;
    
    if (diferenca < 0) {
      return 'Vencida há ${diferenca.abs()} dias';
    } else if (diferenca == 0) {
      return 'Vence hoje';
    } else if (diferenca == 1) {
      return 'Vence amanhã';
    } else {
      return 'Vence em $diferenca dias';
    }
  }

  Future<void> _confirmarPagamento() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Mostrar modal de confirmação
    final dataPagamento = await _mostrarModalConfirmacao();
    if (dataPagamento == null) return;
    
    setState(() { _isProcessando = true; });
    
    try {
      final conta = _formData['contaSelecionada'] as ContaModel;
      final valorString = _tipoPagamento == 'integral' 
          ? CurrencyFormatter.formatForInput(widget.fatura.valorRestante)
          : (_formData['valor'] ?? '0');
      final valor = CurrencyFormatter.parse(valorString);
      
      Map<String, dynamic> resultado = {};
      
      switch (_tipoPagamento) {
        case 'integral':
          resultado = await _faturaService.pagarFaturaIntegral(
            cartaoId: widget.cartao.id,
            faturaVencimento: widget.fatura.dataVencimento.toIso8601String().split('T')[0],
            contaId: conta.id,
            dataPagamento: dataPagamento,
          );
          break;
          
        case 'parcial':
          resultado = await _faturaService.pagarFaturaParcial(
            cartaoId: widget.cartao.id,
            faturaVencimento: widget.fatura.dataVencimento.toIso8601String().split('T')[0],
            contaId: conta.id,
            valorTotal: widget.fatura.valorTotal, // VALOR TOTAL ORIGINAL DA FATURA
            valorPago: valor,                        // VALOR QUE O USUÁRIO QUER PAGAR
            faturaDestino: _calcularProximaFatura(),
            dataPagamento: dataPagamento,
            cartaoNome: widget.cartao.nome,
            contaNome: conta.nome,
          );
          break;
          
        case 'parcelado':
          resultado = await _faturaService.pagarFaturaParcelado(
            cartaoId: widget.cartao.id,
            faturaVencimento: widget.fatura.dataVencimento.toIso8601String().split('T')[0],
            contaId: conta.id,
            valorTotal: widget.fatura.valorRestante,
            numeroParcelas: _formData['numeroParcelas'] ?? 2,
            valorParcela: _formData['valorParcela'] ?? 0.0,
            dataPagamento: dataPagamento,
            cartaoNome: widget.cartao.nome,
            contaNome: conta.nome,
          );
          break;
      }
      
      if (mounted) {
        if (resultado['success'] == true) {
          // ✅ Sistema Universal de Feedback
          await OperationFeedbackHelper.executeWithNavigation(
            context: context,
            operation: OperationType.update,
            entityName: 'pagamento de fatura',
            operationFunction: () async {
              return true; // Operação já foi executada com sucesso
            },
            onRefreshComplete: () async {
              // Aguardar sync processar e então atualizar saldos
              try {
                debugPrint('🔄 Aguardando sync processar...');
                await Future.delayed(const Duration(milliseconds: 1500));
                
                await ContaService.instance.fetchContas();
                debugPrint('✅ Saldos das contas atualizados após pagamento');
              } catch (e) {
                debugPrint('❌ Erro ao atualizar saldos das contas: $e');
              }
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['error'] ?? 'Erro ao processar pagamento'),
              backgroundColor: AppColors.vermelhoErro,
            ),
          );
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessando = false; });
      }
    }
  }

  Future<DateTime?> _mostrarModalConfirmacao() async {
    DateTime dataSelecionada = DateTime.now();
    final dataVencimento = widget.fatura.dataVencimento;
    bool usarDataVencimento = false;
    
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 
                        MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildConfirmacaoHeader(),
                  _buildConfirmacaoBody(
                    setModalState, 
                    usarDataVencimento, 
                    dataSelecionada, 
                    dataVencimento,
                    (bool useVencimento, DateTime newDate) {
                      usarDataVencimento = useVencimento;
                      dataSelecionada = newDate;
                    }
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmacaoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.roxoHeader,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payment,
            color: AppColors.branco,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirmar Pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.branco,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.branco),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmacaoBody(
    StateSetter setModalState,
    bool usarDataVencimento,
    DateTime dataSelecionada,
    DateTime dataVencimento,
    Function(bool, DateTime) onDateChange,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfirmacaoResumo(),
          const SizedBox(height: 24),
          _buildConfirmacaoSeletorData(
            setModalState,
            usarDataVencimento,
            dataSelecionada,
            dataVencimento,
            onDateChange,
          ),
          const SizedBox(height: 32),
          _buildConfirmacaoBotoes(dataSelecionada),
        ],
      ),
    );
  }

  Widget _buildConfirmacaoResumo() {
    final valorString = _tipoPagamento == 'integral' 
        ? CurrencyFormatter.formatForInput(widget.fatura.valorRestante)
        : (_formData['valor'] ?? '0');
    final valor = CurrencyFormatter.parse(valorString);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roxoTransparente10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.roxoTransparente20,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.credit_card,
                color: AppColors.roxoHeader,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.cartao.nome,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.cinzaEscuro,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Valor a pagar',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(valor),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.roxoHeader,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Vencimento',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(widget.fatura.dataVencimento),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmacaoSeletorData(
    StateSetter setModalState,
    bool usarDataVencimento,
    DateTime dataSelecionada,
    DateTime dataVencimento,
    Function(bool, DateTime) onDateChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data do Pagamento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.cinzaEscuro,
          ),
        ),
        const SizedBox(height: 16),
        
        // Opção: Data personalizada (hoje)
        _buildOpcaoData(
          context: context,
          setModalState: setModalState,
          isSelected: !usarDataVencimento,
          titulo: 'Hoje',
          data: dataSelecionada,
          icon: Icons.today,
          onTap: () {
            setModalState(() {
              onDateChange(false, DateTime.now());
            });
          },
          onEditTap: !usarDataVencimento ? () async {
            final novaData = await showDatePicker(
              context: context,
              initialDate: dataSelecionada,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              locale: const Locale('pt', 'BR'),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.roxoHeader,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (novaData != null) {
              setModalState(() {
                onDateChange(false, novaData);
              });
            }
          } : null,
        ),
        
        const SizedBox(height: 12),
        
        // Opção: Data de vencimento
        _buildOpcaoData(
          context: context,
          setModalState: setModalState,
          isSelected: usarDataVencimento,
          titulo: 'Data de vencimento',
          data: dataVencimento,
          icon: Icons.schedule,
          onTap: () {
            setModalState(() {
              onDateChange(true, dataVencimento);
            });
          },
        ),
      ],
    );
  }

  Widget _buildOpcaoData({
    required BuildContext context,
    required StateSetter setModalState,
    required bool isSelected,
    required String titulo,
    required DateTime data,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onEditTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? AppColors.roxoHeader 
                : AppColors.cinzaBorda,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? AppColors.roxoTransparente10
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected 
                  ? Icons.radio_button_checked 
                  : Icons.radio_button_unchecked,
              color: isSelected 
                  ? AppColors.roxoHeader 
                  : AppColors.cinzaTexto,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.cinzaEscuro,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(data),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                ],
              ),
            ),
            if (onEditTap != null)
              IconButton(
                icon: const Icon(
                  Icons.edit_calendar,
                  color: AppColors.roxoHeader,
                ),
                onPressed: onEditTap,
              )
            else
              Icon(
                icon,
                color: AppColors.roxoTransparente50,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmacaoBotoes(DateTime dataSelecionada) {
    return Row(
      children: [
        // Botão Cancelar
        Expanded(
          child: AppButton.outline(
            text: 'CANCELAR',
            onPressed: () => Navigator.of(context).pop(null),
            customColor: AppColors.cinzaTexto,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Botão Confirmar
        Expanded(
          child: AppButton(
            text: 'CONFIRMAR',
            icon: Icons.payment,
            onPressed: () => Navigator.of(context).pop(dataSelecionada),
            customColor: AppColors.roxoHeader,
          ),
        ),
      ],
    );
  }

  String _calcularProximaFatura() {
    final proximoMes = DateTime(
      widget.fatura.dataVencimento.year,
      widget.fatura.dataVencimento.month + 1,
      widget.fatura.dataVencimento.day,
    );
    return proximoMes.toIso8601String().split('T')[0];
  }
}