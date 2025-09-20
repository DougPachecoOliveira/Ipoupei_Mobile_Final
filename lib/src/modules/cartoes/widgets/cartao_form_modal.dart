import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cartao_model.dart';
import '../services/cartao_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../transacoes/components/smart_field.dart';
import '../../shared/theme/app_colors.dart';

/// MoneyInputFormatter para formatação de moeda
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

      final value = int.parse(numbersOnly);
      final formatted = (value / 100).toStringAsFixed(2).replaceAll('.', ',');
      
      final newText = 'R\$ $formatted';
      
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}

class CartaoFormModal extends StatefulWidget {
  final CartaoModel? cartao;

  const CartaoFormModal({Key? key, this.cartao}) : super(key: key);

  @override
  State<CartaoFormModal> createState() => _CartaoFormModalState();
}

class _CartaoFormModalState extends State<CartaoFormModal> {
  final _formKey = GlobalKey<FormState>();
  final CartaoService _cartaoService = CartaoService.instance;
  final ContaService _contaService = ContaService.instance;

  // ✅ CONTROLLERS
  late final TextEditingController _nomeController;
  late final TextEditingController _limiteController;
  late final TextEditingController _diaFechamentoController;
  late final TextEditingController _diaVencimentoController;
  late final TextEditingController _bancoController;
  late final TextEditingController _observacoesController;
  
  // ✅ FOCUS NODES para navegação automática
  final _nomeFocusNode = FocusNode();
  final _limiteFocusNode = FocusNode();
  final _diaFechamentoFocusNode = FocusNode();
  final _diaVencimentoFocusNode = FocusNode();
  final _bancoFocusNode = FocusNode();
  final _observacoesFocusNode = FocusNode();
  final _salvarButtonFocusNode = FocusNode();
  
  // ✅ SCROLL CONTROLLER para navegação automática
  final _scrollController = ScrollController();

  // ✅ ESTADOS
  String? _bandeiraSelecionada;
  String? _bancoSelecionado;
  String? _contaDebitoId;
  String? _corSelecionada;
  List<ContaModel> _contas = [];
  bool _isLoading = false;
  Map<String, String> _erros = {};

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
    _carregarContas();
    
