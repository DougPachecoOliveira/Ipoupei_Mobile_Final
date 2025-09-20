import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cartao_model.dart';
import '../services/cartao_service.dart';
import '../../transacoes/components/smart_field.dart';
import '../../shared/theme/app_colors.dart';
import '../../contas/services/conta_service.dart';

/// MoneyInputFormatter - formatação de moeda
class MoneyInputFormatter extends TextInputFormatter {
  final bool allowNegative;

  MoneyInputFormatter({this.allowNegative = true});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove todos os caracteres não numéricos
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Converte para double e formata
    double value = double.parse(digits) / 100;
    String formatted = 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

    // Adiciona separador de milhares
    if (value >= 1000) {
      List<String> parts = formatted.split(',');
      String intPart = parts[0].replaceAll('R\$ ', '');
      String formattedInt = '';
      
      for (int i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) {
          formattedInt += '.';
        }
        formattedInt += intPart[i];
      }
      
      formatted = 'R\$ $formattedInt,${parts[1]}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Página de CRUD de Cartões
/// Equivalente ao CartoesModal.jsx do React 
class CartoesModalPage extends StatefulWidget {
  final CartaoModel? cartao; // null = criar, not null = editar

  const CartoesModalPage({
    Key? key,
    this.cartao,
  }) : super(key: key);

  @override
  State<CartoesModalPage> createState() => _CartoesModalPageState();
}

class _CartoesModalPageState extends State<CartoesModalPage> {
  final CartaoService _cartaoService = CartaoService.instance;
  final ContaService _contaService = ContaService.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nomeController = TextEditingController();
  final _limiteController = TextEditingController();
  final _bandeiraController = TextEditingController();
  final _contaPadraoController = TextEditingController();
  final _diaFechamentoController = TextEditingController();
  final _diaVencimentoController = TextEditingController();
  final _observacoesController = TextEditingController();

  bool _isLoading = false;
  String _corSelecionada = '#8A05BE'; // Nubank roxinho (cor padrão)
  String? _bandeiraSelecionada;
  String? _contaPadraoSelecionada;
  bool _cartaoPadrao = false;
  Map<String, dynamic> _alteracoesDetectadas = {};
  Map<String, dynamic> _valoresOriginais = {};

  @override
  void initState() {
    super.initState();
    _preencherFormulario();
  }

  void _preencherFormulario() {
    if (widget.cartao != null) {
      final cartao = widget.cartao!;
      _nomeController.text = cartao.nome;
      _limiteController.text = cartao.limite.toString();
      _bandeiraController.text = cartao.bandeira ?? '';
      _bandeiraSelecionada = cartao.bandeira;
      _contaPadraoController.text = cartao.banco ?? ''; // Temporário - depois será conta_id
      _cartaoPadrao = false; // TODO: Implementar lógica de cartão padrão
      _diaFechamentoController.text = cartao.diaFechamento.toString();
      _diaVencimentoController.text = cartao.diaVencimento.toString();
      _observacoesController.text = cartao.observacoes ?? '';
      _corSelecionada = cartao.cor ?? '#8A05BE';
      
      // Salvar valores originais para detectar alterações
      _valoresOriginais = {
        'nome': cartao.nome,
        'limite': cartao.limite,
        'bandeira': cartao.bandeira,
        'conta': cartao.banco, // Temporário
        'diaFechamento': cartao.diaFechamento,
        'diaVencimento': cartao.diaVencimento,
        'cor': cartao.cor ?? '#8A05BE',
        'cartaoPadrao': false, // TODO: Implementar lógica
        'observacoes': cartao.observacoes,
      };
    } else {
      // Valores padrão para novo cartão (iguais ao React)
      _diaFechamentoController.text = '5';
      _diaVencimentoController.text = '15';
      _corSelecionada = '#8A05BE';
      _valoresOriginais = {}; // Novo cartão = sem valores originais
    }
    
    // Adicionar listeners para detectar mudanças
    _adicionarListeners();
  }
  
  void _adicionarListeners() {
    _nomeController.addListener(_detectarAlteracoes);
    _limiteController.addListener(_detectarAlteracoes);
    _diaFechamentoController.addListener(_detectarAlteracoes);
    _diaVencimentoController.addListener(_detectarAlteracoes);
    _contaPadraoController.addListener(_detectarAlteracoes);
    _observacoesController.addListener(_detectarAlteracoes);
  }
  
  void _detectarAlteracoes() {
    if (_valoresOriginais.isEmpty) return; // Novo cartão
    
    setState(() {
      _alteracoesDetectadas.clear();
      
      // Verificar cada campo
      if (_nomeController.text != _valoresOriginais['nome']) {
        _alteracoesDetectadas['nome'] = 'Nome alterado: ${_valoresOriginais['nome']} → ${_nomeController.text}';
      }
      
      final limiteAtual = double.tryParse(_limiteController.text) ?? 0;
      if (limiteAtual != _valoresOriginais['limite']) {
        _alteracoesDetectadas['limite'] = 'Limite alterado: R\$ ${_valoresOriginais['limite']} → R\$ $limiteAtual';
      }
      
      if (_bandeiraSelecionada != _valoresOriginais['bandeira']) {
        _alteracoesDetectadas['bandeira'] = 'Bandeira alterada: ${_valoresOriginais['bandeira'] ?? 'Não definida'} → ${_bandeiraSelecionada ?? 'Não definida'}';
      }
      
      if (_contaPadraoController.text != _valoresOriginais['conta']) {
        _alteracoesDetectadas['conta'] = 'Conta padrão alterada';
      }
      
      final fechamentoAtual = int.tryParse(_diaFechamentoController.text) ?? 0;
      if (fechamentoAtual != _valoresOriginais['diaFechamento']) {
        _alteracoesDetectadas['fechamento'] = 'Dia de fechamento alterado: ${_valoresOriginais['diaFechamento']} → $fechamentoAtual';
      }
      
      final vencimentoAtual = int.tryParse(_diaVencimentoController.text) ?? 0;
      if (vencimentoAtual != _valoresOriginais['diaVencimento']) {
        _alteracoesDetectadas['vencimento'] = 'Dia de vencimento alterado: ${_valoresOriginais['diaVencimento']} → $vencimentoAtual';
      }
      
      if (_corSelecionada != _valoresOriginais['cor']) {
        _alteracoesDetectadas['cor'] = 'Cor alterada';
      }
      
      if (_cartaoPadrao != _valoresOriginais['cartaoPadrao']) {
        _alteracoesDetectadas['padrao'] = _cartaoPadrao ? 'Definido como padrão' : 'Removido como padrão';
      }
      
      if (_observacoesController.text != (_valoresOriginais['observacoes'] ?? '')) {
        _alteracoesDetectadas['observacoes'] = 'Observações alteradas';
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _limiteController.dispose();
    _bandeiraController.dispose();
    _contaPadraoController.dispose();
    _diaFechamentoController.dispose();
    _diaVencimentoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.roxoHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gestão do Cartão',
          style: TextStyle(
            color: Colors.white, 
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // SALVAR no AppBar igual ao despesa_cartao_page
          TextButton(
            onPressed: _isLoading ? null : _salvarCartao,
            child: Text(
              'SALVAR',
              style: TextStyle(
                color: !_isLoading ? Colors.white : AppColors.cinzaMedio,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Preview Card (dinâmico)
                _buildPreviewCard(),
                
                // Form scrollável
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome do Cartão
                          SmartField(
                            controller: _nomeController,
                            label: 'Nome do Cartão *',
                            hint: 'Ex: BTG+ Mastercard',
                            icon: Icons.credit_card,
                            isCartaoContext: true,
                            onChanged: (_) => _detectarAlteracoes(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nome é obrigatório';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Bandeira
                          SmartField(
                            label: 'Bandeira',
                            hint: 'MASTERCARD',
                            icon: Icons.payment,
                            value: _bandeiraSelecionada ?? '',
                            readOnly: true,
                            onTap: _selecionarBandeira,
                            isCartaoContext: true,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Limite do Cartão
                          SmartField(
                            controller: _limiteController,
                            label: 'Limite do Cartão *',
                            hint: 'R\$ 8.000,00',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            inputFormatters: [MoneyInputFormatter()],
                            isCartaoContext: true,
                            onChanged: (_) => _detectarAlteracoes(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Limite é obrigatório';
                              }
                              // Parse do valor formatado com vírgula
                              final cleanValue = value.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
                              final limite = double.tryParse(cleanValue);
                              if (limite == null || limite <= 0) {
                                return 'Limite deve ser maior que zero';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Row com Fechamento e Vencimento  
                          Row(
                            children: [
                              // Dia Fechamento
                              Expanded(
                                child: SmartField(
                                  controller: _diaFechamentoController,
                                  label: 'Dia Fechamento *',
                                  hint: '22',
                                  icon: Icons.calendar_today,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  isCartaoContext: true,
                                  onChanged: (_) => _detectarAlteracoes(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Obrigatório';
                                    }
                                    final dia = int.tryParse(value);
                                    if (dia == null || dia < 1 || dia > 31) {
                                      return 'Entre 1 e 31';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Dia Vencimento
                              Expanded(
                                child: SmartField(
                                  controller: _diaVencimentoController,
                                  label: 'Dia Vencimento *',
                                  hint: '2',
                                  icon: Icons.event,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  isCartaoContext: true,
                                  onChanged: (_) => _detectarAlteracoes(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Obrigatório';
                                    }
                                    final dia = int.tryParse(value);
                                    if (dia == null || dia < 1 || dia > 31) {
                                      return 'Entre 1 e 31';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Conta Padrão para Pagamento
                          SmartField(
                            label: 'Conta Padrão para Pagamento',
                            hint: 'Selecione uma conta (opcional)',
                            icon: Icons.account_balance,
                            value: _contaPadraoSelecionada ?? '',
                            readOnly: true,
                            onTap: _selecionarContaPadrao,
                            isCartaoContext: true,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Cor do Cartão (visual igual às imagens)
                          _buildSeletorCor(),
                          
                          const SizedBox(height: 24),
                          
                          // Toggle Cartão de Crédito Padrão
                          _buildToggleCartaoPadrao(),
                          
                          const SizedBox(height: 24),
                          
                          
                          const SizedBox(height: 24),
                          
                          // Botões de ação (scrolláveis)
                          Row(
                            children: [
                              // Botão CANCELAR scrollável
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.roxoHeader),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.arrow_back, color: AppColors.roxoHeader, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'CANCELAR',
                                        style: TextStyle(
                                          color: AppColors.roxoHeader,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Botão SALVAR scrollável
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _salvarCartao,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.roxoHeader,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                                          'SALVAR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  // ===== WIDGETS DE BUILD =====
  
  /// Preview Card do cartão (tamanho médio)
  Widget _buildPreviewCard() {
    final nome = _nomeController.text.isNotEmpty ? _nomeController.text : 'Nome do Cartão';
    final bandeira = _bandeiraSelecionada ?? 'MASTERCARD';
    final limite = _limiteController.text.isNotEmpty ? 
      'R\$ ${_limiteController.text}' : 'R\$ 8.000,00';
    final fechamento = _diaFechamentoController.text.isNotEmpty ? 
      _diaFechamentoController.text : '22';
    final vencimento = _diaVencimentoController.text.isNotEmpty ? 
      _diaVencimentoController.text : '2';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse(_corSelecionada.replaceAll('#', '0xFF'))),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Nome e Bandeira
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bandeira,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informações do Cartão
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Limite',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    limite,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Fechamento/Vencimento',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$fechamento/$vencimento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
  
  /// Seletor de cor como mini cartões (igual às imagens)
  Widget _buildSeletorCor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor do Cartão',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Cores dos cartões reais brasileiros
              '#8A05BE', // Nubank Roxinho
              '#EC7000', // Itaú Laranja 
              '#1E3A8A', // BTG+ Azul escuro
              '#00D924', // PicPay Verde
              '#CC092F', // Bradesco Vermelho
              '#DAA520', // Amex/XP Dourado  
              '#FF7A00', // Inter Laranja
              '#1C1C1C', // C6 Bank Preto
              '#0066CC', // Caixa/BB Azul
              '#006A4E', // Amex Green
              '#00B04F', // Verde Assaí 
              '#C0C0C0', // Cinza metálico
            ].map((cor) {
              final isSelected = cor == _corSelecionada;
              return GestureDetector(
                onTap: () {
                  setState(() => _corSelecionada = cor);
                  _detectarAlteracoes();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 60,  // Menores: 80→60
                  height: 38, // Menores: 50→38
                  decoration: BoxDecoration(
                    color: Color(int.parse(cor.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.3 : 0.1),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                        spreadRadius: isSelected ? 1 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Check se selecionado - menor
                      if (isSelected)
                        Positioned(
                          top: 3,
                          right: 4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Color(int.parse(cor.replaceAll('#', '0xFF'))),
                              size: 8,
                            ),
                          ),
                        ),
                      // Detalhes do mini cartão - menores
                      Positioned(
                        bottom: 3,
                        left: 6,
                        right: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 1.5,
                              width: 15,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 1),
                            Container(
                              height: 1.5,
                              width: 22,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  /// Toggle Cartão Padrão
  Widget _buildToggleCartaoPadrao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cartão de Crédito Padrão',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Será pré-selecionado em novas despesas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Switch(
            value: _cartaoPadrao,
            onChanged: (value) {
              setState(() => _cartaoPadrao = value);
              _detectarAlteracoes();
            },
            activeColor: AppColors.roxoHeader,
          ),
        ],
      ),
    );
  }
  /// Seletor de bandeira
  void _selecionarBandeira() {
    final bandeiras = ['Visa', 'Mastercard', 'Elo', 'American Express', 'Hipercard'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecionar Bandeira',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...bandeiras.map((bandeira) {
              final isSelected = _bandeiraSelecionada == bandeira;
              return ListTile(
                leading: Icon(
                  Icons.payment,
                  color: AppColors.roxoHeader,
                ),
                title: Text(bandeira),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.roxoHeader)
                    : null,
                onTap: () {
                  setState(() {
                    _bandeiraSelecionada = bandeira;
                    _bandeiraController.text = bandeira;
                  });
                  _detectarAlteracoes();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Seletor de conta padrão - INTEGRAÇÃO COM CONTAS REAIS
  void _selecionarContaPadrao() async {
    try {
      // Buscar contas ativas do usuário
      final contas = await _contaService.getContasAtivas();
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Conta Padrão para Pagamento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta conta será sugerida automaticamente para pagamentos da fatura',
                style: TextStyle(fontSize: 14, color: AppColors.cinzaMedio),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Opção "Nenhuma"
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.cinzaMedio),
                title: const Text('Nenhuma conta padrão'),
                trailing: _contaPadraoSelecionada == null 
                    ? const Icon(Icons.check, color: AppColors.roxoHeader)
                    : null,
                onTap: () {
                  setState(() => _contaPadraoSelecionada = null);
                  _detectarAlteracoes();
                  Navigator.pop(context);
                },
              ),
              
              if (contas.isNotEmpty) const Divider(),
              
              // Contas reais do usuário
              ...contas.map((conta) {
                final isSelected = _contaPadraoSelecionada == conta.nome;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: conta.cor != null
                        ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
                        : AppColors.roxoHeader,
                    child: conta.cor == null 
                        ? const Icon(Icons.account_balance, size: 12, color: Colors.white)
                        : null,
                  ),
                  title: Text(conta.nome),
                  subtitle: Text(conta.banco ?? conta.tipo.toUpperCase()),
                  trailing: isSelected 
                      ? const Icon(Icons.check, color: AppColors.roxoHeader)
                      : null,
                  onTap: () {
                    setState(() => _contaPadraoSelecionada = conta.nome);
                    _detectarAlteracoes();
                    Navigator.pop(context);
                  },
                );
              }),
              
              // Mensagem se não há contas
              if (contas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma conta ativa encontrada.\nCrie uma conta primeiro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.cinzaMedio),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contas: $e')),
        );
      }
    }
  }
  
  /// Seção Alterações Detectadas (igual às imagens)
  Widget _buildAlteracoesDetectadas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Alterações Detectadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_alteracoesDetectadas.values.map((alteracao) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.purple[400], size: 6),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alteracao,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ))),
        ],
      ),
    );
  }
  

  Future<void> _salvarCartao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nome = _nomeController.text.trim();
      
      // Parse do valor formatado com vírgula do MoneyInputFormatter
      final limiteText = _limiteController.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
      final limite = double.parse(limiteText);
      
      final bandeira = _bandeiraController.text.trim();
      final contaPadrao = _contaPadraoController.text.trim();
      final diaFechamento = int.parse(_diaFechamentoController.text);
      final diaVencimento = int.parse(_diaVencimentoController.text);

      bool sucesso;

      if (widget.cartao != null) {
        // Editar cartão existente (todos os campos do React)
        final cartaoAtualizado = widget.cartao!.copyWith(
          nome: nome,
          limite: limite,
          bandeira: bandeira.isEmpty ? null : bandeira,
          banco: contaPadrao.isEmpty ? null : contaPadrao, // TODO: Mudar para conta_id
          diaFechamento: diaFechamento,
          diaVencimento: diaVencimento,
          cor: _corSelecionada,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
          ativo: true, // Sempre ativo por padrão
        );
        sucesso = await _cartaoService.atualizarCartao(cartaoAtualizado);
      } else {
        // Criar novo cartão (todos os campos do React)
        final novoCartao = await _cartaoService.criarCartao(
          nome: nome,
          limite: limite,
          bandeira: bandeira.isEmpty ? null : bandeira,
          banco: contaPadrao.isEmpty ? null : contaPadrao, // TODO: Mudar para conta_id
          diaFechamento: diaFechamento,
          diaVencimento: diaVencimento,
          cor: _corSelecionada,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
        );
        sucesso = novoCartao != null;
      }

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cartao != null 
              ? 'Cartão atualizado com sucesso!' 
              : 'Cartão criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true indicando sucesso
      } else {
        throw Exception('Falha ao salvar cartão');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o cartão "${widget.cartao?.nome}"?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirCartao();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCartao() async {
    if (widget.cartao == null) return;

    setState(() => _isLoading = true);

    try {
      final sucesso = await _cartaoService.excluirCartao(widget.cartao!.id);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartão excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true indicando sucesso
      } else {
        throw Exception('Falha ao excluir cartão');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}