    // ✅ FOCO AUTOMÁTICO no primeiro campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nomeFocusNode.requestFocus();
    });
  }

  void _inicializarControllers() {
    final cartao = widget.cartao;
    
    _nomeController = TextEditingController(text: cartao?.nome ?? '');
    
    // ✅ FORMATO MOEDA para limite
    if (cartao?.limite != null && cartao!.limite > 0) {
      final limiteFormatado = (cartao.limite * 100).toInt();
      final formatter = MoneyInputFormatter();
      final formatted = formatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: limiteFormatado.toString()),
      );
      _limiteController = TextEditingController(text: formatted.text);
    } else {
      _limiteController = TextEditingController();
    }
    
    _diaFechamentoController = TextEditingController(
      text: cartao?.diaFechamento?.toString() ?? '',
    );
    _diaVencimentoController = TextEditingController(
      text: cartao?.diaVencimento?.toString() ?? '',
    );
    _bancoController = TextEditingController(text: cartao?.banco ?? '');
    _observacoesController = TextEditingController(text: cartao?.observacoes ?? '');
    
    _bandeiraSelecionada = cartao?.bandeira;
    _bancoSelecionado = cartao?.banco;
    _contaDebitoId = cartao?.contaDebitoId;
    _corSelecionada = cartao?.cor ?? CartaoModel.coresPadrao.values.first;
  }

  Future<void> _carregarContas() async {
    try {
      final contas = await _contaService.fetchContas(incluirArquivadas: false);
      setState(() => _contas = contas);
    } catch (e) {
      // Ignora erro - modal funcionará sem débito automático
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _limiteController.dispose();
    _diaFechamentoController.dispose();
    _diaVencimentoController.dispose();
    _bancoController.dispose();
    _observacoesController.dispose();
    
    _nomeFocusNode.dispose();
    _limiteFocusNode.dispose();
    _diaFechamentoFocusNode.dispose();
    _diaVencimentoFocusNode.dispose();
    _bancoFocusNode.dispose();
    _observacoesFocusNode.dispose();
    _salvarButtonFocusNode.dispose();
    
    _scrollController.dispose();
    super.dispose();
  }

  /// ✅ SALVAR CARTÃO
  Future<void> _salvarCartao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _erros.clear();
    });

    try {
      // ✅ EXTRAIR VALOR DO FORMATO MOEDA (R$ X.XXX,XX)
      final limiteText = _limiteController.text;
      double limite = 0.0;
      
      if (limiteText.isNotEmpty) {
        final numbersOnly = limiteText.replaceAll(RegExp(r'[^0-9,]'), '');
        if (numbersOnly.isNotEmpty) {
          final cleanNumber = numbersOnly.replaceAll(',', '.');
          limite = double.tryParse(cleanNumber) ?? 0.0;
        }
      }

      // ✅ VALIDAR DADOS
      _erros = _cartaoService.validarCartao(
        nome: _nomeController.text,
        limite: limite,
        diaFechamento: int.tryParse(_diaFechamentoController.text) ?? 0,
        diaVencimento: int.tryParse(_diaVencimentoController.text) ?? 0,
      );

      // ✅ VERIFICAR NOME DUPLICADO
      final nomeDuplicado = await _cartaoService.verificarNomeDuplicado(
        _nomeController.text,
        cartaoIdExcluir: widget.cartao?.id,
      );

      if (nomeDuplicado) {
        _erros['nome'] = 'Já existe um cartão com este nome';
      }

      if (_erros.isNotEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // ✅ CRIAR OU ATUALIZAR
      CartaoModel resultado;
      
      if (widget.cartao == null) {
        // ✅ CRIAR NOVO
        resultado = await _cartaoService.criarCartao(
          nome: _nomeController.text.trim(),
          limite: limite,
          diaFechamento: int.parse(_diaFechamentoController.text),
          diaVencimento: int.parse(_diaVencimentoController.text),
          bandeira: _bandeiraSelecionada,
          banco: _bancoController.text.trim().isEmpty ? null : _bancoController.text.trim(),
          contaDebitoId: _contaDebitoId,
          cor: _corSelecionada,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
        );
      } else {
        // ✅ ATUALIZAR EXISTENTE
        final cartaoAtualizado = widget.cartao!.copyWith(
          nome: _nomeController.text.trim(),
          limite: limite,
          diaFechamento: int.parse(_diaFechamentoController.text),
          diaVencimento: int.parse(_diaVencimentoController.text),
          bandeira: _bandeiraSelecionada,
          banco: _bancoController.text.trim().isEmpty ? null : _bancoController.text.trim(),
          contaDebitoId: _contaDebitoId,
          cor: _corSelecionada,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
        );

        await _cartaoService.atualizarCartao(cartaoAtualizado);
        resultado = cartaoAtualizado;
      }

      // ✅ RETORNAR RESULTADO
      if (mounted) Navigator.of(context).pop(resultado);

    } catch (e) {
      setState(() {
        _erros['geral'] = 'Erro ao salvar: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          /// ✅ HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.azulHeader,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.cartao == null ? 'Novo Cartão' : 'Editar Cartão',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          /// ✅ FORMULÁRIO COM SMARTFIELDS
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  /// ✅ NOME DO CARTÃO
                  TextFormField(
                    controller: _nomeController,
                    focusNode: _nomeFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Nome do Cartão *',
                      hintText: 'Ex: Nubank, Itaú Crédito...',
                      prefixIcon: const Icon(Icons.credit_card),
                      errorText: _erros['nome'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _limiteFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  /// ✅ LIMITE DO CARTÃO
                  TextFormField(
                    controller: _limiteController,
                    focusNode: _limiteFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Limite do Cartão *',
                      hintText: 'R\$ 0,00',
                      prefixIcon: const Icon(Icons.attach_money),
                      errorText: _erros['limite'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoneyInputFormatter()],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _diaFechamentoFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Limite é obrigatório';
                      }
                      
                      final numbersOnly = value.replaceAll(RegExp(r'[^0-9,]'), '');
                      if (numbersOnly.isEmpty) {
                        return 'Digite um valor válido';
                      }
                      
                      final cleanNumber = numbersOnly.replaceAll(',', '.');
                      final limite = double.tryParse(cleanNumber) ?? 0.0;
                      if (limite <= 0) {
                        return 'Limite deve ser maior que zero';
                      }
                      
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  /// ✅ DATAS
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _diaFechamentoController,
                          focusNode: _diaFechamentoFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Dia Fechamento *',
                            hintText: '15',
                            prefixIcon: const Icon(Icons.calendar_today),
                            errorText: _erros['diaFechamento'],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _diaVencimentoFocusNode.requestFocus(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obrigatório';
                            }
                            final dia = int.tryParse(value) ?? 0;
                            if (dia < 1 || dia > 31) {
                              return 'Entre 1 e 31';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _diaVencimentoController,
                          focusNode: _diaVencimentoFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Dia Vencimento *',
                            hintText: '10',
                            prefixIcon: const Icon(Icons.event),
                            errorText: _erros['diaVencimento'],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _bancoFocusNode.requestFocus(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obrigatório';
                            }
                            final dia = int.tryParse(value) ?? 0;
                            if (dia < 1 || dia > 31) {
                              return 'Entre 1 e 31';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// ✅ BANDEIRA
                  DropdownButtonFormField<String>(
                    value: _bandeiraSelecionada,
                    decoration: InputDecoration(
                      labelText: 'Bandeira',
                      prefixIcon: const Icon(Icons.payment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Selecionar...')),
                      ...CartaoModel.bandeirasPadrao.map((bandeira) =>
                          DropdownMenuItem(value: bandeira, child: Text(bandeira))),
                    ],
                    onChanged: (value) => setState(() => _bandeiraSelecionada = value),
                  ),

                  const SizedBox(height: 16),

                  /// ✅ BANCO
                  TextFormField(
                    controller: _bancoController,
                    focusNode: _bancoFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Banco',
                      hintText: 'Ex: Itaú, Bradesco, Nubank...',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _observacoesFocusNode.requestFocus(),
                    onChanged: (value) => _bancoSelecionado = value.isEmpty ? null : value,
                  ),

                  const SizedBox(height: 12),

                  /// ✅ CONTA DÉBITO AUTOMÁTICO
                  if (_contas.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _contaDebitoId,
                      decoration: InputDecoration(
                        labelText: 'Conta Débito Automático',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                        ..._contas.map((conta) =>
                            DropdownMenuItem(value: conta.id, child: Text(conta.nome))),
                      ],
                      onChanged: (value) => setState(() => _contaDebitoId = value),
                    ),

                  const SizedBox(height: 16),

                  /// ✅ COR
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cor do Cartão',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: CartaoModel.coresPadrao.entries.map((cor) {
                          final isSelected = _corSelecionada == cor.value;
                          return GestureDetector(
                            onTap: () => setState(() => _corSelecionada = cor.value),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(int.parse(cor.value.replaceAll('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// ✅ OBSERVAÇÕES
                  TextFormField(
                    controller: _observacoesController,
                    focusNode: _observacoesFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Notas adicionais...',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),

                  /// ✅ ERRO GERAL
                  if (_erros.containsKey('geral'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _erros['geral']!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  /// ✅ BOTÃO SALVAR
                  SizedBox(
                    height: 48,
                    child: Focus(
                      focusNode: _salvarButtonFocusNode,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _salvarCartao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulHeader,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                widget.cartao == null ? 'Criar Cartão' : 'Salvar Alterações',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}